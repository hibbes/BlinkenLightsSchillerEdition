import controlP5.*;          // GUI-Bibliothek fuer Processing (Buttons, Slider, etc.)
import hypermedia.net.*;     // UDP-Bibliothek fuer Processing

/**
 * Blinkenlights_ServerProcessing.pde  --  BlinkenLightsSchillerEdition
 *
 * Processing-Sketch: Steuerzentrale der BlinkenLights-Installation.
 *
 * Diese Datei ist der Hauptsketch (Einstiegspunkt) des Processing-Programms.
 * Sie enthaelt setup() und draw() -- die beiden Pflicht-Funktionen jedes
 * Processing-Sketches (analog zu Arduino).
 *
 * Systemarchitektur:
 *   [Dieser Sketch am PC]
 *       GUI (controlP5-Buttons) -> Farbauswahl pro Lampe
 *       LightMatrix (3x3)       -> verwaltet 9 Light-Objekte
 *       UDP (hypermedia.net)    -> sendet Hex-Codes an NodeMCU-IPs
 *
 *   [NodeMCU ESP8266]
 *       UDP-Empfang -> IR-Signal senden -> Steckdosenlampe an/aus/Farbe
 *
 * Klassen-Uebersicht:
 *   Blinkenlights_ServerProcessing.pde  <- diese Datei (setup/draw/Callbacks)
 *   LightMatrix.pde  <- 3x3-Matrix aus Light-Objekten
 *   Light.pde        <- eine Lampe (IP + Farbe + sendCurrentColor())
 *   Color.pde        <- Farb-Mapping: Index -> Hex-Code + Farbname
 *   Animation.pde    <- vordefinierte Animationssequenzen
 *   GUI.pde          <- Farbauswahl-Buttons (controlP5)
 *   [Name].pde       <- je eine .pde-Datei pro Schueler mit eigener Animation
 *
 * Kommunikationsprotokoll:
 *   - UDP-Port 8881
 *   - Paketinhalt: Hex-String des IR-Codes (z.B. "20DF10EF")
 *   - Jede Lampe bekommt alle 1000 ms ihren aktuellen Farbcode gesendet
 *     (regelmaessige Wiederholung, da UDP keine Zustellungsgarantie hat)
 *
 * Farbsystem:
 *   Color-Objekte repraesentieren vordefinierte Farben (0..22 + Sonder).
 *   Beispiele: red=0, orange=1, ..., white=15, off=22
 *   Color.getCode() liefert den IR-Hex-Code fuer die Steckdose.
 */

// ---- GUI -----------------------------------------------------------------------
GUI gui;

// ---- UDP-Verbindung ------------------------------------------------------------
int port = 8881;    // Ziel-UDP-Port (muss mit UDP_Port in config.h uebereinstimmen)
UDP udp;            // UDP-Socket-Objekt (hypermedia.net.UDP)

// ---- Timing --------------------------------------------------------------------
long previousMillis = 0;
int light = 0;
long interval = 5000;    // Intervall fuer automatische Animationen (ms)
int flicker = 0;
int held = 0;
int start = millis();    // Zeitstempel fuer den 1-Sekunden-Sendetakt

// ---- Status --------------------------------------------------------------------
boolean transferedsuccessful = false;  // Bestaetigungsflag fuer UDP-Echo

// ---- Farbkonstanten (Color-Objekte) --------------------------------------------
// Index entspricht der Reihenfolge in Color.pde
Color red              = new Color(0);
Color orange           = new Color(1);
Color orangeyellowgreen= new Color(2);
Color yellowgreen      = new Color(3);
Color yellow           = new Color(4);
Color green            = new Color(5);
Color greenblue        = new Color(6);
Color bluegreen        = new Color(7);
Color lightbluegreen   = new Color(8);
Color lightblue        = new Color(9);
Color blue             = new Color(10);
Color bluepurple       = new Color(11);
Color purpleblue       = new Color(12);
Color purple           = new Color(13);
Color lightpurple      = new Color(14);
Color white            = new Color(15);
Color off              = new Color(22);  // Lampe ausschalten
Color on               = new Color(99);  // Lampe einschalten (Sonderwert)

// ---- Lichtmatrix ---------------------------------------------------------------
LightMatrix lightMatrix = new LightMatrix();  // 3x3-Matrix aller Lampen

// ---- setup() -------------------------------------------------------------------
/**
 * Wird einmalig beim Start des Sketches ausgefuehrt (analog zu Arduino setup()).
 *
 * Initialisiert:
 * - GUI mit Farbauswahl-Buttons (controlP5) fuer jede der 9 Lampen
 * - Vollbild-Fenster im Querformat
 * - UDP-Verbindung auf Port 8881
 */
void setup() {
  gui = new GUI(this);

  // Farbauswahl-Buttons erzeugen: 3x3-Raster, je 5 Farb-Buttons pro Lampe
  for (int col = 1; col <= 3; col++) {
    for (int row = 1; row <= 3; row++) {
      gui.generateColorSelector(
        (row-1) * height/3,       // x-Position
        col * height/3 - height/6, // y-Position
        height/3,                  // Breite
        height/6,                  // Hoehe
        col, row                   // Matrixposition
      );
    }
  }

  size(displayWidth, displayHeight);  // Vollbild
  orientation(LANDSCAPE);             // Querformat (fuer Tablet/Touchscreen)

  // UDP-Socket oeffnen (nur empfangen, kein Listen noetig fuer reinen Sender)
  udp = new UDP(this, port);
  // udp.log(true);    // Verbindungsaktivitaet ausgeben (Debugging)
  // udp.listen(true); // Echo-Pakete empfangen (optional)

  println("Setup finished");
}

// ---- Hilfsvariablen fuer Layout ------------------------------------------------
int dWidth  = height;
int quarter = width/4;

// ---- draw() --------------------------------------------------------------------
/**
 * Wird nach setup() endlos wiederholt (ca. 60 FPS = Processing-Standard).
 *
 * Aufgaben:
 * 1. Hintergrund weiss zeichnen (loescht vorherigen Frame)
 * 2. Fuer jede Lampe ein Rechteck mit ihrer aktuellen Farbe zeichnen
 * 3. IP-Adresse und Farbname als Text einblenden
 * 4. Alle 1000 ms: sendCurrentColor() fuer alle 9 Lampen aufrufen
 *    (regelmaessige Wiederholung wegen UDP-Unzuverlaessigkeit)
 */
void draw() {
  background(#FFFFFF);  // weisser Hintergrund

  // Jede Lampe als Rechteck darstellen
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      // Rechteck in Lampenfarbe zeichnen
      fill(lightMatrix.getLight(j+1, i+1).getCurrentColor().getHex());
      rect(i * height/3, j * height/3, height/3, height/3);

      // IP und Farbname als Text einblenden
      fill(0, 0, 0);
      textSize(height/30);
      text("IP=" + lightMatrix.getLight(j+1, i+1).getIpAddr(),
           i*height/3 + 20, j*height/3 + 40);
      textSize(height/40);
      text("Color= " + lightMatrix.getLight(j+1, i+1).getCurrentColor().getName(),
           i*height/3 + 20, j*height/3 + 80);
    }
  }

  // Alle 1000 ms: aktuellen Farbcode an alle NodeMCUs senden
  if (millis() - start > 1000) {
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        lightMatrix.getLight(j+1, i+1).sendCurrentColor();
      }
    }
    start = millis();  // Zeitstempel zuruecksetzen
  }
}

// ---- UDP-Callback --------------------------------------------------------------
/**
 * Wird aufgerufen, wenn ein UDP-Echo-Paket vom NodeMCU eintrifft.
 * Setzt transferedsuccessful = true als Bestaetigung.
 *
 * @param data  empfangene Bytes
 * @param ip    Absender-IP
 * @param port  Absender-Port
 */
void receive(byte[] data, String ip, int port) {
  for (int i = 0; i < data.length; i++) {
    print(char(data[i]));
  }
  println(" --> received");
  transferedsuccessful = true;
}

// ---- controlP5-Callback --------------------------------------------------------
/**
 * Wird automatisch aufgerufen, wenn ein controlP5-Button gedrueckt wird.
 *
 * Button-Namen folgen dem Schema: "button" + col + row + farbGruppe + farbIndex
 * Beispiel: "button1215" -> Lampe (1,2), Farb-Gruppe 1, Farb-Index 5 -> Farbe 10
 *
 * @param theEvent  das ausloesende Control-Event
 */
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isController()) {
    for (int col = 1; col <= 3; col++) {
      for (int row = 1; row <= 3; row++) {
        for (int i = 0; i < 5; i++) {
          for (int j = 0; j < 3; j++) {
            if (theEvent.getController().getName().equals("button" + col + row + j + i)) {
              // j*5+i -> Farb-Index in Color.pde (0..14)
              lightMatrix.getLight(col, row).setColor(new Color(j*5 + i));
            }
          }
        }
      }
    }
  }
}

// ---- Animations-Shortcuts ------------------------------------------------------
/** Alle Lampen ausschalten */
public void allOff() {
  Animation off = new Animation("All Off");
  off.allOff();
}

/** Alle Lampen einschalten */
public void allOn() {
  Animation on = new Animation("All On");
  on.allOn();
}

/** Farbdurchlauf-Animation starten */
public void playAnimation(int theValue) {
  Animation a1 = new Animation("Farbdurchlauf");
  a1.animation();
}

// ---- Schueler-Animationen (je eine Methode pro Schueler) -----------------------
// Jeder Schueler hat eine eigene .pde-Datei mit seiner Animationsklasse.
// Der Button in der GUI ruft die entsprechende Methode hier auf.

public void alexandra() { new Alexandra("Alexandras Animationen").alexandrasAnimation(); }
public void celina()    { new Celina("Celinas Animationen").celinasAnimation(); }
public void denis()     { new Denis("Denis' Animationen").denisAnimation(); }
public void marek()     { new Marek("Mareks Animationen").mareksAnimation(); }
public void emanuel()   { new Emanuel("Emanuels Animationen").emanuelsAnimation(); }
public void jannik()    { new Jannik("Janniks Animationen").janniksAnimation(); }
public void maja()      { new Maja("Majas Animationen").majasAnimation(); }
public void raoul()     { new Raoul("Raouls Animationen").raoulsAnimation(); }
public void sven()      { new Sven("Svens Animationen").svensAnimation(); }
public void miko()      { new Miko("Mikos Animationen").mikosAnimation(); }
public void julius()    { new Julius("Julius' Animationen").juliusAnimation(); }
public void enrico()    { new Enrico("Enricos Animationen").enricosAnimation(); }
public void lars()      { new Lars("Lars' Animationen").larsAnimation(); }

// ---- UDP-Hilfsmethode (Legacy) -------------------------------------------------
/**
 * Sendet einen String per UDP und wartet auf Bestaetigung.
 * Veraltet: Diese Methode blockiert (While-Loop), bis transferedsuccessful = true.
 * Besser: sendCurrentColor() nutzen (nicht-blockierend).
 *
 * @param content der zu sendende String (IR-Hex-Code)
 */
void sendudp(String content) {
  println("Tried to send: --> " + content);
  while (!transferedsuccessful) {
    // Warten auf Echo-Bestaetigung (blockierend!)
    delay(1500);
  }
  transferedsuccessful = false;
}

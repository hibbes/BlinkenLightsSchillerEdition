#include <Arduino.h>
#include <WiFiUdp.h>
#include <ESP8266WiFi.h>
#include <IRsend.h>
#include "WiFiConnection.h"
#include "config.h"

/**
 * main.cpp  --  BlinkenLightsSchillerEdition / NodeMCU-Client
 *
 * Firmware fuer den NodeMCU ESP8266 als Empfaenger im BlinkenLights-System.
 *
 * Kommunikationspfad:
 *   Processing-Server (PC) -> UDP-Paket (Port 8881) -> NodeMCU -> IR-Signal -> Steckdose
 *
 * NEC-Protokoll:
 *   Standard-IR-Protokoll fuer Fernbedienungen.
 *   32-Bit-Code: [Adresse 8 Bit][~Adresse][Befehl 8 Bit][~Befehl]
 *   Der Code wird 6x gesendet (Burst) mit 40 ms Pause fuer Zuverlaessigkeit.
 *
 * Debug-Modus:
 *   Ueber #define Debugmode in config.h steuerbar.
 *   #if(Debugmode)...#endif: Debug-Code im Produktivbetrieb vollstaendig entfernt.
 */

/** IR-Sender an GPIO 5 (config.h: IR_Led_Pin) */
IRsend irsend(IR_Led_Pin);

boolean wifiConnected = false;   // true nach erfolgreicher WLAN-Verbindung
WiFiUDP UDP;                     // UDP-Socket
boolean udpConnected = false;    // true nach erfolgreichem UDP-Bind
char packetBuffer[UDP_TX_PACKET_MAX_SIZE]; // Puffer fuer eingehende Pakete
boolean debugmode = Debugmode;   // Lokale Kopie des Debug-Flags

/**
 * Oeffnet den UDP-Port und wartet auf eingehende Datagramme.
 * UDP: verbindungslos und schnell -- ideal fuer kurze Steuerbefehle.
 */
boolean connectUDP() {
  boolean state = false;

  #if(Debugmode)
    Serial.println("");
    Serial.println("Connecting to UDP");
  #endif

  if (UDP.begin(UDP_Port) == 1) {
    #if(Debugmode)
      Serial.println("Connection successful");
    #endif
    state = true;
  } else {
    #if(Debugmode)
      Serial.println("Connection failed");
    #endif
  }
  return state;
}

/**
 * Arduino setup(): wird einmalig beim Einschalten ausgefuehrt.
 * Reihenfolge: Serial -> WLAN -> UDP -> LED-Pin -> IR-Sender
 */
void setup() {
  #if(Debugmode)
    Serial.begin(115200);  // 115200 Baud = Standard fuer ESP8266
  #endif

  wifiConnected = connectWifi();  // WLAN verbinden (SSID + Passwort aus config.h)

  if (wifiConnected) {
    udpConnected = connectUDP();
    if (udpConnected) {
      // GPIO 2 = eingebaute LED des NodeMCU (aktiv-low: LOW = an)
      pinMode(2, OUTPUT);
      digitalWrite(2, 0);  // LED als Betriebsanzeige einschalten
    }
  }

  irsend.begin();  // IR-Sender initialisieren (38-kHz-Traeger starten)
}

/**
 * Arduino loop(): endlose Wiederholung nach setup().
 *
 * Ablauf pro Iteration:
 * 1. UDP.parsePacket(): 0 = kein Paket; >0 = Paketgroesse in Bytes
 * 2. Paket lesen in packetBuffer
 * 3. Hex-String -> Integer: strtol(buffer, 0, 16) [Basis 16 = hex]
 *    Beispiel: "20DF10EF" -> 0x20DF10EF -> 551485679
 * 4. IR-Signal 6x senden (NEC, 32 Bit, 40 ms Pause)
 * 5. Echo-Antwort an Sender
 * 6. 10 ms Pause (max. 100 Pakete/Sekunde)
 */
void loop() {
  if (wifiConnected) {
    if (udpConnected) {

      int packetSize = UDP.parsePacket();  // 0 = kein Paket

      if (packetSize) {
        #if(Debugmode)
          Serial.println("");
          Serial.print("Received packet of size ");
          Serial.println(packetSize);
          Serial.print("From ");
          IPAddress remote = UDP.remoteIP();
          for (int i = 0; i < 4; i++) {
            Serial.print(remote[i], DEC);
            if (i < 3) Serial.print(".");
          }
          Serial.print(", port ");
          Serial.println(UDP.remotePort());
        #endif

        UDP.read(packetBuffer, UDP_TX_PACKET_MAX_SIZE);

        // Hex-String -> Integer (Basis 16)
        int integerValue = (int) strtol(packetBuffer, 0, 16);

        // IR-Signal 6x senden fuer zuverlaessige Uebertragung
        for (int i = 0; i < 6; i++) {
          irsend.sendNEC(integerValue, 32);
          delay(40);
        }

        #if(Debugmode)
          Serial.print("Contents: { Hex: ");
          Serial.print(packetBuffer);
          Serial.print(", Int: ");
          Serial.print(integerValue);
          Serial.print("}\n");
        #endif

        // Echo zurueck an Sender (Bestaetigung)
        UDP.beginPacket(UDP.remoteIP(), UDP.remotePort());
        UDP.write(packetBuffer);
        UDP.endPacket();
      }

      delay(10);
    }
  }
}

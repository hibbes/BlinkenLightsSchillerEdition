/**
 * LightMatrix.pde  --  BlinkenLightsSchillerEdition / Processing-Server
 *
 * Verwaltet die 3x3-Matrix aus 9 Steckdosenlampen an der Schulwand.
 *
 * Jede Lampe (Light-Objekt) hat eine IP-Adresse (NodeMCU im Schul-WLAN).
 * Die Matrix wird 1-basiert angesprochen: getLight(1,1) = oben links.
 * Intern: 0-basiertes 2D-Array lights[3][3].
 *
 * Layout an der Wand (Zeile, Spalte):
 *   [1,1] [1,2] [1,3]
 *   [2,1] [2,2] [2,3]
 *   [3,1] [3,2] [3,3]
 */
class LightMatrix {
  private int sizeX;   // Breite der Matrix (3)
  private int sizeY;   // Hoehe der Matrix (3)

  // IP-Adressen der NodeMCUs im Schulnetz (Zeile_Spalte)
  // Zuordnung muss mit der physischen Position an der Wand uebereinstimmen
  String ip11 = "172.17.243.182";  String ip12 = "172.17.104.185";  String ip13 = "172.17.115.140";
  String ip21 = "172.17.28.154";   String ip22 = "172.17.240.96";   String ip23 = "172.17.112.204";
  String ip31 = "172.17.144.34";   String ip32 = "172.17.95.122";   String ip33 = "172.17.93.237";

  // Light-Objekte: je eines pro NodeMCU/Steckdose
  Light light11 = new Light(ip11);  Light light12 = new Light(ip12);  Light light13 = new Light(ip13);
  Light light21 = new Light(ip21);  Light light22 = new Light(ip22);  Light light23 = new Light(ip23);
  Light light31 = new Light(ip31);  Light light32 = new Light(ip32);  Light light33 = new Light(ip33);

  // 2D-Array der Lights: lights[Zeile-1][Spalte-1]
  // (0-basiert intern, aber 1-basiert nach aussen via getLight())
  Light[][] lights = {
    {light11, light12, light13},
    {light21, light22, light23},
    {light31, light32, light33}
  };

  /** Erstellt die 3x3-Matrix */
  LightMatrix() {
    this.sizeX = 3;
    this.sizeY = 3;
  }

  /**
   * Ersetzt ein Light-Objekt an der angegebenen 1-basierten Position.
   *
   * @param light  neues Light-Objekt
   * @param posX   Zeile (1-3)
   * @param posY   Spalte (1-3)
   * @return true bei Erfolg, false wenn Position ausserhalb der Matrix
   */
  public boolean setLightPos(Light light, int posX, int posY) {
    if (posX <= sizeX && posY <= sizeY) {
      lights[posX][posY] = light;
      return true;
    }
    return false;
  }

  /**
   * Gibt das Light-Objekt an der angegebenen 1-basierten Position zurueck.
   *
   * Beispiel: getLight(1,1) -> Lampe oben links
   *           getLight(3,3) -> Lampe unten rechts
   *
   * Fehlerbehandlung: bei ungueltiger Position wird eine Dummy-Lampe
   * (IP 127.0.0.1 = localhost) zurueckgegeben, damit kein NullPointer auftritt.
   *
   * @param posX  Zeile (1-3)
   * @param posY  Spalte (1-3)
   * @return Light-Objekt an dieser Position
   */
  public Light getLight(int posX, int posY) {
    if (posX <= sizeX && posY <= sizeY && posX > 0 && posY > 0) {
      return lights[posX - 1][posY - 1];  // 1-basiert -> 0-basiert umrechnen
    }
    println("Fehler: getLight(" + posX + "," + posY + ") ausserhalb der Matrix! " +
            "Gueltige Werte: 1 bis " + sizeX + " (Zeile) und 1 bis " + sizeY + " (Spalte).");
    return new Light("127.0.0.1");  // Fallback-Objekt, damit kein NullPointer
  }
}

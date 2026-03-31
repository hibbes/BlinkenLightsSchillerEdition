/**
 * Light.pde  --  BlinkenLightsSchillerEdition / Processing-Server
 *
 * Repraesentiert eine einzelne Steckdosenlampe im BlinkenLights-System.
 *
 * Jede Lampe hat eine IP-Adresse (NodeMCU im Schul-WLAN) und eine aktuelle Farbe.
 * sendCurrentColor() schickt per UDP einen Hex-Code an den NodeMCU,
 * der diesen in ein IR-Signal umwandelt und an die Steckdose sendet.
 *
 * Objekt-Netzwerk:
 *   LightMatrix (3x3)
 *     -> Light [9 Objekte]
 *          -> ipAddr: NodeMCU-IP
 *          -> currentColor: aktuelle Farbe
 *          -> sendCurrentColor(): UDP-Paket senden
 */
class Light {
    private String ipAddr;        // IP-Adresse des zugehoerigen NodeMCU
    private Color currentColor;   // aktuell eingestellte Farbe

    /**
     * Erstellt ein Light-Objekt mit gegebener IP und weisser Startfarbe (Farbe 15).
     */
    Light(String ipAddr) {
        this.ipAddr = ipAddr;
        currentColor = new Color(15);  // 15 = weiss (laut Color.pde)
    }

    /** @return IP-Adresse dieses NodeMCU */
    public String getIpAddr() {
        return ipAddr;
    }

    /** @return aktuell eingestellte Farbe */
    public Color getCurrentColor() {
        return currentColor;
    }

    /**
     * Setzt die Farbe ohne sofortige Uebertragung.
     * Sendung erfolgt durch sendCurrentColor() (alle 1000 ms aus draw()).
     */
    public void setColor(Color c) {
        currentColor = c;
    }

    /** @return UDP-Port (global im Hauptsketch: port = 8881) */
    public int getPort() {
        return port;
    }

    /**
     * Sendet die aktuelle Farbe per UDP an den NodeMCU.
     *
     * Wird aus dem draw()-Loop aufgerufen (alle 1000 ms), so dass jeder
     * Farbbefehl regelmaessig wiederholt wird -- UDP ist verbindungslos
     * und ohne Zustellungsgarantie.
     *
     * Ablauf: currentColor.getCode() -> Hex-String -> UDP-Paket -> NodeMCU -> IR -> Steckdose
     */
    public void sendCurrentColor() {
        udp.send(currentColor.getCode(), ipAddr, port);
    }
}

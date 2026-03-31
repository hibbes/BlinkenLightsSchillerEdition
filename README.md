# BlinkenLightsSchillerEdition

Schulprojekt der **Friedrich-Schiller-Schule**: Eine interaktive 3×3-LED-Matrix, gesteuert
von einem Processing-Server (PC) über UDP-WiFi an NodeMCU-Clients (ESP8266).

> Basiert auf dem [BlinkenLights-Projekt](https://github.com/original/BlinkenLights).
> Diese "Schiller Edition" wurde von Schülern des Informatikunterrichts erweitert.

## Systemarchitektur

```
PC (Processing-Server)          NodeMCU (ESP8266-Client)
┌─────────────────────────┐     ┌─────────────────────────┐
│ Blinkenlights_Server    │ UDP │  BlinkenLights/          │
│ Processing.pde          │────▶│  src/main.cpp            │
│                         │     │  WiFiConnection.cpp/.h   │
│ 3×3 Farbmatrix-GUI      │     │                          │
│ Animationen per Klick   │     │ Empfängt Farbbefehle,    │
│                         │     │ steuert LED-Matrix       │
└─────────────────────────┘     └─────────────────────────┘
```

## Schüler-Animationen

Jeder Schüler hat eine eigene `.pde`-Datei mit einer selbst programmierten Animation:

| Datei | Schüler |
|-------|---------|
| `Alexandra.pde` | Alexandra |
| `Celina.pde` | Celina |
| `Denis.pde` | Denis |
| `Emanuel.pde` | Emanuel |
| `Enrico.pde` | Enrico |
| `Jannick.pde` | Jannick |
| `Julius.pde` | Julius |
| `Lars.pde` | Lars |
| `Maja.pde` | Maja |
| `Marek.pde` | Marek (Lehrer) |
| `Marvin.pde` | Marvin |
| `Miko.pde` | Miko |
| `Raoul.pde` | Raoul |
| `Sven.pde` | Sven |

## Technische Komponenten

### Server (Processing)
- `Blinkenlights_ServerProcessing.pde` – Hauptprogramm: GUI, UDP-Sender, Animation-Dispatcher
- `LightMatrix.pde` – Datenmodell: 3×3 Matrix von `Light`-Objekten
- `Light.pde` – Einzelne LED: IP-Adresse, Farbe, UDP-Senden
- `Color.pde` – Farbdefinitionen (16 vordefinierte + off/on)
- `Animation.pde` – Basisklasse für alle Schüler-Animationen
- `GUI.pde` – Benutzeroberfläche (ControlP5-Bibliothek)

### Client (NodeMCU / C++)
- `src/main.cpp` – Empfängt UDP-Pakete, steuert LEDs
- `src/WiFiConnection.cpp/.h` – WiFi-Verbindungsmanagement
- `src/config.h` – Netzwerkkonfiguration (SSID, Passwort, IP)

## Lernziele (Unterricht)

- **Netzwerkprogrammierung**: UDP-Sockets in Processing
- **IoT / Hardware**: NodeMCU programmieren, LEDs steuern
- **Objektorientierung**: `Animation`-Basisklasse, Vererbung in Processing (Java-ähnlich)
- **Kreatives Programmieren**: Jeder Schüler entwirft eine eigene Lichtanimation

## Verwendete Bibliotheken

- [Processing](https://processing.org/) (Server)
- [ControlP5](http://www.sojamo.de/libraries/controlP5/) (GUI)
- [UDP für Processing](http://ubaa.net/shared/processing/udp/)
- [PlatformIO](https://platformio.org/) (NodeMCU-Firmware)

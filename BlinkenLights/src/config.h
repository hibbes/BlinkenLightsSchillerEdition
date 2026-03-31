//#pragma once

/**
 * config.h  --  BlinkenLightsSchillerEdition / NodeMCU-Client
 *
 * Zentrale Konfigurationsdatei fuer die Hardware-Seite des BlinkenLights-Projekts.
 * Alle hardwareabhaengigen Parameter an einem Ort.
 *
 * Hardware:
 *   NodeMCU ESP8266  (WLAN-Mikrocontroller, Arduino-kompatibel)
 *   IR-LED           an Pin D1 (GPIO 5)
 *   Fernbedienungssteckdose mit NEC-Protokoll
 */

/** IR-LED an GPIO 5 (= Pin D1 auf NodeMCU-Board).
 *  D0 und D1 sind die stabilsten Pins; andere koennen bei WLAN-Aktivitaet flackern. */
#define IR_Led_Pin 5

/** SSID des Schul-WLANs */
#define WiFi_SSID "Grube"

/** WLAN-Passwort */
#define WiFi_PASSWD "sicherheitgehtvor"

/** UDP-Port, auf dem der NodeMCU lauscht.
 *  Muss mit 'port' im Processing-Sketch uebereinstimmen (dort: port = 8881). */
#define UDP_Port 8881

/** Debug-Modus: 0 = aus (Produktivbetrieb), 1 = an (Serial Monitor 115200 Baud).
 *  Mit Debugmode=1 werden Verbindungsstatus und Paketinhalte ausgegeben. */
#define Debugmode 0

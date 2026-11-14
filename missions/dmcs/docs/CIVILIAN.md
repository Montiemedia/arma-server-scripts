# Zivile Einsaetze und dynamisches Zivilleben

DMCS bleibt **COOP-only**, darf aber auch zivilen Spielern Arbeit geben. Fuer Rettungs-, Verwaltungs-, Logistik- oder journalistische Rollen sind nicht automatisch Gegner erforderlich.

## Bereits im Prototyp implementiert

### Ortsbesichtigung (`civ_visit`)

Die Mannschaft wird an einen definierten Punkt geschickt und muss den Bereich fuer die vom Skalierungsprofil vorgegebene Zeit aufsuchen. Keine Gegnergenerierung.

### Botengang (`civ_courier`)

Phase 1: Zum ausgewählten `dyn_zone_X`-Marker fahren, mindestens zehn Sekunden bleiben. Phase 2: Zum Marker `dyn_civ_dropoff` fahren und weitere zehn Sekunden dort bleiben. Das BIS-Task-Ziel wechselt in Phase 2. **Das Abholen/Abgeben ist simuliert.** Kein physischer Gegenstand, Inventar, Unterschrift oder Fahrzeugtransport.

### Bereits vorhandene zivile Varianten

Aufklaerung, Personenschutz und Versorgung duerfen von Zivilspielern ohne automatisch erzeugte Feinde erledigt werden. Komplexe Evakuierung/Patiententransport oder echte Warenlogistik existieren noch nicht.

## Optionale Weltbevoelkerung

Host-Menue: **Zivil EIN** / **Zivil AUS**. Server kontrolliert alle 25 Sekunden die Bevoelkerung. Die Agentenzahl ist begrenzt und skaliert mit der Zahl lebender Spieler. Keine unkontrollierten Respawn- oder Action-Duplikate. In der Mission keine `setFriend`-Aenderungen gegen `civilian` durchfuehren.

Beispielkonfiguration in `description.ext`:

```cpp
playerSide = "AUTO";
ambientCivEnabled = 0;
ambientCivMax = 16;
ambientCivPerPlayer = 2;
ambientCivClasses[] = {"C_man_1"};
civilDropoffMarker = "dyn_civ_dropoff";
```

## Ideen fuer die naechsten Versionen (noch NICHT implementiert)

* Rettungsdienst: Meldung, Patientenversorgung, Fahrzeug-Transport, Uebergabe im Krankenhaus.
* Feuerwehr: Brandstellen absichern, technische Hilfe, Evakuierung und Wasserlogistik.
* Polizei: Verkehrsunfall, Vermisstensuche, Spurensicherung, Identitaetskontrolle.
* Journalismus: Augenzeugen aufsuchen, Tatorte dokumentieren, Interviews ohne bewaffneten Konflikt.
* Humanitaere Hilfe: Versorgungslisten, Lieferungen, Ausgabe und soziale Folgen bei Ausfall.
* Alltagssimulation: Passanten mit Tagesablaeufen, Parkplaetze, kleine lokale Ereignisse, Fahrzeuge, Verkehrsstrom.
* Lagedarsteller: Zivilpersonen, die bei Angriffen fluechten, Beschaedigung melden oder Hilfe anfordern.

Fuer diese Erweiterungen braucht es getrennte Interaktions-, Verkehrs- und Rollenmodule sowie geeignete Konfigurationsprofile und laufzeitbasierte Performancepruefungen.

## Zu testen

In 3DEN zivile Playable-Einheiten anlegen, alle Seiten ausser CIV ohne spielbare Slots lassen, `dyn_zone_1` bis `dyn_zone_3`, `dyn_civ_dropoff` und `respawn_civilian` setzen. Botengang ueber beide Phasen abschliessen, anschliessend Zivil EIN/AUS in Stadt, Dorf und unbesiedeltem Gebiet pruefen. Erst nach echtem Multiplayer-Test als lauffaehig kennzeichnen.

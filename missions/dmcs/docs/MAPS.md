# DMCS – Karten- und Fraktionskompatibilitaet

DMCS ist kein an Altis gebundenes Framework. Pro Karte ist eine eigene `mission.sqm` mit passendem Welt-Namenssuffix erforderlich, z. B. `DMCS.Altis` oder `DMCS.Enoch`.

## Seiten und Fraktionen

* COOP-Spieler duerfen **WEST, EAST, GUER oder CIV** als Seite verwenden.
* Innerhalb der gemeinsamen Spieler-Seite koennen verschiedene Vanilla-/Mod-Fraktionen vertreten sein.
* Die automatische Erkennung verweigert Auftragsstart bei gleichzeitigem menschlichen Einsatz auf unterschiedlichen Seiten, denn gemischte Seiten-Allianzen sind in diesem Prototyp noch nicht umgesetzt.
* Die Gegnerfraktion wird per Missions-Konfig `enemyEastRifle/AR` bzw. `enemyWestRifle/AR` festgelegt; ohne Mod-Anpassung wird auf Vanilla-Klassen zurueckgegriffen.
* EAST-Spieler bekommen WEST als Gegner. WEST oder GUER bekommen EAST als Gegner. CIV-Spieler erhalten keine durch DMCS gespawnten Gegner. Fuer GUER-Einsaetze Feindschaft im 3DEN-Intel setzen oder pruefen. **Keine globalen feindlichen Beziehungen zur zivilen Seite setzen**.

## 3DEN-Marker

* `dyn_zone_1`, `dyn_zone_2`, `dyn_zone_3`: vordefinierte Auftragssektoren.
* `dyn_civ_dropoff`: Botengang-Abgabepunkt (mindestens 60 m vom gewaehlten Auftragseinsatzort).
* `respawn_west`, `respawn_east`, `respawn_guerrila` oder `respawn_civilian` passend zur gewaehlten Team-Seite.

## Optionale zivile Simulation

Das Modul versucht Agenten nur nahe bereits benannter Staedte/Doerfer und in Strassennaehe zu erzeugen. Auf Terrains ohne solche Weltinformationen bleibt die Bevoelkerung gegebenenfalls leer. Es sind noch keine Mod-spezifischen Location-Adapter integriert.

## Abnahmeliste je Karte

1. Alle benoetigten Kartenmods und Signatur-Keys auf Server/Clients vorhanden.
2. Menschliche Coop-Slots und korrekter Respawn fuer die gewaehlte Spieler-Seite.
3. Auftrags- und Botengang-Marker auf freiem, begehbarem Land.
4. Spieler- und Gegner-Klassen in `CfgVehicles` vorhanden, richtige Seitenzuordnung der erzeugten Gegner.
5. Fraktionsbeziehungen im Intel-Dialog passend zur Missionsidee.
6. KI-Pfadfindung, Aufgabe, JIP-Sync und Objektbereinigung mit realen Spielern testen.
7. Civ-Modul nahe Ortschaften und im freien Gelaende mit aktivierter/deaktivierter Population testen.
8. Mod-RPC-Abhaengigkeiten und RPT-Fehler auf TF133-Server pruefen.

**Status:** Konzept mit Prototypcode; keine Garantie fuer alle Modkarten, Fraktionen oder Gameplay-Mods.

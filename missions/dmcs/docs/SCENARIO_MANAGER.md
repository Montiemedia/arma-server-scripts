# DMCS-Szenariomanager – Prototyp 0.4

**Status: Quellcode implementiert; Arma 3, 3DEN, JIP und Dedicated Server NICHT praktisch getestet.**
Dies ist ein bewusst begrenzter *vertical slice* fuer die Einbindung der 800 Erzaehlvorlagen. Keine 800 individuell geskripteten Einsaetze.

## Architektur

```text
scenarios/{WEST,EAST,GUER,CIV}.json     Redaktionsquelle, 200 pro Seite
          |
          v
tools/build_scenario_catalog.py         reproduzierbarer Build
          |
          v
dyn/scenarios/{west,east,guer,civ}.hpp   800 Config-Klassen, UTF-8
          |
          v
dyn/scenarios/catalog.hpp               DYN_ScenarioCatalog
          |
          v
description.ext                          Include im Missionspaket
          |
          +-----------------------+
          |                       |
          v                       v
DYN_fnc_scenarioRefresh     DYN_fnc_scenarioGet
Client: Anzeige/Filter      Server: ID -> vertrauenswuerdige Definition
          |                       ^
          v                       |
DYN_fnc_scenarioSubmit  ------> DYN_fnc_request
nur Szenario-ID + Zone         Admin/UID-Check, gemeinsame COOP-Seite,
                               Typ-/Zonen-Check, maxTasks, DRAFT anlegen
                                      |
                                      v
                                DYN_fnc_start
                                Briefing und Task aus echter Config
                                      |
                                      v
                                bestehende DMCS-Basismethode
```

Die Client-GUI liest jeweils nur 200 Config-Klassen der gewaehlten Seite. Keine 800 Laufzeit-SQF-Prozesse, keine 800 dynamisch gestarteten Missionsauftraege.

## Installation in 3DEN

1. In 3DEN eine Mission fuer die gewuenschte Karte und eine gemeinsame COOP-Seite (WEST/EAST/GUER/CIV) anlegen.
2. Nur die gewuenschte Seite als **spielbar** markieren; andere Seiten duerfen als KI erscheinen.
3. Drei Marker `dyn_zone_1`, `dyn_zone_2`, `dyn_zone_3` auf begehbaren, freien Landpositionen erstellen. Mehr Marker sind ueber `DYN_Settings.zones[]` in `description.ext` moeglich.
4. Fuer die Basismethode `civ_courier` muss auch `dyn_civ_dropoff` vorhanden sein.
5. `description.ext`, `initServer.sqf`, `initPlayerLocal.sqf`, den **gesamten** Ordner `dyn/` inklusive `dyn/scenarios/*.hpp` und `dyn/functions/*.sqf` in das Missionsverzeichnis kopieren. Die `mission.sqm` wird von 3DEN erstellt.
6. Als berechtigter Admin oder Whitelist-Lagedarsteller `DMCS | Einsatzfuehrung` oeffnen und unten `Szenariobibliothek (800)` waehlen.
7. Im Bibliotheksdialog Seite, Kategorie, Zeitfenster und empfohlene Teamgroesse filtern. Die Auswahl einer fremden Seite ist zur Vorschau erlaubt; die Anlage wird serverseitig fuer die falsche Seite abgelehnt.
8. Szenario, Einsatzsektor aus 3DEN und `Als Entwurf anlegen` waehlen. Auf Serverrueckmeldung achten.
9. Ueber `Zur Einsatzfuehrung` zurueckgehen und den neu angelegten Entwurf **aktivieren**. Er kann zuvor in seiner Zone geaendert oder geloescht werden; sein Bibliotheks-Auftragstyp ist geschuetzt.
10. Im BIS-Task-Menue den individuellen Titel, das Story-Briefing und das konkrete Einsatzziel pruefen.

Die Zeit- und Spielerzahlfilter sind **Empfehlungsfilter**; die genannten 25–120 Minuten sind weder durch eine echte Laufzeitmessung noch durch einen Ablauf-Timer unterlegt. Der Server prueft Spielerfraktion, ID und Marker vor Anlage und nochmals Fraktion/Mechanik vor Aktivierung. Die Spielerzahl wird weiterhin fuer die existierende DMCS-Basis-Skalierung verwendet.

## Struktur der exportierten Config

```cpp
class DYN_ScenarioCatalog {
    class WEST {
        class S001 {
            id = "W-001";
            side = "WEST";
            category = "Aufklaerung und Lagebild";
            title = "Die stille Frequenz";
            briefing = "...";
            objective = "...";
            mechanic = "recon";
            estimatedMinutes = 25;
            minPlayers = 2;
            maxPlayers = 6;
        };
        // ... bis S200
    };
    // EAST, GUER, CIV
};
```

Die reale Quelldatei wurde maschinell aus dem Katalog generiert, nicht manuell so geschrieben. Server und Client lesen dieselbe in `missionConfigFile` eingebundene Definition. Clients senden ausschliesslich die Kennung (z. B. `W-001`) und einen freigegebenen Marker. Freie Storytexte, CfgVehicles-Klassen und Positionen sind **keine erlaubten RPC-Argumente**.

## Story vs. Missionsmechanik

Ein Bibliotheks-Szenario hat eine plausible Erzaehlung, einen Namen und einen Vorschlag fuer eine Basismethode. Die Methoden sind:
`recon`, `secure`, `destroy`, `rescue`, `supply`,
`civ_visit`, `civ_courier`, `civ_medical`.

**Die Auswahl startet die passende Basismethode, NICHT die komplette Geschichte.**
Beispiel: `C-001 Rauch ueber der Baeckerei` verwendet zunaechst die Basismethode `civ_visit`. Es wird also eine Ortsbesichtigung als Auftrag angelegt, aber noch **kein Brand** simuliert, keine Bewohner gerettet und kein Loeschangriff gesteuert.

Das ist absichtlich offen benannt. Eine spaetere Version braucht szenario-spezifische Daten zu Objekten, Zivilrollen, Fahrzeugen, Schadenslagen, Bedingungen und plausiblen Folgeereignissen, damit eine Ortsgeschichte als vollstaendige Mission spielbar wird.

## Autorenworkflow

1. Die passende JSON-Datei in `scenarios/` anpassen.
2. IDs und die jeweilige Zahl von 200 Eintraegen beibehalten. Fuer neue Eintraege den Katalog und Validator bewusst versionieren.
3. Exportieren: `python3 tools/build_scenario_catalog.py` (aus `missions/dmcs/`) bzw. `python3 missions/dmcs/tools/build_scenario_catalog.py` (vom Repository-Root).
4. Pruefen: `python3 tools/build_scenario_catalog.py --check` und `python3 tools/validate_scenarios.py`.
5. `python3 tools/validate_static.py` fuer Funktions-/Klammerstruktur verwenden.
6. JSON und generierte HPP-Dateien gemeinsam committen. GitHub Actions prueft alle drei Preflight-Schritte automatisch beim Push/PR.

## Testvorschlaege

* Alle vier Seiten getrennt, Testfall `W-001`, `E-001`, `G-001`, `C-001`.
* Alle Kategorien auf jeder Seite im Filter sichtbar, insgesamt 200 pro Seite ohne Filter.
* Filter fuer unter 30/60/90 Minuten und Spielerempfehlung verifizieren.
* Unpassenden Seitenkatalog aufrufen: Vorschau moeglich, Server lehnt `scenario`-Anfrage ab.
* Gueltige Vorlage als Entwurf anlegen; kontrollieren, ob ID und Typ im Host-Dialog erscheinen.
* Gefaelschte IDs, fehlende Marker, nicht vertrauenswuerdiger Client, Max-Tasks-Grenze.
* Bearbeitung eines Entwurfs: Zone ja, abweichender Typ nein.
* Aufgabenaktivierung und RPT-Meldungen, Titel und Briefing pruefen.
* JIP-Spieler: Aufgabe und Beschreibung sichtbar; bestehende Aufgabenliste laedt.
* Modset ACE/CBA/ACRE2 sowie TF133-Preset; `CfgRemoteExec` kann dabei angepasst werden muessen.
* Zwei gleichzeitig aktive Bibliotheksmissionen, Abschluss und Bereinigung.

Siehe [TESTS.md](TESTS.md).

## Grenzen

Kein eigenstaendiger Missionsexport ohne `mission.sqm`. Keine automatische Anpassung fiktiver Orte an konkrete Karten, kein Szenen-Baukasten, keine zivilen Fahrzeugstroeme und keine szenariogenaue KI-Interaktion. Positionspruefungen sind auf 3DEN-Marker und Wasserbeschaffenheit begrenzt. JIP-Aufgaben beruhen auf dem Vanilla-Task-Framework; ihre korrekte MP-Synchronisation muss praktisch getestet werden. Die `CfgRemoteExec`-Whitelist muss fuer das tatsaechliche Modset geprueft werden.

**Die Quellcode-Einbindung ist eine Implementierung, kein Nachweis fuer fehlerfreien Arma-3-Multiplayer-Betrieb.**

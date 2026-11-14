# DMCS-Szenariobibliothek

**800 fiktive COOP-Szenariovorschlaege** fuer Arma 3, jeweils **200 pro Spielerseite** (`WEST`, `EAST`, `GUER`, `CIV`). Die vier Seiten sind Arma-`Side`-Werte; sie stehen **nicht** fuer konkrete Mod-Fraktionen. Namen, Orte, Institutionen und Konflikte in den Geschichten sind Fiktion.

| Spielerseite | Lesefassung | Datenfassung | Themenbereiche |
|---|---|---|---|
| WEST | [200 Briefings](WEST.md) | [WEST.json](WEST.json) | Aufklaerung, Schutz, Evakuierung, Konvoi, Infrastruktur, CIMIC, Waffenruhe, Kuestenraum, Standortschutz, Krise |
| EAST | [200 Briefings](EAST.md) | [EAST.json](EAST.json) | Grenzschutz, Logistik, Aufklaerung, Objektschutz, Zivilverwaltung, Luft/Kuestenraum, Rettung, Uebergaben, Dienstaufsicht, Katastrophen |
| GUER | [200 Briefings](GUER.md) | [GUER.json](GUER.json) | Gemeindeschutz, Beobachtung, Freiwilligenlogistik, Vermisste, Infrastruktur, Vermittlung, Flucht/Rueckkehr, Verantwortung, Nothilfe, Deeskalation |
| CIV | [200 Briefings](CIV.md) | [CIV.json](CIV.json) | Feuerwehr, Rettungsdienst, Polizei, THW, Hilfsorganisationen, Journalismus, Soziales, Umwelt/Tiere, Verkehr, Bildung/Kultur |

Jede Seite enthaelt **10 Kategorien mit je 20 Szenarien**, insgesamt 40 Kategorien und 800 verschiedene Szenario-IDs.

## Datenmodell pro Szenario

* `id`: stabile Szenario-ID, z. B. `C-041`
* `side`: WEST / EAST / GUER / CIV; die Seitenvorgabe fuer einen gemeinsamen COOP-Einsatz
* `category`: Einsatzfamilie zur spaeteren Auswahl im Host-Menue
* `title`: eindeutiger Titel innerhalb einer Seite
* `lead` oder `characters[]`: fiktive Kontaktperson
* `location`: erzaehlerischer Schauplatz, **keine Kartenkoordinate**
* `premise`: ausloesende Lage
* `complication`: moegliche Unsicherheit oder zweite Entwicklung
* `objective`: menschlich lesbares Einsatzziel
* `story`: zusammengestellter Briefingtext
* `suggested_mechanic`: grober Bezug zu einer DMCS-Auftragsart, **keine Garantie auf Umsetzung**
* `implementation`: weiter `CONCEPT_ONLY`, weil die Erzaehlung noch nicht als spezifische Szenerie mit Objekten/NPCs umgesetzt ist. Die Vorlagen selbst werden seit v0.4 im Host-Menue als Config-Klassen geladen und koennen als generischer DMCS-Auftrag aktiviert werden.
* `estimated_minutes` und `players_recommended`: redaktionelle Richtwerte, **nicht gemessene Spielzeiten**

## Laufzeit-Einbindung seit Prototyp 0.4

Die 800 JSON-Eintraege werden mit `python3 missions/dmcs/tools/build_scenario_catalog.py` in vier `.hpp`-Dateien unter `dyn/scenarios/` exportiert. Ueber `dyn/scenarios/catalog.hpp` und `description.ext` stehen die Definitionen als `DYN_ScenarioCatalog` in `missionConfigFile` bereit. **Die SQF-Engine liest nicht die JSON-Dateien direkt.**

Ueber das Host-Menue (`DMCS | Einsatzfuehrung` -> `Szenariobibliothek (800)`) sind Seite, Kategorie, empfohlene Spielerzahl, Einsatzdauer, Szenario und 3DEN-Zonenmarker waehlbar. Der Server prueft die ID und die gemeinsame Spieler-Seite vor dem Erstellen eines Entwurfs und beim Aktivieren. Dann verwendet der BIS-Task die gewaehlten Texte und die vorhandene Basismethode.

**Bereits implementiert:** Datenexport, Auswahloberflaeche, clientseitige Filterung, servergepruefte Entwurfsanlage, Briefinguebernahme, generische Auftragsaktivierung. **Noch offen:** spezielle Story-Ereignisse, interaktive Rollen/Dialoge, realistische Brand- und Unfallobjekte, automatischer Terrain-Resolver, dynamische Story-Komplikationen, spezifische NPC-Reaktionen und vollstaendige Multiplayer-Abnahme.

Details: [Szenariomanager](../docs/SCENARIO_MANAGER.md).

## Naechste Umsetzungsschritte

1. Pro Szenario ein erweiterbares `ScenarioDefinition` fuer konkrete Objekte, Zustaende, NPCs, Rollen und Folgeereignisse festlegen.
2. Terrain-Resolver fuer Kartenobjekte, freie Spawn-Positionen und Ortstypen erarbeiten.
3. Komplette Einzelmechaniken wie Rettung, Brand, Unfallaufnahme, Interviews, Lieferung, Schutz und Evakuierung integrieren.
4. Multiplayer-/JIP-, Mod-, Dedicated- und Performance-Tests auf realen Karten durchfuehren.

**Nicht behaupten:** 800 fertig geskriptete Einsaetze, reale automatisch erzeugte Schadenlagen, getestete Missionen oder jede Modkarte ohne Anpassung. Derzeit sind 800 **Briefings und Basismethoden** nutzbar.
## Pruefung

`python3 missions/dmcs/tools/validate_scenarios.py`

`python3 missions/dmcs/tools/build_scenario_catalog.py --check`

Der Validator kontrolliert JSON-Gueltigkeit, IDs, Kategorien und Pflichtfelder, **nicht** die militaerische oder soziale Realitaetsnaehe, den Spielablauf oder das Multiplayer-Verhalten. Die Geschichten sind redaktionelle Vorlagen und sollten vor realem Gebrauch an Land, Fraktion, Einsatzziel und lokalen Kontext angepasst werden.

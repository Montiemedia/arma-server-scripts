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
* `implementation`: immer `CONCEPT_ONLY`, da die Bibliothek noch nicht dynamisch in der Missionsengine geladen wird
* `estimated_minutes` und `players_recommended`: redaktionelle Richtwerte, **nicht gemessene Spielzeiten**

## Wie die Szenarien spaeter spielbar werden

1. Pro Szenario ein erweiterbares `ScenarioDefinition` mit erforderlichen Zielen, NPCs, Spawnzonen, Eskalationsregeln, Bedingungen und erlaubten Fraktionen festlegen.
2. Einen serverautoritativen Katalog-Loader fuer Arma/SQF implementieren. **Arma 3 liest diese JSON-Dateien derzeit nicht automatisch ein.** Erst beim Export in ein kompatibles Missionskonfigurationsformat lassen sie sich direkt in einer PBO verwenden.
3. Terrain-Resolver: die abstrakten Schauplaetze auf tatsaechliche Kartenobjekte, Orte, Strassen und freie Spawns abbilden.
4. Mechanikbibliothek ausbauen: Dialoge, Suche/Verifikation, Einschaetzung, Transport, Personeninteraktion, Dokumentation, Bergung, Verkehrs-/Umweltreaktionen und mehrphasige Auftraege.
5. Eine Host-UI mit Filter nach Seite, Kategorie, Spielermenge, Dauer und Schwierigkeit anbieten.
6. Multiplayer-/JIP-, Mod-, Dedicated- und Performance-Tests auf realen Karten durchfuehren.

**Nicht behaupten:** 800 fertig skriptete Spielauftraege, 800 getestete Missionen, echte KI-Dialoge, automatische Kartengenerierung oder bereits integrierte JSON-Auswahl. Das sind Planungsdaten.

## Pruefung

`python3 missions/dmcs/tools/validate_scenarios.py`

Der Validator kontrolliert JSON-Gueltigkeit, IDs, Kategorien und Pflichtfelder, **nicht** die militaerische oder soziale Realitaetsnaehe, den Spielablauf oder das Multiplayer-Verhalten. Die Geschichten sind redaktionelle Vorlagen und sollten vor realem Gebrauch an Land, Fraktion, Einsatzziel und lokalen Kontext angepasst werden.

# DMCS – Dynamic Mission Control System (Arma 3)

**Status: Prototyp 0.3 (Quellstand), nicht in Arma 3 getestet. Nicht als einsatzbereites PBO freigegeben.**

Serverautoritatives SQF-Missionsframework mit Host-Menue, vorbereitbaren Auftraegen, Spieler-Skalierung und optionalem dynamischem Zivilleben. Kein Pflichtmod. Die finale Mission und `mission.sqm` werden in 3DEN erstellt.

## Spielmodus: ausschliesslich COOP (PvE)

**Nicht an BLUFOR gebunden.** Spielbare menschliche Einheiten duerfen auf **WEST, EAST, GUER oder CIV** liegen. Die automatische Team-Seitenerkennung (`playerSide = "AUTO"`) erkennt beim Aktivieren eines Auftrags die gemeinsame Seite aller anwesenden menschlichen Spieler; eine feste Seite ist konfigurierbar.

* Menschen spielen zusammen gegen den vom Server verwalteten Auftrag, **niemals gegeneinander**.
* Alle menschlichen Teilnehmer muessen derzeit **derselben Arma-Seite** angehoeren. Unterschiedliche Fraktionen **innerhalb** dieser Seite sind zulaessig.
* Menschen gleichzeitig auf mehreren Seiten (z. B. WEST + GUER) sind **noch nicht** als Koalition unterstuetzt. Die Auftragsaktivierung wird dann verweigert.
* Gegner-KI: WEST-Spieler -> EAST-Gegner, EAST-Spieler -> WEST-Gegner, GUER-Spieler -> EAST-Gegner. Klassen sind im Missionsprofil editierbar.
* Bei CIV-Spielern gibt es keine durch DMCS erzwungene Feindschaft gegen CIV: Sicherung und Zerstoerung sind nicht verfuegbar; andere Auftraege laufen ohne Gegner-KI. Zivile Spieler sollten unbewaffnete oder nichtkaempfende Szenarien verwenden.
* Einheiten jeder Seite koennen aus Vanilla oder Mod-Fraktionen stammen, **sofern die Klassen auf Server und Clients existieren**. Die realen Mod-Klassen sind noch nicht integriert bzw. getestet.

## Enthaltene Auftragsarten

| Name | Technik | Anmerkung |
|---|---|---|
| Aufklaerung | Aufenthalt am Einsatzpunkt | Ohne Gegner fuer CIV-Spieler |
| Sicherung | Gegner besiegen + Gebiet halten | Fuer CIV-Spieler gesperrt |
| Zerstoerung | Objekt zerstoeren | Fuer CIV-Spieler gesperrt |
| Personenschutz | Geisel/Zivilperson lebend erreichen | **Noch keine Evakuierung** |
| Versorgung | Materialstelle erreichen und sichern | **Noch keine Lieferung/Transport** |
| Ortsbesichtigung | Vor-Ort-Aufenthalt dokumentieren | Friedlicher Auftrag, alle vier Spieler-Seiten |
| Botengang | Zuerst Abholpunkt, danach Abgabepunkt | Zwei Phasen, **Uebergabe nur simuliert** |
| Medizinischer Notfall | Patienten-NPC untersuchen, danach Erste Hilfe leisten | Zwei servervalidierte Spieleraktionen, **noch keine ACE-/Vanilla-Medizin** |

Der Host kann Entwuerfe anlegen, bearbeiten, aktivieren, Zielauswertung pausieren, fortsetzen und entfernen. Berechtigung serverseitig ueber Serveradministrator oder explizite Trusted UID.

## Dynamisches Zivilleben (optional)

Im Host-Dialog **Zivil EIN** / **Zivil AUS**. Standardmaessig ausgeschaltet (`ambientCivEnabled = 0`).

* Begrenzt auf `ambientCivMax = 16` leichte Agenten; Zielpopulation `ambientCivPerPlayer = 2` pro lebendem Spieler, maximal 16.
* Alle 25 Sekunden serverseitige Bestandskontrolle, **hoechstens 2 neue Agenten pro Durchlauf**.
* Spawnt nur bei Spielern in der Naehe benannter Staedte/Doerfer und geeigneter Strassensegmente, nicht einfach mitten auf freiem Feld.
* Agenten erhalten gelegentlich ein einfaches Wegziel. Sie werden bei Abwesenheit von Spielern, deaktiviertem Modul oder Ueberkapazitaet entfernt.
* **Noch kein Verkehr, keine Passanteninteraktion, keine zivilen Routinen oder Gebaeude-Innenleben**. Je nach Terrain ohne Staedte/Strassen kann die Population leer bleiben.
* Verwendete Zivilistenklasse derzeit `C_man_1`; weitere Klassen sind ueber `ambientCivClasses[]` konfigurierbar, aber nur nach Existenzpruefung.

## 3DEN – Installation

1. Gewuenschte Karte laden, spielbare Coop-Einheiten einer gemeinsamen Seite setzen: WEST, EAST, GUER **oder CIV**. Andere Seiten als KI sind erlaubt, aber nicht als gegnerische **Spieler-Slots**.
2. Respawn-Marker passend zur Spieler-Seite anlegen: `respawn_west`, `respawn_east`, `respawn_guerrila` oder `respawn_civilian`. Schreibweise und Respawn-Einstellungen in 3DEN bzw. auf dem Server testen.
3. Mindestens drei geeignete Marker `dyn_zone_1`, `dyn_zone_2`, `dyn_zone_3` anlegen: Landflaechen, frei fuer Zielobjekte und KI.
4. Fuer den zweiphasigen Botengang **zusaetzlich** `dyn_civ_dropoff` setzen, mindestens 60 m vom Abholpunkt entfernt, ebenfalls auf Land.
5. Mission als `DMCS.<WorldName>` speichern (etwa `DMCS.Altis`). Die erzeugte `mission.sqm` **nicht** durch Dateien aus GitHub ersetzen.
6. `description.ext`, `initServer.sqf`, `initPlayerLocal.sqf` und den gesamten `dyn/`-Ordner in den Missionsordner kopieren.
7. Im Multiplayer starten. Admin oder freigegebener Lagedarsteller oeffnet die Spieleraktion `DMCS | Einsatzfuehrung`.
8. Erst einen friedlichen Auftrag, dann (mit militaerischen Teams) einen Kampfauftrag und anschliessend die Zivilbevoelkerung testen.

## Technische Grenzen und Sicherheit

* **Ungetestet:** SQF-Ingame-Ausfuehrung, Dedicated-Server, JIP, Multiplayer-Latenz, Kollisionen, Task-Marker und Modkompatibilitaet.
* Einfache Ki-Spawns nutzen Offsets um Marker; keine vollstaendige Pruefung auf Gebaeude, Wasser, Hindernisse, unwegsames Gelaende oder versteckte Sektoren.
* Zivilisten werden als serverseitige `createAgent`-Objekte verwaltet; die Steuerung ist kein vollstaendiges ziviles Simulationsframework.
* **CIV ist nicht automatisch eine Kampfseite.** Absichtlich keine globalen `setFriend`-Feindschaften gegen Zivilisten, da das Weltobjekte beeintraechtigen kann.
* Fuer GUER-Spieler die Beziehungen zu EAST in den 3DEN-Missionseinstellungen pruefen. Eine neutrale Beziehung kann Kampfauftraege unbrauchbar machen.
* Die Missions-`CfgRemoteExec`-Whitelist kann mit ACE/CBA/ACRE bzw. weiteren Mods kollidieren. In dieser Form nicht ungetestet auf produktiven Modservern einsetzen.
* Die Aufgabenregistrierung fuer JIP basiert auf dem Vanilla-BIS-Task-Framework. Praktische Synchronisation noch pruefen.
* Die Population wird nur **serverseitig** verwaltet und repliziert ihre Agenten als Engine-Objekte. Keine Pro-Agent-RPCs.
* Der medizinische Notfall bietet zwei Spieleraktionen mit serverseitig kontrollierten Phasen; keine realistische Behandlung oder Evakuierung.
* Der lokale Strukturcheck `python3 missions/dmcs/tools/validate_static.py` ist kein SQF-Compiler. Die Abnahme-Checkliste steht in [docs/TESTS.md](docs/TESTS.md).

Details: [Kartenkompatibilitaet](docs/MAPS.md), [Zivile Einsaetze](docs/CIVILIAN.md), [Multiplayer-Testplan](docs/TESTS.md).

## Zwingende Tests vor Freigabe

Vier getrennte Missionsinstanzen je Spieler-Seite (WEST/EAST/GUER/CIV), Auftragsstart/Abbruch, 2+ Auftragssituationen, unberechtigter Client, JIP, Respawn, Spielerwechsel, Civ-Modul EIN/AUS, KI-Cleanup und RPT-Ausgabe. Militaerische und zivile Modi getrennt bewerten.

**Hinweis:** Das Verzeichnis ist Quellcode. Ohne `mission.sqm` kein direkt startbarer Missionsexport.

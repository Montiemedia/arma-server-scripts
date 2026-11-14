# DMCS – Testplan fuer Multiplayer und Missionsabnahme

**Status: manuelle Checkliste, NICHT als bereits durchgefuehrte Tests verstehen.**

## 0. Statische Vorpruefung (kein Arma-Test)

Vom Repository-Root:

```bash
python3 missions/dmcs/tools/validate_static.py
```

Der lokale Checker prueft Dateinamen, CfgFunctions-Registrierung, Klammerstruktur und einige Feature-Verweise. Kein Ersatz fuer Arma-Parser, 3DEN oder Multiplayer-Tests.

## 1. Testumgebung

1. Einmal Vanilla ohne Mods, danach mit dem tatsaechlichen TF133-Modpreset testen.
2. 3DEN-Testmission mit gemeinsamen spielbaren Slots, keine gemischten menschlichen Seiten. Je ein Durchlauf fuer WEST, EAST, GUER, CIV.
3. Mindestens drei freie Landmarker: dyn_zone_1..3. Fuer Botengang zusaetzlich dyn_civ_dropoff.
4. Als Host mindestens einen Admin bzw. einen Trusted-UID-Zugang und einen unberechtigten Spieler vorsehen.
5. Separat Listenserver und Dedicated Server, Client mit JIP, Respawn aktivieren.
6. Die RPT-Dateien von Client und Server auf fehlende Funktionen, RemoteExec-Verweigerungen und SQF-Fehler pruefen.

## 2. Medizinischer Notfall (civ_medical)

* [ ] Im Host-Menue neuen Auftrag "Zivil: Medizinischer Notfall" als Entwurf anlegen.
* [ ] Aktivieren: Ein lebender Zivilist entsteht am Marker; keine Gegner-KI wird erzeugt.
* [ ] Spieler >6 m entfernt: keine patientenbezogene Aktion sichtbar.
* [ ] Spieler am Patienten, zu Fuss: "DMCS | Patient untersuchen" sichtbar.
* [ ] Aktion ausloesen: Auftrag bleibt ACTIVE, Phase wechselt serverseitig auf 1.
* [ ] "DMCS | Erste Hilfe leisten" erscheint statt der ersten Interaktion.
* [ ] Behandlung ausloesen: Aufgabe wird SUCCEEDED, keine weiteren medizinischen Aktionen.
* [ ] Zwei Spieler gleichzeitig auf "Untersuchen": nur ein Phasenwechsel.
* [ ] Aktion nach Pause/Entfernung: keine Statusaenderung.
* [ ] Aktion durch fremde Seite/fernen Spieler/Clients mit gefaelschten ID-Werten: abgelehnt.
* [ ] Patient stirbt vor Abschluss: Auftrag wird FAILED.
* [ ] Patient, KI und Gruppen werden fruehestens 90 Sekunden nach Abschluss bereinigt.
* [ ] Ein JIP-Spieler sieht Phase 1 korrekt und kann Phase 2 ausloesen.
* [ ] Nach Respawn existieren die Aktionen nur einmal am neuen Spielerslot.
* [ ] Zwei zeitgleiche aktive medizinische Auftraege nutzen unterschiedliche IDs und eigene Ziele.

## 3. Team- und Fraktionsverhalten

* [ ] WEST: feindliche KI EAST; eigene Tasks fuer WEST.
* [ ] EAST: feindliche KI WEST; eigene Tasks fuer EAST.
* [ ] GUER: EAST-KI nur bei in 3DEN gesetzter korrekter Feindschaft.
* [ ] CIV: friedliche Auftraege, keine erzwungene Kampf-KI; Kampfauftraege abgelehnt.
* [ ] Menschliche Spieler von zwei Seiten gleichzeitig: Auftragsstart abgelehnt.
* [ ] RHS/3CB/BWMod: Klassen nur nach Existenzpruefung angeben; reale Spawn- und KI-Reaktionen testen.

## 4. Dynamisches Zivilleben

* [ ] "Zivil EIN" aktiviert die Schleife ohne doppelte Spawns.
* [ ] Nahe einer Ortschaft und Strassen werden Agenten erzeugt, maximal zwei neue pro Zyklus.
* [ ] Obergrenze 16 und zwei Agenten je lebendem Spieler werden eingehalten.
* [ ] "Zivil AUS" entfernt ausschliesslich dynamisch erzeugte Ambient-Agenten, nicht den medizinischen NPC.
* [ ] Keine Spieler innerhalb von 650 m: Agenten verschwinden im naechsten Zyklus.
* [ ] Modkarte ohne Roads/Locations: keine Fehler, gegebenenfalls keine Agenten.
* [ ] Zivil-Modul verursacht keinen unverhaeltnismaessigen Server-FPS-Einbruch.

## 5. Release-Gate

Erst nach bestandenem Vanilla-Multiplayer-Test und Mod-/Karten-Test darf die Version als lauffaehig und multiplayer-tauglich bezeichnet werden. Als Nachweis: benutzte Build-/Modversionen, RPT-Auszuege, mindestens zwei Clients, Listen- und Dedicated-Server, bekannte Restfehler.

Offen fuer spaetere Version: echte ACE-Behandlung, Transport mit Fahrzeug, ziviler Verkehr, persistente Zivilpopulation, dynamisch automatisch ausgeloeste Vorfaelle, gemischte Coop-Seiten.

## 6. Szenariobibliothek 0.4

* [ ] `python3 missions/dmcs/tools/build_scenario_catalog.py --check` meldet keine Abweichungen zur JSON-Quelle.
* [ ] Der Spielleiter kann das Fenster `Szenariobibliothek (800)` im Host-Dialog oeffnen.
* [ ] WEST, EAST, GUER und CIV zeigen ohne Filter je exakt 200 Vorlagen.
* [ ] Kategorien, Dauerlimit (30/60/90/120 Minuten) und Spielergroessen-Filter funktionieren, ohne den Server zu belasten.
* [ ] Seitenfremdes Szenario: Client darf eine Geschichte ansehen, aber Server lehnt Entwurfsanlage ab.
* [ ] `W-001` als WEST-Spieler mit gueltiger Zone `dyn_zone_1` erzeugt einen neuen DRAFT-Auftrag.
* [ ] Die Liste zeigt die Verknuepfung zur Szenario-ID; Aktivierung verwendet Titel, Story und konkretes Ziel aus `missionConfigFile`.
* [ ] `scenario`-RPC mit `W-999`, manipuliertem Text oder unbekannter Zone wird verweigert.
* [ ] Fehlender Szenario-Export (`dyn/scenarios/*.hpp`): Mission soll nicht als funktional freigegeben werden.
* [ ] Kopie eines Bibliotheksentwurfs kann Zone aendern, aber nicht unbemerkt die Basismethode tauschen.
* [ ] Nach dem Aktivieren pruefen, dass die generische Basismethode korrekt laeuft (z. B. `recon` durch Aufenthalt am Marker).
* [ ] Listenserver, Dedicated Server und JIP; Task-Metadaten und Briefing auch fuer Spaeteinsteiger.
* [ ] Mehrere Bibliotheksauftraege, maxTasks/maxActive, Pause/Fortsetzen, Abbruch, KI-Cleanup.
* [ ] Das groessere Config-Volumen auf dem tatsaechlichen TF133-Modpreset messen; Performance nicht aus Dateigroesse ableiten.

**Grenze:** Ein Szenario-Briefing ersetzt keine spezifische Szene. Brand, Verkehrsunfall, Gespraeche, Personenschutz oder echte Lieferungen brauchen separate Missionsmodule.

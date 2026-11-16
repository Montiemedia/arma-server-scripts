# @DMCS – Eigenstaendige Arma-3-Mod (0.5.1 TEST)

**Wichtiger Status: Der HEMTT-Build ist in CI bereits nachweislich erfolgreich; der Spieltest der Hotfix-Version steht noch aus.**
Die Quellen, das HEMTT-Buildprojekt, die automatische Initialisierung und die
Generierung von maximal 12 Karten-Einsatzsektoren wurden ins Repository
eingebunden. Ein fertiges Download-Archiv existiert erst, wenn der
GitHub-Actions-Workflow **DMCS Mod Build (HEMTT)** erfolgreich durchgelaufen ist.

## Download des Testbuilds

1. [GitHub Actions: DMCS Mod Build (HEMTT)](https://github.com/Montiemedia/arma-server-scripts/actions/workflows/dmcs-mod-build.yml) oeffnen.
2. Einen gruenen, erfolgreich abgeschlossenen Build auf **main** aufrufen.
3. Unter **Artifacts** das Archiv `DMCS-test-mod-0.5.1` herunterladen.
4. Das darin enthaltene HEMTT-Release-ZIP entpacken. Es sollte
   `@DMCS/addons/*.pbo`, zugehoerige `.bisign` und einen
   oeffentlichen `.bikey` enthalten.
5. Wenn die Struktur hiervon abweicht oder keine Artefakte vorhanden
   sind, **nicht** behaupten, es sei ein funktionierender Release.

## Installation

**Server und jeder Spieler brauchen das identische Addon**. Ein
rein serverseitiges Addon genuegt derzeit nicht, weil Host-UI,
Funktionen und Szenariodefinitionen auf den Clients verfuegbar sein muessen.

1. `@DMCS` in das Arma-3-Verzeichnis des Servers und auf die
   Spieler-PCs kopieren.
2. Auf einem Dedicated Server `-mod=@DMCS` zu den Startparametern
   hinzufuegen; bei anderer Modverwaltung den Ordner wie eine normale
   Client+Server-Mod aktivieren. Existierende Mod-Presets beibehalten.
3. Wenn `verifySignatures=2` aktiv ist, die im **selben Release**
   enthaltene `.bikey` in das `keys/`-Verzeichnis des Servers legen.
   **Niemals einen privaten Signaturschluessel hochladen oder verteilen.**
4. Auf Clients dieselbe Version `@DMCS` im Arma-Launcher laden.
5. Eine normale COOP-Mission starten. **Keine DMCS-`mission.sqm` erforderlich.**
6. Ein als Serveradmin angemeldeter Spieler (`#login`) oder ein in
   `DYN_Settings.trustedUIDs[]` der Mod konfigurierter Spielleiter
   oeffnet `DMCS | Einsatzfuehrung`.
7. `Szenariobibliothek (800)` aufrufen, passende Seite und Kategorie
   waehlen, einen der automatisch generierten Einsatzsektoren auswaehlen,
   **Entwurf anlegen**, dann im Host-Menue **Aktivieren**.
8. RPT-Dateien des Servers und mindestens eines Clients pruefen.

## Ohne manuelle 3DEN-Arbeit

Das Addon verwendet `CfgFunctions.postInit` und erzeugt beim Missionsstart
auf dem Server hoechstens 12 Marker `DMCS_AUTO_1` bis
`DMCS_AUTO_12`. Sie werden aus kartografisch definierten Orten und
einer begrenzten Suche nach Landpositionen ermittelt.

**Terrain-Grenze:** Wenn die Karte zu wenig brauchbare Positionen
bietet, entstehen weniger Einsatzsektoren. Ein Ortspunkt bedeutet nicht
automatisch, dass alle KI-Spawns, Missionsobjekte und Wege dort sicher sind.
Die Karte wird nicht verändert oder umgebaut.

Das Addon kann ohne CBA gestartet werden, muss aber weiterhin mit den
real installierten ACE/CBA/ACRE/RHS/3CB/CUP- und Kartenmodifikationen
getestet werden. Bestehende Missionen koennen `CfgRemoteExec` so
einschraenken, dass die Menue-RPCs nicht durchkommen. Dafuer gibt es
noch **keine universelle Mod-Kompatibilitaetsgarantie**.

## Quellcode reproduzierbar bauen

Voraussetzung: Python 3.9+ und aktuelles
[HEMTT](https://hemtt.dev/).

Vom Repository-Root:

```bash
python3 missions/dmcs/tools/validate_scenarios.py
python3 missions/dmcs/tools/build_scenario_catalog.py --check
python3 missions/dmcs/mod/tools/stage_addon.py
cd missions/dmcs/mod
hemtt check
hemtt release
```

Der Stage-Schritt kopiert den vorhandenen Mission-SQF-Kern in
`mod/addons/core/` und ersetzt die verankerten `missionConfigFile`
Zugriffe in diesen Build-Kopien durch `configFile`.
`config.cpp` wird generiert. Die 800 Szenariodefinitionen werden
aus den bereits versionierten HPP-Katalogen aufgenommen.

Zur Freigabe als produktiv taugliche Mod fehlen weiterhin:

* Nachweis eines erfolgreichen signierten PBO-Builds
* Test der Auto-Sektoren und des Host-Menues in Arma 3
* 2-Client-Test fuer Task-Start, Rechte, RemoteExec, Spieler-Respawn, JIP
* Test auf Dedicated- und Listenserver
* Test mit dem realen TF133-Modset
* Last- und RPT-Pruefung
* Eigene szenariospezifische Mechaniken (Brand, Verkehrsunfall,
  Personenbefragung usw.) jenseits der vorhandenen acht Basis-Aufgaben

**Prototyp 0.5 ist kein als produktionsreif freigegebener Workshop-Release.**

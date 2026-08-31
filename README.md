# TF133 Arma 3 Control

Serversteuerung, Webpanel und Einsteiger-Installer für einen modifizierten
Arma-3-Dedicated-Server auf Ubuntu 24.04 x86-64.

Noch nie einen Linux-Server eingerichtet? Öffne die
[Schritt-für-Schritt-Anleitung](INSTALLATION-EINFACH.md).

## Schnellinstallation

Auf einem frischen Ubuntu-24.04-Server:

```bash
sudo apt update
sudo apt install -y git
git clone --branch fix/resilient-mod-updates --single-branch https://github.com/Montiemedia/arma-server-scripts.git
cd arma-server-scripts
sudo ./install.sh
```

Der Installer richtet Systembenutzer, Serverstruktur, Webpanel, Menü,
SteamCMD, DepotDownloader und den Arma 3 Dedicated Server ein. Workshop-Mods
können direkt im Installer geladen werden. Lokale Kane-Mods müssen anschließend
manuell kopiert werden.

Das Administrationsmenü startet danach mit:

```bash
sudo arma3-menu
```

## Enthalten

- interaktives Bash-Menü mit Serverstart, Stopp, Status, Logs und Diagnose
- FastAPI-Webpanel hinter Nginx und HTTPS
- Arma 3 Dedicated Server über SteamCMD App-ID `233780`
- einzelne Workshop-Downloads mit Wiederholungsversuchen
- DepotDownloader als Ausweichlösung für problematische Workshop-Downloads
- Abschlussliste der erfolgreich heruntergeladenen Workshop-Mods
- nummeriertes, bestätigungspflichtiges Löschen installierter Workshop-Mods
- dauerhafte Fehlerliste unter `/home/arma3/state/failed-mods.csv`
- automatische Kleinschreibung der Moddateien für Linux
- Synchronisierung der `.bikey`-Dateien
- Backups von Konfiguration, Missionen, Profilen und lokalen Mods
- gemeinsamer Wartungs-Lock für Menü, Webpanel und Automatisierungen
- automatisierte Bash-, Python- und Konfigurationstests

## Wichtige Pfade

```text
/opt/arma3-control/                  installierte Control-Dateien
/usr/local/bin/arma3-menu            kurzer Startbefehl für das Menü
/etc/arma3/arma3.env                 zentrale Einstellungen
/etc/arma3/mods.csv                  aktive Modliste
/home/arma3/server/                  Arma-3-Server
/home/arma3/server/mods/             Modordner
/home/arma3/server/mpmissions/       Multiplayer-Missionen
/home/arma3/steamcmd/                SteamCMD
/home/arma3/depotdownloader/         DepotDownloader
/home/arma3/workshop/                SteamCMD-Workshopdaten
/home/arma3/depot-workshop/          DepotDownloader-Workshopdaten
/home/arma3/backups/                 Sicherungen
/home/arma3/state/failed-mods.csv    letzte Modfehler
/var/lib/arma3-panel/jobs/           Ausgaben der Panelaufträge
```

Der Missionsordner heißt unter Linux bewusst `mpmissions`. Beim erneuten
Bootstrap wird ein vorhandener Ordner `MPMissions` übernommen, damit ältere
Installationen ihre Missionen nicht verlieren.

## Menüfunktionen

```text
 1  Server starten
 2  Server stoppen
 3  Server neu starten
 4  Serverstatus anzeigen
 5  Server-Journal live anzeigen, einschließlich 300 vorheriger Zeilen
 6  frei wählbare Anzahl letzter Journalzeilen anzeigen
 7  UDP-Ports prüfen
 8  Workshop-Mods aktualisieren und Abschlussliste anzeigen
 9  Mod-Keys synchronisieren
10  Serverdiagnose ausführen
11  server.cfg öffnen
12  basic.cfg öffnen
13  start-server.sh anzeigen
14  Missionen aus mpmissions auflisten
15  UFW-Status anzeigen
16  Steam-Verbindung prüfen
17  failed-mods.csv anzeigen
18  mods.csv öffnen
19  installierten Workshop-Mod nummeriert löschen
 0  Menü beenden
```

Punkt 19 zeigt nur Workshop-Mods aus der kontrollierten `mods.csv`. Nach der
Bestätigung werden Serverkopie und Downloadkopien gelöscht. Der Eintrag wird
auf `enabled=0` gesetzt, damit der Mod nicht beim nächsten Update sofort wieder
heruntergeladen wird. Der Server bleibt danach bewusst angehalten.

Schreibende Aktionen verwenden `scripts/arma3ctl`. Dadurch bleibt die Sperre
`/run/lock/arma3-control.lock` wirksam und parallele Wartungsaktionen werden
verhindert.

## Direkte Befehle

```bash
sudo /opt/arma3-control/scripts/arma3ctl start
sudo /opt/arma3-control/scripts/arma3ctl stop
sudo /opt/arma3-control/scripts/arma3ctl restart
sudo /opt/arma3-control/scripts/arma3ctl update-server
sudo /opt/arma3-control/scripts/arma3ctl update-mods
sudo /opt/arma3-control/scripts/arma3ctl update-all
sudo /opt/arma3-control/scripts/arma3ctl backup
sudo /opt/arma3-control/scripts/arma3ctl sync-keys
sudo /opt/arma3-control/scripts/arma3ctl doctor
sudo /opt/arma3-control/scripts/arma3ctl logs 300
sudo /opt/arma3-control/scripts/arma3ctl remove-mod @modordner
```

## Bestehende Installation aktualisieren

Im geklonten Projektordner:

```bash
git pull
sudo ./scripts/bootstrap.sh
```

Eigene `/etc/arma3/arma3.env`, `/etc/arma3/mods.csv`, `server.cfg`,
`basic.cfg` und vorhandene Zugangsdaten werden dabei nicht überschrieben.

## Modfehler

Jeder Workshop-Mod wird einzeln verarbeitet. Nach einem endgültigen Fehler
läuft die Aktualisierung mit dem nächsten Mod weiter. Am Ende liefert der
Gesamtlauf Exit-Code `1`, damit Webpanel und Automatisierungen den Teilfehler
erkennen.

Details stehen in:

```bash
sudo cat /home/arma3/state/failed-mods.csv
```

## Betriebssicherheit

- Serveraktionen und Updates verwenden einen systemweiten `flock`-Lock.
- `update-all` hält den Server während Server- und Modupdate durchgehend an.
- Schreibende Browseranfragen werden auf denselben Ursprung begrenzt.
- Das Panel erhält nur eng begrenzte Befehle über `sudoers`.
- Die Firewall wird nicht automatisch aktiviert, damit ein abweichender
  SSH-Port den Administrator nicht aussperrt.
- Das erste TLS-Zertifikat ist selbstsigniert. Für den Dauerbetrieb sollte eine
  Domain mit regulärem Zertifikat eingerichtet werden.

## Projekt prüfen

Auf Ubuntu 24.04:

```bash
make test
```

Die GitHub-Actions-Pipeline führt zusätzlich ShellCheck aus.

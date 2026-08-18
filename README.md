# TF133 Arma 3 Server Toolkit

Linux-Toolkit für einen modifizierten Arma-3-Dedicated-Server der Task Force 133. Das Repository fasst die bisher gebauten Server-Skripte, Modverwaltung, systemd-Services, Diagnose, Backups und das Webpanel zusammen.

Ziel: Ein frischer Ubuntu-Server soll mit möglichst wenigen Eingaben reproduzierbar eingerichtet werden können.

## Schnellstart

Auf Ubuntu 24.04:

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/Montiemedia/arma-server-scripts.git
cd arma-server-scripts
sudo bash ./scripts/install.sh
```

Der Installer fragt nur die Werte ab, die nicht sinnvoll erraten werden können:

- Steam-Benutzer
- Servername
- optionales Server-Passwort
- maximale Spielerzahl
- Game-Port
- optional eine Steam64-ID als fester Admin

Das Arma-Admin-Kennwort und das Webpanel-Kennwort werden automatisch erzeugt. Steam-Kennwörter werden nicht gespeichert.

## Was automatisch erledigt wird

- Linux-Abhängigkeiten installieren
- Benutzer und Verzeichnisse anlegen
- SteamCMD installieren
- Arma 3 Dedicated Server über App-ID `233780` installieren/validieren
- Workshop-Mods aus `config/mods.csv` einzeln herunterladen
- fehlgeschlagene Mods protokollieren und mit den übrigen Mods fortfahren
- Moddateien für Linux auf konsistente Kleinschreibung normalisieren
- `.bikey`-Dateien der vorhandenen Mods synchronisieren
- `server.cfg` erzeugen
- systemd-Services installieren
- Webpanel und nginx installieren
- Backups und Diagnosewerkzeuge bereitstellen
- Missionspfad auf Linux korrekt als `mpmissions` verwenden
- typische Missionsfehler wie `template = "Mission.Stratis.pbo"` erkennen

## Zielstruktur

```text
/opt/arma3-control/                  installierte Steuerung/Webpanel
/etc/arma3/arma3.env                 zentrale Pfade und Startparameter
/etc/arma3/mods.csv                  Modliste
/home/arma3/server/                  Arma-3-Server
/home/arma3/server/mods/             normalisierte Modordner
/home/arma3/server/mpmissions/       Multiplayer-Missionen
/home/arma3/server/keys/             akzeptierte Mod-Keys
/home/arma3/steamcmd/                SteamCMD
/home/arma3/workshop/                Workshop-Downloadbereich
/home/arma3/state/                   Status/Fehlerlisten
/home/arma3/backups/                 Sicherungen
/var/lib/arma3-panel/jobs/           Panel-Auftragsstatus
```

## Wichtige Linux-Fallen, die das Toolkit abfängt

### `mpmissions` statt `MPMissions`

Linux unterscheidet Groß- und Kleinschreibung. Das Toolkit verwendet deshalb konsequent:

```text
/home/arma3/server/mpmissions
```

Eine alte `MPMissions`-Struktur wird beim Setup nach `mpmissions` übernommen.

### Missionsname in `server.cfg`

Richtig:

```cpp
template = "test.VR";
```

Falsch:

```cpp
template = "test.VR.pbo";
```

`arma3ctl doctor` meldet diesen Fehler automatisch.

### Mod-Downloads

Ein kaputter Workshop-Download beendet nicht mehr den gesamten Durchlauf. Jeder Mod bekommt mehrere Versuche. Fehler landen am Ende in:

```text
/home/arma3/state/failed-mods.txt
```

Danach kann einfach erneut ausgeführt werden:

```bash
sudo /opt/arma3-control/scripts/arma3ctl update-mods
```

## Standardkonfiguration TF133

Der geführte Installer verwendet derzeit folgende Defaults:

```text
Servername:          Task Force 133 - Eventserver
Spieler:             60
Port:                2302
verifySignatures:    0
BattlEye:            0
persistent:          0
VoN:                 aktiviert
```

Kennwörter und persönliche Admin-IDs werden nicht im öffentlichen Repository hinterlegt.

## Bedienung

```bash
sudo /opt/arma3-control/scripts/arma3ctl start
sudo /opt/arma3-control/scripts/arma3ctl stop
sudo /opt/arma3-control/scripts/arma3ctl restart
sudo /opt/arma3-control/scripts/arma3ctl status
sudo /opt/arma3-control/scripts/arma3ctl logs 300
sudo /opt/arma3-control/scripts/arma3ctl update-server
sudo /opt/arma3-control/scripts/arma3ctl update-mods
sudo /opt/arma3-control/scripts/arma3ctl update-all
sudo /opt/arma3-control/scripts/arma3ctl sync-keys
sudo /opt/arma3-control/scripts/arma3ctl missions
sudo /opt/arma3-control/scripts/arma3ctl backup
sudo /opt/arma3-control/scripts/arma3ctl doctor
```

## Missionen installieren

PBO-Dateien nach folgendem Verzeichnis kopieren:

```text
/home/arma3/server/mpmissions/
```

Danach prüfen:

```bash
sudo /opt/arma3-control/scripts/arma3ctl missions
sudo /opt/arma3-control/scripts/arma3ctl doctor
```

Eine feste Missionsrotation kann anschließend in `/home/arma3/server/server.cfg` definiert werden. Der `template`-Wert enthält den Missionsnamen inklusive Kartenname, aber ohne `.pbo`.

## Mods

Die zentrale Liste liegt in:

```text
config/mods.csv
```

Format:

```csv
name,type,workshop_id,target,enabled
ace,workshop,463939057,@ace,1
```

Lokale Mods können ebenfalls eingetragen werden:

```csv
Mein lokaler Mod,local,,@mein_mod,1
```

Das Startskript baut `-mod=` automatisch aus allen aktivierten und vorhandenen Modverzeichnissen zusammen.

## Diagnose

```bash
sudo /opt/arma3-control/scripts/arma3ctl doctor
```

Geprüft werden unter anderem:

- Serverbinary und Configs
- `mpmissions`-Schreibweise
- Missions-PBOs
- `.pbo` fälschlich im `template`-Wert
- aktivierte, aber fehlende Mods
- Großbuchstaben innerhalb der Linux-Modstruktur
- Fehlerliste des letzten Modupdates
- Ports und freier Speicher

## Firewall

Arma 3 verwendet für die erste Instanz typischerweise UDP `2302` bis `2306`.

Der Installer aktiviert UFW absichtlich nicht automatisch, weil ein unbekannter SSH-Port sonst den Administrator aussperren könnte.

Bei Standard-SSH:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 2302:2306/udp
sudo ufw enable
```

## Webpanel

Das vorhandene schlanke FastAPI-Webpanel bleibt Bestandteil des Projekts. Es bietet Serveraktionen über systemd, Updates, Backups, Diagnose und Logs. nginx schützt das Panel mit Basic Auth und HTTPS.

Initiale Zugangsdaten werden lokal gespeichert unter:

```text
/root/arma3-initial-credentials.txt
```

Diese Datei nach Übernahme der Kennwörter löschen.

## Manuelle Installation

Wer den geführten Installer nicht verwenden möchte, kann weiterhin nur das Grundsystem installieren:

```bash
sudo bash ./scripts/bootstrap.sh
```

Danach stehen die einzelnen `arma3ctl`-Befehle zur Verfügung.

## Grundprinzip

Das Repository enthält keine echten Server-Passwörter, keine Steam-Kennwörter und keine privaten Tokens. Konfigurationen werden aus Vorlagen beziehungsweise während der Installation erzeugt.

Serverbetrieb und Fehlerbehandlung sollen reproduzierbar sein: keine zehn Copy-and-Paste-Zettel, keine versteckten Pfade und kein komplettes Abbrechen eines 25-Mod-Downloads nur weil Steam bei Mod Nummer 7 gerade schlechte Laune hat.

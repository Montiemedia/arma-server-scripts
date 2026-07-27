# TF133 Arma 3 Control

Schlankes Web-Panel und Serverscript für einen modifizierten Arma-3-Dedicated-Server unter Ubuntu 24.04 (x86-64). Das Projekt ist auf einen einzelnen Linux-Host mit systemd, maximal 20 Spieler und den vorhandenen TF133-ALiVE-Modsatz ausgelegt. Windows wird weder als Serverplattform unterstützt noch in der Installation berücksichtigt.

## Enthalten

- FastAPI-Webpanel ohne Node.js-Buildkette
- Start, Stopp und Neustart über systemd
- Aktualisierung des Dedicated Servers über SteamCMD App-ID `233780`
- Aktualisierung der 23 Workshop-Mods aus `TF133_Alive.html`
- Einträge für die beiden lokalen Kane-Mods
- automatische Kleinschreibung aller Moddateien für Linux
- Synchronisierung der `.bikey`-Dateien
- Backups von Konfiguration, Missionen, Profilen und lokalen Mods
- Diagnosefunktion für Dateien, Mods, Schreibweise, Speicher und Ports
- Nginx-Reverse-Proxy mit Basic Auth und restriktiven Browser-Headern
- eng begrenzte sudo-Regeln für das Panel
- Same-Origin-Prüfung für schreibende Webaktionen
- systemweiter Wartungs-Lock gegen parallele Updates und Serveraktionen

## Zielstruktur

```text
/opt/arma3-control/                  Panel und root-eigene Steuerscripte
/etc/arma3/arma3.env                 zentrale Pfade und Startparameter
/etc/arma3/mods.csv                  Modliste
/home/arma3/server/                  Arma-3-Server
/home/arma3/server/mods/             normalisierte Modordner
/home/arma3/server/MPMissions/       Missionen
/home/arma3/steamcmd/                SteamCMD
/home/arma3/workshop/                Workshop-Downloadbereich
/home/arma3/backups/                 Sicherungen
/var/lib/arma3-panel/jobs/           Auftragsstatus und Ausgaben
```

## Installation auf Ubuntu 24.04

Repository auf den Server kopieren und dann ausführen:

```bash
cd arma3-control
sudo ./scripts/bootstrap.sh
```

Die initialen Zugangsdaten werden root-exklusiv abgelegt:

```bash
sudo cat /root/arma3-initial-credentials.txt
```

Danach den Steam-Benutzer in `/etc/arma3/arma3.env` eintragen. Für Workshop-Downloads ist ein getrenntes Steam-Konto sinnvoll. Das Kennwort wird bewusst nicht in der Konfigurationsdatei gespeichert.

```bash
sudo nano /etc/arma3/arma3.env
sudo /opt/arma3-control/scripts/arma3ctl steam-login
sudo /opt/arma3-control/scripts/arma3ctl install-server
```

Beim interaktiven Steam-Login kann Steam Guard bestätigt werden. Danach verwendet SteamCMD seine lokal gecachten Anmeldedaten.

## Lokale Kane-Mods

Die beiden lokalen Mods werden nicht über Steam heruntergeladen. Die entpackten Ordner müssen so vorliegen:

```text
/home/arma3/server/mods/@kane_3cb_alive_civilian
/home/arma3/server/mods/@kane_3cb_middle_east_civilian_alive
```

Danach:

```bash
sudo chown -R arma3:arma3 /home/arma3/server/mods/@kane_*
sudo -u arma3 python3 /opt/arma3-control/scripts/lowercase_tree.py \
  /home/arma3/server/mods/@kane_3cb_alive_civilian
sudo -u arma3 python3 /opt/arma3-control/scripts/lowercase_tree.py \
  /home/arma3/server/mods/@kane_3cb_middle_east_civilian_alive
```

## Mods installieren und Server starten

```bash
sudo /opt/arma3-control/scripts/arma3ctl update-mods
sudo /opt/arma3-control/scripts/arma3ctl doctor
sudo systemctl start arma3-server
```

Das Panel ist anschließend über `https://<IPv4-Adresse>` erreichbar. Das Bootstrap-Script erzeugt zunächst ein selbstsigniertes Zertifikat, weshalb der Browser beim ersten Aufruf warnt. Vor einer dauerhaften öffentlichen Nutzung sollte eine Domain mit einem regulären TLS-Zertifikat eingerichtet werden.

## Firewall

Arma 3 benötigt für die erste Instanz standardmäßig UDP `2302` bis `2306`. Der Server braucht eine echte öffentliche IPv4-Adresse. Die Firewall nicht blind aktivieren, wenn SSH auf einem abweichenden Port läuft.

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 2302:2306/udp
sudo ufw enable
```

## TLS mit eigener Domain

Nach Eintrag eines DNS-A/AAAA-Records die Nginx-Datei anpassen:

```bash
sudo nano /etc/nginx/sites-available/arma3-panel.conf
```

`server_name _;` durch die Domain ersetzen. Danach kann beispielsweise Certbot verwendet werden. Das selbstsignierte Zertifikat kann anschließend durch ein reguläres Zertifikat ersetzt werden. HTTP wird bereits automatisch auf HTTPS umgeleitet.

## Bedienung ohne Webpanel

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
```

## Wichtige Grenzen dieses ersten Stands

- Keine RCON-Konsole und keine Ingame-Adminbefehle im Browser
- Noch keine Anzeige verbundener Spieler
- Keine Bearbeitung von `server.cfg` oder Missionen im Browser
- Keine automatische TLS-Einrichtung
- Keine automatische Installation der beiden lokalen Mods

Diese Funktionen sind bewusst nicht halbgar eingebaut. Der erste Stand konzentriert sich auf kontrollierbare Serveraktionen, Updates, Backups und nachvollziehbare Logs.

## Betriebssicherheit

Schreibende Browseranfragen werden anhand von `Origin`, `Referer` und
`Sec-Fetch-Site` auf denselben Ursprung begrenzt. Direkte CLI-Anfragen ohne
Browser-Header bleiben möglich und müssen weiterhin die Nginx Basic Auth
passieren.

Alle verändernden `arma3ctl`-Befehle verwenden zusätzlich
`/run/lock/arma3-control.lock`. Dadurch können Webpanel, Administratoren und
Automatisierungen keine konkurrierenden Updates oder Serveraktionen starten.
`update-all` hält den Server während Server- und Modaktualisierung durchgehend
gestoppt und startet ihn erst danach wieder.

## Offizielle technische Referenzen

- Bohemia Interactive Community Wiki: Arma 3 Dedicated Server
- Bohemia Interactive Community Wiki: Arma 3 Startup Parameters
- Bohemia Interactive Community Wiki: Arma 3 Server Configuration
- Valve Developer Community: SteamCMD

# Installation für Einsteiger

Diese Variante ist für einen frischen Ubuntu-24.04-Server gedacht. Ziel ist, möglichst wenig von Hand einzutragen.

## 1. Mit dem Server verbinden

Unter Windows PowerShell:

```powershell
ssh DEIN_BENUTZER@SERVER_IP
```

## 2. Repository laden

Auf dem Linux-Server:

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/Montiemedia/arma-server-scripts.git
cd arma-server-scripts
```

## 3. Installer starten

```bash
sudo bash ./scripts/install.sh
```

Der Installer fragt nacheinander:

1. Steam-Benutzer
2. Servername
3. Server-Passwort, optional
4. maximale Spielerzahl
5. Game-Port
6. Steam64-ID eines festen Admins, optional

Die vorgeschlagenen Standardwerte können meistens einfach mit `Enter` übernommen werden.

Danach erledigt das Script automatisch:

- Systempakete
- Linux-Benutzer und Verzeichnisse
- SteamCMD
- Server-Konfiguration
- systemd
- Webpanel
- Steam-Login
- Arma-3-Dedicated-Server
- Workshop-Mods
- Mod-Keys
- Linux-Kleinschreibung
- Diagnose

Beim Steam-Login müssen das Steam-Kennwort und ggf. der Steam-Guard-Code interaktiv eingegeben werden. Das Kennwort wird nicht in den Projektdateien gespeichert.

## 4. Zugangsdaten ansehen

Nach der Installation:

```bash
sudo cat /root/arma3-initial-credentials.txt
```

Dort stehen die automatisch erzeugten Kennwörter für Arma-Admin und Webpanel.

Nach dem Übertragen in einen Passwortmanager:

```bash
sudo rm /root/arma3-initial-credentials.txt
```

## 5. Missionen kopieren

Missionen gehören unter Linux nach:

```text
/home/arma3/server/mpmissions/
```

Wichtig: `mpmissions` ist kleingeschrieben.

Danach:

```bash
sudo /opt/arma3-control/scripts/arma3ctl missions
sudo /opt/arma3-control/scripts/arma3ctl doctor
```

Wenn eine Mission beispielsweise so heißt:

```text
test.VR.pbo
```

lautet der Eintrag in `server.cfg`:

```cpp
template = "test.VR";
```

Nicht:

```cpp
template = "test.VR.pbo";
```

## 6. Server starten

```bash
sudo /opt/arma3-control/scripts/arma3ctl start
```

Status:

```bash
sudo /opt/arma3-control/scripts/arma3ctl status
```

Logs:

```bash
sudo /opt/arma3-control/scripts/arma3ctl logs 200
```

## Wenn ein Mod nicht heruntergeladen wird

Der Installer bricht nicht mehr beim ersten kaputten Workshop-Download komplett ab. Die übrigen Mods werden weiter abgearbeitet.

Fehlgeschlagene Mods stehen unter:

```text
/home/arma3/state/failed-mods.txt
```

Noch einmal versuchen:

```bash
sudo /opt/arma3-control/scripts/arma3ctl update-mods
```

## Diagnose

```bash
sudo /opt/arma3-control/scripts/arma3ctl doctor
```

Die Diagnose prüft unter anderem:

- Arma-Serverbinary
- Config-Dateien
- Modverzeichnisse
- fehlgeschlagene Downloads
- Linux-Groß-/Kleinschreibung
- `mpmissions`
- vorhandene Missions-PBOs
- falsche `.pbo`-Endungen in `class Missions`

## Firewall

Der Installer aktiviert die Firewall absichtlich nicht selbst. Damit wird verhindert, dass ein Server mit abweichendem SSH-Port versehentlich ausgesperrt wird.

Bei normalem SSH-Port 22:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 2302:2306/udp
sudo ufw enable
```

## Die wichtigsten Befehle

```bash
sudo /opt/arma3-control/scripts/arma3ctl start
sudo /opt/arma3-control/scripts/arma3ctl stop
sudo /opt/arma3-control/scripts/arma3ctl restart
sudo /opt/arma3-control/scripts/arma3ctl status
sudo /opt/arma3-control/scripts/arma3ctl update-server
sudo /opt/arma3-control/scripts/arma3ctl update-mods
sudo /opt/arma3-control/scripts/arma3ctl update-all
sudo /opt/arma3-control/scripts/arma3ctl missions
sudo /opt/arma3-control/scripts/arma3ctl backup
sudo /opt/arma3-control/scripts/arma3ctl doctor
sudo /opt/arma3-control/scripts/arma3ctl logs 200
```

Für eine normale Neuinstallation ist aber nur der Einstieg über `scripts/install.sh` vorgesehen. Die Einzelbefehle sind hauptsächlich für Wartung und Fehlersuche da.

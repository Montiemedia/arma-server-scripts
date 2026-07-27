# Installation für Einsteiger

Diese Anleitung führt dich durch die Installation auf einem frischen Server
mit Ubuntu 24.04. Du brauchst keine Linux-Erfahrung. Kopiere die Befehle
einzeln und warte jeweils, bis der vorherige Befehl fertig ist.

## Was du vorher brauchst

- einen Server mit Ubuntu 24.04 (64 Bit)
- die öffentliche IPv4-Adresse des Servers
- einen Benutzer, der `sudo` verwenden darf
- ein separates Steam-Konto für die Arma-3-Downloads
- die beiden lokalen Kane-Mods als entpackte Ordner

Für den Server samt Mods sind 8 GB RAM und 100 GB freier Speicher ein
vernünftiger Ausgangspunkt. Mehr Spieler und große Missionen brauchen
entsprechend mehr Leistung.

> **Wichtig:** Diese Anleitung ist für Ubuntu. Führe die Befehle nicht in der
> Windows-Eingabeaufforderung aus.

## 1. Mit dem Server verbinden

Öffne auf deinem PC PowerShell. Ersetze `SERVER_IP` durch die IP-Adresse deines
Servers:

```powershell
ssh DEIN_BENUTZER@SERVER_IP
```

Beim ersten Verbindungsaufbau erscheint eine Rückfrage zum Fingerabdruck.
Antworte mit `yes`. Gib anschließend das Kennwort deines Serverbenutzers ein.
Bei der Kennworteingabe werden keine Zeichen angezeigt. Das ist normal.

## 2. Projekt herunterladen

Die folgenden Befehle laufen jetzt auf dem Ubuntu-Server:

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/Montiemedia/arma-server-scripts.git
cd arma-server-scripts
```

Falls der Ordner bereits vorhanden ist:

```bash
cd arma-server-scripts
git pull
```

## 3. Grundinstallation starten

```bash
sudo ./scripts/bootstrap.sh
```

Das dauert einige Minuten. Das Script installiert unter anderem nginx, Python
und die benötigten 32-Bit-Bibliotheken. Es legt außerdem die Benutzer `arma3`
und `arma3panel` an.

Wenn am Ende `Installation des Panels abgeschlossen` steht, war dieser Schritt
erfolgreich.

## 4. Kennwörter notieren

Die Installation erzeugt ein Kennwort für das Webpanel und eines für den
Arma-Administrator:

```bash
sudo cat /root/arma3-initial-credentials.txt
```

Speichere beide Kennwörter in einem Passwortmanager. Lösche die Datei erst,
wenn du sicher bist, dass du die Kennwörter gespeichert hast:

```bash
sudo rm /root/arma3-initial-credentials.txt
```

## 5. Steam-Benutzer eintragen

Öffne die Konfiguration:

```bash
sudo nano /etc/arma3/arma3.env
```

Suche diese Zeile:

```text
STEAM_USER=
```

Trage rechts vom Gleichheitszeichen den Steam-Benutzernamen ein, zum Beispiel:

```text
STEAM_USER=mein_steam_name
```

Speichern und schließen:

1. `Strg` + `O` drücken
2. mit `Enter` bestätigen
3. `Strg` + `X` drücken

Das Steam-Kennwort gehört **nicht** in diese Datei.

## 6. Bei Steam anmelden

```bash
sudo /opt/arma3-control/scripts/arma3ctl steam-login
```

SteamCMD fragt nach dem Kennwort und möglicherweise nach einem Steam-Guard-Code.
Nach erfolgreicher Anmeldung gibst du Folgendes ein:

```text
quit
```

## 7. Arma-3-Server installieren

```bash
sudo /opt/arma3-control/scripts/arma3ctl install-server
```

Der Download ist groß und kann eine Weile dauern. Schließe das Terminal während
des Downloads nicht.

## 8. Lokale Kane-Mods kopieren

Am einfachsten geht das mit einem SFTP-Programm wie WinSCP. Kopiere die beiden
entpackten Modordner nach:

```text
/home/arma3/server/mods/
```

Danach müssen genau diese Ordner vorhanden sein:

```text
/home/arma3/server/mods/@kane_3cb_alive_civilian
/home/arma3/server/mods/@kane_3cb_middle_east_civilian_alive
```

Korrigiere anschließend Besitzer und Schreibweise:

```bash
sudo chown -R arma3:arma3 /home/arma3/server/mods/@kane_3cb_alive_civilian
sudo chown -R arma3:arma3 /home/arma3/server/mods/@kane_3cb_middle_east_civilian_alive
sudo -u arma3 python3 /opt/arma3-control/scripts/lowercase_tree.py /home/arma3/server/mods/@kane_3cb_alive_civilian
sudo -u arma3 python3 /opt/arma3-control/scripts/lowercase_tree.py /home/arma3/server/mods/@kane_3cb_middle_east_civilian_alive
```

## 9. Workshop-Mods laden

```bash
sudo /opt/arma3-control/scripts/arma3ctl update-mods
```

Auch dieser Download kann lange dauern. Das Script lädt alle aktivierten Mods,
vereinheitlicht die Dateinamen und kopiert die Signaturschlüssel.

## 10. Installation prüfen

```bash
sudo /opt/arma3-control/scripts/arma3ctl doctor
```

Am Ende sollte möglichst Folgendes stehen:

```text
Ergebnis: 0 Fehler, 0 Warnungen
```

Fehlende lokale Mods werden als Warnung angezeigt. Starte den Spielserver erst,
wenn alle aktivierten Mods vorhanden sind.

## 11. Firewall öffnen

Prüfe zuerst, ob du den normalen SSH-Port 22 verwendest:

```bash
sudo ss -ltnp | grep ssh
```

Bei Port 22:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 2302:2306/udp
sudo ufw enable
```

Wenn SSH auf einem anderen Port läuft, öffne diesen Port **vor** dem Aktivieren
der Firewall. Beispiel für Port 2222:

```bash
sudo ufw allow 2222/tcp
```

Bestätige die Aktivierung mit `y`.

## 12. Server starten

```bash
sudo systemctl start arma3-server
sudo systemctl status arma3-server --no-pager
```

Steht dort `active (running)`, läuft der Server.

## 13. Webpanel öffnen

Öffne auf deinem PC:

```text
https://SERVER_IP
```

Der Browser warnt vor dem selbstsignierten Zertifikat. Für den ersten Test ist
das erwartbar. Melde dich mit dem Benutzer `armaadmin` und dem zuvor notierten
Panel-Kennwort an.

Für einen dauerhaft öffentlich erreichbaren Server solltest du später eine
Domain und ein reguläres TLS-Zertifikat einrichten.

## Die wichtigsten Befehle

Server starten:

```bash
sudo /opt/arma3-control/scripts/arma3ctl start
```

Server stoppen:

```bash
sudo /opt/arma3-control/scripts/arma3ctl stop
```

Alles aktualisieren:

```bash
sudo /opt/arma3-control/scripts/arma3ctl update-all
```

Backup erstellen:

```bash
sudo /opt/arma3-control/scripts/arma3ctl backup
```

Letzte Servermeldungen anzeigen:

```bash
sudo /opt/arma3-control/scripts/arma3ctl logs 200
```

## Wenn etwas nicht funktioniert

Status des Spielservers:

```bash
sudo systemctl status arma3-server --no-pager
```

Status des Webpanels:

```bash
sudo systemctl status arma3-panel --no-pager
```

Fehler des Spielservers:

```bash
sudo journalctl -u arma3-server -n 200 --no-pager
```

Fehler des Webpanels:

```bash
sudo journalctl -u arma3-panel -n 200 --no-pager
```

nginx prüfen:

```bash
sudo nginx -t
```

Freien Speicher prüfen:

```bash
df -h
```

Wenn ein Befehl fehlschlägt, kopiere die vollständige Fehlermeldung. Der letzte
rote Satz allein reicht für die Fehlersuche oft nicht aus.

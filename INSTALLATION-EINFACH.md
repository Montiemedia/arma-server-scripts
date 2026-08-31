# Installation für Einsteiger

Diese Anleitung ist für einen frischen Server mit Ubuntu 24.04. Du brauchst
keine Linux-Erfahrung. Kopiere jeden Befehl vollständig und drücke danach
`Enter`. Warte immer, bis der Befehl fertig ist.

## Bevor du anfängst

Du brauchst:

- einen Server mit Ubuntu 24.04 und x86-64
- die öffentliche IPv4-Adresse des Servers
- einen Benutzer mit `sudo`-Rechten
- ein eigenes Steam-Konto für die Serverdownloads
- die beiden lokalen Kane-Mods als entpackte Ordner
- ungefähr 100 GB freien Speicher

Das Steam-Kennwort wird nicht in einer Konfigurationsdatei gespeichert.

> Wichtig: Nur der erste SSH-Befehl wird in Windows PowerShell eingegeben.
> Danach arbeitest du auf dem Ubuntu-Server. Du erkennst das an einer Zeile wie
> `benutzer@server:~$`.

## Schritt 1: Mit dem Server verbinden

Öffne auf deinem Windows-PC PowerShell. Ersetze `DEIN_BENUTZER` und
`SERVER_IP` durch deine Daten:

```powershell
ssh DEIN_BENUTZER@SERVER_IP
```

Beim ersten Verbindungsaufbau erscheint eine Rückfrage. Schreibe `yes` und
drücke `Enter`.

Danach wird das Kennwort deines Serverbenutzers abgefragt. Während der Eingabe
werden keine Zeichen angezeigt. Das ist normal. Tippe das Kennwort trotzdem
vollständig ein und drücke `Enter`.

Kontrollpunkt: Die Eingabezeile sollte jetzt ungefähr so aussehen:

```text
DEIN_BENUTZER@SERVER:~$
```

## Schritt 2: Projekt herunterladen

Diese Befehle werden auf dem Ubuntu-Server eingegeben:

```bash
sudo apt update
sudo apt install -y git
git clone --branch fix/resilient-mod-updates --single-branch https://github.com/Montiemedia/arma-server-scripts.git
cd arma-server-scripts
```

Falls `arma-server-scripts` bereits vorhanden ist, nicht noch einmal klonen.
Verwende stattdessen:

```bash
cd arma-server-scripts
git pull
```

Kontrollpunkt:

```bash
ls
```

In der Ausgabe müssen unter anderem `install.sh`, `README.md` und der Ordner
`scripts` stehen.

## Schritt 3: Automatische Installation starten

```bash
sudo ./install.sh
```

Der Installer führt dich durch sechs Schritte:

1. Er installiert das Webpanel, die Serverbenutzer und das Administrationsmenü.
2. Er fragt nach dem Namen des Steam-Kontos. Hier gehört kein Kennwort hinein.
3. SteamCMD fragt nach dem Steam-Kennwort und eventuell nach Steam Guard.
4. DepotDownloader wird als Ausweichlösung für schwierige Workshop-Mods eingerichtet.
5. Der Arma 3 Dedicated Server wird heruntergeladen.
6. Die Workshop-Mods werden auf Wunsch heruntergeladen.

Große Downloads können mehrere Stunden dauern. Das Terminal muss dabei geöffnet
bleiben.

Wenn Steam nach einem Kennwort fragt und nichts auf dem Bildschirm erscheint,
ist nichts kaputt. Linux zeigt Kennwörter bei der Eingabe nicht an.

Kontrollpunkt: Am Ende muss dieser Satz erscheinen:

```text
Die automatische Grundinstallation ist fertig.
```

Der Installer kann später erneut gestartet werden. Vorhandene `server.cfg`,
`basic.cfg`, Steam-Einstellungen, Modliste und Panel-Zugangsdaten bleiben dabei
erhalten.

## Schritt 4: Zugangsdaten anzeigen

```bash
sudo cat /root/arma3-initial-credentials.txt
```

Notiere das Panel-Kennwort und das Arma-Admin-Kennwort in einem
Passwortmanager. Wenn dort steht, dass das Panel-Kennwort unverändert bleibt,
gilt das Kennwort der ersten Installation weiter.

## Schritt 5: Lokale Kane-Mods kopieren

Die beiden lokalen Mods kommen nicht aus dem Steam Workshop. Kopiere die
entpackten Ordner mit WinSCP nach:

```text
/home/arma3/server/mods/
```

Danach müssen diese beiden Ordner vorhanden sein:

```text
/home/arma3/server/mods/@kane_3cb_alive_civilian
/home/arma3/server/mods/@kane_3cb_middle_east_civilian_alive
```

Besitzer und Linux-Schreibweise korrigieren:

```bash
sudo chown -R arma3:arma3 /home/arma3/server/mods/@kane_3cb_alive_civilian
sudo chown -R arma3:arma3 /home/arma3/server/mods/@kane_3cb_middle_east_civilian_alive
sudo -u arma3 python3 /opt/arma3-control/scripts/lowercase_tree.py /home/arma3/server/mods/@kane_3cb_alive_civilian
sudo -u arma3 python3 /opt/arma3-control/scripts/lowercase_tree.py /home/arma3/server/mods/@kane_3cb_middle_east_civilian_alive
```

## Schritt 6: Missionen kopieren

Multiplayer-Missionen gehören in diesen Ordner:

```text
/home/arma3/server/mpmissions
```

Wichtig: Auf Linux wird der Ordner vollständig kleingeschrieben. Der alte
Ordner `MPMissions` wird bei der Installation automatisch übernommen. Neue
Missionen gehören trotzdem immer nach `mpmissions`.

Eine Mission sieht zum Beispiel so aus:

```text
meine_mission.Altis.pbo
```

Nach dem Kopieren die Rechte korrigieren:

```bash
sudo chown arma3:arma3 /home/arma3/server/mpmissions/*.pbo
sudo chmod 0644 /home/arma3/server/mpmissions/*.pbo
```

Missionen im Menü prüfen:

```bash
sudo arma3-menu
```

Wähle Punkt `14`.

## Schritt 7: Installation prüfen

Öffne das Menü:

```bash
sudo arma3-menu
```

Führe zuerst diese Punkte aus:

1. Punkt `10` für die Serverdiagnose
2. Punkt `14` für die Missionsliste
3. Punkt `16` für die Steam-Verbindung
4. Punkt `17` für fehlgeschlagene Mods

Weitere wichtige Punkte:

- Punkt `8` aktualisiert die Mods und zeigt am Ende alle erfolgreichen Downloads.
- Punkt `18` öffnet die Modliste `mods.csv` im Editor.
- Punkt `19` listet installierte Workshop-Mods nummeriert zum Löschen auf.

Beim Löschen fragt das Menü noch einmal nach. Danach bleibt der Server
angehalten. Prüfe die Modliste und starte ihn anschließend bewusst neu.

Bei Punkt `10` ist dieses Ergebnis ideal:

```text
Ergebnis: 0 Fehler, 0 Warnungen
```

Warnungen wegen fehlender lokaler Mods müssen vor dem Serverstart behoben
werden.

## Schritt 8: Firewall sicher einrichten

Prüfe zuerst den SSH-Port:

```bash
sudo ss -ltnp | grep ssh
```

Wenn dort Port `22` steht:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 2302:2306/udp
sudo ufw enable
```

Bestätige die Aktivierung mit `y`.

Wenn SSH einen anderen Port verwendet, muss dieser Port vor `ufw enable`
freigegeben werden. Beispiel für Port 2222:

```bash
sudo ufw allow 2222/tcp
```

Wenn du den falschen SSH-Port freigibst, kannst du dich selbst aussperren.

## Schritt 9: Server starten

```bash
sudo arma3-menu
```

Wähle Punkt `1`. Prüfe danach mit Punkt `4`, ob der Server als
`active (running)` angezeigt wird.

Falls der Start fehlschlägt, wähle Punkt `6` und anschließend Punkt `10`.

## Schritt 10: Webpanel öffnen

Öffne auf deinem PC im Browser:

```text
https://SERVER_IP
```

Ersetze `SERVER_IP` durch die echte IP-Adresse. Der Browser warnt beim ersten
Aufruf vor dem selbstsignierten Zertifikat. Das ist bei dieser
Grundinstallation normal.

Benutzername:

```text
armaadmin
```

Das Kennwort steht in `/root/arma3-initial-credentials.txt`.

## Spätere Aktualisierung des Control-Projekts

```bash
cd ~/arma-server-scripts
git pull
sudo ./scripts/bootstrap.sh
```

Danach funktioniert das Menü weiterhin mit:

```bash
sudo arma3-menu
```

## Wenn Kane es kaputtgeklickt hat

### Das Menü startet nicht

```bash
sudo bash -n /opt/arma3-control/scripts/arma3-menu.sh
sudo chmod 0755 /opt/arma3-control/scripts/arma3-menu.sh
sudo ln -sfn /opt/arma3-control/scripts/arma3-menu.sh /usr/local/bin/arma3-menu
sudo arma3-menu
```

### Der Server startet nicht

Im Menü nacheinander Punkt `10`, Punkt `17` und Punkt `6` ausführen. Die
vollständige Fehlermeldung kopieren. Der letzte rote Satz allein reicht oft
nicht aus.

### Missionen werden nicht angezeigt

```bash
sudo ls -lisa /home/arma3/server/mpmissions
```

Die PBO-Dateien müssen im kleingeschriebenen Ordner `mpmissions` liegen und
`arma3:arma3` gehören.

### Workshop-Mods schlagen fehl

Im Menü Punkt `16` für die Steam-Verbindung prüfen. Danach Punkt `8` erneut
ausführen und Punkt `17` kontrollieren. Ein fehlgeschlagener Mod beendet nicht
mehr den gesamten Durchlauf. Die übrigen Mods werden weiterverarbeitet.

### Webpanel ist nicht erreichbar

```bash
sudo systemctl status arma3-panel --no-pager
sudo systemctl status nginx --no-pager
sudo nginx -t
```

### Speicher ist voll

```bash
df -h
```

Die wichtige Zeile beginnt normalerweise mit `/dev/`. Wenn die Spalte `Use%`
nahe `100%` liegt, muss Speicher freigegeben oder erweitert werden.

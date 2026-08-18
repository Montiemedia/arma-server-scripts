#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

[[ $EUID -eq 0 ]] || { echo "Bitte als root ausführen: sudo ./scripts/install.sh" >&2; exit 1; }

SOURCE_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ENV_FILE=/etc/arma3/arma3.env
SERVER_CFG=/home/arma3/server/server.cfg
CREDENTIAL_FILE=/root/arma3-initial-credentials.txt

say() { printf '\n=== %s ===\n' "$*"; }
ask() {
    local var="$1" prompt="$2" default="${3:-}" value
    if [[ -n "$default" ]]; then
        read -r -p "$prompt [$default]: " value
        value=${value:-$default}
    else
        read -r -p "$prompt: " value
    fi
    printf -v "$var" '%s' "$value"
}
escape_cfg() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

cat <<'BANNER'
TF133 Arma 3 Server Installer

Der Installer richtet den Linux-Server, SteamCMD, systemd, Mods,
Signatur-Keys, Logging und die Grundkonfiguration ein.
Steam-Kennwörter werden nicht gespeichert.
BANNER

ask STEAM_USER "Steam-Benutzer für Arma/Workshop" ""
ask SERVER_NAME "Servername" "Task Force 133 - Eventserver"
ask SERVER_PASSWORD "Server-Passwort (leer = keines)" ""
ask MAX_PLAYERS "Maximale Spielerzahl" "60"
ask SERVER_PORT "Game-Port" "2302"
ask ADMIN_UID "Steam64-ID eines festen Admins (leer = überspringen)" ""

if [[ -z "$STEAM_USER" ]]; then
    echo "Steam-Benutzer darf nicht leer sein." >&2
    exit 1
fi
[[ "$MAX_PLAYERS" =~ ^[0-9]+$ ]] || { echo "Maximale Spielerzahl muss numerisch sein." >&2; exit 1; }
[[ "$SERVER_PORT" =~ ^[0-9]+$ ]] || { echo "Port muss numerisch sein." >&2; exit 1; }
[[ -z "$ADMIN_UID" || "$ADMIN_UID" =~ ^[0-9]{17}$ ]] || { echo "Steam64-ID muss 17 Ziffern haben." >&2; exit 1; }

say "1/7 Grundsystem"
"$SOURCE_ROOT/scripts/bootstrap.sh"

say "2/7 Konfiguration"
# shellcheck disable=SC1090
source "$ENV_FILE"
python3 - "$ENV_FILE" "$STEAM_USER" "$SERVER_PORT" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
steam_user, port = sys.argv[2], sys.argv[3]
lines = p.read_text().splitlines()
out = []
seen = set()
updates = {"STEAM_USER": steam_user, "SERVER_PORT": port}
for line in lines:
    if "=" in line and not line.lstrip().startswith("#"):
        key = line.split("=", 1)[0]
        if key in updates:
            out.append(f"{key}={updates[key]}")
            seen.add(key)
            continue
    out.append(line)
for key, value in updates.items():
    if key not in seen:
        out.append(f"{key}={value}")
p.write_text("\n".join(out) + "\n")
PY
chmod 0640 "$ENV_FILE"

admin_password=$(openssl rand -hex 18)
server_name_escaped=$(escape_cfg "$SERVER_NAME")
server_password_escaped=$(escape_cfg "$SERVER_PASSWORD")
admin_uid_cfg=""
[[ -n "$ADMIN_UID" ]] && admin_uid_cfg="\"$ADMIN_UID\""

cat > "$SERVER_CFG" <<CFG
// Generiert durch TF133 Arma 3 Server Installer
hostname = "$server_name_escaped";
logFile = "server_console.log";
password = "$server_password_escaped";
passwordAdmin = "$admin_password";
maxPlayers = $MAX_PLAYERS;

// Sicherheit
// 0 = keine Signaturprüfung. Für geschlossene Events bewusst als Standard gesetzt.
verifySignatures = 0;
equalModRequired = 0;
kickDuplicate = 1;
allowedFilePatching = 0;
admins[] = { $admin_uid_cfg };
BattlEye = 0;

// Voice
// ACRE kann parallel als Mod genutzt werden.
disableVoN = 0;
vonCodec = 1;
vonCodecQuality = 30;

// Serververhalten
persistent = 0;
timeStampFormat = "full";

// Voting
voteMissionPlayers = 1;
voteThreshold = 0.33;

motd[] =
{
    "Willkommen auf dem Task Force 133 Server!",
    "Alles frei von Verpflichtungen, unverkrampft und gemeinsam Spaß haben."
};
motdInterval = 5;

// Missionsrotation optional. Der template-Name wird OHNE .pbo angegeben.
// Linux: Missionsverzeichnis ist /home/arma3/server/mpmissions (kleingeschrieben).
// class Missions
// {
//     class EventMission
//     {
//         template = "MissionName.Stratis";
//         difficulty = "Veteran";
//     };
// };
CFG
chown arma3:arma3 "$SERVER_CFG"
chmod 0640 "$SERVER_CFG"

if [[ -f "$CREDENTIAL_FILE" ]]; then
    cat >> "$CREDENTIAL_FILE" <<CREDS

Durch install.sh neu gesetzte Serverdaten:
Servername: $SERVER_NAME
Game-Port: $SERVER_PORT
Arma-Admin-Kennwort: $admin_password
CREDS
    chmod 0600 "$CREDENTIAL_FILE"
fi

say "3/7 Steam-Anmeldung"
echo "SteamCMD öffnet sich jetzt interaktiv. Kennwort und ggf. Steam-Guard-Code eingeben."
echo "Nach erfolgreichem Login mit 'quit' beenden."
/opt/arma3-control/scripts/arma3ctl steam-login

say "4/7 Dedicated Server"
/opt/arma3-control/scripts/arma3ctl install-server

say "5/7 Workshop-Mods"
set +e
/opt/arma3-control/scripts/arma3ctl update-mods
mods_rc=$?
set -e

say "6/7 Diagnose"
set +e
/opt/arma3-control/scripts/arma3ctl doctor
doctor_rc=$?
set -e

say "7/7 Abschluss"
echo "Installation abgeschlossen."
echo
printf 'Server:      %s\n' "$SERVER_NAME"
printf 'Port:        %s/UDP\n' "$SERVER_PORT"
printf 'Serverpfad:  /home/arma3/server\n'
printf 'Missionen:   /home/arma3/server/mpmissions\n'
printf 'Modliste:    /etc/arma3/mods.csv\n'
printf 'Zugangsdaten:%s\n' " $CREDENTIAL_FILE"
echo
if (( mods_rc != 0 )); then
    echo "WARNUNG: Mindestens ein Workshop-Mod ist fehlgeschlagen."
    echo "Liste: /home/arma3/state/failed-mods.txt"
    echo "Erneut versuchen: sudo /opt/arma3-control/scripts/arma3ctl update-mods"
fi
if (( doctor_rc != 0 )); then
    echo "WARNUNG: Die Diagnose meldet Fehler. Vor dem Event mit 'arma3ctl doctor' prüfen."
fi
cat <<'NEXT'

Wichtige Befehle:
  sudo /opt/arma3-control/scripts/arma3ctl start
  sudo /opt/arma3-control/scripts/arma3ctl stop
  sudo /opt/arma3-control/scripts/arma3ctl restart
  sudo /opt/arma3-control/scripts/arma3ctl update-all
  sudo /opt/arma3-control/scripts/arma3ctl doctor
  sudo /opt/arma3-control/scripts/arma3ctl logs 200

Firewall:
  Der Installer aktiviert UFW absichtlich NICHT automatisch, damit SSH nicht
  versehentlich ausgesperrt wird. Für Standard-SSH und Port 2302:
    sudo ufw allow OpenSSH
    sudo ufw allow 2302:2306/udp
    sudo ufw enable
NEXT

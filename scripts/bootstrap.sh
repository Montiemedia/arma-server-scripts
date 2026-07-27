#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

[[ $EUID -eq 0 ]] || { echo "Bitte als root ausführen: sudo ./scripts/bootstrap.sh" >&2; exit 1; }

SOURCE_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TARGET_ROOT=/opt/arma3-control
ARMA_USER=arma3
PANEL_USER=arma3panel
OPS_GROUP=arma3ops
CREDENTIAL_FILE=/root/arma3-initial-credentials.txt

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }

log "Installiere Systempakete ..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates curl tar rsync sudo openssl apache2-utils nginx ufw \
    python3 python3-venv python3-pip lib32gcc-s1 lib32stdc++6

getent group "$OPS_GROUP" >/dev/null || groupadd --system "$OPS_GROUP"
if ! id "$ARMA_USER" >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash "$ARMA_USER"
fi
if ! id "$PANEL_USER" >/dev/null 2>&1; then
    useradd --system --create-home --home-dir /var/lib/arma3-panel --shell /usr/sbin/nologin "$PANEL_USER"
fi
usermod -aG "$OPS_GROUP" "$ARMA_USER"
usermod -aG "$OPS_GROUP",arma3,systemd-journal "$PANEL_USER"

log "Installiere Control-Panel unter $TARGET_ROOT ..."
install -d -o root -g root -m 0755 "$TARGET_ROOT"
rsync -a --delete \
    --exclude '.venv' \
    --exclude '__pycache__' \
    "$SOURCE_ROOT/" "$TARGET_ROOT/"
chown -R root:root "$TARGET_ROOT"
find "$TARGET_ROOT/scripts" -maxdepth 1 -type f -exec chmod 0755 {} +

install -d -o root -g "$OPS_GROUP" -m 0750 /etc/arma3
if [[ ! -f /etc/arma3/arma3.env ]]; then
    install -o root -g "$OPS_GROUP" -m 0640 "$TARGET_ROOT/config/arma3.env.example" /etc/arma3/arma3.env
fi
install -o root -g "$OPS_GROUP" -m 0640 "$TARGET_ROOT/config/mods.csv" /etc/arma3/mods.csv

install -d -o "$ARMA_USER" -g "$ARMA_USER" -m 0750 \
    /home/arma3/steamcmd /home/arma3/server /home/arma3/server/mods \
    /home/arma3/server/MPMissions /home/arma3/workshop /home/arma3/backups \
    /home/arma3/state "/home/arma3/.local/share/Arma 3" \
    "/home/arma3/.local/share/Arma 3 - Other Profiles"

panel_password=$(openssl rand -hex 12)
server_admin_password=""
if [[ ! -f /home/arma3/server/server.cfg ]]; then
    server_admin_password=$(openssl rand -hex 18)
    sed "s/CHANGE_ME_IMMEDIATELY/$server_admin_password/" "$TARGET_ROOT/config/server.cfg.example" \
        > /home/arma3/server/server.cfg
    chown "$ARMA_USER:$ARMA_USER" /home/arma3/server/server.cfg
    chmod 0640 /home/arma3/server/server.cfg
else
    server_admin_password=$(sed -nE 's/^[[:space:]]*passwordAdmin[[:space:]]*=[[:space:]]*"([^"]*)".*/\1/p' /home/arma3/server/server.cfg | head -n1)
    [[ -n "$server_admin_password" ]] || server_admin_password="In vorhandener server.cfg prüfen"
fi
if [[ ! -f /home/arma3/server/basic.cfg ]]; then
    install -o "$ARMA_USER" -g "$ARMA_USER" -m 0640 \
        "$TARGET_ROOT/config/basic.cfg.example" /home/arma3/server/basic.cfg
fi

log "Erstelle Python-Umgebung ..."
python3 -m venv "$TARGET_ROOT/.venv"
"$TARGET_ROOT/.venv/bin/pip" install --disable-pip-version-check --no-cache-dir \
    -r "$TARGET_ROOT/backend/requirements.txt"
chown -R root:root "$TARGET_ROOT/.venv"

install -d -o "$PANEL_USER" -g "$PANEL_USER" -m 0750 /var/lib/arma3-panel/jobs
install -o root -g root -m 0644 "$TARGET_ROOT/systemd/arma3-server.service" /etc/systemd/system/arma3-server.service
install -o root -g root -m 0644 "$TARGET_ROOT/systemd/arma3-panel.service" /etc/systemd/system/arma3-panel.service
install -o root -g root -m 0440 "$TARGET_ROOT/sudoers/arma3-panel" /etc/sudoers.d/arma3-panel
visudo -cf /etc/sudoers.d/arma3-panel

htpasswd -bc /etc/nginx/.htpasswd armaadmin "$panel_password" >/dev/null
install -d -o root -g root -m 0700 /etc/nginx/ssl
if [[ ! -f /etc/nginx/ssl/arma3-panel.key || ! -f /etc/nginx/ssl/arma3-panel.crt ]]; then
    openssl req -x509 -newkey rsa:3072 -nodes -days 825 \
        -subj "/CN=arma3-panel.local" \
        -keyout /etc/nginx/ssl/arma3-panel.key \
        -out /etc/nginx/ssl/arma3-panel.crt >/dev/null 2>&1
    chmod 0600 /etc/nginx/ssl/arma3-panel.key
    chmod 0644 /etc/nginx/ssl/arma3-panel.crt
fi
chown root:www-data /etc/nginx/.htpasswd
chmod 0640 /etc/nginx/.htpasswd
rm -f /etc/nginx/sites-enabled/default
install -o root -g root -m 0644 "$TARGET_ROOT/nginx/arma3-panel.conf" /etc/nginx/sites-available/arma3-panel.conf
ln -sfn /etc/nginx/sites-available/arma3-panel.conf /etc/nginx/sites-enabled/arma3-panel.conf
nginx -t

cat > "$CREDENTIAL_FILE" <<CREDS
TF133 Arma 3 Control – initiale Zugangsdaten

Panel-Benutzer: armaadmin
Panel-Kennwort: $panel_password
Arma-Admin-Kennwort: $server_admin_password

Das Panel läuft über HTTPS mit einem selbstsignierten Zertifikat. Die erste Browserwarnung ist daher erwartbar. Vor dauerhafter öffentlicher Nutzung eine Domain und ein reguläres TLS-Zertifikat einrichten.
Nach Übernahme der Kennwörter diese Datei löschen:
rm -f $CREDENTIAL_FILE
CREDS
chmod 0600 "$CREDENTIAL_FILE"

systemctl daemon-reload
systemctl enable arma3-panel.service nginx
systemctl restart arma3-panel.service
systemctl restart nginx
systemctl enable arma3-server.service

cat <<RESULT

Installation des Panels abgeschlossen.

Initiale Zugangsdaten:
  $CREDENTIAL_FILE

Nächste Schritte:
  1. STEAM_USER in /etc/arma3/arma3.env setzen.
  2. sudo /opt/arma3-control/scripts/arma3ctl steam-login
  3. sudo /opt/arma3-control/scripts/arma3ctl install-server
  4. Lokale Kane-Mods nach /home/arma3/server/mods/ kopieren.
  5. sudo /opt/arma3-control/scripts/arma3ctl update-mods
  6. sudo /opt/arma3-control/scripts/arma3ctl doctor
  7. sudo systemctl start arma3-server

Firewall erst nach Prüfung des SSH-Ports aktivieren:
  ufw allow OpenSSH
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw allow 2302:2306/udp
  ufw enable

Panel lokal prüfen:
  curl -k -u armaadmin:<Kennwort> https://127.0.0.1/healthz
RESULT

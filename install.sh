#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ENV_FILE="${ARMA_ENV_FILE:-/etc/arma3/arma3.env}"
CONTROL_ROOT="${CONTROL_ROOT:-/opt/arma3-control}"
ARMA3CTL="$CONTROL_ROOT/scripts/arma3ctl"
OPS_GROUP=arma3ops

step() {
    printf '\n============================================================\n'
    printf '%s\n' "$1"
    printf '============================================================\n\n'
}

die() {
    printf '\nFEHLER: %s\n' "$*" >&2
    exit 1
}

require_supported_system() {
    [[ $EUID -eq 0 ]] || die "Bitte so starten: sudo ./install.sh"
    [[ -r /etc/os-release ]] || die "Ubuntu konnte nicht erkannt werden."
    # shellcheck disable=SC1091
    source /etc/os-release
    [[ "${ID:-}" == "ubuntu" && "${VERSION_ID:-}" == "24.04" ]] \
        || die "Unterstützt wird Ubuntu 24.04 auf x86-64."
    [[ "$(uname -m)" == "x86_64" ]] || die "Unterstützt wird nur x86-64."
}

ask_yes_no() {
    local question="$1" default="${2:-yes}" answer hint
    if [[ "$default" == "yes" ]]; then
        hint='J/n'
    else
        hint='j/N'
    fi
    IFS= read -r -p "$question [$hint]: " answer || answer=""
    if [[ -z "$answer" ]]; then
        [[ "$default" == "yes" ]]
        return
    fi
    case "$answer" in
        j|J|ja|Ja|JA|y|Y|yes|Yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

valid_steam_user() {
    [[ "$1" =~ ^[A-Za-z0-9_.-]+$ ]]
}

render_steam_env() {
    local source_file="$1" steam_user="$2"
    awk -v steam_user="$steam_user" '
        BEGIN { found = 0 }
        /^STEAM_USER=/ {
            print "STEAM_USER=" steam_user
            found = 1
            next
        }
        { print }
        END {
            if (!found) print "STEAM_USER=" steam_user
        }
    ' "$source_file"
}

save_steam_user() {
    local steam_user="$1" temporary
    temporary=$(mktemp)
    render_steam_env "$ENV_FILE" "$steam_user" > "$temporary"
    install -o root -g "$OPS_GROUP" -m 0640 "$temporary" "$ENV_FILE"
    rm -f -- "$temporary"
}

main() {
    local steam_user="" current_steam_user=""
    require_supported_system

    step "Schritt 1 von 6: Grundsystem, Webpanel und Menü installieren"
    "$PROJECT_ROOT/scripts/bootstrap.sh"
    [[ -x "$ARMA3CTL" ]] || die "arma3ctl wurde nicht installiert: $ARMA3CTL"

    step "Schritt 2 von 6: Steam-Konto eintragen"
    current_steam_user=$(sed -n 's/^STEAM_USER=//p' "$ENV_FILE" | head -n1)
    if [[ -n "$current_steam_user" ]]; then
        printf 'Aktuell eingetragenes Steam-Konto: %s\n' "$current_steam_user"
        if ask_yes_no "Dieses Steam-Konto weiterverwenden?" yes; then
            steam_user="$current_steam_user"
        fi
    fi
    while [[ -z "$steam_user" ]]; do
        IFS= read -r -p 'Steam-Kontoname eingeben, ohne Kennwort: ' steam_user || true
        if ! valid_steam_user "$steam_user"; then
            printf 'Bitte nur Buchstaben, Zahlen, Punkt, Unterstrich oder Minus verwenden.\n'
            steam_user=""
        fi
    done
    save_steam_user "$steam_user"
    printf 'Steam-Konto wurde gespeichert. Das Kennwort wird nicht in einer Datei abgelegt.\n'

    step "Schritt 3 von 6: Steam Guard bestätigen"
    printf 'SteamCMD fragt gleich nach dem Steam-Kennwort und eventuell nach Steam Guard.\n'
    printf 'Bei der Kennworteingabe können die Zeichen unsichtbar bleiben. Das ist normal.\n\n'
    "$ARMA3CTL" steam-login

    step "Schritt 4 von 6: Downloadwerkzeuge installieren"
    "$ARMA3CTL" install-depotdownloader

    step "Schritt 5 von 6: Arma 3 Dedicated Server installieren"
    "$ARMA3CTL" install-server

    step "Schritt 6 von 6: Workshop-Mods herunterladen"
    if ask_yes_no "Workshop-Mods jetzt herunterladen? Das kann mehrere Stunden dauern." yes; then
        if ! "$ARMA3CTL" update-mods; then
            printf '\nMindestens ein Mod ist fehlgeschlagen. Die übrigen Mods wurden trotzdem verarbeitet.\n'
            printf 'Die Fehlerliste findest du später über Menüpunkt 17.\n'
        fi
    else
        printf 'Übersprungen. Später im Menü den Punkt 8 auswählen.\n'
    fi

    printf '\nDie automatische Grundinstallation ist fertig.\n\n'
    printf 'Noch zu erledigen:\n'
    printf '  1. Die beiden lokalen Kane-Mods nach /home/arma3/server/mods kopieren.\n'
    printf '  2. Missionen nach /home/arma3/server/mpmissions kopieren.\n'
    printf '  3. Firewall erst nach Prüfung des SSH-Ports aktivieren.\n'
    printf '  4. Das Menü starten: sudo arma3-menu\n\n'
    printf 'Webpanel-Zugangsdaten anzeigen:\n'
    printf '  sudo cat /root/arma3-initial-credentials.txt\n'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

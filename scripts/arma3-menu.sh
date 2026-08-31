#!/usr/bin/env bash
set -uo pipefail
umask 027

CONTROL_ROOT="${CONTROL_ROOT:-/opt/arma3-control}"
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
if [[ -x "$CONTROL_ROOT/scripts/arma3ctl" ]]; then
    SCRIPT_DIR="$CONTROL_ROOT/scripts"
fi
ENV_FILE="${ARMA_ENV_FILE:-/etc/arma3/arma3.env}"
ARMA3CTL="${ARMA3CTL:-$SCRIPT_DIR/arma3ctl}"
START_SCRIPT="${START_SCRIPT:-$SCRIPT_DIR/start-server.sh}"

require_root() {
    if [[ ${ARMA_MENU_SKIP_ROOT_CHECK:-0} == "1" ]]; then
        return 0
    fi
    if [[ $EUID -ne 0 ]]; then
        printf 'Bitte mit sudo starten:\n  sudo %q\n' "$0" >&2
        exit 1
    fi
}

load_config() {
    if [[ ! -r "$ENV_FILE" ]]; then
        printf 'FEHLER: Konfiguration fehlt oder ist nicht lesbar: %s\n' "$ENV_FILE" >&2
        exit 1
    fi
    # shellcheck disable=SC1090
    source "$ENV_FILE"

    : "${SERVER_DIR:=/home/arma3/server}"
    : "${SERVER_UNIT:=arma3-server.service}"
    : "${SERVER_PORT:=2302}"
    : "${SERVER_CONFIG:=server.cfg}"
    : "${BASIC_CONFIG:=basic.cfg}"
    : "${STATE_DIR:=/home/arma3/state}"
    : "${FAILED_MODS_FILE:=$STATE_DIR/failed-mods.csv}"
    : "${MISSION_DIR:=$SERVER_DIR/mpmissions}"
}

pause_menu() {
    printf '\n'
    IFS= read -r -p 'Enter drücken, um zum Menü zurückzukehren ... ' _ || true
}

confirm_action() {
    local prompt="$1" answer
    IFS= read -r -p "$prompt [j/N]: " answer || return 1
    case "$answer" in
        j|J|ja|Ja|JA) return 0 ;;
        *) printf 'Aktion abgebrochen.\n'; return 1 ;;
    esac
}

run_ctl() {
    local command="$1"
    shift
    if [[ ! -x "$ARMA3CTL" ]]; then
        printf 'FEHLER: arma3ctl ist nicht ausführbar: %s\n' "$ARMA3CTL" >&2
        return 1
    fi
    if "$ARMA3CTL" "$command" "$@"; then
        printf '\nAktion erfolgreich abgeschlossen.\n'
    else
        local status=$?
        printf '\nFEHLER: Die Aktion endete mit Exit-Code %d.\n' "$status" >&2
        return "$status"
    fi
}

resolve_config_path() {
    local configured="$1"
    if [[ "$configured" == /* ]]; then
        printf '%s\n' "$configured"
    else
        printf '%s/%s\n' "$SERVER_DIR" "$configured"
    fi
}

open_in_editor() {
    local path="$1" editor
    if command -v nano >/dev/null 2>&1; then
        editor='nano'
    elif command -v vi >/dev/null 2>&1; then
        editor='vi'
    else
        printf 'FEHLER: Weder nano noch vi ist installiert.\n' >&2
        return 1
    fi
    printf 'Öffne %s mit %s.\n' "$path" "$editor"
    "$editor" "$path"
}

show_file() {
    local path="$1"
    if [[ ! -r "$path" ]]; then
        printf 'FEHLER: Datei fehlt oder ist nicht lesbar: %s\n' "$path" >&2
        return 1
    fi
    if [[ -t 1 ]] && command -v less >/dev/null 2>&1; then
        printf 'Mit q kehrst du zum Menü zurück.\n\n'
        less -R "$path"
    else
        sed -n '1,240p' "$path"
    fi
}

show_live_logs() {
    printf 'Live-Journal für %s. Mit Strg+C kehrst du zum Menü zurück.\n\n' "$SERVER_UNIT"
    journalctl -u "$SERVER_UNIT" -n 300 -f --no-pager --full -o short-iso || true
}

show_recent_logs() {
    local lines
    IFS= read -r -p 'Wie viele Zeilen anzeigen? [200]: ' lines || return 0
    lines=${lines:-200}
    if [[ ! "$lines" =~ ^[1-9][0-9]{0,3}$ ]] || (( lines > 5000 )); then
        printf 'Ungültige Eingabe. Erlaubt sind 1 bis 5000 Zeilen.\n' >&2
        return 1
    fi
    run_ctl logs "$lines"
}

check_ports() {
    local first_port="$SERVER_PORT" last_port
    if [[ ! "$first_port" =~ ^[0-9]+$ ]] || (( first_port < 1 || first_port > 65531 )); then
        printf 'FEHLER: Ungültiger SERVER_PORT in %s: %s\n' "$ENV_FILE" "$first_port" >&2
        return 1
    fi
    last_port=$((first_port + 4))
    if ! command -v ss >/dev/null 2>&1; then
        printf 'FEHLER: Das Programm ss ist nicht installiert.\n' >&2
        return 1
    fi
    printf 'Lauschende UDP-Ports von %d bis %d:\n' "$first_port" "$last_port"
    local result
    result=$(ss -H -lunp 2>/dev/null | awk -v first="$first_port" -v last="$last_port" '
        {
            for (i = 1; i <= NF; i++) {
                port = $i
                sub(/^.*:/, "", port)
                if (port ~ /^[0-9]+$/ && port >= first && port <= last) {
                    print
                    next
                }
            }
        }
    ')
    if [[ -n "$result" ]]; then
        printf '%s\n' "$result"
    else
        printf 'Keine passenden UDP-Ports lauschen. Ist der Server gestartet?\n'
    fi
}

list_missions() {
    local result
    printf 'Missionen unter %s:\n' "$MISSION_DIR"
    if [[ ! -d "$MISSION_DIR" ]]; then
        printf 'Der Ordner existiert nicht.\n'
        return 1
    fi
    result=$(find "$MISSION_DIR" -mindepth 1 -maxdepth 1 -printf '%f\n' 2>/dev/null | sort -f)
    if [[ -n "$result" ]]; then
        printf '%s\n' "$result"
    else
        printf 'Keine Missionen gefunden.\n'
    fi
}

show_ufw_status() {
    if ! command -v ufw >/dev/null 2>&1; then
        printf 'FEHLER: UFW ist nicht installiert.\n' >&2
        return 1
    fi
    ufw status verbose
}

check_steam_connection() {
    local url='https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz'
    printf 'Prüfe DNS und HTTPS-Verbindung zum SteamCMD-Download ...\n'
    if command -v getent >/dev/null 2>&1; then
        getent ahostsv4 steamcdn-a.akamaihd.net | awk 'NR == 1 {print "Steam-CDN-Adresse: " $1}' || true
    fi
    if ! command -v curl >/dev/null 2>&1; then
        printf 'FEHLER: curl ist nicht installiert.\n' >&2
        return 1
    fi
    if curl -fsSIL --connect-timeout 10 --max-time 20 "$url" >/dev/null; then
        printf 'Steam-Verbindungscheck erfolgreich. DNS, HTTPS und Steam-CDN sind erreichbar.\n'
    else
        printf 'FEHLER: Steam-CDN ist nicht erreichbar. DNS, Internetzugang und Firewall prüfen.\n' >&2
        return 1
    fi
}

show_failed_mods() {
    if [[ ! -e "$FAILED_MODS_FILE" ]]; then
        printf 'Noch keine Fehlerliste vorhanden: %s\n' "$FAILED_MODS_FILE"
        return 0
    fi
    if [[ ! -r "$FAILED_MODS_FILE" ]]; then
        printf 'FEHLER: Fehlerliste ist nicht lesbar: %s\n' "$FAILED_MODS_FILE" >&2
        return 1
    fi
    printf 'Fehlerliste aus %s:\n\n' "$FAILED_MODS_FILE"
    if [[ $(wc -l < "$FAILED_MODS_FILE") -le 1 ]]; then
        printf 'Keine fehlgeschlagenen Mods protokolliert.\n'
    else
        sed -n '1,240p' "$FAILED_MODS_FILE"
    fi
}

delete_mod_interactive() {
    local -a mod_names=() mod_targets=()
    local name type _workshop_id target enabled choice index

    printf 'Installierte Workshop-Mods:\n\n'
    while IFS=, read -r name type _workshop_id target enabled; do
        enabled=${enabled%$'\r'}
        [[ "$name" == "name" || "$type" != "workshop" ]] && continue
        [[ -d "$SERVER_DIR/mods/$target" ]] || continue
        mod_names+=("$name")
        mod_targets+=("$target")
        printf '  %2d) %s (%s)\n' "${#mod_names[@]}" "$name" "$target"
    done < "$MODS_FILE"

    if (( ${#mod_names[@]} == 0 )); then
        printf 'Keine installierten Workshop-Mods gefunden.\n'
        return 0
    fi

    printf '   0) Abbrechen\n\n'
    IFS= read -r -p 'Nummer des zu löschenden Mods: ' choice || return 0
    [[ "$choice" == "0" ]] && { printf 'Aktion abgebrochen.\n'; return 0; }
    if [[ ! "$choice" =~ ^[1-9][0-9]*$ ]] || (( choice > ${#mod_names[@]} )); then
        printf 'Ungültige Modnummer.\n' >&2
        return 1
    fi

    index=$((choice - 1))
    printf '\nAusgewählt: %s (%s)\n' "${mod_names[$index]}" "${mod_targets[$index]}"
    printf 'Der Server wird angehalten. Der Modordner und seine Downloadkopien werden gelöscht.\n'
    printf 'Der Eintrag in mods.csv wird deaktiviert und nicht automatisch erneut geladen.\n'
    if confirm_action 'Diesen Workshop-Mod wirklich löschen?'; then
        run_ctl remove-mod "${mod_targets[$index]}"
    fi
}

show_menu() {
    if [[ -t 1 && -n ${TERM:-} && ${TERM:-dumb} != dumb ]]; then
        clear 2>/dev/null || true
    fi
    cat <<'MENU'
============================================================
 TF133 Arma 3 Control Menü
============================================================
  1) Server starten
  2) Server stoppen
  3) Server neu starten
  4) Serverstatus anzeigen
  5) Server-Journal live anzeigen
  6) Letzte Zeilen des Server-Journals anzeigen
  7) Arma-UDP-Ports prüfen
  8) Workshop-Mods aktualisieren
  9) Mod-Keys synchronisieren
 10) Serverdiagnose ausführen
 11) server.cfg öffnen
 12) basic.cfg öffnen
 13) start-server.sh anzeigen
 14) Missionen auflisten
 15) UFW-Status anzeigen
 16) Steam-Verbindung prüfen
 17) failed-mods.csv anzeigen
 18) mods.csv öffnen
 19) Workshop-Mod löschen
  0) Menü beenden
============================================================
MENU
}

main() {
    local choice
    require_root
    load_config

    while true; do
        show_menu
        if ! IFS= read -r -p 'Auswahl: ' choice; then
            printf '\nMenü beendet.\n'
            return 0
        fi
        printf '\n'

        case "$choice" in
            1) run_ctl start || true ;;
            2) confirm_action 'Server wirklich stoppen?' && run_ctl stop || true ;;
            3) confirm_action 'Server wirklich neu starten?' && run_ctl restart || true ;;
            4) run_ctl status || true ;;
            5) show_live_logs ;;
            6) show_recent_logs || true ;;
            7) check_ports || true ;;
            8) confirm_action 'Workshop-Mods jetzt aktualisieren?' && run_ctl update-mods || true ;;
            9) confirm_action 'Mod-Keys jetzt synchronisieren?' && run_ctl sync-keys || true ;;
            10) run_ctl doctor || true ;;
            11) open_in_editor "$(resolve_config_path "$SERVER_CONFIG")" || true ;;
            12) open_in_editor "$(resolve_config_path "$BASIC_CONFIG")" || true ;;
            13) show_file "$START_SCRIPT" || true ;;
            14) list_missions || true ;;
            15) show_ufw_status || true ;;
            16) check_steam_connection || true ;;
            17) show_failed_mods || true ;;
            18) open_in_editor "$MODS_FILE" || true ;;
            19) delete_mod_interactive || true ;;
            0) printf 'Menü beendet.\n'; return 0 ;;
            *) printf 'Ungültige Auswahl. Bitte eine Zahl von 0 bis 19 eingeben.\n' ;;
        esac
        pause_menu
    done
}

main "$@"

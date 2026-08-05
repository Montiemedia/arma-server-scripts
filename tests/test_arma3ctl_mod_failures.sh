#!/usr/bin/env bash
set -Eeuo pipefail
PATH="/usr/bin:/bin:$PATH"

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ARMA3CTL_UNDER_TEST=${ARMA3CTL_UNDER_TEST:-$PROJECT_ROOT/scripts/arma3ctl}
TEST_ROOT=$(mktemp -d)
export TEST_ROOT
trap 'rm -rf "$TEST_ROOT"' EXIT

cat > "$TEST_ROOT/arma3.env" <<'ENV'
ARMA_USER=testuser
ARMA_HOME="$TEST_ROOT/home"
SERVER_DIR="$TEST_ROOT/server"
STEAMCMD_DIR="$TEST_ROOT/steamcmd"
WORKSHOP_DIR="$TEST_ROOT/workshop"
BACKUP_DIR="$TEST_ROOT/backups"
STATE_DIR="$TEST_ROOT/state"
MODS_FILE="$TEST_ROOT/mods.csv"
SERVER_UNIT=arma3-test.service
WORKSHOP_RETRIES=2
WORKSHOP_RETRY_DELAY=0
WORKSHOP_ITEM_TIMEOUT=5m
ENV

cat > "$TEST_ROOT/mods.csv" <<'CSV'
name,type,workshop_id,target,enabled
Erster Mod,workshop,101,@first,1
Defekter Mod,workshop,202,@broken,1
Letzter Mod,workshop,303,@last,1
CSV

export ARMA_ENV_FILE="$TEST_ROOT/arma3.env"

# Lade die Funktionen, aber nicht den Befehlsverteiler am Dateiende.
# shellcheck disable=SC1090
source <(sed '/^command="${1:-}"$/,$d' "$ARMA3CTL_UNDER_TEST")

require_root() { :; }
ensure_steamcmd() { mkdir -p "$STATE_DIR" "$WORKSHOP_DIR" "$SERVER_DIR/mods"; }
chown() { :; }
chmod() { :; }
sleep() { :; }

timeout() {
    while [[ "${1:-}" == --* ]]; do shift; done
    shift
    "$@"
}

runuser() {
    local arg workshop_id=""
    for arg in "$@"; do
        if [[ "$arg" =~ ^(101|202|303)$ ]]; then
            workshop_id="$arg"
        fi
    done

    printf '%s\n' "$workshop_id" >> "$TEST_ROOT/download-calls.txt"
    if [[ "$workshop_id" == "202" ]]; then
        printf 'ERROR! Download item %s failed (Failure).\n' "$workshop_id"
        return 1
    fi

    mkdir -p "$WORKSHOP_DIR/steamapps/workshop/content/107410/$workshop_id"
    printf 'Success. Downloaded item %s\n' "$workshop_id"
}

sync_workshop_item() {
    printf '%s\n' "$2" >> "$TEST_ROOT/sync-calls.txt"
    return 0
}

sync_keys() { :; }

: > "$TEST_ROOT/download-calls.txt"
: > "$TEST_ROOT/sync-calls.txt"

update_mods_core > "$TEST_ROOT/output.txt" 2>&1

[[ "$MOD_UPDATE_RESULT" == "1" ]]
[[ "$(grep -c '^101$' "$TEST_ROOT/download-calls.txt")" == "1" ]]
[[ "$(grep -c '^202$' "$TEST_ROOT/download-calls.txt")" == "2" ]]
[[ "$(grep -c '^303$' "$TEST_ROOT/download-calls.txt")" == "1" ]]
[[ "$(grep -c '^101$' "$TEST_ROOT/sync-calls.txt")" == "1" ]]
[[ "$(grep -c '^202$' "$TEST_ROOT/sync-calls.txt" || true)" == "0" ]]
[[ "$(grep -c '^303$' "$TEST_ROOT/sync-calls.txt")" == "1" ]]
[[ "$(wc -l < "$FAILED_MODS_FILE")" == "2" ]]
grep -Fq '"Defekter Mod","202","@broken","download"' "$FAILED_MODS_FILE"
grep -Fq '=== Fehlerhafte Mods (1) ===' "$TEST_ROOT/output.txt"
grep -Fq 'Alle übrigen Mods wurden weiterverarbeitet.' "$TEST_ROOT/output.txt"

echo "test_arma3ctl_mod_failures: OK"

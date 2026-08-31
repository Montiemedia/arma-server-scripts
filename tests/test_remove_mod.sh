#!/usr/bin/env bash
set -Eeuo pipefail
PATH="/usr/bin:/bin:$PATH"

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
export TEST_ROOT
trap 'rm -rf "$TEST_ROOT"' EXIT

cat > "$TEST_ROOT/arma3.env" <<'ENV'
ARMA_USER=testuser
ARMA_HOME="$TEST_ROOT/home"
SERVER_DIR="$TEST_ROOT/server"
STEAMCMD_DIR="$TEST_ROOT/steamcmd"
WORKSHOP_DIR="$TEST_ROOT/workshop"
DEPOT_WORKSHOP_DIR="$TEST_ROOT/depot-workshop"
BACKUP_DIR="$TEST_ROOT/backups"
STATE_DIR="$TEST_ROOT/state"
MODS_FILE="$TEST_ROOT/mods.csv"
MISSION_DIR="$TEST_ROOT/server/mpmissions"
SERVER_UNIT=arma3-test.service
ENV

cat > "$TEST_ROOT/mods.csv" <<'CSV'
name,type,workshop_id,target,enabled
Erster Mod,workshop,101,@first,1
Lokaler Mod,local,,@local,1
CSV

export ARMA_ENV_FILE="$TEST_ROOT/arma3.env"
# shellcheck disable=SC1090
source <(sed '/^command="${1:-}"$/,$d' "$PROJECT_ROOT/scripts/arma3ctl")

require_root() { :; }
ensure_dirs() { mkdir -p "$STATE_DIR" "$SERVER_DIR/mods"; }
# shellcheck disable=SC2034  # Die Produktivfunktion liest diese globale Variable.
stop_for_maintenance() { service_was_active=1; }
sync_keys() { :; }
install() {
    local -a arguments=("$@")
    local count=${#arguments[@]}
    command cp "${arguments[$((count - 2))]}" "${arguments[$((count - 1))]}"
}

mkdir -p \
    "$SERVER_DIR/mods/@first" \
    "$WORKSHOP_DIR/steamapps/workshop/content/107410/101" \
    "$STEAMCMD_DIR/steamapps/workshop/content/107410/101" \
    "$SERVER_DIR/steamapps/workshop/content/107410/101" \
    "$DEPOT_WORKSHOP_DIR/101"
touch "$SERVER_DIR/mods/@first/test.pbo"

remove_workshop_mod "@first" > "$TEST_ROOT/output.txt"

[[ ! -e "$SERVER_DIR/mods/@first" ]]
[[ ! -e "$WORKSHOP_DIR/steamapps/workshop/content/107410/101" ]]
[[ ! -e "$STEAMCMD_DIR/steamapps/workshop/content/107410/101" ]]
[[ ! -e "$SERVER_DIR/steamapps/workshop/content/107410/101" ]]
[[ ! -e "$DEPOT_WORKSHOP_DIR/101" ]]
grep -Fxq 'Erster Mod,workshop,101,@first,0' "$MODS_FILE"
grep -Fq 'Der Server bleibt angehalten.' "$TEST_ROOT/output.txt"

mkdir -p "$SERVER_DIR/mods/@local"
if (remove_workshop_mod "@local" >/dev/null 2>&1); then
    echo "Ein lokaler Mod wurde unerwartet als Workshop-Mod akzeptiert." >&2
    exit 1
fi
[[ -d "$SERVER_DIR/mods/@local" ]]
if (remove_workshop_mod "../unsicher" >/dev/null 2>&1); then
    echo "Ein unsicherer Mod-Pfad wurde unerwartet akzeptiert." >&2
    exit 1
fi

echo "test_remove_mod: OK"

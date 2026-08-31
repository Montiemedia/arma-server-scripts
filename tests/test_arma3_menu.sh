#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/server/mpmissions" "$TEST_ROOT/state"
touch "$TEST_ROOT/server/mpmissions/test.VR.pbo"
cat > "$TEST_ROOT/arma3.env" <<ENV
SERVER_DIR=$TEST_ROOT/server
SERVER_UNIT=arma3-test.service
SERVER_PORT=2302
SERVER_CONFIG=server.cfg
BASIC_CONFIG=basic.cfg
STATE_DIR=$TEST_ROOT/state
FAILED_MODS_FILE=$TEST_ROOT/state/failed-mods.csv
MISSION_DIR=$TEST_ROOT/server/mpmissions
ENV

cat > "$TEST_ROOT/arma3ctl" <<MOCK
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$TEST_ROOT/ctl-calls.txt"
MOCK
chmod +x "$TEST_ROOT/arma3ctl"

printf '99\n\n4\n\n6\n25\n\n14\n\n0\n' | \
    ARMA_MENU_SKIP_ROOT_CHECK=1 \
    ARMA_ENV_FILE="$TEST_ROOT/arma3.env" \
    ARMA3CTL="$TEST_ROOT/arma3ctl" \
    bash "$PROJECT_ROOT/scripts/arma3-menu.sh" > "$TEST_ROOT/output.txt" 2>&1

grep -Fq 'Ungültige Auswahl' "$TEST_ROOT/output.txt"
grep -Fxq 'status' "$TEST_ROOT/ctl-calls.txt"
grep -Fxq 'logs 25' "$TEST_ROOT/ctl-calls.txt"
grep -Fq 'test.VR.pbo' "$TEST_ROOT/output.txt"
grep -Fq 'Menü beendet.' "$TEST_ROOT/output.txt"

: > "$TEST_ROOT/ctl-calls.txt"
printf '2\nn\n\n0\n' | \
    ARMA_MENU_SKIP_ROOT_CHECK=1 \
    ARMA_ENV_FILE="$TEST_ROOT/arma3.env" \
    ARMA3CTL="$TEST_ROOT/arma3ctl" \
    bash "$PROJECT_ROOT/scripts/arma3-menu.sh" > "$TEST_ROOT/cancel-output.txt" 2>&1

[[ ! -s "$TEST_ROOT/ctl-calls.txt" ]]
grep -Fq 'Aktion abgebrochen.' "$TEST_ROOT/cancel-output.txt"

# Der kurze Startbefehl unter /usr/local/bin wird als symbolischer Link
# eingerichtet. Das Menü muss seine Begleitskripte trotzdem im echten
# Installationsordner finden.
mkdir -p "$TEST_ROOT/install/scripts" "$TEST_ROOT/bin" "$TEST_ROOT/mock-bin"
cp "$PROJECT_ROOT/scripts/arma3-menu.sh" "$TEST_ROOT/install/scripts/arma3-menu.sh"
cp "$TEST_ROOT/arma3ctl" "$TEST_ROOT/install/scripts/arma3ctl"
ln -s "$TEST_ROOT/install/scripts/arma3-menu.sh" "$TEST_ROOT/bin/arma3-menu"
cat > "$TEST_ROOT/mock-bin/readlink" <<MOCK
#!/usr/bin/env bash
printf '%s\n' "$TEST_ROOT/install/scripts/arma3-menu.sh"
MOCK
chmod +x "$TEST_ROOT/mock-bin/readlink"
: > "$TEST_ROOT/ctl-calls.txt"

printf '4\n\n0\n' | \
    ARMA_MENU_SKIP_ROOT_CHECK=1 \
    ARMA_ENV_FILE="$TEST_ROOT/arma3.env" \
    PATH="$TEST_ROOT/mock-bin:$PATH" \
    bash "$TEST_ROOT/bin/arma3-menu" > "$TEST_ROOT/symlink-output.txt" 2>&1

if ! grep -Fxq 'status' "$TEST_ROOT/ctl-calls.txt"; then
    cat "$TEST_ROOT/symlink-output.txt" >&2
    exit 1
fi
grep -Fq 'Menü beendet.' "$TEST_ROOT/symlink-output.txt"

echo "test_arma3_menu: OK"

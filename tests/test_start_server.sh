#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/server/mods/@ace"
cat > "$TMP/mods.csv" <<CSV
name,type,workshop_id,target,enabled
ace,workshop,463939057,@ace,1
Missing Test,local,,@missing,1
Disabled Test,local,,@disabled,0
CSV
cat > "$TMP/arma3.env" <<ENV
SERVER_DIR=$TMP/server
MODS_FILE=$TMP/mods.csv
SERVER_PORT=2302
PROFILE_NAME=server
SERVER_CONFIG=server.cfg
BASIC_CONFIG=basic.cfg
SERVER_MODS=
ADDITIONAL_ARGS=-noPause
STRICT_MOD_CHECK=0
ENV
: > "$TMP/server/server.cfg"
: > "$TMP/server/basic.cfg"
cat > "$TMP/server/arma3server_x64" <<'FAKE'
#!/usr/bin/env bash
printf '%s\n' "$@"
FAKE
chmod +x "$TMP/server/arma3server_x64"

OUTPUT=$(ARMA_ENV_FILE="$TMP/arma3.env" "$ROOT/scripts/start-server.sh" 2>"$TMP/stderr")
grep -q -- '-mod=mods/@ace' <<< "$OUTPUT"
grep -q -- '-config=server.cfg' <<< "$OUTPUT"
grep -q -- '-cfg=basic.cfg' <<< "$OUTPUT"
grep -q -- '-noPause' <<< "$OUTPUT"
! grep -q -- '-profiles=' <<< "$OUTPUT"
grep -q 'Aktivierter Mod fehlt: Missing Test' "$TMP/stderr"

echo "test_start_server: OK"

#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck disable=SC1091
source "$PROJECT_ROOT/install.sh"

TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

cat > "$TEST_ROOT/arma3.env" <<'ENV'
SERVER_DIR=/home/arma3/server
STEAM_USER=
SERVER_PORT=2302
ENV

render_steam_env "$TEST_ROOT/arma3.env" "kane_test" > "$TEST_ROOT/rendered.env"
grep -Fxq 'STEAM_USER=kane_test' "$TEST_ROOT/rendered.env"
[[ "$(grep -c '^STEAM_USER=' "$TEST_ROOT/rendered.env")" == "1" ]]
valid_steam_user "kane_test-1"
if valid_steam_user "kane test"; then
    echo "Steam-Benutzername mit Leerzeichen wurde unerwartet akzeptiert." >&2
    exit 1
fi

printf '\n' | ask_yes_no "Standard Ja" yes
if printf '\n' | ask_yes_no "Standard Nein" no; then
    echo "Leere Antwort wurde beim Standard Nein unerwartet akzeptiert." >&2
    exit 1
fi
printf 'j\n' | ask_yes_no "Explizit Ja" no
if printf 'n\n' | ask_yes_no "Explizit Nein" yes; then
    echo "Antwort Nein wurde unerwartet als Ja ausgewertet." >&2
    exit 1
fi

echo "test_install: OK"

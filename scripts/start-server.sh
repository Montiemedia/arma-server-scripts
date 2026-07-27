#!/usr/bin/env bash
set -Eeuo pipefail

ENV_FILE="${ARMA_ENV_FILE:-/etc/arma3/arma3.env}"
[[ -r "$ENV_FILE" ]] || { echo "Konfiguration fehlt: $ENV_FILE" >&2; exit 1; }
# shellcheck disable=SC1090
source "$ENV_FILE"

: "${SERVER_DIR:?SERVER_DIR fehlt}"
: "${MODS_FILE:?MODS_FILE fehlt}"
: "${SERVER_PORT:=2302}"
: "${PROFILE_NAME:=server}"
: "${SERVER_CONFIG:=server.cfg}"
: "${BASIC_CONFIG:=basic.cfg}"
: "${SERVER_MODS:=}"
: "${ADDITIONAL_ARGS:=}"
: "${STRICT_MOD_CHECK:=1}"

cd "$SERVER_DIR"
[[ -x "$SERVER_DIR/arma3server_x64" ]] || { echo "arma3server_x64 fehlt." >&2; exit 1; }
[[ -r "$SERVER_CONFIG" ]] || { echo "$SERVER_CONFIG fehlt." >&2; exit 1; }

mods=()
missing_mods=0
while IFS=, read -r name type workshop_id target enabled; do
    [[ "$name" == "name" ]] && continue
    [[ "$enabled" == "1" ]] || continue
    [[ "$target" =~ ^@[a-z0-9_+.-]+$ ]] || { echo "Ungültiger Modordner in CSV: $target" >&2; exit 1; }
    if [[ -d "$SERVER_DIR/mods/$target" ]]; then
        mods+=("mods/$target")
    else
        echo "WARNUNG: Aktivierter Mod fehlt: $name ($target)" >&2
        ((missing_mods+=1))
    fi
done < "$MODS_FILE"

if (( missing_mods > 0 )) && [[ "$STRICT_MOD_CHECK" == "1" ]]; then
    echo "Start abgebrochen: $missing_mods aktivierte Modverzeichnisse fehlen." >&2
    exit 1
fi

args=(
    "-name=$PROFILE_NAME"
    "-config=$SERVER_CONFIG"
    "-cfg=$BASIC_CONFIG"
    "-port=$SERVER_PORT"
    "-world=empty"
    "-noSound"
    "-loadMissionToMemory"
)

if ((${#mods[@]})); then
    mod_arg=$(IFS=';'; echo "${mods[*]}")
    args+=("-mod=$mod_arg")
fi

if [[ -n "$SERVER_MODS" ]]; then
    args+=("-serverMod=$SERVER_MODS")
fi

if [[ -n "$ADDITIONAL_ARGS" ]]; then
    # The administrator controls this root-owned file. Split only on spaces.
    read -r -a extra <<< "$ADDITIONAL_ARGS"
    args+=("${extra[@]}")
fi

printf 'Starte: %q ' "$SERVER_DIR/arma3server_x64" "${args[@]}"
printf '\n'
exec "$SERVER_DIR/arma3server_x64" "${args[@]}"

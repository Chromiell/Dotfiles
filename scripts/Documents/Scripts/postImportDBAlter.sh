#!/usr/bin/env bash

# Commentato perche' mandava potenzialmente un interrupt al processo e bloccava l'esecuzione degli script successivi al primo
#set -euo pipefail

# Determine script and data directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DATA_DIR="${SCRIPTS_DATA_DIR:-$(cd "${SCRIPT_DIR}/../ScriptsData" 2>/dev/null && pwd || echo "${HOME}/Documents/ScriptsData")}"
if [[ ! -d "$SCRIPTS_DATA_DIR" && -d "${HOME}/Documents/ScriptsData" ]]; then
    SCRIPTS_DATA_DIR="${HOME}/Documents/ScriptsData"
fi

CONFIG_FILE="${SCRIPTS_DATA_DIR}/config.env"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

BASE_DIR="${POST_IMPORT_BASE_DIR:-}"
URL_BASE="${POST_IMPORT_URL_BASE:-}"

if [[ -z "$BASE_DIR" || -z "$URL_BASE" ]]; then
    echo "Error: POST_IMPORT_BASE_DIR or POST_IMPORT_URL_BASE is not configured in config.env." >&2
    exit 1
fi

if [[ ! -d "$BASE_DIR" ]]; then
    echo "Warning: Database migration directory $BASE_DIR does not exist." >&2
    exit 0
fi

for file in "$BASE_DIR"/*.php; do
    [[ -e "$file" ]] || continue
    filename="$(basename "$file")"

    # Skip index.php
    if [[ "$filename" == "index.php" ]]; then
        continue
    fi

    curl --silent --output /dev/null --max-time 1 \
        "${URL_BASE}/$filename"
done

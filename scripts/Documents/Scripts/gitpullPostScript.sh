#!/bin/bash
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

DEPLOY_STORAGE_DIR="${DEPLOY_STORAGE_DIR:-${DEPLOY_ROOT:-/var/www/html}/application_5/storage}"

if [[ -d "$DEPLOY_STORAGE_DIR" ]]; then
    chown --silent -R www-data:www-data "$DEPLOY_STORAGE_DIR"
fi

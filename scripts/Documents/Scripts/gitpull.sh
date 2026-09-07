#!/bin/bash
umask 002

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

DEPLOY_ROOT="${DEPLOY_ROOT:-/var/www/html}"

TARGET_1="${DEPLOY_TARGET_1:-}"
TARGET_2="${DEPLOY_TARGET_2:-}"
TARGET_3="${DEPLOY_TARGET_3:-}"
TARGET_4="${DEPLOY_TARGET_4:-}"
TARGET_5="${DEPLOY_TARGET_5:-}"

if [[ -n "$TARGET_1" && -d "${DEPLOY_ROOT}/${TARGET_1}" ]]; then
    cd "${DEPLOY_ROOT}/${TARGET_1}"
    git pull > /dev/null 2>&1
    npm run prod > /dev/null 2>&1
    npm run prod-el > /dev/null 2>&1
    npm run prod-b > /dev/null 2>&1
    npx @tailwindcss/cli -o ./css/tailwind.css --minify > /dev/null 2>&1
    chgrp -R www-data "${DEPLOY_ROOT}/${TARGET_1}" > /dev/null 2>&1
fi

if [[ -n "$TARGET_2" && -d "${DEPLOY_ROOT}/${TARGET_2}" ]]; then
    cd "${DEPLOY_ROOT}/${TARGET_2}"
    git pull > /dev/null 2>&1
    npm run prod-file target.scss
    chgrp -R www-data "${DEPLOY_ROOT}/${TARGET_2}" > /dev/null 2>&1
fi

if [[ -n "$TARGET_3" && -d "${DEPLOY_ROOT}/${TARGET_3}" ]]; then
    cd "${DEPLOY_ROOT}/${TARGET_3}"
    git pull > /dev/null 2>&1
    #npm run build > /dev/null 2>&1
    chgrp -R www-data "${DEPLOY_ROOT}/${TARGET_3}" > /dev/null 2>&1
fi

if [[ -n "$TARGET_4" && -d "${DEPLOY_ROOT}/${TARGET_4}" ]]; then
    cd "${DEPLOY_ROOT}/${TARGET_4}"
    git pull > /dev/null 2>&1
    chgrp -R www-data "${DEPLOY_ROOT}/${TARGET_4}" > /dev/null 2>&1
fi

if [[ -n "$TARGET_5" && -d "${DEPLOY_ROOT}/${TARGET_5}" ]]; then
    cd "${DEPLOY_ROOT}/${TARGET_5}"
    git pull > /dev/null 2>&1
    npm run build > /dev/null 2>&1
    chgrp -R www-data "${DEPLOY_ROOT}/${TARGET_5}" > /dev/null 2>&1
fi

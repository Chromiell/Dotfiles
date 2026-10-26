#!/usr/bin/env bash

# Strict modes stay disabled on purpose: a failure on one migration script must
# not abort the remaining ones. Failures are reported individually and reflected
# in the final exit status instead.
#set -euo pipefail

# Timestamped log; stderr so the caller's cron redirect captures it.
log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2
}

log_error() {
    printf '[%s] ERROR: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2
}

log "postImportDBAlter: started"

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
    log "postImportDBAlter: config=${CONFIG_FILE}"
else
    log "postImportDBAlter: warning: config file not found (${CONFIG_FILE})"
fi

# Strip CR characters and surrounding whitespace: config.env is sometimes edited
# on machines with CRLF line endings or with an accidental trailing space, which
# silently breaks directory checks and curl URLs.
trim() {
    local value="${1//$'\r'/}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

BASE_DIR="$(trim "${POST_IMPORT_BASE_DIR:-}")"
URL_BASE="$(trim "${POST_IMPORT_URL_BASE:-}")"
URL_BASE="${URL_BASE%/}"
MAX_TIME="$(trim "${POST_IMPORT_CURL_MAX_TIME:-300}")"
CONNECT_TIMEOUT="$(trim "${POST_IMPORT_CURL_CONNECT_TIMEOUT:-10}")"

log "postImportDBAlter: base=${BASE_DIR:-<unset>} url=${URL_BASE:-<unset>}"

if [[ -z "$BASE_DIR" || -z "$URL_BASE" ]]; then
    log_error "POST_IMPORT_BASE_DIR or POST_IMPORT_URL_BASE is not configured in ${CONFIG_FILE}."
    exit 1
fi

if [[ "$URL_BASE" != http://* && "$URL_BASE" != https://* ]]; then
    log_error "POST_IMPORT_URL_BASE must start with http:// or https:// (got '${URL_BASE}')."
    exit 1
fi

if [[ ! "$MAX_TIME" =~ ^[0-9]+$ ]]; then
    log "Warning: POST_IMPORT_CURL_MAX_TIME='${MAX_TIME}' is not a number, using 300."
    MAX_TIME=300
fi

if [[ ! "$CONNECT_TIMEOUT" =~ ^[0-9]+$ ]]; then
    log "Warning: POST_IMPORT_CURL_CONNECT_TIMEOUT='${CONNECT_TIMEOUT}' is not a number, using 10."
    CONNECT_TIMEOUT=10
fi

if [[ ! -d "$BASE_DIR" ]]; then
    log "Warning: Database migration directory $BASE_DIR does not exist (config: ${CONFIG_FILE})."
    exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
    log_error "curl is not installed; no migration script can be triggered."
    exit 1
fi

shopt -s nullglob
files=("$BASE_DIR"/*.php)
shopt -u nullglob

if ((${#files[@]} == 0)); then
    log "Warning: no *.php migration script found in $BASE_DIR."
    exit 0
fi

log "postImportDBAlter: found ${#files[@]} .php file(s) in ${BASE_DIR}"

triggered=0
failures=0

for file in "${files[@]}"; do
    [[ -f "$file" ]] || continue
    filename="$(basename "$file")"

    # Skip index.php
    if [[ "$filename" == "index.php" ]]; then
        log "Skipping index.php"
        continue
    fi

    url="${URL_BASE}/${filename}"
    triggered=$((triggered + 1))

    # --show-error keeps failures visible (plain --silent hides them); --location
    # follows the http->https or trailing-slash redirects that commonly serve the
    # same script from a different URL.
    http_code="$(curl --silent --show-error \
        --location --max-redirs 5 \
        --connect-timeout "$CONNECT_TIMEOUT" \
        --max-time "$MAX_TIME" \
        --output /dev/null \
        --write-out '%{http_code}' \
        "$url")"
    curl_status=$?

    if ((curl_status != 0)); then
        log_error "${url} -> curl exit ${curl_status}"
        failures=$((failures + 1))
    elif [[ "$http_code" != 2* ]]; then
        log_error "${url} -> HTTP ${http_code}"
        failures=$((failures + 1))
    else
        log "OK: ${url} -> HTTP ${http_code}"
    fi
done

if ((triggered == 0)); then
    log "Warning: no migration script to trigger in $BASE_DIR (only index.php found)."
    exit 0
fi

if ((failures > 0)); then
    log_error "${failures}/${triggered} migration script(s) failed."
    exit 1
fi

log "postImportDBAlter: triggered ${triggered} script(s), all succeeded"

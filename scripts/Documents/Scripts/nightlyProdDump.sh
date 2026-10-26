#!/usr/bin/env bash
set -euo pipefail

# Timestamped progress log. Everything goes to stderr so a single cron redirect
# (`> log 2>&1`) captures the full run, including failures.
log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2
}

log_error() {
    printf '[%s] ERROR: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2
}

trap 'log_error "command failed at line ${LINENO} (status $?)"' ERR

on_exit() {
    local status=$?
    log "=== nightlyProdDump finished (status $status) ==="
}
trap on_exit EXIT

log "=== nightlyProdDump started (pid $$, user $(id -un)) ==="

# Determine script and data directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DATA_DIR="${SCRIPTS_DATA_DIR:-$(cd "${SCRIPT_DIR}/../ScriptsData" 2>/dev/null && pwd || echo "${HOME}/Documents/ScriptsData")}"
if [[ ! -d "$SCRIPTS_DATA_DIR" && -d "${HOME}/Documents/ScriptsData" ]]; then
    SCRIPTS_DATA_DIR="${HOME}/Documents/ScriptsData"
fi

# Let the post-import script read the exact same configuration file
export SCRIPTS_DATA_DIR

# Load configuration if available
CONFIG_FILE="${SCRIPTS_DATA_DIR}/config.env"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    log "Loaded config: ${CONFIG_FILE}"
else
    log "Warning: config file not found: ${CONFIG_FILE}"
fi

DUMP_DIR="${PROD_DUMP_DIR:-${HOME}/ProdDump}"
POST_SCRIPT="${PROD_DUMP_POST_SCRIPT:-${SCRIPT_DIR}/postImportDBAlter.sh}"
# Strip a trailing CR or space from a hand-edited config.env value
POST_SCRIPT="${POST_SCRIPT//$'\r'/}"
POST_SCRIPT="${POST_SCRIPT%"${POST_SCRIPT##*[![:space:]]}"}"

REMOTE_SSH_USER="${PROD_DUMP_REMOTE_SSH_USER:-}"
REMOTE_SSH_HOST="${PROD_DUMP_REMOTE_SSH_HOST:-}"
REMOTE_DB_USER="${PROD_DUMP_REMOTE_DB_USER:-}"
REMOTE_DB_NAME="${PROD_DUMP_REMOTE_DB_NAME:-}"
LOCAL_DB_USER="${PROD_DUMP_LOCAL_DB_USER:-root}"
LOCAL_DB_NAME="${PROD_DUMP_LOCAL_DB_NAME:-db}"
TABLES="${PROD_DUMP_TABLES:-}"
REMOTE_DB_PASSWORD="${PROD_DUMP_REMOTE_DB_PASSWORD:-}"
LOCAL_DB_PASSWORD="${PROD_DUMP_LOCAL_DB_PASSWORD:-}"

log "Dump directory: ${DUMP_DIR}"
log "Remote source: ${REMOTE_SSH_USER:-?}@${REMOTE_SSH_HOST:-?} database=${REMOTE_DB_NAME:-?}"
log "Local target: user=${LOCAL_DB_USER} database=${LOCAL_DB_NAME}"
log "Tables: ${TABLES:-<all>}"
log "Post-import script: ${POST_SCRIPT}"

# Validate directories
if [[ ! -d "$DUMP_DIR" ]]; then
    log_error "directory $DUMP_DIR does not exist"
    exit 1
fi

# Validate remote connection details and passwords
if [[ -z "$REMOTE_SSH_USER" || -z "$REMOTE_SSH_HOST" || -z "$REMOTE_DB_USER" || -z "$REMOTE_DB_NAME" ]]; then
    log_error "Remote database connection parameters are missing. Please configure config.env."
    exit 1
fi

if [[ -z "$REMOTE_DB_PASSWORD" ]]; then
    log_error "PROD_DUMP_REMOTE_DB_PASSWORD is not set in config.env."
    exit 1
fi

if [[ -z "$LOCAL_DB_PASSWORD" ]]; then
    log_error "PROD_DUMP_LOCAL_DB_PASSWORD is not set in config.env."
    exit 1
fi

cd "$DUMP_DIR"

# Keep only the 2 most recent files
mapfile -t files < <(ls -1t "$DUMP_DIR")
log "Retention: found ${#files[@]} file(s) in ${DUMP_DIR}"

if ((${#files[@]} > 2)); then
    for ((i = 2; i < ${#files[@]}; i++)); do
        f="${files[$i]}"
        if [[ -f "$f" ]]; then
            log "Removing old dump: ${f}"
            rm -- "$f"
        fi
    done
fi

# Generate date-based filename
TODAY="$(date +%Y%m%d)"
OUTFILE="dump-${TODAY}.sql.gz"

# Create new dump from remote server
log "Creating remote dump -> ${DUMP_DIR}/${OUTFILE}"
ssh "${REMOTE_SSH_USER}@${REMOTE_SSH_HOST}" \
    "mariadb-dump -u '${REMOTE_DB_USER}' -p'${REMOTE_DB_PASSWORD}' \
    --single-transaction --skip-lock-tables --quick --skip-add-locks --no-autocommit \
    '${REMOTE_DB_NAME}' \
    ${TABLES} \
    | gzip" \
    >"$OUTFILE"
log "Dump created: ${OUTFILE} ($(du -h "$OUTFILE" | cut -f1))"

# Import into local DB
log "Importing dump into local database '${LOCAL_DB_NAME}'"
gunzip -c "$OUTFILE" | mariadb -u "${LOCAL_DB_USER}" -p"${LOCAL_DB_PASSWORD}" "${LOCAL_DB_NAME}"
log "Import completed"

# Run post-import script
log "Running post-import script: ${POST_SCRIPT}"
if [[ -x "$POST_SCRIPT" ]]; then
    "$POST_SCRIPT"
elif [[ -e "$POST_SCRIPT" ]]; then
    log_error "$POST_SCRIPT exists but is not executable (run: chmod +x '$POST_SCRIPT')"
    exit 1
else
    log_error "post-import script not found at $POST_SCRIPT"
    exit 1
fi
log "Post-import script completed"

#!/usr/bin/env bash
set -euo pipefail

# Determine script and data directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DATA_DIR="${SCRIPTS_DATA_DIR:-$(cd "${SCRIPT_DIR}/../ScriptsData" 2>/dev/null && pwd || echo "${HOME}/Documents/ScriptsData")}"
if [[ ! -d "$SCRIPTS_DATA_DIR" && -d "${HOME}/Documents/ScriptsData" ]]; then
    SCRIPTS_DATA_DIR="${HOME}/Documents/ScriptsData"
fi

# Load configuration if available
CONFIG_FILE="${SCRIPTS_DATA_DIR}/config.env"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

DUMP_DIR="${PROD_DUMP_DIR:-${HOME}/ProdDump}"
POST_SCRIPT="${PROD_DUMP_POST_SCRIPT:-${SCRIPT_DIR}/postImportDBAlter.sh}"

REMOTE_SSH_USER="${PROD_DUMP_REMOTE_SSH_USER:-}"
REMOTE_SSH_HOST="${PROD_DUMP_REMOTE_SSH_HOST:-}"
REMOTE_DB_USER="${PROD_DUMP_REMOTE_DB_USER:-}"
REMOTE_DB_NAME="${PROD_DUMP_REMOTE_DB_NAME:-}"
LOCAL_DB_USER="${PROD_DUMP_LOCAL_DB_USER:-root}"
LOCAL_DB_NAME="${PROD_DUMP_LOCAL_DB_NAME:-db}"
TABLES="${PROD_DUMP_TABLES:-}"
REMOTE_DB_PASSWORD="${PROD_DUMP_REMOTE_DB_PASSWORD:-}"
LOCAL_DB_PASSWORD="${PROD_DUMP_LOCAL_DB_PASSWORD:-}"

# Validate directories
if [[ ! -d "$DUMP_DIR" ]]; then
    echo "Error: directory $DUMP_DIR does not exist" >&2
    exit 1
fi

# Validate remote connection details and passwords
if [[ -z "$REMOTE_SSH_USER" || -z "$REMOTE_SSH_HOST" || -z "$REMOTE_DB_USER" || -z "$REMOTE_DB_NAME" ]]; then
    echo "Error: Remote database connection parameters are missing. Please configure config.env." >&2
    exit 1
fi

if [[ -z "$REMOTE_DB_PASSWORD" ]]; then
    echo "Error: PROD_DUMP_REMOTE_DB_PASSWORD is not set in config.env." >&2
    exit 1
fi

if [[ -z "$LOCAL_DB_PASSWORD" ]]; then
    echo "Error: PROD_DUMP_LOCAL_DB_PASSWORD is not set in config.env." >&2
    exit 1
fi

cd "$DUMP_DIR"

# Keep only the 2 most recent files
mapfile -t files < <(ls -1t "$DUMP_DIR")

if (( ${#files[@]} > 2 )); then
    for ((i=2; i<${#files[@]}; i++)); do
        f="${files[$i]}"
        if [[ -f "$f" ]]; then
            rm -- "$f"
        fi
    done
fi

# Generate date-based filename
TODAY="$(date +%Y%m%d)"
OUTFILE="dump-${TODAY}.sql.gz"

# Create new dump from remote server
ssh "${REMOTE_SSH_USER}@${REMOTE_SSH_HOST}" \
    "mariadb-dump -u '${REMOTE_DB_USER}' -p'${REMOTE_DB_PASSWORD}' \
    --single-transaction --skip-lock-tables --quick --skip-add-locks --no-autocommit \
    '${REMOTE_DB_NAME}' \
    ${TABLES} \
    | gzip" \
    > "$OUTFILE"

# Import into local DB
gunzip -c "$OUTFILE" | mariadb -u "${LOCAL_DB_USER}" -p"${LOCAL_DB_PASSWORD}" "${LOCAL_DB_NAME}"

# Run post-import script
if [[ -x "$POST_SCRIPT" ]]; then
    "$POST_SCRIPT"
else
    echo "Warning: $POST_SCRIPT not found or not executable" >&2
fi

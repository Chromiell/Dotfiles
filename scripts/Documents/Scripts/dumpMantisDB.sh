#!/bin/bash
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

log "=== dumpMantisDB started (pid $$, user $(id -un)) ==="

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
    log "Loaded config: ${CONFIG_FILE}"
else
    log "Warning: config file not found: ${CONFIG_FILE}"
fi

TARGET_DIR="${MANTIS_TARGET_DIR:-/mnt/bckmantis}"
PATTERN="database-[0-9]{8}\.sql\.gz"
CIFS_SHARE="${MANTIS_CIFS_SHARE:-}"
CIFS_CREDENTIALS="${MANTIS_CIFS_CREDENTIALS:-/etc/samba/.smbcredentials}"
DB_USER="${MANTIS_DB_USER:-root}"
DB_NAME="${MANTIS_DB_NAME:-mantis}"
LOCAL_DB_PASSWORD="${MANTIS_LOCAL_DB_PASSWORD:-${LOCAL_DB_PASSWORD:-}}"

TODAY="$(date +%Y%m%d)"
OUTFILE="${TARGET_DIR}/database-${TODAY}.sql.gz"

log "Target directory: ${TARGET_DIR}"
log "CIFS share: ${CIFS_SHARE} (credentials: ${CIFS_CREDENTIALS})"
log "Database: user=${DB_USER} name=${DB_NAME}"
log "Retention: keeping the 2 most recent ${PATTERN} files"

# Cleanup function that always runs on exit
cleanup() {
    local status=$?
    # Errors are already reported by the ERR trap; don't recurse into it while exiting
    trap - ERR
    if [[ -n "${TARGET_DIR:-}" ]]; then
        if mountpoint -q "$TARGET_DIR"; then
            log "Unmounting ${TARGET_DIR}"
            umount "$TARGET_DIR" 2>/dev/null || log "Warning: umount failed for ${TARGET_DIR}"
        fi
        rmdir "$TARGET_DIR" 2>/dev/null || log "Warning: rmdir failed or directory not empty: ${TARGET_DIR}"
    else
        log "Skipping cleanup: TARGET_DIR is unset or empty"
    fi
    log "=== dumpMantisDB finished (status ${status}) ==="
}
trap cleanup EXIT

# Ensure variables are not empty
if [[ -z "$TARGET_DIR" || -z "$PATTERN" || -z "$CIFS_SHARE" ]]; then
    log_error "TARGET_DIR, PATTERN, or MANTIS_CIFS_SHARE is empty"
    exit 1
fi

if [[ -z "$LOCAL_DB_PASSWORD" ]]; then
    log_error "MANTIS_LOCAL_DB_PASSWORD (or LOCAL_DB_PASSWORD) is not set in config.env."
    exit 1
fi

mkdir -p "$TARGET_DIR"
log "Mounting ${CIFS_SHARE} on ${TARGET_DIR}"
mount -t cifs "$CIFS_SHARE" "$TARGET_DIR" -o "credentials=$CIFS_CREDENTIALS"
log "Mounted ${TARGET_DIR}"

# Delete all but the latest 2 matching files
find "$TARGET_DIR" -type f -regextype posix-extended -regex ".*/$PATTERN" -printf '%T@ %p\n' |
    sort -nr | tail -n +3 | cut -d' ' -f2- | while read -r file; do
    [[ -n "$file" ]] || continue
    log "Removing old backup: ${file}"
    rm -f "$file"
done

# Dump and compress the database
log "Creating dump: ${OUTFILE}"
mysqldump --single-transaction -u "$DB_USER" -p"$LOCAL_DB_PASSWORD" "$DB_NAME" | gzip >"$OUTFILE"
log "Dump created: ${OUTFILE} ($(du -h "$OUTFILE" | cut -f1))"
log "Backup completed"

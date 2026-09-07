#!/bin/bash
set -euo pipefail

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

TARGET_DIR="${MANTIS_TARGET_DIR:-/mnt/bckmantis}"
PATTERN="database-[0-9]{8}\.sql\.gz"
CIFS_SHARE="${MANTIS_CIFS_SHARE:-}"
CIFS_CREDENTIALS="${MANTIS_CIFS_CREDENTIALS:-/etc/samba/.smbcredentials}"
DB_USER="${MANTIS_DB_USER:-root}"
DB_NAME="${MANTIS_DB_NAME:-mantis}"
LOCAL_DB_PASSWORD="${MANTIS_LOCAL_DB_PASSWORD:-${LOCAL_DB_PASSWORD:-}}"

# Cleanup function that always runs on exit
cleanup() {
  if [[ -n "${TARGET_DIR:-}" ]]; then
    umount "$TARGET_DIR" 2>/dev/null || echo "Warning: umount failed"
    rmdir "$TARGET_DIR" 2>/dev/null || echo "Warning: rmdir failed"
  else
    echo "Skipping cleanup: TARGET_DIR is unset or empty"
  fi
}
trap cleanup EXIT

# Ensure variables are not empty
if [[ -z "$TARGET_DIR" || -z "$PATTERN" || -z "$CIFS_SHARE" ]]; then
  echo "Error: TARGET_DIR, PATTERN, or MANTIS_CIFS_SHARE is empty"
  exit 1
fi

if [[ -z "$LOCAL_DB_PASSWORD" ]]; then
  echo "Error: MANTIS_LOCAL_DB_PASSWORD (or LOCAL_DB_PASSWORD) is not set in config.env." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
mount -t cifs "$CIFS_SHARE" "$TARGET_DIR" -o "credentials=$CIFS_CREDENTIALS"

# Delete all but the latest 2 matching files
find "$TARGET_DIR" -type f -regextype posix-extended -regex ".*/$PATTERN" -printf '%T@ %p\n' | \
  sort -nr | tail -n +3 | cut -d' ' -f2- | while read -r file; do
    rm -f "$file"
done

# Dump and compress the database
mysqldump --single-transaction -u "$DB_USER" -p"$LOCAL_DB_PASSWORD" "$DB_NAME" | gzip > "$TARGET_DIR/database-$(date +%Y%m%d).sql.gz"

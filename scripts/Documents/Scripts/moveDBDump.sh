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

TARGET_DIR="${MOVE_DUMP_TARGET_DIR:-/mnt/bckdump}"
PATTERN="dump-[0-9]{8}\.sql\.gz"
SOURCE_DIR="${MOVE_DUMP_SOURCE_DIR:-${PROD_DUMP_DIR:-${HOME}/ProdDump}}"
CIFS_SHARE="${MOVE_DUMP_CIFS_SHARE:-}"
CIFS_CREDENTIALS="${MOVE_DUMP_CIFS_CREDENTIALS:-/etc/samba/.smbcredentials}"

TODAY="$(date +%Y%m%d)"
TODAY_FILE="dump-${TODAY}.sql.gz"
SOURCE_FILE="${SOURCE_DIR}/${TODAY_FILE}"

cleanup() {
  if mountpoint -q "$TARGET_DIR"; then
    umount "$TARGET_DIR" 2>/dev/null || echo "Warning: umount failed"
  fi

  # Remove mount directory only if empty
  if [[ -d "$TARGET_DIR" ]]; then
    rmdir "$TARGET_DIR" 2>/dev/null || echo "Warning: rmdir failed or directory not empty"
  fi
}
trap cleanup EXIT

# Validate variables
if [[ -z "$TARGET_DIR" || -z "$PATTERN" || -z "$CIFS_SHARE" ]]; then
  echo "Error: TARGET_DIR, PATTERN, or MOVE_DUMP_CIFS_SHARE is empty"
  exit 1
fi

# Validate today's file exists before mounting
if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Error: Expected file not found: $SOURCE_FILE"
  exit 1
fi

mkdir -p "$TARGET_DIR"

mount -t cifs "$CIFS_SHARE" \
  "$TARGET_DIR" \
  -o "credentials=$CIFS_CREDENTIALS"

# Keep only the 2 most recent matching files
find "$TARGET_DIR" -type f -regextype posix-extended -regex ".*/$PATTERN" \
  -printf '%T@ %p\n' | \
  sort -nr | tail -n +3 | cut -d' ' -f2- | \
  while read -r file; do
    if [[ -n "$file" ]]; then
      rm -f "$file"
    fi
  done

# Move today's dump into the network share
cp --preserve=mode,timestamps "$SOURCE_FILE" "$TARGET_DIR"/

echo "Successfully copied $SOURCE_FILE to $TARGET_DIR"

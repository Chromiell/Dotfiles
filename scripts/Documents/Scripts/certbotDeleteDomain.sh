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

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

DOMAIN="$1"

# Local paths
HAPROXY_SSL_DIR="${HAPROXY_SSL_DIR:-/etc/haproxy/ssl}"
RENEWAL_CONF="/etc/letsencrypt/renewal/${DOMAIN}.conf"
HOOK_SCRIPT="/etc/letsencrypt/renewal-hooks/post/haproxy-${DOMAIN}.sh"
LIVE_DIR="/etc/letsencrypt/live/${DOMAIN}"
ARCHIVE_DIR="/etc/letsencrypt/archive/${DOMAIN}"
HAPROXY_PEM="${HAPROXY_SSL_DIR}/${DOMAIN}.pem"

# Remote server info
REMOTE_HOST="${REMOTE_HAPROXY_HOST:-${REMOTE_HOST:-}}"

if [[ -z "$REMOTE_HOST" ]]; then
    echo "Error: REMOTE_HAPROXY_HOST is not configured in config.env." >&2
    exit 1
fi

REMOTE_PEM="${HAPROXY_SSL_DIR}/${DOMAIN}.pem"

echo "Preparing to delete Let's Encrypt and HAProxy SSL data for domain: ${DOMAIN}"
echo "This operation is destructive. Press Ctrl+C to abort."
sleep 2

### LOCAL DELETIONS ###

# Files
for FILE in "$RENEWAL_CONF" "$HOOK_SCRIPT" "$HAPROXY_PEM"; do
    if [[ -f "$FILE" ]]; then
        echo "Deleting file $FILE"
        rm -f "$FILE"
    else
        echo "File not found: $FILE"
    fi
done

# Directories
for DIR in "$LIVE_DIR" "$ARCHIVE_DIR"; do
    if [[ -d "$DIR" ]]; then
        echo "Deleting directory $DIR"
        rm -rf "$DIR"
    else
        echo "Directory not found: $DIR"
    fi
done

### REMOTE DELETION ###

echo "Checking remote server for $REMOTE_PEM"

if ssh "$REMOTE_HOST" "[ -f '$REMOTE_PEM' ]"; then
    echo "Deleting remote file $REMOTE_PEM"
    ssh "$REMOTE_HOST" "rm -f '$REMOTE_PEM'"
else
    echo "Remote file not found: $REMOTE_PEM"
fi

echo "Cleanup completed for domain: ${DOMAIN}"

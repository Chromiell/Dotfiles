#!/bin/bash

# Refresh the package list
sudo apt update > /dev/null 2>&1

# Check for available upgrades
UPDATES=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | wc -l)

# Determine script and data directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DATA_DIR="${SCRIPTS_DATA_DIR:-$(cd "${SCRIPT_DIR}/../ScriptsData" 2>/dev/null && pwd || echo "${HOME}/Documents/ScriptsData")}"
if [[ ! -d "$SCRIPTS_DATA_DIR" && -d "${HOME}/Documents/ScriptsData" ]]; then
    SCRIPTS_DATA_DIR="${HOME}/Documents/ScriptsData"
fi

# Load configuration
CONFIG_FILE="${SCRIPTS_DATA_DIR}/config.env"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

# Set defaults for SMTP parameters if not defined in config.env
GMAIL_ACCOUNT="${GMAIL_ACCOUNT:-gmail}"
GMAIL_HOST="${GMAIL_HOST:-smtp.gmail.com}"
GMAIL_PORT="${GMAIL_PORT:-587}"
GMAIL_USER="${GMAIL_USER:-$EMAIL_FROM}"

EMAIL_FROM="${EMAIL_FROM:-}"
EMAIL_TO="${EMAIL_TO:-}"
EMAIL_SUBJECT="${EMAIL_SUBJECT:-Debian Updates Available}"
EMAIL_BODY="${EMAIL_BODY:-New system updates are available.}"

if [[ -z "$EMAIL_FROM" || -z "$EMAIL_TO" ]]; then
    echo "Error: EMAIL_FROM or EMAIL_TO is not configured in config.env." >&2
    exit 1
fi

# If updates are available, send an email
if [ "$UPDATES" -gt 0 ]; then
    printf "From: %s\nTo: %s\nSubject: %s\n\n%s\n" \
        "$EMAIL_FROM" "$EMAIL_TO" "$EMAIL_SUBJECT" "$EMAIL_BODY" \
        | msmtp --read-envelope-from --read-recipients -C <(cat <<EOF
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt

account ${GMAIL_ACCOUNT}
host ${GMAIL_HOST}
port ${GMAIL_PORT}
from ${EMAIL_FROM}
user ${GMAIL_USER}
password ${GMAIL_APP_PASSWORD}

account default : ${GMAIL_ACCOUNT}
EOF
)
fi

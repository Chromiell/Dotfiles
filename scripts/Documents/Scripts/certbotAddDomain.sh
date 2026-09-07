#!/bin/bash
#
# create-haproxy-cert
# Automates certificate creation + HAProxy PEM assembly + renewal hook + rsync
#

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

# --- CONFIG ---
HAPROXY_SSL_DIR="${HAPROXY_SSL_DIR:-/etc/haproxy/ssl}"
CERTBOT_PORT="${CERTBOT_PORT:-8888}"
REMOTE_HAPROXY="${REMOTE_HAPROXY_HOST:-${REMOTE_HAPROXY:-}}"
RENEW_HOOK_DIR="/etc/letsencrypt/renewal-hooks/post"

# --- INPUT CHECK ---
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 app.example.com"
    exit 1
fi

if [[ -z "$REMOTE_HAPROXY" ]]; then
    echo "Error: REMOTE_HAPROXY_HOST is not configured in config.env." >&2
    exit 1
fi

DOMAIN="$1"

echo ">>> Creating certificate for: $DOMAIN"

# --- CHECK HAPROXY SSL DIR ---
if [[ ! -d "$HAPROXY_SSL_DIR" ]]; then
    echo "Creating HAProxy SSL directory: $HAPROXY_SSL_DIR"
    mkdir -p "$HAPROXY_SSL_DIR"
    chmod 700 "$HAPROXY_SSL_DIR"
fi

# --- RUN CERTBOT ---
echo ">>> Running Certbot..."
certbot certonly --standalone \
    --preferred-challenges http \
    --http-01-port "$CERTBOT_PORT" \
    -d "$DOMAIN"

echo ">>> Certbot completed."

LIVE_DIR="/etc/letsencrypt/live/$DOMAIN"

if [[ ! -d "$LIVE_DIR" ]]; then
    echo "ERROR: Certificate directory not found: $LIVE_DIR"
    exit 1
fi

# --- BUILD PEM FILE ---
PEM_FILE="$HAPROXY_SSL_DIR/$DOMAIN.pem"

echo ">>> Building HAProxy PEM: $PEM_FILE"

cat "$LIVE_DIR/fullchain.pem" "$LIVE_DIR/privkey.pem" > "$PEM_FILE"

chmod 644 "$PEM_FILE"
chown root:root "$PEM_FILE"

echo ">>> PEM created and permissions updated."

# --- RELOAD HAPROXY ---
echo ">>> Reloading HAProxy..."
systemctl reload haproxy

echo ">>> HAProxy reloaded."

# --- CREATE RENEWAL HOOK ---
echo ">>> Creating renewal hook..."

mkdir -p "$RENEW_HOOK_DIR"

HOOK_FILE="$RENEW_HOOK_DIR/haproxy-${DOMAIN}.sh"

cat > "$HOOK_FILE" <<EOF
#!/bin/bash
DOMAIN="$DOMAIN"
HAPROXY_SSL_DIR="/etc/haproxy/ssl"

cat /etc/letsencrypt/live/\$DOMAIN/fullchain.pem \
    /etc/letsencrypt/live/\$DOMAIN/privkey.pem \
    > \$HAPROXY_SSL_DIR/\$DOMAIN.pem

chmod 644 \$HAPROXY_SSL_DIR/\$DOMAIN.pem
chown root:root \$HAPROXY_SSL_DIR/\$DOMAIN.pem
EOF

chmod +x "$HOOK_FILE"

echo ">>> Renewal hook created at: $HOOK_FILE"

# --- RSYNC TO SECOND HAPROXY NOW ---
echo ">>> Syncing certificates to HAProxy #2..."
rsync -a "$HAPROXY_SSL_DIR/" "$REMOTE_HAPROXY:/etc/haproxy/ssl/"

echo ">>> Sync completed."

echo ">>> All done. Certificate for $DOMAIN is active and renewal is fully automated."

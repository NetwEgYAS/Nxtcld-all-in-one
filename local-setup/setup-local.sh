#!/usr/bin/env bash
# =============================================================
# Nextcloud AIO — Local Setup Script
# =============================================================
# This script automates the local Nextcloud setup.
# Run as: bash setup-local.sh
# =============================================================

set -euo pipefail

DOMAIN="${NC_DOMAIN:-nextcloud.local}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================="
echo " Nextcloud AIO — Local Setup"
echo "============================================="

# 1. Check dependencies
for cmd in docker openssl; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: '$cmd' is not installed. Please install it first."
    exit 1
  fi
done

# 2. Create .env from template if not present
if [ ! -f "$SCRIPT_DIR/.env" ]; then
  cp "$SCRIPT_DIR/.env.local" "$SCRIPT_DIR/.env"
  echo "[1/5] Created .env from .env.local"
  echo "      -> Edit .env and fill in all TODO fields, then re-run this script."
  exit 0
else
  echo "[1/5] .env already exists — using existing file"
fi

# 3. Check that TODO fields have been filled in
if grep -q "changeme_" "$SCRIPT_DIR/.env"; then
  echo "ERROR: Please replace all 'changeme_*' values in .env before continuing."
  exit 1
fi

# 4. Add local domain to /etc/hosts if not already present
if ! grep -qF "$DOMAIN" /etc/hosts; then
  echo "[2/5] Adding $DOMAIN to /etc/hosts (requires sudo)..."
  echo "127.0.0.1   $DOMAIN" | sudo tee -a /etc/hosts
else
  echo "[2/5] $DOMAIN already in /etc/hosts"
fi

# 5. Update Caddyfile with actual domain
sed -i "s|nextcloud.local|$DOMAIN|g" "$SCRIPT_DIR/Caddyfile"
echo "[3/5] Caddyfile updated with domain: $DOMAIN"

# 6. Start containers
echo "[4/5] Starting containers..."
docker compose -f "$SCRIPT_DIR/compose.local.yaml" --env-file "$SCRIPT_DIR/.env" up -d

# 7. Done
echo ""
echo "[5/5] Done!"
echo ""
echo "  AIO Interface : https://localhost:8080"
echo "  Nextcloud     : https://$DOMAIN"
echo ""
echo "  First-time setup:"
echo "    1. Open https://localhost:8080 in your browser"
echo "    2. Accept the self-signed certificate warning"
echo "    3. Follow the AIO setup wizard"
echo ""
echo "  NOTE: Your browser may warn about the local certificate."
echo "  This is expected for local domains using 'tls internal'."
echo "  Add the Caddy root CA to your browser to trust it:"
echo "    caddy trust  (run inside the caddy container)"

#!/bin/bash
# acme-renew.sh
# Manually forces certificate renewal and restarts Caddy.
# Use this when you need to renew before the automatic cron window.
#
# Normal renewal is handled automatically by acme.sh's own cron:
#   34 0 * * * "/home/ubuntu/.acme.sh"/acme.sh --cron --home "/home/ubuntu/.acme.sh" > /dev/null
#
# Usage:
#   bash scripts/acme-renew.sh

set -e

DOMAIN="akshad.duckdns.org"
CERT_DIR="$HOME/adguard-certs"

echo "[$(date)] Forcing renewal for $DOMAIN..."
"$HOME/.acme.sh/acme.sh" --renew -d "$DOMAIN" --force

echo "[$(date)] Installing renewed certificate to $CERT_DIR..."
"$HOME/.acme.sh/acme.sh" --install-cert -d "$DOMAIN" \
  --cert-file      "$CERT_DIR/akshad.crt" \
  --key-file       "$CERT_DIR/akshad.key" \
  --reloadcmd      "docker restart caddy"

echo "[$(date)] Verifying certificate dates..."
openssl x509 -in "$CERT_DIR/akshad.crt" -noout -dates

echo "[$(date)] Done."

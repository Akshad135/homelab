#!/bin/bash

# --- Credentials & Config ---
# Load from .env file in the same directory
source "$(dirname "$0")/.env"

# Exact folder path
SYNC_DIR="/home/ubuntu/rclone-server/data/Backup Codes"

cd "$SYNC_DIR" || exit

# 1. Point CLI to your Tailscale Vaultwarden instance
bw config server https://akshad.duckdns.org:8002

# 2. Log in using API keys
bw login --apikey > /dev/null 2>&1

# 3. Unlock vault to get session key (This requires --passwordenv)
export BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)

# 4. Export natively encrypted JSON (This requires --password)
TIMESTAMP=$(date +"%Y%m%d_%H%M")
EXPORT_FILE="vw_backup_$TIMESTAMP.json"

bw export --output "$EXPORT_FILE" --format encrypted_json --password "$BW_PASSWORD"

# Grant read permissions so the rclone container can sync it
chmod 664 "$EXPORT_FILE"

# 5. Lock vault and logout to destroy the session
bw lock
bw logout

# 6. Purge policy: Keep only the 2 newest JSON files
ls -1t vw_backup_*.json 2>/dev/null | tail -n +3 | xargs -r rm

# Vaultwarden

Self-hosted Bitwarden. Passwords, 2FA codes, secure notes.

- **URL:** `https://akshad.duckdns.org:8002`
- **Image:** `vaultwarden/server:latest`

Signups are disabled (`SIGNUPS_ALLOWED=false`). `DOMAIN` needs to match the exact URL including the port number, otherwise the mobile app gets confused about endpoints.

Vault data is in `./data/`. Daily JSON export runs at 2am via `scripts/vw-json-backup.sh`.

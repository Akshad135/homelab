# rclone

SFTP server for syncing files between Oracle and Windows. Exposes a directory over SFTP on port 9000.

- **Port:** `9000` — SFTP, direct, does not go through Caddy
- **Image:** `rclone/rclone:latest`

Windows rclone config uses the `oracle-sftp` remote pointing at `100.109.80.25:9000`. Bisync runs on demand.

Also exposes a metrics endpoint at `:5572` internally — Glance uses this for the health check (`http://rclone-server:5572/metrics`).

# Caddy

Single reverse proxy for everything. One cert, one container, handles all HTTP/HTTPS routing.

The `Caddyfile` uses a `common_tls` snippet so every service block is 3 lines. Adding a new service means adding one block and running `caddy reload`. No restart, no downtime.

---

## Adding a New Service

1. Add a block to `Caddyfile`:
    ```caddy
    https://akshad.duckdns.org:800X {
        import common_tls
        reverse_proxy <container-name>:<port>
    }
    ```

2. Make sure the service container is on the `homelab` network.

3. Reload:
    ```bash
    docker exec caddy caddy reload --config /etc/caddy/Caddyfile
    ```

Ports `8000-8999` are already exposed as a range in `docker-compose.yml` so no compose changes needed for `8xxx` ports.

---

## Useful Commands

```bash
# Reload config (no downtime)
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# Check for syntax errors before reloading
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# Format the Caddyfile (removes the annoying warning in logs)
docker exec caddy caddy fmt --overwrite /etc/caddy/Caddyfile

# Live logs
docker compose logs -f
```

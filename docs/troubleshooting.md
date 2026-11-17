# Troubleshooting

Things that broke, why they broke, how they got fixed. Keeping this so I don't spend another 3 hours on the same problem.

---

## Caddy Can't Reach the Service (`bad address 'vaultwarden'`)

The service container isn't on the `homelab` network.

```bash
docker network inspect homelab
# Check if the container appears under "Containers"

# Quick fix for a running container
docker network connect homelab <container-name>
```

Permanent fix: make sure `docker-compose.yml` has `networks: - homelab` and recreate the container.

---

## Port Already Allocated When Starting Caddy

Something else is publishing that host port. Usually a service container that still has an old `ports:` mapping.

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

Fix: remove `ports:` from the conflicting service's compose file. Only Caddy owns web ports.

---

## `akshad.duckdns.org` Resolves to Oracle's Public IP

The AdGuard DNS rewrite isn't being applied. Check:

1. Is the device using AdGuard? (Tailscale admin -> Override DNS -> `100.109.80.25`)
2. Is the rewrite in AdGuard? (Filters -> DNS Rewrites -> `akshad.duckdns.org -> 100.109.80.25`)

```bash
nslookup akshad.duckdns.org
# Should return 100.x.x.x, not Oracle's public IP
```

---

## Caddy Logs Show `no valid A records found`

Caddy is trying to get a cert from Let's Encrypt for the hostname. Happens when the Caddyfile has something like `adguard.akshad.duckdns.org { ... }` — Caddy assumes you want a cert for that subdomain, which has no DNS record.

Fix: use `https://akshad.duckdns.org:8001 { tls /mnt/certs/akshad.crt /mnt/certs/akshad.key }`. Specify the cert manually, don't let Caddy try to get one.

---

## Caddyfile Formatting Warning in Logs

```
Caddyfile input is not formatted
```

Not an error, config loaded fine. Silence it:

```bash
docker exec caddy caddy fmt --overwrite /etc/caddy/Caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

---

## New Service Shows `ERR_CONNECTION_REFUSED`

Two possible causes:

1. **Caddy isn't publishing that port** — `docker ps | grep caddy` and check the ports column. For `8xxx` this shouldn't happen since `8000-8999` is already exposed as a range. For others, add to `caddy/docker-compose.yml` and recreate. <br>

   _Literally what took so much time of mine ;-;_

2. **Service container isn't on the homelab network** — see first item in this list.

---

## AdGuard Logs Full of `i/o timeout` to Unbound

```
exchanging with 172.x.x.x:53 over udp: i/o timeout
```

Unbound is either down or not on the same network subnet. Check that both containers are on `homelab` and Unbound is healthy.

---

## Glance Health Check Shows Red Even Though Service is Fine

Glance only accepts HTTP 200 as healthy. If `check-url` returns 204, 302, or anything else, it shows as down.

Use internal Docker network URLs for health checks — not the public Caddy URLs:

```yaml
check-url: http://vaultwarden
check-url: http://adguardhome
check-url: http://bookmark-manager:3000/api/health
check-url: http://ignis:8080/
check-url: http://helium-nginx/robots.txt   # /connectivitycheck returns 204, robots.txt returns 200
```

---

## Glance Won't Start (`yaml: line 2: mapping values are not allowed`)

The `glance.yml` starts with a shell prompt line that got pasted in by accident. Open the file and delete line 1.

---

## Helium Extension Download Fails / "Download Interrupted"

The nginx config had a missing trailing slash. `location = /ext` was using `proxy_pass http://exts;` which forwards the `/ext` path to the backend instead of stripping it — 404, download fails.

Fixed by changing to `proxy_pass http://exts/;` in `nginx.conf.j2`. After any change to that file:

```bash
docker compose build helium-nginx
docker compose up -d helium-nginx
```

---

## `docker inspect <container>` Returns `{}` for Networks

The container is stopped, not just unhealthy. Stopped containers have no network attachments.

```bash
docker ps -a          # check STATUS
docker logs <container>   # why did it exit?
```

---

## Vaultwarden Mobile App Can't Connect After Migration

`DOMAIN` must match the exact URL including the port:

```yaml
DOMAIN: "https://akshad.duckdns.org:8002"
```

The Bitwarden mobile app also needs to be pointed at this URL.

---

## Docker Hub Pull Rate Limit (`429 Too Many Requests`)

### Symptoms
When running `docker compose pull` or `docker pull`, daemon errors with:
```
toomanyrequests: You have reached your unauthenticated pull rate limit. Sign in for a higher limit: https://www.docker.com/increase-rate-limit
```

### Cause
Docker Hub enforces an anonymous limit of 100 pulls per hour per IP. Oracle Cloud egress IPs are shared or quickly exhaust this pool.

### Solution
1. **Option A (Log in with free Docker Hub account):**
   ```bash
   docker login
   ```
   Free personal accounts receive 200 pulls per 6 hours tied to the account instead of the host IP.
2. **Option B (Pull locally via crane and stream over Tailscale):**
   ```bash
   crane pull <image> /tmp/img.tar --platform linux/arm64
   tailscale ssh ubuntu@oracle 'docker load' < /tmp/img.tar
   ```

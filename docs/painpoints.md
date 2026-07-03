# Pain Points (Things That Cost Me Hours)

A graveyard of all the annoying issues, bugs, and head-scratching moments that took way too long to fix. If it breaks again, check here first.

---

## 1. The Helium Nginx Trailing Slash 404

* **The Pain:** Accessing the Helium extension proxy at `/ext` hit Nginx's automatic canonicalization. Nginx appended a trailing slash and issued a 301 redirect to `http://.../ext/` on port 80. This completely bypassed the HTTPS reverse proxy and broke the extension downloads.
* **The Fix:** Added an exact match location block in the Nginx config (`location = /ext { proxy_pass http://exts; }`) without a trailing slash to prevent Nginx from issuing its default redirect.

## 2. Caddy's DNS Challenge Failing on Subdomains

* **The Pain:** Caddy was trying to obtain Let's Encrypt certificates for sub-subdomains like `adguard.akshad.duckdns.org`, but DuckDNS doesn't magically resolve arbitrary sub-subdomains without A records. Caddy's auto-HTTPS kept throwing "no valid A records found" challenge errors.
* **The Fix:** Switched to port-based routing via a single domain (`https://akshad.duckdns.org:<port>`). Used the `tls` directive in the Caddyfile to explicitly point to the pre-existing `acme.sh` certs, which turns off Caddy's ACME requests entirely.

## 3. AdGuard Split DNS Sending Traffic to the Public Internet

* **The Pain:** Even while on Tailscale, devices querying `akshad.duckdns.org` were getting the public Oracle IP from DuckDNS. This forced traffic out to the public internet where it hit the Oracle firewall, completely breaking access.
* **The Fix:** Set up a Split-Horizon DNS rewrite rule inside AdGuard Home (`akshad.duckdns.org -> 100.x.x.x` Tailscale IP). Now devices using AdGuard resolve the domain internally and never traverse the public internet.

## 4. Glance Health Check Refusing to Accept HTTP 204

* **The Pain:** The Glance monitor displayed a warning alert for Helium. Helium's `/connectivitycheck` endpoint correctly returns `HTTP 204 No Content` for a successful connection, but Glance strictly requires an `HTTP 200 OK` to consider a service "healthy".
* **The Fix:** Changed the Glance monitor's `check-url` to point to a tiny static file (`http://helium-nginx/robots.txt`), which always returns the standard `HTTP 200 OK`.

## 5. Caddy Failing to Resolve Docker Containers

* **The Pain:** The Caddy reverse proxy failed with `curl: (6) Could not resolve host: adguardhome`, rendering the reverse proxy useless.
* **The Fix:** The containers were on different Docker networks. Ensured Caddy and all backend containers shared a common Docker network (`homelab`) so Docker's internal DNS could properly resolve container names.

## 6. acme.sh Renewal Hook Broken After Directory Move

* **The Pain:** Renamed the certificate directory from `~/adguard-certs` to `~/certs`, breaking `acme.sh` renewals which were still pointing to the old paths. Caddy also wasn't being reloaded upon renewal.
* **The Fix:** Re-ran `acme.sh --install-cert` with the updated target paths and explicitly set `--reloadcmd "docker restart caddy"` so Caddy automatically restarts and picks up new certificates upon future renewals.

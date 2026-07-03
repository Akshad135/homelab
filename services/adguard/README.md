# AdGuard Home

DNS resolver and ad blocker for everything on the tailnet. Also where the critical `akshad.duckdns.org -> 100.109.80.25` rewrite lives — without that entry nothing works.

- **URL:** `https://akshad.duckdns.org:8001`
- **Image:** `adguard/adguardhome`
- **DNS:** port 53 (TCP + UDP)
- **DoT:** port 853

Runs alongside Unbound in the same compose stack. Unbound does the actual recursive resolution, AdGuard handles filtering and rewrites.

The web UI used to be published directly on `:8001` from the container. Removed that mapping so Caddy owns the port instead.

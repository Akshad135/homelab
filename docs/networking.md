# Networking & DNS

---

## Tailscale

Tailscale connects Oracle, Linux, Windows, and Android in an encrypted mesh. Oracle acts as the exit node and central homelab host.

Key setting in Tailscale admin:

- **Override DNS** → `100.109.80.25` (Oracle Tailscale IP)

This routes every device on the tailnet to send DNS queries to AdGuard Home on the Oracle VM. MagicDNS is preserved so `*.ts.net` names resolve, while our homelab services use `akshad.duckdns.org`.

---

## The DNS Rewrite (Split-Horizon)

DuckDNS points `akshad.duckdns.org` to Oracle's public IP. But Oracle's public IP has no open web ports. Inside AdGuard, we rewrite the domain to the Tailscale IP:

```
akshad.duckdns.org → 100.109.80.25
```

Every device using AdGuard resolves the domain directly to the Tailscale IP. Traffic routes through the WireGuard mesh, never traversing the public internet.

```mermaid
sequenceDiagram
    autonumber
    actor Device as Tailscale Device (Client)
    participant Tailscale as Tailscale Override DNS
    participant AdGuard as AdGuard Home (Oracle)
    participant Unbound as Unbound (Recursive)
    participant Caddy as Caddy (100.109.80.25)
    participant Root as Root DNS Servers

    Device->>Tailscale: Query akshad.duckdns.org:8002
    Tailscale->>AdGuard: Forward DNS to 100.109.80.25:53
    alt Split-Horizon Match: akshad.duckdns.org
        AdGuard-->>Device: Return 100.109.80.25 (Tailscale IP)
        Device->>Caddy: HTTPS Request to 100.109.80.25:8002
    else Other Domain (e.g. github.com)
        AdGuard->>Unbound: Forward query to unbound:53
        Unbound->>Root: Recursive Root Resolution
        Root-->>Unbound: IP Answer
        Unbound-->>AdGuard: Cache & Return IP
        AdGuard-->>Device: Return resolved public IP
    end
```

---

## AdGuard + Unbound

AdGuard acts as the DNS ad-blocker and DNS rewrite engine. For recursive resolving of internet queries, AdGuard forwards upstream requests to Unbound running in the same Docker network (`unbound:53`). Unbound queries root DNS nameservers directly.

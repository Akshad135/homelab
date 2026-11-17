# Architecture

Oracle ARM VM, Tailscale mesh, Caddy as the single entry point.

---

## The Big Picture

```mermaid
flowchart TB
    subgraph Clients["Tailscale Mesh Devices"]
        phone["Android (Samsung)"]
        laptop["Linux (Omarchy)"]
        desktop["Windows (IdeaPad)"]
    end

    subgraph Tailnet["Tailscale Network (Encrypted WireGuard Mesh)"]
        dns_override["Tailscale DNS Override<br/>100.109.80.25"]
    end

    subgraph Oracle["Oracle Cloud Free-Tier VM (Ubuntu ARM64)"]
        subgraph Ingress["Ingress & Edge"]
            caddy["Caddy Reverse Proxy<br/>Ports 80, 443, 8000-8099, 9001<br/>TLS: akshad.crt / akshad.key"]
            acme["acme.sh (Cron)<br/>DuckDNS DNS-01 Challenge"]
        end

        subgraph DNS["DNS & Resolution"]
            adguard["AdGuard Home (:53, :853)<br/>Split-Horizon Rewrite:<br/>akshad.duckdns.org -> 100.109.80.25"]
            unbound["Unbound Recursive Resolver<br/>Root DNS queries (:5335)"]
        end

        subgraph HomelabNet["Docker Network: homelab"]
            glance["Glance Dashboard (:8080)<br/>https://akshad.duckdns.org"]
            vw["Vaultwarden (:80)<br/>:8002"]
            bm["Bookmarks (:3000)<br/>:8003"]
            ignis["Ignis LiveSync (:8080)<br/>:8004"]
            pastebin["Ghostbin Pastebin (:8788)<br/>:8005"]
            helium_nginx["Helium Nginx (:80)<br/>:9001"]
            helium_proxies["ext_proxy / ubo_proxy<br/>Deno Proxies"]
            rclone["rclone SFTP Server (:9000)<br/>akshad.duckdns.org:9000"]
        end
    end

    Clients --> Tailnet
    Tailnet --> Oracle
    dns_override --> adguard
    adguard --> unbound
    caddy --> glance
    caddy --> adguard
    caddy --> vw
    caddy --> bm
    caddy --> ignis
    caddy --> pastebin
    caddy --> helium_nginx
    helium_nginx --> helium_proxies
    acme -.-> Ingress
```

All services run on a Docker bridge network called `homelab`. Caddy reaches them by container name (e.g. `vaultwarden:80`). No HTTP service publishes its own host port — only Caddy does.

---

## Docker Network

Single external bridge called `homelab`. Created once on the host:

```bash
docker network create homelab
```

Every compose file references it as external. This is how Caddy can do `reverse_proxy vaultwarden:80` and Docker resolves the name. Glance health checks also run over this network directly (`http://adguardhome`, not the public URL through Caddy).

---

## Oracle VM

One ARM VM, always-free tier (4 OCPUs, 24GB RAM, 200GB storage). Oracle's security list / firewall only permits SSH (22) and Tailscale (41641/UDP). Everything else is strictly accessible through Tailscale.

---

## Diagrams

Full diagram sources (`.mmd`) and previews (`.png`) are located in [`../diagrams/`](../diagrams/).

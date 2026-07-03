# Unbound

Recursive DNS resolver. Runs as a sidecar to AdGuard in the same compose file.

Instead of forwarding queries to Cloudflare or Google, Unbound goes to root servers directly. AdGuard uses it as its upstream. Nothing else talks to it directly.

No additional config needed beyond what's in the compose file.

# URL Management

When `wendy start` runs, two URLs are available to connect your AI agent:

| URL | Changes on restart? | Use case |
|---|---|---|
| `https://xxxx.trycloudflare.com` | Yes | External clients (another machine) |
| `http://localhost:3001/mcp` | Never | Local agents (same machine) |

---

## Local URL — permanent, no setup required

If your AI agent runs on the **same machine** as the companion, always use:

```
http://localhost:3001/mcp
```

This URL is fixed. It never changes. No tunnel, no Cloudflare, no URL to update. Agents on the same machine bypass authentication automatically.

→ See [MCP Connection — Local](mcp-connection/local.md) for setup.

---

## Temporary URL — Cloudflare quick tunnel

When you run `wendy start`, a temporary `trycloudflare.com` URL is created automatically. It works immediately, requires no Cloudflare account, and is accessible from any machine.

**Limitation:** the URL changes every time `wendy start` runs. If your AI client stores the URL in its config, you'll need to update it after each restart.

Use the temporary URL when:
- You're testing or experimenting
- You don't have a domain registered with Cloudflare

→ See [MCP Connection — Cloudflare temporary](mcp-connection/cloudflare-temporary.md) for setup.

---

## Stable URL — Cloudflare named tunnel {#stable-url-cloudflare-named-tunnel}

A named Cloudflare tunnel gives you a permanent subdomain (e.g. `whiteboard.yourdomain.com`) that never changes, even after restarting the companion.

Requirements:
- A domain registered with Cloudflare (or transferred to Cloudflare DNS)
- A free Cloudflare account

Once set up, configure your AI client once and never touch it again.

→ See [MCP Connection — Cloudflare stable](mcp-connection/cloudflare-stable.md) for setup.

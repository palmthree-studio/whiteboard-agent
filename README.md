# Whiteboard

### Your Agent Just Got Eyes & Hands.

Give your AI agents a shared canvas. They read it, write it, build on it — alongside you.

---

Whiteboard is a local-first canvas your agents can actually *use*. Not screenshots, not descriptions — a real surface where they create tickets, draw connectors, rearrange the layout, and leave their marks. You watch every move land in real time. You take over whenever you want.

The app is free. Forever. Yours forever.

---

## Quick start

Tell your agent:

> *"Map out the architecture of a SaaS app with auth, API, database and CDN."*

Then give it the canvas. Drop this into your MCP client config:

```json
{
  "mcpServers": {
    "whiteboard": {
      "command": "npx",
      "args": ["-y", "@palmthree-studio/whiteboard-mcp"]
    }
  }
}
```

Restart your client. The board is live.

---

**17 MCP tools.** All free.

**Compatible clients** — Claude · Cursor · Windsurf · OpenAI Codex · Cline · Openclaw · Hermes

---

## CLI

After install, `wendy` lives in your terminal:

| Command | What it does |
|---|---|
| `wendy start` | Re-launch the companion (and Cloudflare tunnel if needed) |
| `wendy stop` | Stop the companion |
| `wendy status` | Show companion status and URL |
| `wendy update` | Pull the latest companion binary |
| `wendy activate <license-key>` | Activate PRO on this machine |
| `wendy deactivate` | Deactivate PRO on this machine |
| `wendy configure-tunnel --token <token> --url <url>` | Configure a permanent Cloudflare tunnel (PRO) |

---

## PRO — €29 one-time

The app is free. PRO unlocks two things:

- **Custom Public URL** — your companion always reachable at the same domain, via Cloudflare Tunnel.
- **Offline Mode** — keep the loop going without an internet connection.

€29 one-time for early adopters. €49 after. **Buy once, own it forever.**

---

## Multi-agent

Drop several agents on the same board. Each gets its own named token from the **Agents** panel and signs every action it takes — so you always know who moved what.

Agents can call `get_agents` to see who else is on the canvas. Setup details: [Agent Tokens — Multi-agent Collaboration](./docs/agents.md).

---

## Local-first

Your boards live on your machine. No cloud, no account, no telemetry. **Your computer is your server.** Nothing leaves unless you export it.

---

*Built by [Palmthree Studio](https://github.com/palmthree-studio)*

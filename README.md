# Whiteboard Agent

**Your agent got eyes and hands.**

Whiteboard is a collaborative canvas app built for AI agents. Your agent can create tickets, draw connectors, apply layouts, and organize boards — live, while you watch.

Meet **Wendy** — the companion that bridges your AI agent and the canvas. Wendy runs locally on your machine, exposes an MCP server, and keeps your boards alive.

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/palmthree-studio/whiteboard-agent/main/install.sh | bash
```

The installer sets up Wendy and walks you through connecting your first AI agent. No account required. Everything runs on your machine.

---

## Quick start

```bash
wendy start    # Launch the companion and open a Cloudflare tunnel
wendy update   # Pull the latest companion binary
```

When `wendy start` runs, you'll see:

```
Temporary URL : https://xxxx.trycloudflare.com
Username      : younes
Local MCP URL : http://localhost:3001/mcp
```

Use the **Temporary URL** to connect external AI clients (Claude Desktop, Cursor).  
Use the **Local MCP URL** to connect agents running on the same machine — it never changes.

---

## Documentation

- [Installation](docs/installation.md) — prerequisites, install script, what gets installed
- [Wendy CLI](docs/wendy-cli.md) — `start`, `update`, options
- [URL Management](docs/url-management.md) — temporary vs stable URLs, when to use each
- [MCP Connection](docs/mcp-connection/index.md) — connect your AI agent, capabilities, all methods

---

*Built by [Palmthree Studio](https://github.com/palmthree-studio)*

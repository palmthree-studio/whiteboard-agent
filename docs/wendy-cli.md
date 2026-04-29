# Wendy CLI

Wendy is the command-line interface that manages the companion server and its Cloudflare tunnel.

## Commands

### `wendy start`

Launches the companion server and opens a temporary Cloudflare tunnel.

```bash
wendy start
```

Output:

```
Temporary URL : https://xxxx.trycloudflare.com
Username      : younes
Local MCP URL : http://localhost:3001/mcp
```

- **Temporary URL** — a public HTTPS URL that routes to your companion. Changes on every restart. Use this for external AI clients (Claude Desktop, Cursor on another machine).
- **Local MCP URL** — always `http://localhost:3001/mcp`. Use this for agents running on the same machine. Never changes.

The companion stays alive as long as the terminal session is open. Closing the terminal stops both the companion and the tunnel.

### `wendy update`

Downloads and installs the latest companion binary.

```bash
wendy update
```

Your configuration (username, password) is preserved. Restart with `wendy start` after updating.

## Keeping the companion running

To keep Wendy running after closing the terminal, use a process manager:

```bash
# With pm2
npm install -g pm2
pm2 start "wendy start" --name whiteboard-agent
pm2 save
pm2 startup
```

Note: the Cloudflare tunnel URL will change each time the companion restarts. For a stable URL that survives restarts, see [URL Management — Stable URL](url-management.md#stable-url-cloudflare-named-tunnel).

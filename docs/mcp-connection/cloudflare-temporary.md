# MCP Connection — Cloudflare Temporary URL

Use this method to connect an AI client running on **another machine**. The URL is generated automatically by `wendy start` — no Cloudflare account needed.

## Limitation

The URL changes every time `wendy start` runs. You'll need to update your client config after each restart.

For a permanent URL, see [Cloudflare stable tunnel](cloudflare-stable.md).

## Steps

1. Run `wendy start` on the machine hosting the companion
2. Note the **Temporary URL** printed in the output (e.g. `https://xxxx.trycloudflare.com`)
3. Open that URL in a browser and log in with your username and password
4. Copy the URL and add it to your client config (see below)

## Configuration by client

Replace `https://xxxx.trycloudflare.com` with your actual temporary URL.

### Claude Desktop — `~/.config/claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "whiteboard": {
      "url": "https://xxxx.trycloudflare.com/mcp",
      "transport": "http"
    }
  }
}
```

### Cursor — `.cursor/mcp.json`

```json
{
  "mcpServers": {
    "whiteboard": {
      "url": "https://xxxx.trycloudflare.com/mcp"
    }
  }
}
```

### Windsurf — `~/.codeium/windsurf/mcp_config.json`

```json
{
  "mcpServers": {
    "whiteboard": {
      "serverUrl": "https://xxxx.trycloudflare.com/mcp"
    }
  }
}
```

## Authentication

The companion requires a browser login before MCP calls will work. Open the tunnel URL in a browser, log in once, and the session cookie persists for 30 days.

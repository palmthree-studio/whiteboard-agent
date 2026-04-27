# Whiteboard Agent

Whiteboard Agent is an MCP-powered collaborative whiteboard. Your local
companion runs at **$COMPANION_URL** and exposes an MCP server that your
AI clients (Claude Desktop, Cursor, Windsurf, etc.) can call to create
tickets, connectors, and organize a board in real time.

## Capabilities

- **Tickets**: create, move, resize, color, and format content
  (bold / underline / strikethrough).
- **Connectors**: link two tickets, choose a style (solid, dotted,
  dashed) and source/target arrow.
- **Auto layouts**: `tree` and `radial`.
- **Named boards**: save, load, and list your persisted boards.
- **Comments**: annotate each ticket with a signed comment thread.

## MCP connection

The MCP server is available at:

```
$COMPANION_URL/mcp
```

All API routes are protected by your username + password (httpOnly
cookie). The configurations below assume you have already logged in to
**$COMPANION_URL** in a browser at least once.

### Claude Desktop — `~/.config/claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "whiteboard": {
      "url": "$COMPANION_URL/mcp",
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
      "url": "$COMPANION_URL/mcp"
    }
  }
}
```

### Windsurf — `~/.codeium/windsurf/mcp_config.json`

```json
{
  "mcpServers": {
    "whiteboard": {
      "serverUrl": "$COMPANION_URL/mcp"
    }
  }
}
```

### Generic format (any MCP-compatible client)

```json
{
  "name": "whiteboard",
  "transport": {
    "type": "http",
    "url": "$COMPANION_URL/mcp"
  }
}
```

## Verify everything works

```bash
curl -i $COMPANION_URL/api/auth/me
```

If you get `401`, open `$COMPANION_URL` in a browser, log in, then
retry the request with your session cookie.

## Help

- Cloudflare Tunnel docs: <https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/>
- Source code: <https://github.com/palmthree-studio/whiteboard-agent>

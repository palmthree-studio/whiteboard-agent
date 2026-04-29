# MCP Connection — Local (same machine)

Use this method when your AI agent runs on the **same machine** as the companion. No auth required, URL never changes.

## MCP URL

```
http://localhost:3001/mcp
```

## Configuration by client

### Claude Code (Claude Desktop CLI)

Add to your MCP config:

```json
{
  "mcpServers": {
    "whiteboard": {
      "url": "http://localhost:3001/mcp",
      "transport": "http"
    }
  }
}
```

### Claude Desktop — `~/.config/claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "whiteboard": {
      "url": "http://localhost:3001/mcp",
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
      "url": "http://localhost:3001/mcp"
    }
  }
}
```

### Windsurf — `~/.codeium/windsurf/mcp_config.json`

```json
{
  "mcpServers": {
    "whiteboard": {
      "serverUrl": "http://localhost:3001/mcp"
    }
  }
}
```

## Prerequisites

- The companion must be running (`wendy start`)
- The companion version must be **v1.3.1 or later** (localhost bypass support)

Verify your companion version:

```bash
wendy update   # pulls latest if outdated
```

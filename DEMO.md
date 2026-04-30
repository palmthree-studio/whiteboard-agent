# Whiteboard × AI — Demo Guide

## Architecture

```
Claude Desktop
    │  stdio (MCP)
    ▼
npm run mcp          ← MCP server
    │  HTTP REST
    ▼
npm run server       ← Companion server (port 3001)
    │  WebSocket
    ▼
npm start            ← Angular app (port 4200)
```

## Getting started

```bash
# Terminal 1 — Angular app
npm start

# Terminal 2 — Companion server (WebSocket + REST)
npm run server

# Terminal 3 — MCP server (optional if using Claude Desktop)
npm run mcp
```

## Claude Desktop setup

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "whiteboard": {
      "command": "npm",
      "args": ["run", "mcp"],
      "cwd": "/absolute/path/to/whiteboard"
    }
  }
}
```

Restart Claude Desktop. The green **AI connected** badge appears in the top-right corner when the companion server is running.

## MCP tools reference

| Tool | Description |
|---|---|
| `get_board` | Get full board state (tickets with IDs, connectors) |
| `add_ticket` | Create a ticket (content, x, y, color, font…) |
| `update_ticket` | Modify an existing ticket |
| `remove_ticket` | Delete a ticket and its connectors |
| `add_connector` | Draw an arrow between two tickets |
| `remove_connector` | Remove a connector |
| `clear_board` | Remove all tickets and connectors |
| `import_board` | Replace the entire board in one request |

## Quick-start prompts

See the [`prompts/`](prompts/) folder for ready-to-use examples.

**System design**
> Generate an architecture diagram for a modern web app with authentication, REST API, database and CDN. Use different colors per layer. Apply tree layout.

**Mind map**
> Create a mind map about machine learning: a central node, main families (supervised, unsupervised, reinforcement), and 2–3 algorithms each. Radial layout.

## Native desktop build (Tauri)

```bash
# Prerequisites
curl https://sh.rustup.rs -sSf | sh   # Rust
curl -fsSL https://bun.sh/install | bash  # Bun (to compile the sidecar binary)

# Compile companion server to a native binary
npm run build:companion

# Dev mode (native window)
npm run tauri:dev

# Production build (.dmg / .app)
npm run tauri:build
```

## Publish MCP server to npm

```bash
# Bundle MCP server into a standalone CJS file
npm run build:mcp

# Publish to npm (requires npm login)
npm run publish:mcp
```

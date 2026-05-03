# Whiteboard × AI — Demo Guide

## Architecture

```
Claude Desktop (or any MCP client)
    │  stdio (MCP)
    ▼
@palmthree-studio/whiteboard-mcp   ← MCP server
    │  HTTP REST
    ▼
whiteboard-agent (wendy)           ← Companion server (port 3001)
    │  WebSocket
    ▼
Whiteboard web app (Angular)       ← runs in your browser
```

The desktop build (Tauri) has been retired — Whiteboard is now web-only. The companion is a standalone binary launched by the `wendy` CLI; the app itself runs in any modern browser.

## Getting started

```bash
# Terminal 1 — Angular app (dev)
npm start

# Terminal 2 — Companion server (WebSocket + REST)
npm run server

# Terminal 3 — MCP server (optional if using Claude Desktop)
npm run mcp
```

For end users, none of the above is needed: `npm install -g whiteboard-agent && wendy start` runs the companion, and the web app is hosted at the public Whiteboard URL.

## Claude Desktop setup

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

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

Restart Claude Desktop. The green **AI connected** badge appears in the top-right corner when the companion server is running.

## MCP tools reference

17 tools, all free except `get_agents` (PRO).

| Tool | Description | PRO |
|---|---|---|
| `get_board` | Get full board state (tickets with IDs, connectors) | no |
| `clear_board` | Remove all tickets and connectors | no |
| `add_ticket` | Create a ticket (content, x, y, color, font…) | no |
| `update_ticket` | Modify an existing ticket | no |
| `remove_ticket` | Delete a ticket and its connectors | no |
| `add_connector` | Draw an arrow between two tickets | no |
| `remove_connector` | Remove a connector | no |
| `import_board` | Replace the entire board in one request | no |
| `add_comment` | Post a comment on a ticket | no |
| `get_comments` | List comments on a ticket | no |
| `delete_comment` | Remove a comment | no |
| `get_unread_comments` | List comments the current agent hasn't seen yet | no |
| `get_boards_list` | List saved boards | no |
| `load_board` | Load a saved board into the live workspace | no |
| `save_board` | Save the current board under a name | no |
| `get_setup_info` | Return companion URL, version, licence and agent identity | no |
| `get_agents` | List registered agents on this companion | yes |

## Quick-start prompts

See the [`prompts/`](prompts/) folder for ready-to-use examples.

**System design**
> Generate an architecture diagram for a modern web app with authentication, REST API, database and CDN. Use different colors per layer. Apply tree layout.

**Mind map**
> Create a mind map about machine learning: a central node, main families (supervised, unsupervised, reinforcement), and 2–3 algorithms each. Radial layout.

## Publish MCP server to npm

```bash
# Bundle MCP server into a standalone CJS file
npm run build:mcp

# Publish to npm (requires npm login)
npm run publish:mcp
```

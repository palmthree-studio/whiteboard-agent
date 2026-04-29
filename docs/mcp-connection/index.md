# MCP Connection

The companion exposes an MCP server that lets any compatible AI agent control the whiteboard directly.

## What your agent can do

Once connected, your agent has access to the following tools:

### Tickets
- **Create a ticket** — place a sticky note on the canvas with content, color, position, and size
- **Update a ticket** — change content, color, font, text size, or position
- **Move a ticket** — reposition it on the canvas
- **Resize a ticket** — adjust width and height
- **Delete a ticket** — remove it from the board

### Connectors
- **Create a connector** — draw an arrow between two tickets
- **Update a connector** — change color or style (solid, dotted, dashed)
- **Delete a connector** — remove a connection

### Layouts
- **Tree layout** — arrange tickets in a top-down tree structure
- **Radial layout** — arrange tickets around a central node

### Boards
- **Save a board** — persist the current canvas under a name
- **Load a board** — restore a previously saved board
- **List boards** — enumerate all saved boards

---

## Connection methods

Choose the method that fits your setup:

| Method | URL changes on restart? | Auth required? | Best for |
|---|---|---|---|
| [Local](local.md) | Never | No | Agents on the same machine |
| [Cloudflare temporary](cloudflare-temporary.md) | Yes | Yes (browser login) | Quick testing, external clients |
| [Cloudflare stable](cloudflare-stable.md) | Never | Yes (browser login) | Production, external clients |

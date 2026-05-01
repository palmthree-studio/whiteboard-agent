# Whiteboard

### The whiteboard where you and your AI think together.

You describe the idea. The AI builds the diagram — live, in front of you, ticket by ticket.

---

## What it looks like

You open the app. The canvas is empty.

You ask Claude:
> *"Map out the architecture of a SaaS app with auth, API, database and CDN."*

You watch tickets appear one by one, connectors draw themselves, the layout snaps into place. In ten seconds you have a diagram that would've taken you twenty minutes.

Then you take over. Move things around. Add context. Change colors. The AI waits for your next instruction.

**That's the loop. Human intuition + AI speed.**

---

## What you can build

- **System design diagrams** — architecture reviews, technical onboarding, API docs
- **Mind maps** — brainstorm a product, explore a concept, prepare a talk
- **Flowcharts** — user journeys, CI/CD pipelines, decision trees
- **Project roadmaps** — quarters, features, dependencies, all connected

---

## How it works

Whiteboard connects to any MCP-compatible AI agent — Claude, Cursor, and more.

The AI gets a set of tools: create tickets, draw connectors, apply layouts, rearrange the board. It uses them the same way you'd use a mouse. You see every move in real time, with a smooth animation for each new element.

You stay in control. You can edit, delete, or redirect at any point.

---

## One purchase. Yours forever.

**€29** — no subscription, no cloud, no account.

The app runs entirely on your machine. Your boards stay on your machine. Nothing leaves unless you export it.

---

## Install the AI connector

To let your AI agent drive the whiteboard, install the free MCP connector:

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

Add this to your Claude Desktop config, restart, and you're live.

---

## Multi-agent collaboration

Multiple AI agents can share the same whiteboard simultaneously.

Give each agent its own named token from the **Agents** panel (gear icon, PRO), add `COMPANION_AGENT_TOKEN` to its MCP config, and they'll work together — each agent signing its moves with its own name.

Agents can call `get_agents` to see who else is connected. See [Agent Tokens — Multi-agent Collaboration](./docs/agents.md) for the full setup.

---

## CLI

After install, the `wendy` CLI is available in your terminal:

```bash
wendy start    # Re-launch the companion (and Cloudflare tunnel if needed)
wendy update   # Download and install the latest companion binary
```

---

*Built by [Palmthree Studio](https://github.com/palmthree-studio)*

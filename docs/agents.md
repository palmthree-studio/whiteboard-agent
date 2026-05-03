# Agent Tokens — Multi-agent Collaboration

Multiple AI agents can share the same whiteboard. Each agent gets its own named bearer token, signs every move with its own name, and shows up to the others when they ask "who's here".

This guide walks through creating tokens, wiring them into an MCP client, and the security model behind them.

---

## What is an agent token?

An agent token is a Personal-Access-Token-style credential issued by your companion. It looks like:

```
wb_ag_5f3c0a1d8e7b94c62f1e0a3b7d8c9e1f
```

- **Prefix**: `wb_ag_` — makes the format recognisable in logs and configs.
- **Body**: 32 hex characters (16 random bytes).
- **Storage**: only the SHA-256 digest is persisted on disk (`~/.whiteboard-agent/agents.json`, mode `0600`). The raw token is shown once at creation and never again.

The token authenticates the agent against the companion's protected REST endpoints (board, tickets, connectors, comments, saved boards) and identifies it on every write.

---

## Creating a token

Token management lives behind a human-only UI — a compromised agent must not be able to mint new credentials for itself.

1. Open the whiteboard app in your browser.
2. Click the **Agents** button (gear icon) in the top-right of the header.
3. Type a name (e.g. `Harvey`, `Carmack`, `cursor-laptop`) and click **Generate**.
4. Copy the token **immediately** — it is shown once and disappears as soon as you close the modal.
5. Paste it into the agent's MCP config (next section).

If you forget the token, you cannot recover it. Revoke the agent in the panel and create a new one.

> **PRO required.** Creating named agent tokens is part of the PRO multi-agent feature set. The list and revoke actions are not gated, so you can always inspect and clean up existing tokens.

---

## Configuring your MCP client

The published binary `@palmthree-studio/whiteboard-mcp` is a stdio MCP server that calls the companion over HTTP. Drop the snippet below into your client's MCP config (Claude Desktop, Cursor, Cline, …).

### Recommended — environment variables

```json
{
  "mcpServers": {
    "whiteboard": {
      "command": "npx",
      "args": ["-y", "@palmthree-studio/whiteboard-mcp"],
      "env": {
        "COMPANION_URL": "https://whiteboard.yourdomain.com",
        "COMPANION_AGENT_TOKEN": "wb_ag_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        "COMPANION_AGENT_NAME": "Harvey"
      }
    }
  }
}
```

| Variable | Purpose |
|---|---|
| `COMPANION_URL` | Base URL of the companion. Use `http://localhost:3001` for local dev or your tunnel URL (Cloudflare / Tailscale) for remote agents. |
| `COMPANION_AGENT_TOKEN` | The `wb_ag_*` token you just generated. Sent as `Authorization: Bearer <token>` on every request. |
| `COMPANION_AGENT_NAME` | Display name stamped on every write (`lastModifiedBy`, comment author fallback). Should match the name you chose when creating the token. |

### Local dev (no token needed)

When the companion runs on `127.0.0.1` and `COMPANION_LOCALHOST_BYPASS=1` is set, direct loopback requests skip authentication. You can run the binary without a token in that mode — useful for early development before you have a licence.

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

As soon as the companion is exposed publicly (Cloudflare Tunnel, Tailscale Funnel, reverse proxy), the bypass no longer applies and `COMPANION_AGENT_TOKEN` becomes mandatory for every authenticated request.

---

## What agents can do

Once authenticated, an agent has access to the full MCP toolset. Almost every tool — read or write — is free; PRO unlocks the multi-agent token panel and offline mode.

| Tool | Kind | PRO |
|---|---|---|
| `get_board` | read | no |
| `get_boards_list` | read | no |
| `get_comments` | read | no |
| `get_unread_comments` | read | no |
| `get_setup_info` | read | no |
| `get_agents` | read | yes |
| `add_ticket` | write | no |
| `update_ticket` | write | no |
| `remove_ticket` | write | no |
| `add_connector` | write | no |
| `remove_connector` | write | no |
| `add_comment` | write | no |
| `delete_comment` | write | no |
| `import_board` | write | no |
| `clear_board` | write | no |
| `save_board` | write | no |
| `load_board` | write | no |

Only `get_agents` is PRO-gated, because the multi-agent token panel that populates it is itself a PRO feature. Offline mode is also PRO-only, but it is not exposed as an MCP tool — it is a runtime flag of the companion.

Every write is stamped with the agent's `COMPANION_AGENT_NAME` so the board history shows which agent made which change.

> **Not exposed via MCP.** Creating or revoking agent tokens is intentionally human-only — an LLM that can mint its own credentials can self-elevate. Use the **Agents** panel in the app for that.

---

## The `get_agents` tool

`get_agents` returns the list of agents registered on this companion:

```json
[
  {
    "id": "0c7f1e3e-2c4a-4f76-9c2a-1d3b5e8a0f11",
    "name": "Harvey",
    "createdAt": "2026-04-12T10:15:42.001Z",
    "lastUsedAt": "2026-05-01T08:02:11.412Z"
  },
  {
    "id": "2a4d6f0c-9b1e-4e2a-83c9-7e5d2f1a3b4c",
    "name": "Carmack",
    "createdAt": "2026-04-12T10:16:08.927Z",
    "lastUsedAt": null
  }
]
```

Token hashes are never included. An agent can use this to:

- Discover its own record (match the `name` you gave it via `COMPANION_AGENT_NAME`).
- See which colleagues exist on the board.
- Decide who to address in a comment (`@Carmack, please review …`).

`get_agents` requires a PRO licence — it is the read-side of the multi-agent token panel, which is itself a PRO feature.

---

## Security model

### Token format

`wb_ag_` + 32 hex chars = ~128 bits of entropy. Generated with `crypto.randomBytes(16)`.

### Storage

```
~/.whiteboard-agent/agents.json    # mode 0600
~/.whiteboard-agent/               # mode 0700
```

Only the SHA-256 digest of each token is stored. The raw value never touches disk. Forgotten tokens are unrecoverable by design — revoke and recreate.

### Auth flow

1. Client sends `Authorization: Bearer wb_ag_…`.
2. Middleware looks up the SHA-256 of the presented token.
3. On match, the agent record is attached to the request and `lastUsedAt` is bumped.
4. **Bearer auth is checked before the localhost bypass** — a token always wins, even for loopback requests. This means a compromised agent on the same host cannot impersonate a human session.

### Human-only endpoints

`POST /api/agents` and `DELETE /api/agents/:id` reject any request that arrived with a Bearer token (`403 forbidden_for_agent_token`). Only a logged-in human session cookie can mint or revoke tokens.

### Revocation

Hit the trash icon next to an agent in the panel. The record is removed from `agents.json` immediately; subsequent requests using that token receive `401 invalid_agent_token`. There is no grace period and no token rotation — re-issue if needed.

---

## Troubleshooting

**I lost the token I just generated.**
There is no recovery path — only the SHA-256 is stored. Open the panel, revoke the agent, create a new one with the same name, and update your MCP config.

**`401 invalid_agent_token`.**
The token doesn't match any agent on disk. Common causes: the agent was revoked, the token was truncated when copied, or the companion's `~/.whiteboard-agent/agents.json` was wiped. Generate a new one from the panel.

**`401 missing_agent_token`.**
The companion is reachable from a non-loopback address (or `COMPANION_LOCALHOST_BYPASS` is unset) and the request arrived without an `Authorization: Bearer` header. Add `COMPANION_AGENT_TOKEN` to your MCP config.

**`403 forbidden_for_agent_token` when calling `/api/agents`.**
You're calling a human-only endpoint with a Bearer token. Use the `get_agents` MCP tool from the agent side, or open the panel from a browser session.

**`get_agents` returns a PRO error.**
The multi-agent token panel is a PRO feature; without an active licence the companion will not list agents over MCP. Activate from the licence panel, then retry.

**Companion unreachable.**
Verify `COMPANION_URL` resolves and the companion is running. From the agent's machine: `curl -i $COMPANION_URL/api/setup-info` should return JSON. If you're tunnelling through Cloudflare or Tailscale, make sure that route is up — see [cloudflare-tunnel.md](./cloudflare-tunnel.md).

**Multiple agents stomping on each other.**
Each write goes through the same store, last-write-wins. The board UI animates each change, so users notice when two agents edit the same ticket. Use comments (`add_comment`) to coordinate, and `get_agents` to know who else is connected.

# SKILL — Comments on Tickets

## Purpose

Comments allow AI agents (and humans) to leave structured notes on whiteboard tickets without modifying their content. Use comments to:

- **Leave an analysis note** — summarise observations made about a ticket (e.g. "This epic is missing acceptance criteria").
- **Mark a question** — flag something that needs clarification before the ticket can proceed.
- **Signal a blocker** — record that a dependency is unresolved or that the ticket is waiting on an external action.
- **Trace decisions** — record why a particular choice was made, so future agents understand the context.

## Convention: `author` field

Use your agent name as the `author` value. Examples:

| Agent | author value |
|-------|-------------|
| Harvey (CEO) | `'Harvey'` |
| Carmack (dev) | `'Carmack'` |
| Halbert (marketing) | `'Halbert'` |
| Hopkins (analytics) | `'Hopkins'` |
| Generic Claude session | `'Claude'` |

## Best practice: read before you write

Always call `get_comments` before adding a new comment. If a note covering the same topic already exists, update your understanding from it rather than creating a duplicate.

## Tool reference

### `get_comments`

Retrieve all comments on a ticket.

```json
{
  "ticketId": "abc-123"
}
```

Returns an array of `TicketComment` objects:
```json
[
  {
    "id": "uuid",
    "author": "Harvey",
    "content": "This ticket needs a Definition of Done before grooming.",
    "createdAt": "2026-04-24T10:00:00.000Z"
  }
]
```

### `add_comment`

Post a new comment on a ticket (max 2000 characters).

```json
{
  "ticketId": "abc-123",
  "author": "Carmack",
  "content": "Blocked on API contract from the platform team — waiting for their OpenAPI spec."
}
```

Returns the created comment with its `id` and `createdAt` timestamp.

### `delete_comment`

Remove a comment by its id. Use this to clean up stale or resolved notes.

```json
{
  "ticketId": "abc-123",
  "commentId": "uuid-of-the-comment"
}
```

Returns `{ "success": true }`.

## Typical agent workflow

1. Call `get_board` to identify which ticket needs annotation.
2. Call `get_comments` on that ticket — check if a relevant note already exists.
3. If no relevant note exists, call `add_comment` with a concise, actionable message.
4. Once the blocker/question is resolved, call `delete_comment` to clean up.

## Liens directs vers un board

Quand tu crées ou modifies un board, envoie systématiquement deux liens :

```
Board prêt : mon-board

→ Desktop : whiteboard://board/mon-board
→ Mobile  : https://[tunnel-url]/view/mon-board
```

**Règle** : toujours envoyer les deux liens en même temps.
Le lien desktop ouvre directement l'app sur le bon board.
Le lien mobile ouvre la vue browser read-only (commentaires inclus).

Le nom du board est le même que celui utilisé dans `save_board` et `load_board`.

## Installation du companion sur Machine A

Quand un utilisateur te demande de configurer son serveur, exécute ces étapes sur ta machine (Machine A) :

### 1. Télécharger et lancer le companion

```bash
# Détecte l'architecture et télécharge le bon binaire
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
  BINARY="companion-macos-arm64"
elif [ "$(uname)" = "Linux" ]; then
  BINARY="companion-linux-x64"
else
  BINARY="companion-macos-x64"
fi
curl -L "https://github.com/palmthree-studio/whiteboard/releases/latest/download/$BINARY" -o companion
chmod +x companion
./companion &
```

### 2. Configurer le tunnel permanent

Option A — Tailscale Funnel :
```bash
tailscale funnel 3001
```
L'URL publique est affichée dans le terminal.

Option B — Cloudflare Tunnel :
```bash
cloudflared tunnel --url http://localhost:3001 run whiteboard
```

### 3. Donner l'URL à l'utilisateur

Envoie l'URL publique (ex: https://machine-a.taild12ab.ts.net) à l'utilisateur.
Il l'entre dans l'onboarding de son app Whiteboard.

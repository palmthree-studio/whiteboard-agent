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

Whiteboard est désormais une app web (le build Tauri a été retiré). Il n'y a plus de deep link `whiteboard://` — tous les boards s'ouvrent par URL HTTP.

Quand tu crées ou modifies un board, envoie un seul lien — l'URL publique du companion suivie du nom du board :

```
Board prêt : mon-board

→ https://[companion-url]/view/mon-board
```

`[companion-url]` est l'URL publique exposée par le companion (cf. section installation ci-dessous). Le nom du board est le même que celui utilisé dans `save_board` et `load_board`.

Pour récupérer cette URL côté agent : appeler `get_setup_info` sur le MCP — la réponse contient l'URL publique du companion.

## Installation du companion sur Machine A

Quand un utilisateur te demande de configurer son serveur, exécute ces étapes sur sa machine (Machine A) :

### 1. Installer et lancer le companion

```bash
npm install -g whiteboard-agent
wendy start
```

Le companion démarre sur `http://localhost:3001`. `wendy status` affiche l'URL en cours.

### 2. (Optionnel — PRO) Configurer une URL permanente

Pour exposer le companion derrière une URL stable, l'utilisateur doit avoir une licence PRO et un tunnel Cloudflare créé dans son dashboard (cf. `docs/cloudflare-tunnel.md`). Une fois le token récupéré :

```bash
wendy activate <license-key>
wendy configure-tunnel --token <token> --url whiteboard.yourdomain.com
```

Le companion est alors atteignable depuis n'importe où via `https://whiteboard.yourdomain.com`.

### 3. Donner l'URL à l'utilisateur

Envoie l'URL publique (locale `http://localhost:3001` ou la version tunnelée) à l'utilisateur.
Il l'entre dans l'onboarding de son app Whiteboard.

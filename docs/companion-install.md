# Installation du companion sur Machine A

Le companion est le serveur qui tourne sur la machine de l'agent (Machine A).

## Install via npm (recommended)

```bash
npm install -g whiteboard-agent
wendy start
```

That's it. The companion starts on `http://localhost:3001`.

Other commands:

```bash
wendy status                                         # check companion status + version
wendy stop                                           # stop the companion
wendy update                                         # re-download the latest binary
wendy activate <license-key>                         # activate a PRO licence on this machine
wendy deactivate                                     # deactivate the PRO licence on this machine
wendy configure-tunnel --token <token> --url <url>   # configure a permanent Cloudflare tunnel (PRO)
```

## Manual install (alternative)

### Téléchargement

```bash
# macOS Apple Silicon
curl -L https://github.com/palmthree-studio/whiteboard-agent/releases/latest/download/companion-macos-arm64 -o companion
chmod +x companion

# macOS Intel
curl -L https://github.com/palmthree-studio/whiteboard-agent/releases/latest/download/companion-macos-x64 -o companion
chmod +x companion

# Linux x64
curl -L https://github.com/palmthree-studio/whiteboard-agent/releases/latest/download/companion-linux-x64 -o companion
chmod +x companion
```

### Lancement

```bash
./companion
# Le companion démarre sur http://localhost:3001
```

## Lancement permanent (macOS)

```bash
# Avec pm2
npm install -g pm2
pm2 start ./companion --name whiteboard-companion
pm2 save
pm2 startup
```

## Variables d'environnement

- `PORT` : port d'écoute (défaut : 3001)
- `BOARDS_DIR` : dossier de stockage des boards (défaut : ~/.whiteboard/boards/)

## Agent tokens

To let multiple AI agents connect to the same companion, create a named token for each one from the **Agents** panel (gear icon) in the app.

See [Agent Tokens — Multi-agent Collaboration](./agents.md) for the full setup guide.

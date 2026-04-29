# Installation

## Prerequisites

- macOS or Linux (Windows not supported)
- `curl` available in your terminal
- `cloudflared` installed ([install guide](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/))

## Install

Run the install script:

```bash
curl -fsSL https://raw.githubusercontent.com/palmthree-studio/whiteboard-agent/main/install.sh | bash
```

The script:
1. Downloads the latest `companion` binary for your platform (macOS arm64, macOS x64, Linux x64)
2. Installs the `wendy` CLI
3. Walks you through setting a username and password for the companion
4. Generates a `whiteboard_agent.md` file with your connection details

Everything is installed to `~/.whiteboard-agent/`.

## What gets installed

| Path | Description |
|---|---|
| `~/.whiteboard-agent/companion` | The companion server binary |
| `~/.whiteboard-agent/wendy` | The Wendy CLI |
| `~/.whiteboard-agent/whiteboard_agent.md` | Your connection reference doc |

## After install

Run `wendy start` to launch the companion and open a tunnel. See the [Wendy CLI](wendy-cli.md) page for details.

## Update

To pull the latest companion binary at any time:

```bash
wendy update
```

This replaces only the companion binary. Your configuration is preserved.

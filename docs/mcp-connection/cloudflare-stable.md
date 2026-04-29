# MCP Connection — Cloudflare Stable Tunnel

A named Cloudflare tunnel gives you a permanent subdomain for the companion. The URL never changes across restarts. Set your client config once and forget it.

## Prerequisites

- A domain managed by Cloudflare (DNS must be on Cloudflare)
- A Cloudflare account (free tier is sufficient)
- `cloudflared` installed

## Setup

### 1. Authenticate cloudflared

```bash
cloudflared tunnel login
```

This opens a browser. Log in to your Cloudflare account and authorize.

### 2. Create a named tunnel

```bash
cloudflared tunnel create whiteboard
```

Note the tunnel UUID printed in the output.

### 3. Configure the tunnel

Create or edit `~/.cloudflared/config.yml`:

```yaml
tunnel: <your-tunnel-uuid>
credentials-file: /Users/<you>/.cloudflared/<your-tunnel-uuid>.json

ingress:
  - hostname: whiteboard.yourdomain.com
    service: http://localhost:3001
  - service: http_status:404
```

### 4. Add a DNS record

```bash
cloudflared tunnel route dns whiteboard whiteboard.yourdomain.com
```

### 5. Run the tunnel

```bash
cloudflared tunnel run whiteboard
```

To keep it running permanently, see [cloudflared system service](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/configure-tunnels/local-management/as-a-service/).

## Configuration by client

Replace `whiteboard.yourdomain.com` with your actual subdomain.

### Claude Desktop — `~/.config/claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "whiteboard": {
      "url": "https://whiteboard.yourdomain.com/mcp",
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
      "url": "https://whiteboard.yourdomain.com/mcp"
    }
  }
}
```

### Windsurf — `~/.codeium/windsurf/mcp_config.json`

```json
{
  "mcpServers": {
    "whiteboard": {
      "serverUrl": "https://whiteboard.yourdomain.com/mcp"
    }
  }
}
```

## Authentication

Open `https://whiteboard.yourdomain.com` in a browser and log in once. The session persists for 30 days.

# Cloudflare Tunnel — get your permanent URL

Whiteboard Agent needs a public HTTPS URL so your AI clients can reach the companion from anywhere. Cloudflare Tunnel is the recommended way to get one.

---

## Recommended — `wendy configure-tunnel`

The companion CLI does the entire setup in a single command. You just need a Cloudflare account, a tunnel created in the dashboard, and the token Cloudflare gives you.

### Prerequisites

1. A Cloudflare account with a domain attached. `.com` domains cost ~$10/year on Cloudflare Registrar; any registrar works as long as the domain is on Cloudflare's nameservers.
2. A tunnel created from the Cloudflare Zero Trust dashboard:
   - Go to **Zero Trust → Networks → Tunnels → Create a tunnel**.
   - Pick the **Cloudflared** connector type, give it a name (e.g. `whiteboard-agent`).
   - On the next screen, copy the **tunnel token** — it is a long string starting with `eyJ…`.
3. A subdomain you want to use (e.g. `whiteboard.yourdomain.com`). You can either configure the public hostname from the dashboard, or let `wendy` route it for you on first run.

### Run it

```bash
wendy configure-tunnel --token <token> --url whiteboard.yourdomain.com
```

That's it. `wendy` installs `cloudflared` if missing, writes the tunnel config, registers the route, and starts the tunnel as a background service. Your companion is now reachable at `https://whiteboard.yourdomain.com`.

This command requires a PRO licence (`wendy activate <license-key>`).

---

## Advanced — Manual setup

Skip this section unless you need fine-grained control over the tunnel config (custom ingress rules, multiple hostnames, non-default credentials path, etc.). For 99% of users, `wendy configure-tunnel` is enough.

### Step 1 — Install cloudflared

**macOS**
```bash
brew install cloudflare/cloudflare/cloudflared
```

**Linux**
```bash
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update && sudo apt install cloudflared
```

**Windows** — download the installer: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/

### Step 2 — Log in to Cloudflare

```bash
cloudflared login
```

A browser window opens. Select the domain you want to use (or add one — `.com` domains cost ~$10/year on Cloudflare Registrar).

### Step 3 — Create the tunnel

```bash
cloudflared tunnel create whiteboard-agent
```

This generates a credentials file and a tunnel ID. Note the tunnel ID printed in the output.

### Step 4 — Route your subdomain to the tunnel

Replace `whiteboard.yourdomain.com` with the subdomain you want.

```bash
cloudflared tunnel route dns whiteboard-agent whiteboard.yourdomain.com
```

### Step 5 — Create the config file

Replace `YOUR_TUNNEL_ID` and `whiteboard.yourdomain.com` accordingly.  
The companion runs on port **3001** by default.

```bash
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/config.yml << EOF
tunnel: YOUR_TUNNEL_ID
credentials-file: ~/.cloudflared/YOUR_TUNNEL_ID.json

ingress:
  - hostname: whiteboard.yourdomain.com
    service: http://localhost:3001
  - service: http_status:404
EOF
```

### Step 6 — Start the tunnel

```bash
cloudflared tunnel run whiteboard-agent
```

Your companion is now live at `https://whiteboard.yourdomain.com`. Use this URL during the install.

### Keep the tunnel running on startup

**macOS**
```bash
sudo cloudflared service install
sudo launchctl start com.cloudflare.cloudflared
```

**Linux (systemd)**
```bash
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

---

## No domain? Quick test (temporary URL)

If you just want to test without a domain, this gives you a temporary URL that changes on every restart:

```bash
cloudflared tunnel --url http://localhost:3001
```

The URL appears in the terminal output. It expires when the process stops.

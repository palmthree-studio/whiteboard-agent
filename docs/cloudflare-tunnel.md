# Cloudflare Tunnel — get your permanent URL

Whiteboard Agent needs a public HTTPS URL so your AI clients can reach the companion from anywhere.

---

## Step 1 — Install cloudflared

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

---

## Step 2 — Log in to Cloudflare

```bash
cloudflared login
```

A browser window opens. Select the domain you want to use (or add one — `.com` domains cost ~$10/year on Cloudflare Registrar).

---

## Step 3 — Create the tunnel

```bash
cloudflared tunnel create whiteboard-agent
```

This generates a credentials file and a tunnel ID. Note the tunnel ID printed in the output.

---

## Step 4 — Route your subdomain to the tunnel

Replace `whiteboard.yourdomain.com` with the subdomain you want.

```bash
cloudflared tunnel route dns whiteboard-agent whiteboard.yourdomain.com
```

---

## Step 5 — Create the config file

Replace `YOUR_TUNNEL_ID` and `whiteboard.yourdomain.com` accordingly.  
The companion runs on port **3210** by default.

```bash
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/config.yml << EOF
tunnel: YOUR_TUNNEL_ID
credentials-file: ~/.cloudflared/YOUR_TUNNEL_ID.json

ingress:
  - hostname: whiteboard.yourdomain.com
    service: http://localhost:3210
  - service: http_status:404
EOF
```

---

## Step 6 — Start the tunnel

```bash
cloudflared tunnel run whiteboard-agent
```

Your companion is now live at `https://whiteboard.yourdomain.com`. Use this URL during the install.

---

## Keep the tunnel running on startup

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
cloudflared tunnel --url http://localhost:3210
```

The URL appears in the terminal output. It expires when the process stops.

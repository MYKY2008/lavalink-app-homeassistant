# Lavalink — Home Assistant Addon

[![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)](https://github.com/MYKY2008/lavalink-app-homeassistant)
[![Architecture](https://img.shields.io/badge/arch-aarch64%20%7C%20amd64-lightgrey.svg)](https://github.com/MYKY2008/lavalink-app-homeassistant)
[![GHCR](https://img.shields.io/badge/docker-GHCR%20Prebuilt-success.svg)](https://github.com/MYKY2008/lavalink-app-homeassistant/pkgs/container/lavalink-app-homeassistant)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Standalone [Lavalink v4](https://github.com/lavalink-devs/Lavalink) audio server running as a native Home Assistant addon. Designed for Discord music bots hosted on external servers (e.g., Oracle Cloud, VPS) — takes advantage of your residential home IPv4 address to stream YouTube without datacenter IP blocks.

---

## Key Features

- ⚡ **Instant Installation & Updates** — Pre-built multi-arch Docker images hosted on GitHub Container Registry (GHCR). Installs/updates in seconds without compiling on your Home Assistant OS device.
- 💾 **Persistent Plugin Storage** — Plugins are saved to `/data/plugins`, so they are downloaded only once and persist across restarts and updates.
- 🎵 **YouTube Integration** — Configured for `lavalink-devs/youtube-source` plugin v1.18.2 with multi-client support (`MUSIC`, `ANDROID_VR`, `WEBEMBEDDED`, `MWEB`, `IOS`, `TVHTML5`).
- 🔑 **YouTube OAuth & PO-Token Support** — Full support for Google OAuth device auth and Proof of Origin (PO-Token) for advanced YouTube rate-limit bypass.
- 🎛️ **Full HA UI Configuration** — Every Lavalink setting is exposed in the addon Configuration tab.
- 🔒 **Isolated Networking** — Runs in Docker bridge network on port 2333.

---

## Installation

### 1. Add repository to Home Assistant

In Home Assistant: **Settings → Add-ons → Add-on Store → ⋮ (three dots) → Repositories**

Add the repository URL:
```
https://github.com/MYKY2008/lavalink-app-homeassistant
```

### 2. Install & Start

1. Find **Lavalink** in the store and click **Install** (takes < 10 seconds thanks to pre-built GHCR images).
2. Go to **Configuration** tab to review settings (or keep defaults).
3. Click **Start**.

Check the **Log** tab — you should see:
```text
=== Lavalink Addon v2.1.0 ===
Prepojene plugins ulozisko s /data/plugins
Generujem application.yml z HA konfiguracie...
Port: 2333 | Heap: 64m-256m | Log: INFO
Spustam Lavalink JVM...
...
Lavalink is ready to accept connections.
```

---

## 🌐 Setting up Domain / Reverse Proxy (`lavalink.myky.cz`)

Lavalink is an **API and WebSocket server** for Discord bots — it does **NOT** contain a web browser user interface (HTML page).

> ⚠️ **Important Browser Note:**
> If you visit `http://<IP>:2333` or `https://lavalink.myky.cz` in a web browser, it will return HTTP `401 Unauthorized` or `404 Not Found`. Cloudflare or Nginx Proxy Manager will display an error page (*"This website has a problem"* / 502 / 401). **This is completely normal and expected.**

### Connecting Discord Bot via Subdomain

To connect a Discord Music Bot (running on Oracle Cloud or anywhere else) via subdomains like `lavalink.myky.cz`:

#### Nginx / Nginx Proxy Manager Config
Ensure **WebSockets** are enabled on your proxy host.

```nginx
server {
    listen 80;
    server_name lavalink.myky.cz;

    location / {
        proxy_pass http://<HOME_ASSISTANT_LOCAL_IP>:2333;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Testing Connection via `curl`

To test if Lavalink is working over network:
```bash
curl -H "Authorization: hFb1XfbERVLgxuuHzZuHNqIX5vwqzN2D" http://<HOME_ASSISTANT_IP>:2333/version
```
Expected response:
```text
4.0.8
```

---

## Configuration Reference

| Option | Description | Default |
|---|---|---|
| `server_port` | Port Lavalink listens on | `2333` |
| `server_password` | Password for bot authentication | `hFb1XfbERVLgxuuHzZuHNqIX5vwqzN2D` |
| `jvm_max_heap_mb` | JVM maximum heap in MB | `256` |
| `jvm_min_heap_mb` | JVM initial heap in MB | `64` |
| `source_youtube` | Enable native YouTube source (keep `false` when using plugin) | `false` |
| `youtube_plugin_version` | Version of the youtube-source plugin | `1.18.2` |
| `youtube_clients` | Comma-separated list of YouTube InnerTube clients | `MUSIC,ANDROID_VR,WEBEMBEDDED,MWEB,IOS,TVHTML5` |
| `youtube_oauth_enabled` | Enable YouTube OAuth | `false` |
| `youtube_oauth_refresh_token` | OAuth refresh token after authorization | *(empty)* |
| `youtube_po_token` | Proof of Origin token (optional) | *(empty)* |
| `youtube_visitor_data` | Visitor Data for PO token (optional) | *(empty)* |
| `log_level` | Logging verbosity | `INFO` |

---

## Connecting Your Discord Bot (e.g., from Oracle Cloud)

Set these environment variables on your Discord Music Bot running on Oracle Cloud:

```bash
LAVALINK_HOST=lavalink.myky.cz   # Or your Home Assistant WAN IP / local IP
LAVALINK_PORT=2333               # Or 443 if proxied via SSL
LAVALINK_PASSWORD=hFb1XfbERVLgxuuHzZuHNqIX5vwqzN2D
LAVALINK_SECURE=false            # Set true if using https/wss
```

> **Why this works:** YouTube blocks Oracle Cloud IPs. When the bot delegates audio playback to Lavalink running on your Home Assistant OS, stream traffic originates from your home residential IPv4 connection.

---

## Changelog

### 2.1.0
- **Instant Installation & Updates:** Pre-built multi-arch Docker images (`amd64`, `aarch64`) published to GitHub Container Registry (GHCR).
- **Persistent Plugins Storage:** Plugins are now saved to `/data/plugins` and persist across container updates and restarts.
- **YouTube PO-Token Support:** Added `youtube_po_token` and `youtube_visitor_data` configuration options.
- **Updated YouTube Clients:** Set default clients to `MUSIC,ANDROID_VR,WEBEMBEDDED,MWEB,IOS,TVHTML5` for high reliability.
- **Documentation:** Added Nginx/Cloudflare reverse proxy & WebSocket configuration guide.

---

## License

MIT — see [LICENSE](LICENSE)

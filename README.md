# Lavalink — Home Assistant Addon

[![Version](https://img.shields.io/badge/version-2.0.4-blue.svg)](https://github.com/MYKY2008/lavalink-app-homeassistant)
[![Architecture](https://img.shields.io/badge/arch-aarch64%20%7C%20amd64-lightgrey.svg)](https://github.com/MYKY2008/lavalink-app-homeassistant)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Standalone [Lavalink v4](https://github.com/lavalink-devs/Lavalink) audio server running as a native Home Assistant addon. Designed for Discord music bots hosted on a separate server — takes advantage of your home IP address to stream YouTube without datacenter IP blocks.

---

## Features

- **Full HA UI configuration** — every Lavalink setting is exposed in the addon Configuration tab, no manual YAML editing required
- **YouTube plugin** — `youtube-source` plugin with multi-client support (MUSIC, ANDROID_VR, WEB, WEBEMBEDDED, TVHTML5_SIMPLY, MWEB, IOS)
- **Multi-source support** — YouTube, SoundCloud, Bandcamp, Twitch, Vimeo, HTTP streams
- **YouTube OAuth** — optional OAuth token support for datacenter IP bypass (not needed when running on home IP)
- **Isolated networking** — runs in Docker bridge network, port not exposed to internet without explicit router port-forward
- **Configurable JVM heap** — tune memory usage to fit your hardware
- **s6-overlay v3** — correct HA addon service lifecycle, clean startup/shutdown

---

## Installation

### 1. Add this repository to Home Assistant

In Home Assistant, go to:

**Settings → Add-ons → Add-on Store → ⋮ (three dots) → Repositories**

Add the following URL:

```
https://github.com/MYKY2008/lavalink-app-homeassistant
```

### 2. Install

After adding the repository, find **Lavalink** in the store and click **Install**.

> First build downloads `Lavalink.jar` (~100 MB) — takes 2–5 minutes depending on your connection.

### 3. Configure

Go to the **Configuration** tab and adjust settings as needed. All values have sensible defaults.

### 4. Start

Click **Start**. Check the **Log** tab — you should see:

```
=== Lavalink Addon v2.0.4 ===
Generujem application.yml z HA konfiguracie...
Port: 2333 | Heap: 64m-256m | Log: INFO
Spustam Lavalink JVM...
...
Lavalink is ready to accept connections.
```

---

## Configuration Reference

| Option | Description | Default |
|---|---|---|
| `server_port` | Port Lavalink listens on | `2333` |
| `server_password` | Password for bot authentication | `hFb1XfbERVLgxuuHzZuHNqIX5vwqzN2D` |
| `jvm_max_heap_mb` | JVM maximum heap in MB | `256` |
| `jvm_min_heap_mb` | JVM initial heap in MB | `64` |
| `source_youtube` | Enable native YouTube source (without plugin) | `false` |
| `source_soundcloud` | Enable SoundCloud source | `true` |
| `source_bandcamp` | Enable Bandcamp source | `true` |
| `source_twitch` | Enable Twitch source | `true` |
| `source_vimeo` | Enable Vimeo source | `true` |
| `source_http` | Enable direct HTTP stream URLs | `true` |
| `youtube_plugin_version` | Version of the youtube-source plugin | `1.18.2` |
| `youtube_clients` | Comma-separated list of YouTube InnerTube clients | `MUSIC,ANDROID_VR,WEB,...` |
| `youtube_oauth_enabled` | Enable YouTube OAuth (for datacenter IP bypass) | `false` |
| `youtube_oauth_refresh_token` | OAuth refresh token after authorization | *(empty)* |
| `buffer_duration_ms` | Audio buffer duration in ms | `400` |
| `frame_buffer_duration_ms` | Frame buffer duration in ms | `5000` |
| `player_update_interval` | Player state update interval in seconds | `5` |
| `youtube_playlist_load_limit` | Max pages when loading a YouTube playlist | `6` |
| `log_level` | Logging verbosity | `INFO` |

---

## Connecting Your Discord Bot

Set these environment variables on your bot server:

```bash
LAVALINK_HOST=192.168.1.x      # Your Home Assistant local IP
LAVALINK_PORT=2333
LAVALINK_PASSWORD=hFb1XfbERVLgxuuHzZuHNqIX5vwqzN2D
```

> **Home IP = YouTube works without restrictions.** Leave `youtube_oauth_enabled` set to `false`.

If your bot runs on a **datacenter IP** (Oracle Cloud, VPS, etc.) and YouTube blocks it:

1. Set `youtube_oauth_enabled: true`, leave `youtube_oauth_refresh_token` empty
2. Restart the addon
3. In the **Log** tab, find the activation URL + code:
   ```
   Please visit https://www.google.com/device  Code: XXXX-XXXX
   ```
4. Open the link in a browser, sign in with a **burner Google account**
5. Copy the printed `refreshToken` into the Configuration tab
6. Restart the addon

---

## Changing the Port

1. In **Configuration**, change `server_port` to the desired number
2. In the **Network** section of the addon page, update the port mapping to match
3. **Restart** the addon
4. Update `LAVALINK_PORT` on your bot accordingly

---

## Security

- Runs in an **isolated Docker bridge network** — `host_network: false`
- Port 2333 is only accessible within your **local network** by default
- No access to Home Assistant Core API or Supervisor API
- Password is configured through HA UI, never stored in source files
- JVM heap is capped to prevent memory pressure on your HA instance

---

## Requirements

- Home Assistant OS or Supervised installation
- Architecture: `amd64` or `aarch64`
- At least **512 MB free RAM** (Lavalink uses ~150–200 MB in steady state)

---

## Changelog

### 2.0.4
- Updated default `youtube_plugin_version` to `1.18.2` (1.18.1 deprecated)

### 2.0.3
- Fixed `s6-rc-compile: invalid type` — all s6-overlay `type`, `up`, `run`, `finish` files now guaranteed LF endings
- Fixed `s6-envdir: unable to envdir /run/s6/container_environment` — `lavalink-config/up` uses execline `foreground`
- Added `.gitattributes` to enforce LF on all future pushes from Windows
- Rewritten to correct **s6-overlay v3** service structure (`rootfs/etc/s6-overlay/`)
- Fixed `with-contenv` path error causing exit code 111
- `generate_config.sh` runs as s6 oneshot before JVM starts
- Removed deprecated `armv7` architecture

### 2.0.2
- Added `dos2unix` to Dockerfile as secondary CRLF guard

### 2.0.1
- Added `dos2unix` to Dockerfile to fix CRLF line endings on Windows-copied files

### 2.0.0
- Full HA UI configurator — all Lavalink settings exposed as addon options
- Dynamic `application.yml` generation at runtime from addon config
- Configurable JVM heap, sources, YouTube clients, OAuth, log level

### 1.0.0
- Initial release

---

## License

MIT — see [LICENSE](LICENSE)

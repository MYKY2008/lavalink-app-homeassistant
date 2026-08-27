# Lavalink Addon pre Home Assistant

Lavalink v4 audio server pre Discord music boty. Všetky nastavenia
meníš priamo v HA UI — žiadne YAML ručne.

---

## Inštalácia

### 1. Skopíruj addon súbory na HA

Cez **Samba** addon (odporúčané):
- Pripoj sa na `\\homeassistant.local\addons` (Windows) alebo `smb://homeassistant.local/addons` (Mac)
- Skopíruj celý priečinok `ha-addon-lavalink` ako `/addons/lavalink`

Výsledná štruktúra:
```
/addons/lavalink/
  ├── config.yaml
  ├── Dockerfile
  ├── run.sh
  └── DOCS.md
```

### 2. Nainštaluj v HA

1. **Settings → Add-ons → Add-on Store**
2. Klikni **⋮ (tri bodky)** vpravo hore → **Check for updates**
3. Obnov stránku — v sekcii **"Local add-ons"** uvidíš **Lavalink**
4. Klikni → **Install**

> Prvý build stiahne Lavalink.jar (~100 MB) — môže trvať 1-2 minúty.

### 3. Nakonfiguruj (záložka Configuration)

Všetky hodnoty meníš v HA UI — žiadne súbory:

| Možnosť | Popis | Default |
|---|---|---|
| `server_port` | Port na ktorom Lavalink počúva | `2333` |
| `server_password` | Heslo pre pripojenie bota | `hFb1XfbERVLgxuuHzZuHNqIX5vwqzN2D` |
| `jvm_max_heap_mb` | Max RAM pre JVM v MB | `256` |
| `jvm_min_heap_mb` | Štartovacia RAM pre JVM v MB | `64` |
| `source_youtube` | Natívny YT zdroj (bez pluginu) | `false` |
| `source_soundcloud` | SoundCloud zdroj | `true` |
| `source_bandcamp` | Bandcamp zdroj | `true` |
| `source_twitch` | Twitch zdroj | `true` |
| `source_vimeo` | Vimeo zdroj | `true` |
| `source_http` | Priame HTTP stream URL | `true` |
| `youtube_plugin_version` | Verzia youtube-plugin JAR | `1.18.1` |
| `youtube_clients` | YT klienti oddelení čiarkou | `MUSIC,ANDROID_VR,WEB,...` |
| `youtube_oauth_enabled` | OAuth autorizácia (datacenter IP) | `false` |
| `youtube_oauth_refresh_token` | OAuth token po autorizácii | *(prázdne)* |
| `buffer_duration_ms` | Audio buffer v ms | `400` |
| `frame_buffer_duration_ms` | Frame buffer v ms | `5000` |
| `player_update_interval` | Interval update správ (s) | `5` |
| `youtube_playlist_load_limit` | Max stránok pri načítaní YT playlistu | `6` |
| `log_level` | Úroveň logovania | `INFO` |

### 4. Spusti

Klikni **Start**. V záložke **Log** uvidíš:
```
Lavalink Addon v2.0.0
Port: 2333
...
Lavalink is ready to accept connections.
```

---

## Pripojenie Discord bota

Na Oracle Cloud (alebo iný server) nastav env premenné:

```bash
LAVALINK_HOST=192.168.1.x    # IP tvojho HA v lokálnej sieti
LAVALINK_PORT=2333
LAVALINK_PASSWORD=hFb1XfbERVLgxuuHzZuHNqIX5vwqzN2D
```

Alebo ak bot beží na rovnakom stroji ako HA:
```bash
LAVALINK_HOST=localhost
```

> **Domáca IP = YouTube funguje bez obmedzení.** `youtube_oauth_enabled` nechaj `false`.

---

## Zmena portu

1. V **Configuration** zmeň `server_port` na požadované číslo (napr. `2334`)
2. V **Configuration** zmeň aj port v sekcii **Network** (HA zobrazí GUI pre port mapping)
3. **Reštartuj** addon
4. Aktualizuj `LAVALINK_PORT` env premennú na bote

---

## Bezpečnosť

- Addon beží v **izolovanom Docker bridge networku** (`host_network: false`)
- Port je dostupný len v **lokálnej sieti** — bez router port-forwardu internet ho nevidí
- Addon nemá prístup k HA Core API ani Supervisor API
- Heslo nastavuj priamo v HA UI, nie v súboroch

---

## Riešenie problémov

**"Local add-ons" sa neobjaví:**
Skontroluj Settings → System → Logs → vyber "Supervisor" — tam bude YAML chyba.

**Addon sa nespustí / JVM crash:**
Zvýš `jvm_max_heap_mb` (skús 512). Lavalink potrebuje ~150-200 MB v steady state.

**Bot sa nevie pripojiť:**
- Skontroluj IP HA v lokálnej sieti (Settings → System → Network)
- Skontroluj či heslo v bote = heslo v addon Configuration
- Skontroluj či port súhlasí

**YouTube blokuje (ak bot beží na datacenter IP):**
Zapni `youtube_oauth_enabled: true`, nechaj `youtube_oauth_refresh_token` prázdny,
reštartuj — v logoch nájdeš aktivačný link + kód. Po autorizácii vlož token a reštartuj znova.

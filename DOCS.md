# Lavalink Addon pre Home Assistant

Lavalink v4 audio server pre Discord music boty (napr. na Oracle Cloud). Všetky nastavenia upravuješ pohodlne cez HA UI.

---

## Inštalácia pomocou Add-on Store

### 1. Pridanie repozitára do HA
V Home Assistant prejdi do:
**Nastavenia (Settings) → Doplnky (Add-ons) → Obchod s doplnkami (Add-on Store) → ⋮ (tri bodky vpravo hore) → Repozitáre (Repositories)**

Vlož URL:
```text
https://github.com/MYKY2008/lavalink-app-homeassistant
```

### 2. Inštalácia
1. V obchode s doplnkami vyhľadaj **Lavalink**.
2. Klikni **Inštalovať** (díky predpripraveným GHCR Docker obrazom inštalácia trvá iba pár sekúnd).
3. V záložke **Konfigurácia (Configuration)** skontroluj nastavenia.
4. Klikni **Spustiť (Start)**.

---

## Ako funguje doména / poddoména (`lavalink.myky.cz`)

Lavalink **nie je webstránka s rozhraním pre prehliadač**. Je to backend API server pre Discord botov.

> ⚠️ **Prečo prehliadač zobrazuje "This website has a problem" alebo HTTP 401/404?**
> Ak otvoríš `http://<IP>:2333` alebo `https://lavalink.myky.cz` vo webovom prehliadači (Chrome, Firefox, Brave), server vráti kód `401 Unauthorized` (pretože prehliadač neposiela heslo v hlavičke). Reverse proxy (ako Cloudflare alebo Nginx Proxy Manager) vtedy zobrazí svoju chybovú stránku. **To je normálne a správne správanie backendu.**

### Nastavenie Nginx Proxy Manager / Reverse Proxy
Pre správne fungovanie pripojenia Discord bota cez subdoménu `lavalink.myky.cz`:

1. V Nginx Proxy Manager / Cloudflare Tunnel nastav smerovanie na IP vášho Home Assistant a port `2333`.
2. **Uisti sa, že sú zapnuté WebSockets** (`Websockets Support` v NPM).

Príklad pre Nginx:
```nginx
location / {
    proxy_pass http://192.168.1.X:2333;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host $host;
}
```

### Overenie funkčnosti servera cez `curl`
V termináli môžeš overiť, že Lavalink beží a odpovedá:
```bash
curl -H "Authorization: hFb1XfbERVLgxuuHzZuHNqIX5vwqzN2D" http://192.168.1.X:2333/version
```
Odpoveď vráti verziu Lavalinku (napr. `4.0.8`).

---

## Prepojenie Discord Bota (Oracle Cloud -> Domáci HA)

Keď bot beží na Oracle Cloud a Lavalink doma na Home Assistant OS:

V konfigurácii bota (environment premenné alebo config súbor bota):
```bash
LAVALINK_HOST=lavalink.myky.cz     # alebo tvoja domáca IPv4 adresa
LAVALINK_PORT=2333                 # alebo 443 ak používaš HTTPS/WSS proxy
LAVALINK_PASSWORD=hFb1XfbERVLgxuuHzZuHNqIX5vwqzN2D
LAVALINK_SECURE=false              # nastav true pri wss:// (HTTPS)
```

**Výhoda:** Všetok audio stream z YouTube ide cez tvoju domácu rezidenčnú prípojku (IPv4), čím sa úplne vyhneš blokáciám YouTube pre datacentrá (Oracle Cloud, AWS atď.).

---

## Konfiguračné možnosti (Configuration Tab)

| Možnosť | Popis | Default |
|---|---|---|
| `server_port` | Port na ktorom Lavalink počúva | `2333` |
| `server_password` | Heslo pre pripojenie bota | `hFb1XfbERVLgxuuHzZuHNqIX5vwqzN2D` |
| `jvm_max_heap_mb` | Max RAM pre JVM v MB | `256` |
| `jvm_min_heap_mb` | Štartovacia RAM pre JVM v MB | `64` |
| `source_youtube` | Natívny YT zdroj (ponechaj `false` pri použití pluginu) | `false` |
| `youtube_plugin_version` | Verzia dev.lavalink.youtube pluginu | `1.18.2` |
| `youtube_clients` | YT InnerTube klienti | `MUSIC,ANDROID_VR,WEBEMBEDDED,MWEB,IOS,TVHTML5` |
| `youtube_oauth_enabled` | YouTube Google OAuth autorizácia | `false` |
| `youtube_oauth_refresh_token` | OAuth refresh token | *(prázdne)* |
| `youtube_po_token` | Proof of Origin token (voliteľné) | *(prázdne)* |
| `youtube_visitor_data` | Visitor Data pre PO token (voliteľné) | *(prázdne)* |
| `log_level` | Úroveň logovania | `INFO` |

---

## Trvalé úložisko pre Plugin (Persistent Storage)

Všetky stiahnuté plugin súbory sa ukladajú do `/data/plugins`. Pri reštarte alebo aktualizácii addonu sa plugin nemusí znova sťaahovať z internetu, čo urýchľuje štart na minimum.

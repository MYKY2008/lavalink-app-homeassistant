#!/command/with-contenv bashio
# ==============================================================================
# Generuje application.yml z HA addon options
# Spusta sa ako s6 oneshot pred Lavalink JVM
# ==============================================================================
set -e

CONFIG_FILE="/opt/lavalink/application.yml"

bashio::log.info "=== Lavalink Addon v3.2.0 ==="

# --- Zabezpec trvale ulozisko pre plugins ---
mkdir -p /data/plugins
if [ ! -L /opt/lavalink/plugins ]; then
    rm -rf /opt/lavalink/plugins
    ln -s /data/plugins /opt/lavalink/plugins
    bashio::log.info "Prepojene plugins ulozisko s /data/plugins"
fi

bashio::log.info "Generujem application.yml z HA konfiguracie..."

# --- Nacitaj options ---
SERVER_PORT=$(bashio::config 'server_port' '2333')
SERVER_PASSWORD=$(bashio::config 'server_password' 'hFb1XfbERVLgxuuHzZuHNqIX5vwqzN2D')
JVM_MAX=$(bashio::config 'jvm_max_heap_mb' '512')
JVM_MIN=$(bashio::config 'jvm_min_heap_mb' '256')
LOG_LEVEL=$(bashio::config 'log_level' 'INFO')
YT_PLUGIN=$(bashio::config 'youtube_plugin_version' '1.18.2')
YT_OAUTH=$(bashio::config 'youtube_oauth_enabled' 'false')
YT_TOKEN=$(bashio::config 'youtube_oauth_refresh_token' '')
YT_POTOKEN=$(bashio::config 'youtube_po_token' '')
YT_VISITOR=$(bashio::config 'youtube_visitor_data' '')
YT_CIPHER_URL=$(bashio::config 'youtube_remote_cipher_url' 'https://cipher.kikkia.dev/')
YT_CLIENTS=$(bashio::config 'youtube_clients' 'MUSIC,TV,WEBEMBEDDED,ANDROID_VR,MWEB,WEB')
SRC_YT=$(bashio::config 'source_youtube' 'false')
SRC_SC=$(bashio::config 'source_soundcloud' 'true')
SRC_BC=$(bashio::config 'source_bandcamp' 'true')
SRC_TW=$(bashio::config 'source_twitch' 'true')
SRC_VI=$(bashio::config 'source_vimeo' 'true')
SRC_HT=$(bashio::config 'source_http' 'true')
BUFFER=$(bashio::config 'buffer_duration_ms' '400')
FBUFFER=$(bashio::config 'frame_buffer_duration_ms' '5000')
PUPDATE=$(bashio::config 'player_update_interval' '5')
YTLIMIT=$(bashio::config 'youtube_playlist_load_limit' '6')

bashio::log.info "Port: ${SERVER_PORT} | Heap: ${JVM_MIN}m-${JVM_MAX}m | Log: ${LOG_LEVEL}"

# --- Konvertuj CSV klientov na YAML ---
YT_CLIENTS_YAML=""
OLD_IFS="$IFS"
IFS=','
for c in $YT_CLIENTS; do
    c=$(echo "$c" | tr -d '[:space:]')
    [ -n "$c" ] && YT_CLIENTS_YAML="${YT_CLIENTS_YAML}      - ${c}"$'\n'
done
IFS="$OLD_IFS"
[ -z "$YT_CLIENTS_YAML" ] && YT_CLIENTS_YAML="      - MUSIC"$'\n'"      - TV"$'\n'"      - WEBEMBEDDED"$'\n'"      - ANDROID_VR"$'\n'"      - MWEB"$'\n'"      - WEB"$'\n'

# --- OAuth blok ---
if [ "${YT_OAUTH}" = "true" ]; then
    if [ -n "${YT_TOKEN}" ] && [ "${YT_TOKEN}" != "null" ] && [ "${YT_TOKEN}" != "" ]; then
        OAUTH_YAML="    oauth:"$'\n'"      enabled: true"$'\n'"      refreshToken: \"${YT_TOKEN}\""
    else
        OAUTH_YAML="    oauth:"$'\n'"      enabled: true"
    fi
else
    OAUTH_YAML="    oauth:"$'\n'"      enabled: false"
fi

# --- PO Token blok ---
POT_YAML=""
if [ -n "${YT_POTOKEN}" ] && [ "${YT_POTOKEN}" != "null" ] && [ "${YT_POTOKEN}" != "" ]; then
    POT_YAML=$'\n'"    pot:"$'\n'"      token: \"${YT_POTOKEN}\""
    if [ -n "${YT_VISITOR}" ] && [ "${YT_VISITOR}" != "null" ] && [ "${YT_VISITOR}" != "" ]; then
        POT_YAML="${POT_YAML}"$'\n'"      visitorData: \"${YT_VISITOR}\""
    fi
fi

# --- Remote Cipher blok ---
CIPHER_YAML=""
if [ -n "${YT_CIPHER_URL}" ] && [ "${YT_CIPHER_URL}" != "null" ] && [ "${YT_CIPHER_URL}" != "" ]; then
    CIPHER_YAML=$'\n'"    remoteCipher:"$'\n'"      url: \"${YT_CIPHER_URL}\""
fi

# --- Spotify / LavaSrc options ---
SPOTIFY_ENABLED=$(bashio::config 'spotify_enabled' 'false')
SPOTIFY_CLIENT_ID=$(bashio::config 'spotify_client_id' '')
SPOTIFY_CLIENT_SECRET=$(bashio::config 'spotify_client_secret' '')
SPOTIFY_COUNTRY_CODE=$(bashio::config 'spotify_country_code' 'SK')

# --- LavaSrc Plugin blok ---
LAVASRC_PLUGIN_YAML=""
LAVASRC_CONFIG_YAML=""
if [ "${SPOTIFY_ENABLED}" = "true" ] || [ -n "${SPOTIFY_CLIENT_ID}" ]; then
    bashio::log.info "Pripajam plugin LavaSrc (Spotify / Deezer)..."
    LAVASRC_PLUGIN_YAML=$'\n'"    - dependency: \"com.github.topi314.lavasrc:lavasrc-plugin:4.4.1\""$'\n'"      repository: \"https://maven.lavalink.dev/releases\""$'\n'"      snapshot: false"
    LAVASRC_CONFIG_YAML=$'\n'"  lavasrc:"$'\n'"    providers:"$'\n'"      - \"ytmsearch:\\\"%ISRC%\\\"\""$'\n'"      - \"ytmsearch:%QUERY%\""$'\n'"      - \"ytsearch:\\\"%ISRC%\\\"\""$'\n'"      - \"ytsearch:%QUERY%\""$'\n'"    sources:"$'\n'"      spotify: true"$'\n'"      applemusic: false"$'\n'"      deezer: true"$'\n'"      yandexmusic: false"$'\n'"      flowerytts: false"$'\n'"      youtube: false"
    if [ -n "${SPOTIFY_CLIENT_ID}" ] && [ "${SPOTIFY_CLIENT_ID}" != "null" ]; then
        LAVASRC_CONFIG_YAML="${LAVASRC_CONFIG_YAML}"$'\n'"    spotify:"$'\n'"      clientId: \"${SPOTIFY_CLIENT_ID}\""$'\n'"      clientSecret: \"${SPOTIFY_CLIENT_SECRET}\""$'\n'"      countryCode: \"${SPOTIFY_COUNTRY_CODE}\""$'\n'"      playlistLoadLimit: 6"$'\n'"      albumLoadLimit: 6"
    fi
fi

# --- Generuj application.yml ---
cat > "${CONFIG_FILE}" <<EOF
server:
  port: ${SERVER_PORT}
  address: 0.0.0.0

lavalink:
  plugins:
    - dependency: "dev.lavalink.youtube:youtube-plugin:${YT_PLUGIN}"
      snapshot: false${LAVASRC_PLUGIN_YAML}
  server:
    password: "${SERVER_PASSWORD}"
    sources:
      youtube: ${SRC_YT}
      bandcamp: ${SRC_BC}
      soundcloud: ${SRC_SC}
      twitch: ${SRC_TW}
      vimeo: ${SRC_VI}
      http: ${SRC_HT}
      local: false
    filters:
      volume: true
    bufferDurationMs: ${BUFFER}
    frameBufferDurationMs: ${FBUFFER}
    youtubePlaylistLoadLimit: ${YTLIMIT}
    playerUpdateInterval: ${PUPDATE}
    youtubeSearchEnabled: true
    soundcloudSearchEnabled: true

plugins:
  youtube:
    enabled: true
    allowSearch: true
    allowDirectVideoIds: true
    allowDirectPlaylistIds: true
    clients:
${YT_CLIENTS_YAML}${OAUTH_YAML}${POT_YAML}${CIPHER_YAML}${LAVASRC_CONFIG_YAML}

metrics:
  prometheus:
    enabled: false

sentry:
  dsn: ""

logging:
  level:
    root: ${LOG_LEVEL}
    lavalink: ${LOG_LEVEL}
    dev.lavalink.youtube.http.YoutubeOauth2Handler: INFO
EOF

bashio::log.info "application.yml vygenerovany OK"

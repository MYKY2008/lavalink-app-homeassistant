#!/command/with-contenv bashio
# ==============================================================================
# Generuje application.yml z HA addon options
# Spusta sa ako s6 oneshot pred Lavalink JVM
# ==============================================================================
set -e

CONFIG_FILE="/opt/lavalink/application.yml"

bashio::log.info "=== Lavalink Addon v2.6.0 ==="

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
JVM_MAX=$(bashio::config 'jvm_max_heap_mb' '256')
JVM_MIN=$(bashio::config 'jvm_min_heap_mb' '64')
LOG_LEVEL=$(bashio::config 'log_level' 'INFO')
YT_PLUGIN=$(bashio::config 'youtube_plugin_version' '1.18.2')
YT_OAUTH=$(bashio::config 'youtube_oauth_enabled' 'false')
YT_TOKEN=$(bashio::config 'youtube_oauth_refresh_token' '')
YT_POTOKEN=$(bashio::config 'youtube_po_token' '')
YT_VISITOR=$(bashio::config 'youtube_visitor_data' '')
YT_CIPHER_URL=$(bashio::config 'youtube_remote_cipher_url' 'https://cipher.kikkia.dev/')
YT_CLIENTS=$(bashio::config 'youtube_clients' 'MUSIC,TVHTML5,TV,WEB,ANDROID_MUSIC,ANDROID_VR,WEBEMBEDDED,MWEB,IOS,TVHTML5_SIMPLY')
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
[ -z "$YT_CLIENTS_YAML" ] && YT_CLIENTS_YAML="      - MUSIC"$'\n'"      - TVHTML5"$'\n'"      - TV"$'\n'"      - WEB"$'\n'"      - ANDROID_MUSIC"$'\n'"      - ANDROID_VR"$'\n'"      - WEBEMBEDDED"$'\n'"      - MWEB"$'\n'"      - IOS"$'\n'"      - TVHTML5_SIMPLY"$'\n'

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

# --- Generuj application.yml ---
cat > "${CONFIG_FILE}" <<EOF
server:
  port: ${SERVER_PORT}
  address: 0.0.0.0

lavalink:
  plugins:
    - dependency: "dev.lavalink.youtube:youtube-plugin:${YT_PLUGIN}"
      snapshot: false
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
${YT_CLIENTS_YAML}${OAUTH_YAML}${POT_YAML}${CIPHER_YAML}

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

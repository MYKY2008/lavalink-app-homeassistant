ARG BUILD_FROM=ghcr.io/home-assistant/base:latest
FROM ${BUILD_FROM}

# Java 17 + curl + dos2unix
RUN apk add --no-cache \
    openjdk17-jre-headless \
    curl \
    ca-certificates \
    dos2unix

ARG LAVALINK_VERSION=4.0.8

WORKDIR /opt/lavalink

# Stiahni Lavalink.jar pocas buildu
RUN curl -fsSL \
    "https://github.com/lavalink-devs/Lavalink/releases/download/${LAVALINK_VERSION}/Lavalink.jar" \
    -o Lavalink.jar

# Vytvor slozku pre plugins (bude prepojena s /data/plugins pre ukladanie na trvale ulozisko)
RUN mkdir -p /opt/lavalink/plugins /data/plugins

# Skopiruj celu rootfs strukturu (s6-overlay services + skripty)
COPY rootfs/ /

# Garantovane LF endings a spravne permissions pre vsetky skripty
RUN find /etc/s6-overlay /opt/lavalink -name "run" -o -name "finish" -o -name "*.sh" 2>/dev/null | \
    xargs -r dos2unix && \
    find /etc/s6-overlay -name "run" -o -name "finish" 2>/dev/null | \
    xargs -r chmod +x && \
    chmod +x /opt/lavalink/generate_config.sh 2>/dev/null || true

EXPOSE 2333

LABEL org.opencontainers.image.source="https://github.com/MYKY2008/lavalink-app-homeassistant"

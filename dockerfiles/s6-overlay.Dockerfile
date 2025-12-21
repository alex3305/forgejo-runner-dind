FROM base

ARG TARGETARCH
ARG TARGETOS
ARG S6_OVERLAY_VERSION

RUN S6_TARGETARCH=$(case ${TARGETARCH} in \
        "amd64")   echo "x86_64"  ;; \
        "arm64")   echo "aarch64" ;; \
        "arm/v7")  echo "arm"     ;; \
        "arm/v6")  echo "armhf"   ;; \
    esac) && \
    \
    S6_NOARCH_FILENAME="s6-overlay-noarch.tar.xz" && \
    S6_TARGETARCH_FILENAME="s6-overlay-${S6_TARGETARCH}.tar.xz" && \
    \
    S6_NOARCH_DOWNLOAD_URL="https://www.github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/${S6_NOARCH_FILENAME}" && \
    S6_TARGETARCH_DOWNLOAD_URL="https://www.github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/${S6_TARGETARCH_FILENAME}" && \
    \
    cd /tmp && \
    \
    echo "Downloading S6 Overlay (no-arch) from ${S6_NOARCH_DOWNLOAD_URL}..." && \
    curl -LO "${S6_NOARCH_DOWNLOAD_URL}" && \
    \
    echo "Downloading S6 Overlay (no-arch) checksum from ${S6_NOARCH_DOWNLOAD_URL}.sha256..." && \
    curl -LO "${S6_NOARCH_DOWNLOAD_URL}.sha256" && \
    \
    echo "Downloading S6 Overlay (${S6_TARGETARCH}) from ${S6_TARGETARCH_DOWNLOAD_URL}..." && \
    curl -LO "${S6_TARGETARCH_DOWNLOAD_URL}" && \
    \
    echo "Downloading S6 Overlay (${S6_TARGETARCH}) checksum from ${S6_TARGETARCH_DOWNLOAD_URL}.sha256..." && \
    curl -LO "${S6_TARGETARCH_DOWNLOAD_URL}.sha256" && \
    \
    echo "Verifying S6 Overlay checksums..." && \
    sha256sum -c "${S6_NOARCH_FILENAME}.sha256" "${S6_TARGETARCH_FILENAME}.sha256" && \
    \
    mkdir -p /s6 && \
    tar -C /s6 -Jxpf "/tmp/${S6_NOARCH_FILENAME}" && \
    tar -C /s6 -Jxpf "/tmp/${S6_TARGETARCH_FILENAME}"

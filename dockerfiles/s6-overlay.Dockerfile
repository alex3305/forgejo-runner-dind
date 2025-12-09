FROM base AS s6-overlay

ARG TARGETARCH

# renovate: datasource=github-releases depName=s6-overlay packageName=just-containers/s6-overlay
ARG S6_OVERLAY_VERSION=3.2.1.0

RUN S6_TARGETARCH=$(case ${TARGETARCH} in \
        "amd64")   echo "x86_64"  ;; \
        "arm64")   echo "aarch64" ;; \
        "arm/v7")  echo "arm"     ;; \
        "arm/v6")  echo "armhf"   ;; \
    esac) && \
    \
    curl -Lo /tmp/s6-overlay-noarch.tar.xz \
         https://www.github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz \
         && \
    curl -Lo /tmp/s6-overlay-${S6_TARGETARCH}.tar.xz \
         https://www.github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_TARGETARCH}.tar.xz \
         && \
    \
    mkdir -p /s6 && \
    tar -C /s6 -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C /s6 -Jxpf /tmp/s6-overlay-${S6_TARGETARCH}.tar.xz

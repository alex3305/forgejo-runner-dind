FROM alpine:3.22.0 AS docker

# renovate: datasource=github-releases depName=moby packageName=moby/moby
ARG DOCKER_VERSION=28.3.2

ARG TARGETARCH
ARG TARGETOS

RUN DOCKER_TARGETARCH=$(case ${TARGETARCH} in \
        "amd64")   echo "x86_64"  ;; \
        "arm64")   echo "aarch64" ;; \
        "arm/v7")  echo "armel"   ;; \
        "arm/v6")  echo "armhf"   ;; \
    esac) && \
    \
    wget https://download.docker.com/${TARGETOS}/static/stable/${DOCKER_TARGETARCH}/docker-${DOCKER_VERSION}.tgz \
         -O /tmp/docker.tgz && \
    wget https://download.docker.com/${TARGETOS}/static/stable/${DOCKER_TARGETARCH}/docker-rootless-extras-${DOCKER_VERSION}.tgz \
         -O /tmp/docker-rootless-extras.tgz && \
    \
    mkdir -p /docker && \
    tar -xvzf /tmp/docker.tgz -C /docker --strip-components 1 && \
    tar -xvzf /tmp/docker-rootless-extras.tgz -C /docker --strip-components 1


FROM alpine:3.22.0 AS forgejo-runner

# renovate: datasource=gitea-releases depName=forgejo-runner packageName=forgejo/runner registryUrl=https://code.forgejo.org/
ARG FORGEJO_RUNNER_VERSION=6.4.0

ARG TARGETARCH
ARG TARGETOS

RUN ACT_TARGETARCH=$(case ${TARGETARCH} in \
        "amd64")   echo "amd64"  ;; \
        "arm64")   echo "arm64" ;; \
    esac) && \
    \
    mkdir -p /act && \
    wget https://code.forgejo.org/forgejo/runner/releases/download/v${FORGEJO_RUNNER_VERSION}/forgejo-runner-${FORGEJO_RUNNER_VERSION}-${TARGETOS}-${ACT_TARGETARCH} \
         -O /act/forgejo-runner


FROM alpine:3.22.0 AS s6-overlay

# renovate: datasource=github-releases depName=s6-overlay packageName=just-containers/s6-overlay
ARG S6_OVERLAY_VERSION=3.2.1.0

ARG TARGETARCH

RUN S6_TARGETARCH=$(case ${TARGETARCH} in \
        "amd64")   echo "x86_64"  ;; \
        "arm64")   echo "aarch64" ;; \
        "arm/v7")  echo "arm"     ;; \
        "arm/v6")  echo "armhf"   ;; \
    esac) && \
    \
    wget https://www.github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz \
         -O /tmp/s6-overlay-noarch.tar.xz && \
    wget https://www.github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_TARGETARCH}.tar.xz \
         -O /tmp/s6-overlay-${S6_TARGETARCH}.tar.xz && \
    \
    mkdir -p /s6 && \
    tar -C /s6 -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C /s6 -Jxpf /tmp/s6-overlay-${S6_TARGETARCH}.tar.xz


FROM alpine:3.22.0

# Setup Rootless user
ENV UID=1000
RUN adduser -h /home/rootless -g 'Rootless' -D -u ${UID} rootless

# Add Rootless Docker in Docker from build stage
COPY --from=docker \
     --chown=root:rootless \
     --chmod=0750 \
     /docker /usr/local/bin/

# Add Forgejo Runner from build stage
COPY --from=forgejo-runner \
     --chown=root:rootless \
     --chmod=0750 \
     /act/forgejo-runner /usr/local/bin/

# Add S6 Overlay from build stage
COPY --from=s6-overlay \
     --chown=root:rootless \
     /s6 /

# Add S6 Configuration
COPY --chown=root:rootless \
     --chmod=0750 \
     root/ /

RUN apk add --no-cache bash \
                       curl \
                       fuse-overlayfs \
                       git \
                       iproute2 \
                       iptables \
                       openssl \
                       pigz \
                       shadow-uidmap \
                       xz && \
    \
    addgroup -g 2375 -S docker && \
    \
    addgroup -S dockremap && \
    adduser -H -S -G dockremap dockremap && \
    echo 'dockremap:165536:65536' >> /etc/subuid && \
    echo 'dockremap:165536:65536' >> /etc/subgid && \
    \
    addgroup rootless docker && \
    echo 'rootless:100000:65536' >> /etc/subuid && \
    echo 'rootless:100000:65536' >> /etc/subgid && \
    \
    mkdir -p /config \
             /home/rootless/.local/share/docker \
             /home/rootless/.cache/actcache \
             /home/rootless/.cache/toolcache \
             /opt/containerd \
             /run/docker \
             /run/containerd \
             /run/user && \
    \
    chmod -R 1777 /run && \
    chown -R rootless:rootless /config \
                               /home/rootless \
                               /opt/containerd \
                               /var/run

USER rootless

ENV XDG_RUNTIME_DIR="/run/user/${UID}"
ENV DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/docker.sock"
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

HEALTHCHECK --interval=15s \
            --timeout=5s \
            --start-period=60s \
            --retries=5 \
            CMD /command/s6-svstat /var/run/s6-rc/servicedirs/svc-forgejo-runner

ENTRYPOINT ["/init"]

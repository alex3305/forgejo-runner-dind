FROM code.forgejo.org/forgejo/runner:6.3.1 AS forgejo-runner

FROM alpine:3.22.0

# renovate: datasource=github-releases depName=moby/moby
ARG DOCKER_VERSION=28.2.2

ADD https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz /tmp/docker.tgz
ADD https://download.docker.com/linux/static/stable/x86_64/docker-rootless-extras-${DOCKER_VERSION}.tgz /tmp/docker-rootless-extras.tgz

# renovate: datasource=github-releases depName=just-containers/s6-overlay
ARG S6_OVERLAY_VERSION=3.2.1.0

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp

COPY --from=forgejo-runner /bin/forgejo-runner /usr/local/bin/forgejo-runner
COPY root/ /

ENV UID=1000
ENV XDG_RUNTIME_DIR="/run/user/${UID}"
ENV DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/docker.sock"
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

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
    addgroup -S dockremap && \
    adduser -S -G dockremap dockremap && \
    echo 'dockremap:165536:65536' >> /etc/subuid && \
    echo 'dockremap:165536:65536' >> /etc/subgid && \
    \
    adduser -h /home/rootless -g 'Rootless' -D -u ${UID} rootless && \
    echo 'rootless:100000:65536' >> /etc/subuid && \
    echo 'rootless:100000:65536' >> /etc/subgid && \
    \
    tar -xvzf /tmp/docker.tgz -C /usr/local/bin/ --strip-components 1 && \
    tar -xvzf /tmp/docker-rootless-extras.tgz -C /usr/local/bin/ --strip-components 1 && \
    \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
    \
    mkdir -p /data \
             /home/rootless/.local/share/docker \
             /home/rootless/.cache/actcache \
             /home/rootless/.cache/toolcache \
             /opt/containerd \
             /run/docker \
             /run/containerd \
             /run/user && \
    \
    chmod -R a+rx /usr/local/bin \
                  /etc/periodic \
                  /etc/s6-overlay && \
    \
    chmod -R 1777 /run && \
    chown -R rootless:rootless /data \
                               /home/rootless \
                               /opt/containerd \
                               /var/run && \
    \
    rm -rf /tmp/*

USER rootless

HEALTHCHECK --interval=15s \
            --timeout=5s \
            --start-period=60s \
            --retries=5 \
            CMD /command/s6-svstat \
                /var/run/s6-rc/servicedirs/svc-forgejo-runner

ENTRYPOINT ["/init"]

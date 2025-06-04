FROM code.forgejo.org/forgejo/runner:6.3.1 AS forgejo-runner
FROM docker:28.2.2-dind-rootless AS dind-rootless

# renovate: datasource=github-releases depName=just-containers/s6-overlay
ARG S6_OVERLAY_VERSION=3.2.1.0

USER root

# Add S6 overlay (https://github.com/just-containers/s6-overlay)
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp

RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

# Add Forgejo Runner from official OCI
COPY --from=forgejo-runner /bin/forgejo-runner /usr/local/bin/forgejo-runner

# Add S6 scripts
COPY root/ /

RUN apk add --no-cache bash git iptables \
    && \
    mkdir -p /data \
             /opt/containerd \
             /tmp/hostedtoolcache \
             /var/run \
    && \
    chmod -R a+rx /usr/local/bin \
                  /etc/s6-overlay \
    && \
    chown -R rootless:rootless /data \
                               /home/rootless \
                               /opt/containerd \
                               /tmp

# TODO Maybe remove variables below??
# Exit the container when services don't go up
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

# Keep environment variables for dind
ENV S6_KEEP_ENV=1

ENV DOCKER_HOST=unix:///run/user/1000/docker.sock
VOLUME /data

USER rootless

HEALTHCHECK --interval=60s \
            --timeout=30s \
            --start-period=5s \
            --retries=3 \
            CMD ["/command/s6-svstat /var/run/s6-rc/servicedirs/svc-forgejo-runner"]

ENTRYPOINT ["/init"]

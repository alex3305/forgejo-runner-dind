FROM code.forgejo.org/forgejo/runner:6.3.1 AS forgejo-runner
FROM docker:28.2.2-dind-rootless AS dind-rootless

FROM alpine:3.22

# renovate: datasource=github-releases depName=just-containers/s6-overlay
ARG S6_OVERLAY_VERSION=3.2.1.0

# Add S6 overlay (https://github.com/just-containers/s6-overlay)
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp

RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

# Add Forgejo Runner from official OCI
COPY --from=forgejo-runner /bin/forgejo-runner /usr/local/bin/forgejo-runner

# Add Docker from official image
COPY --from=dind-rootless /usr/local/bin/ /usr/local/bin/

# Add S6 scripts
COPY rootfs/ /

# Create rootless user
RUN set -eux; \
        adduser -h /home/rootless -g 'Rootless' -D -u 1000 rootless; \
        echo 'rootless:100000:65536' >> /etc/subuid; \
	    echo 'rootless:100000:65536' >> /etc/subgid

RUN apk add --no-cache bash git \
    && \
    mkdir -p /data \
             /home/rootless/.local/share/docker \
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

VOLUME /data
VOLUME /home/rootless/.local/share/docker

USER rootless

# # Add Docker health check
# HEALTHCHECK --interval=60s \
#             --timeout=30s \
#             --start-period=5s \
#             --retries=3 \
#             CMD ["s6-svstat /etc/s6/forgejo-runner"]

ENTRYPOINT ["/init"]

FROM code.forgejo.org/forgejo/runner:6.3.1 AS forgejo-runner
FROM docker:28.2.2-dind-rootless AS dind-rootless

USER root

COPY --from=forgejo-runner /bin/forgejo-runner /usr/local/bin/forgejo-runner

COPY scripts/s6 /etc/s6
COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/register.sh /register.sh

ENV DOCKER_HOST=unix:///run/user/1000/docker.sock

RUN apk add --no-cache s6 bash git \
    && \
    mkdir -p /data \
             /var/run/ \
             /opt/containerd \
             /tmp/hostedtoolcache \
    && \
    chmod a+x /usr/local/bin/forgejo-runner \
              /entrypoint.sh \
              /register.sh \
    && \
    chmod -R a+rx /etc/s6 \
    && \
    chown -R rootless:rootless /etc/s6 \
                               /data \
                               /opt/containerd \
                               /tmp \
                               /entrypoint.sh \
                               /register.sh

VOLUME /data
USER rootless

HEALTHCHECK --interval=60s \
            --timeout=30s \
            --start-period=5s \
            --retries=3 \
            CMD ["s6-svstat /etc/s6/forgejo-runner"]

ENTRYPOINT ["/entrypoint.sh"]

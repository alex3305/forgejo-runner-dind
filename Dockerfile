FROM code.forgejo.org/forgejo/runner:6.3.1 AS forgejo-runner
FROM docker:28.1.1-dind-rootless AS dind-rootless

USER root

COPY --from=forgejo-runner /bin/forgejo-runner /usr/local/bin/forgejo-runner

COPY scripts/s6 /etc/s6
COPY scripts/s6-init /etc/s6-init
COPY scripts/entrypoint.sh /entrypoint.sh

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
    && \
    chmod -R a+rx /etc/s6 \
                  /etc/s6-init \
    && \
    chown -R rootless:rootless /etc/s6 \
                               /etc/s6-init \
                               /data \
                               /opt/containerd \
                               /tmp \
                               /entrypoint.sh

VOLUME /data
USER rootless

ENTRYPOINT ["/entrypoint.sh"]

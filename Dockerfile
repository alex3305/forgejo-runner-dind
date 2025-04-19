FROM code.forgejo.org/forgejo/runner:6.3.1 AS forgejo-runner
FROM docker:28.1.1-dind-rootless AS dind-rootless

USER root

RUN apk add --no-cache s6 bash git

COPY --from=forgejo-runner /bin/forgejo-runner /usr/local/bin/forgejo-runner
COPY scripts/run.sh /usr/local/bin/run.sh
COPY scripts/s6 /etc/s6

ENV DOCKER_HOST=unix:///run/user/1000/docker.sock

RUN mkdir -p /data /var/run/ \
    && chmod a+x /usr/local/bin/forgejo-runner \
    && chmod a+x /usr/local/bin/run.sh \
    && chmod -R a+x /etc/s6 \
    && chown -R rootless:rootless /etc/s6 /data

VOLUME /data
USER rootless

ENTRYPOINT ["s6-svscan", "/etc/s6"]

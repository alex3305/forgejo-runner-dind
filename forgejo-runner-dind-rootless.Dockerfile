ARG DOCKER_VERSION=dind-rootless

FROM docker:${DOCKER_VERSION}

ARG FORGEJO_RUNNER_VERSION
ARG DOCKER_VERSION

USER root

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
     ./root/ /

RUN mkdir -p /config \
             /home/rootless/.local/share/docker \
             /home/rootless/.cache/actcache \
             /home/rootless/.cache/toolcache && \
    \
    chown -R rootless:rootless /config \
                               /home/rootless && \
    \
    chmod 0555 /etc/crontabs/*

ENV UID=1000
ENV XDG_RUNTIME_DIR="/run/user/${UID}"
ENV DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/docker.sock"

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV TINI_SUBREAPER=1

HEALTHCHECK --interval=15s         \
            --timeout=5s           \
            --start-period=60s     \
            --retries=5            \
            CMD /command/s6-svstat /var/run/s6-rc/servicedirs/svc-forgejo-runner

ENTRYPOINT ["/init"]

USER rootless

LABEL org.opencontainers.image.title="Forgejo Runner With Docker" \
      org.opencontainers.image.description="Forgejo Runner with embedded, rootless  Docker in Docker" \
      org.opencontainers.image.version="${FORGEJO_RUNNER_VERSION}-dind-rootless-${DOCKER_VERSION}" \
      org.opencontainers.image.authors="Alex van den Hoogen" \
      org.opencontainers.image.documentation="https://github.com/alex3305/forgejo-runner-dind" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/alex3305/forgejo-runner-dind" \
      org.opencontainers.image.url="https://github.com/alex3305/forgejo-runner-dind" \
      org.opencontainers.image.vendor="Alex van den Hoogen"

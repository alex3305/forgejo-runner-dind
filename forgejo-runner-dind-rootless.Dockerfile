FROM dind-rootless

ARG FORGEJO_RUNNER_VERSION
ARG DOCKER_VERSION

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
    chmod 0555 /etc/crontabs/* && \
    \
    touch /etc/s6-overlay/s6-rc.d/svc-cron/dependencies.d/svc-docker && \
    touch /etc/s6-overlay/s6-rc.d/svc-forgejo-runner/dependencies.d/svc-docker && \
    touch /etc/s6-overlay/s6-rc.d/user/contents.d/svc-docker

USER rootless

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV LOG_LEVEL="info"

HEALTHCHECK --interval=15s         \
            --timeout=5s           \
            --start-period=60s     \
            --retries=5            \
            CMD /command/s6-svstat /var/run/s6-rc/servicedirs/svc-forgejo-runner

ENTRYPOINT ["/init"]

LABEL org.opencontainers.image.title="Forgejo Runner With Docker" \
      org.opencontainers.image.description="Forgejo Runner with embedded Docker in Docker" \
      org.opencontainers.image.version="${FORGEJO_RUNNER_VERSION}-dind-${DOCKER_VERSION}"

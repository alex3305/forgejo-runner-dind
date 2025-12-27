ARG DOCKER_VERSION=dind

FROM docker:${DOCKER_VERSION}

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

RUN mkdir -p /config /root

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

HEALTHCHECK --interval=15s         \
            --timeout=5s           \
            --start-period=60s     \
            --retries=5            \
            CMD /command/s6-svstat /var/run/s6-rc/servicedirs/svc-forgejo-runner

ENTRYPOINT ["/init"]

LABEL org.opencontainers.image.title="Forgejo Runner With Docker" \
      org.opencontainers.image.description="Forgejo Runner with embedded Docker in Docker" \
      org.opencontainers.image.version="${FORGEJO_RUNNER_VERSION}-dind-${DOCKER_VERSION}" \
      org.opencontainers.image.authors="Alex van den Hoogen" \
      org.opencontainers.image.documentation="https://github.com/alex3305/forgejo-runner-dind" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/alex3305/forgejo-runner-dind" \
      org.opencontainers.image.url="https://github.com/alex3305/forgejo-runner-dind" \
      org.opencontainers.image.vendor="Alex van den Hoogen"

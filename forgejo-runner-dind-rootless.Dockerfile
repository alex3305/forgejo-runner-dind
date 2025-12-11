FROM base

ARG FORGEJO_RUNNER_VERSION
ARG DOCKER_VERSION

# Setup Rootless user
ENV UID=1000
RUN adduser -h /home/rootless -g 'Rootless' -D -u ${UID} rootless

# Add Rootless Docker in Docker from build stage
COPY --from=dind-rootless \
     --chown=root:rootless \
     --chmod=0750 \
     /docker /usr/local/bin/

# Add Forgejo Runner from build stage
COPY --from=forgejo-act-runner \
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

RUN addgroup -g 2375 -S docker && \
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

LABEL org.opencontainers.image.title="Forgejo Runner With Docker" \
      org.opencontainers.image.description="Forgejo act runner with embedded Docker in Docker" \
      org.opencontainers.image.version="${FORGEJO_RUNNER_VERSION}-dind-${DOCKER_VERSION}"

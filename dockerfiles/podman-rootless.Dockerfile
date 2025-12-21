FROM base

ARG PODMAN_VERSION

ENV UID=1000

RUN adduser -h /home/rootless -g 'Rootless' -D -u ${UID} rootless && \
    \
    apk add --no-cache podman=~${PODMAN_VERSION} \
                       podman-docker=~${PODMAN_VERSION} && \
    \
    echo 'rootless:100000:65536' >> /etc/subuid && \
    echo 'rootless:100000:65536' >> /etc/subgid && \
    \
    mkdir -p /run/user/ && \
    chmod -R 1777 /run

ENV DOCKER_HOST="unix:///run/user/${UID}/podman.sock"

FROM base AS dind-rootless

ARG TARGETARCH
ARG TARGETOS
ARG DOCKER_VERSION

ENV UID=1000

RUN DOCKER_TARGETARCH=$(case ${TARGETARCH} in \
        "amd64")   echo "x86_64"  ;; \
        "arm64")   echo "aarch64" ;; \
        "arm/v7")  echo "armel"   ;; \
        "arm/v6")  echo "armhf"   ;; \
    esac) && \
    \
    curl -Lo /tmp/docker.tgz \
         https://download.docker.com/${TARGETOS}/static/stable/${DOCKER_TARGETARCH}/docker-${DOCKER_VERSION}.tgz \
         && \
    curl -Lo /tmp/docker-rootless-extras.tgz \
         https://download.docker.com/${TARGETOS}/static/stable/${DOCKER_TARGETARCH}/docker-rootless-extras-${DOCKER_VERSION}.tgz \
         && \
    \
    mkdir -p /tmp/docker && \
    tar -xvzf /tmp/docker.tgz -C /tmp/docker --strip-components 1 && \
    tar -xvzf /tmp/docker-rootless-extras.tgz -C /tmp/docker --strip-components 1 && \
    \
    mv /tmp/docker/* /usr/local/bin && \
    rm -rf /tmp/* && \
    \
    adduser -h /home/rootless -g 'Rootless' -D -u ${UID} rootless && \
    \
    addgroup -g 2375 -S docker && \
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
    mkdir -p /home/rootless/.local/share/docker \
             /opt/containerd \
             /run/docker \
             /run/containerd \
             /run/user && \
    \
    chmod -R 0750 /usr/local/bin && \
    chmod -R 1777 /run && \
    chown -R rootless:rootless /opt/containerd \
                               /usr/local/bin \
                               /var/run

ENV XDG_RUNTIME_DIR="/run/user/${UID}"
ENV DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/docker.sock"

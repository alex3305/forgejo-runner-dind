FROM base AS dind-rootless

ARG TARGETARCH
ARG TARGETOS
ARG DOCKER_VERSION

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
    mkdir -p /docker && \
    tar -xvzf /tmp/docker.tgz -C /docker --strip-components 1 && \
    tar -xvzf /tmp/docker-rootless-extras.tgz -C /docker --strip-components 1

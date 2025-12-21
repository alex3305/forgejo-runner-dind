FROM base

ARG TARGETARCH
ARG TARGETOS
ARG FORGEJO_RUNNER_VERSION

RUN ACT_TARGETARCH=$(case ${TARGETARCH} in \
        "amd64")   echo "amd64"  ;; \
        "arm64")   echo "arm64" ;; \
    esac) && \
    \
    FORGEJO_RUNNER_FILENAME="forgejo-runner-${FORGEJO_RUNNER_VERSION}-${TARGETOS}-${ACT_TARGETARCH}" && \
    FORGEJO_RUNNER_DOWNLOAD_URL="https://code.forgejo.org/forgejo/runner/releases/download/v${FORGEJO_RUNNER_VERSION}/${FORGEJO_RUNNER_FILENAME}" && \
    \
    mkdir -p /act && \
    cd /act && \
    \
    echo "Downloading ${FORGEJO_RUNNER_FILENAME} from ${FORGEJO_RUNNER_DOWNLOAD_URL}..." && \
    curl -LO "${FORGEJO_RUNNER_DOWNLOAD_URL}" && \
    \
    echo "Downloading ${FORGEJO_RUNNER_FILENAME}.sha256 from ${FORGEJO_RUNNER_DOWNLOAD_URL}..." && \
    curl -LO "${FORGEJO_RUNNER_DOWNLOAD_URL}.sha256" && \
    \
    echo "Verifying Forgejo Runner checksum..." && \
    sha256sum -c ${FORGEJO_RUNNER_FILENAME}.sha256 && \
    \
    rm "/act/${FORGEJO_RUNNER_FILENAME}.sha256" && \
    \
    ln -s "${FORGEJO_RUNNER_FILENAME}" forgejo-runner && \
    chmod -R a+rx /act

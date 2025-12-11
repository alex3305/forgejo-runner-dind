FROM base AS forgejo-act-runner

ARG TARGETARCH
ARG FORGEJO_RUNNER_VERSION

RUN ACT_TARGETARCH=$(case ${TARGETARCH} in \
        "amd64")   echo "amd64"  ;; \
        "arm64")   echo "arm64" ;; \
    esac) && \
    \
    mkdir -p /act && \
    curl -Lo /act/forgejo-runner \
         https://code.forgejo.org/forgejo/runner/releases/download/v${FORGEJO_RUNNER_VERSION}/forgejo-runner-${FORGEJO_RUNNER_VERSION}-${TARGETOS}-${ACT_TARGETARCH}

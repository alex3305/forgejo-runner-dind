FROM base

ARG PODMAN_VERSION

ENV UID=1000

RUN adduser -h /home/rootless -g 'Rootless' -D -u ${UID} rootless && \
    \
    apk add --no-cache podman=~${PODMAN_VERSION} && \
    \
    echo 'rootless:100000:65536' >> /etc/subuid && \
    echo 'rootless:100000:65536' >> /etc/subgid && \
    \
    echo -e '#!/bin/bash\npodman "$@"' > /usr/bin/docker && \
    chmod +x /usr/bin/docker

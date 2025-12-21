FROM alpine:3.23.0

ARG TARGETARCH
ARG TARGETOS

RUN apk add --no-cache bash            \
                       ca-certificates \
                       curl            \
                       git             \
                       openssl         \
                       tar             \
                       xz

LABEL org.opencontainers.image.authors="Alex van den Hoogen" \
      org.opencontainers.image.documentation="https://github.com/alex3305/forgejo-runner-dind" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/alex3305/forgejo-runner-dind" \
      org.opencontainers.image.url="https://github.com/alex3305/forgejo-runner-dind" \
      org.opencontainers.image.vendor="Alex van den Hoogen"

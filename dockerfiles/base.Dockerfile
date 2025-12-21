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

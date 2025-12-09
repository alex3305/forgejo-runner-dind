FROM alpine:3.23.0 AS base

ARG TARGETARCH
ARG TARGETOS

RUN apk add --no-cache bash            \
                       ca-certificates \
                       curl            \
                       fuse-overlayfs  \
                       git             \
                       iproute2        \
                       iptables        \
                       openssl         \
                       pigz            \
                       shadow-uidmap   \
                       tar             \
                       xz

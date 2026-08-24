ARG GO_VERSION=1.27.0
FROM golang:${GO_VERSION}-bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends make git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

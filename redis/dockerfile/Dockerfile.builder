FROM debian:stable-slim AS builder

RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources && \
    apt-get update && \
    apt-get install -y dos2unix && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /script

COPY entrypoint/docker-entrypoint-*.sh .
COPY entrypoint/redis-setup.sh .

RUN dos2unix redis-setup.sh && \
    chmod +x redis-setup.sh

RUN for f in docker-entrypoint-*.sh; do \
        dos2unix "$f"; \
        chmod +x "$f"; \
    done
ARG REDIS_VERSION=7.0-alpine
FROM debian:stable-slim AS builder

RUN apt-get update && apt-get install -y dos2unix && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY docker-entrypoint.sh .

RUN dos2unix docker-entrypoint.sh && \
    chmod +x docker-entrypoint.sh

FROM redis:${REDIS_VERSION} AS RUNNER

COPY --from=builder /app/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["redis-server"]

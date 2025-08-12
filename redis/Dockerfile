ARG REDIS_VERSION=7.0-alpine
FROM redis:${REDIS_VERSION}

COPY docker-entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["redis-server"]

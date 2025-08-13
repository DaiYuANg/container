#!/bin/sh
set -e
. /usr/local/bin/redis-setup.sh

if [ -z "$REDIS_MASTER_HOST" ]; then
  echo "ERROR: REDIS_MASTER_HOST is required for replica mode"
  exit 1
fi

echo "replicaof $REDIS_MASTER_HOST ${REDIS_MASTER_PORT:-6379}" >> /redis.conf
[ -n "$REDIS_PASSWORD" ] && echo "masterauth $REDIS_PASSWORD" >> /redis.conf

exec redis-server /redis.conf

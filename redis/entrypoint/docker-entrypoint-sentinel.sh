#!/bin/sh
set -e
. /usr/local/bin/redis-setup.sh

if [ -z "$REDIS_MASTER_HOST" ]; then
  echo "ERROR: REDIS_MASTER_HOST is required for sentinel mode"
  exit 1
fi

cat > /sentinel.conf <<EOF
port 26379
dir /tmp
sentinel monitor mymaster $REDIS_MASTER_HOST ${REDIS_MASTER_PORT:-6379} ${REDIS_SENTINEL_QUORUM:-2}
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
EOF

[ -n "$REDIS_PASSWORD" ] && echo "sentinel auth-pass mymaster $REDIS_PASSWORD" >> /sentinel.conf

exec redis-sentinel /sentinel.conf

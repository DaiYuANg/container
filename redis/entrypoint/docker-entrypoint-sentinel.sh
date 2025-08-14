#!/bin/sh
set -e
. /usr/local/bin/redis-setup.sh

# Sentinel 监控名称，默认 mymaster
SENTINEL_NAME=${REDIS_SENTINEL_NAME:-mymaster}

if [ -z "$REDIS_MASTER_HOST" ]; then
  echo "ERROR: REDIS_MASTER_HOST is required for sentinel mode"
  exit 1
fi

cat > /sentinel.conf <<EOF
port 26379
dir /tmp
sentinel monitor $SENTINEL_NAME $REDIS_MASTER_HOST ${REDIS_MASTER_PORT:-6379} ${REDIS_SENTINEL_QUORUM:-2}
sentinel down-after-milliseconds $SENTINEL_NAME 5000
sentinel failover-timeout $SENTINEL_NAME 60000
sentinel parallel-syncs $SENTINEL_NAME 1
sentinel resolve-hostnames yes
EOF

# 如果设置了密码
[ -n "$REDIS_PASSWORD" ] && echo "sentinel auth-pass $SENTINEL_NAME $REDIS_PASSWORD" >> /sentinel.conf

# 如果设置了 announce-ip
[ -n "$REDIS_SENTINEL_ANNOUNCE_IP" ] && echo "sentinel announce-ip $REDIS_SENTINEL_ANNOUNCE_IP" >> /sentinel.conf

# 如果设置了 announce-port
[ -n "$REDIS_SENTINEL_ANNOUNCE_PORT" ] && echo "sentinel announce-port $REDIS_SENTINEL_ANNOUNCE_PORT" >> /sentinel.conf

exec redis-sentinel /sentinel.conf

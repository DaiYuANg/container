#!/bin/sh
set -e

# 默认环境变量
REDIS_PASSWORD=${REDIS_PASSWORD:-}
REDIS_REPLICATION_MODE=${REDIS_REPLICATION_MODE:-standalone} # standalone|replica|sentinel
REDIS_MASTER_HOST=${REDIS_MASTER_HOST:-}
REDIS_MASTER_PORT=${REDIS_MASTER_PORT:-6379}
REDIS_SENTINEL_QUORUM=${REDIS_SENTINEL_QUORUM:-2}
REDIS_APPENDONLY=${REDIS_APPENDONLY:-yes}

# 新增配置项
REDIS_LOG_LEVEL=${REDIS_LOG_LEVEL:-notice}       # debug, verbose, notice, warning
REDIS_MAX_CLIENTS=${REDIS_MAX_CLIENTS:-10000}
REDIS_RDB_ENABLED=${REDIS_RDB_ENABLED:-yes}      # yes or no
REDIS_RDB_FILENAME=${REDIS_RDB_FILENAME:-dump.rdb}
REDIS_RDB_SAVE=${REDIS_RDB_SAVE:-"900 1 300 10 60 10000"}

echo "Starting Redis container with mode=$REDIS_REPLICATION_MODE"

# 生成 redis.conf
cat > /redis.conf <<EOF
port 6379
appendonly $REDIS_APPENDONLY
loglevel $REDIS_LOG_LEVEL
maxclients $REDIS_MAX_CLIENTS
EOF

if [ "$REDIS_RDB_ENABLED" = "yes" ]; then
  echo "save $REDIS_RDB_SAVE" >> /redis.conf
  echo "dbfilename $REDIS_RDB_FILENAME" >> /redis.conf
else
  echo "save \"\"" >> /redis.conf
fi

if [ -n "$REDIS_PASSWORD" ]; then
  echo "requirepass $REDIS_PASSWORD" >> /redis.conf
fi

if [ "$REDIS_REPLICATION_MODE" = "replica" ]; then
  if [ -z "$REDIS_MASTER_HOST" ]; then
    echo "ERROR: REDIS_MASTER_HOST is required for replica mode" >&2
    exit 1
  fi
  echo "replicaof $REDIS_MASTER_HOST $REDIS_MASTER_PORT" >> /redis.conf
  if [ -n "$REDIS_PASSWORD" ]; then
    echo "masterauth $REDIS_PASSWORD" >> /redis.conf
  fi
fi

# 生成 sentinel.conf
cat > /sentinel.conf <<EOF
port 26379
dir /tmp
sentinel monitor mymaster $REDIS_MASTER_HOST $REDIS_MASTER_PORT $REDIS_SENTINEL_QUORUM
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
EOF

if [ -n "$REDIS_PASSWORD" ]; then
  echo "sentinel auth-pass mymaster $REDIS_PASSWORD" >> /sentinel.conf
fi

# 启动对应进程
case "$REDIS_REPLICATION_MODE" in
  standalone)
    echo "Running redis-server in standalone mode"
    exec redis-server /redis.conf
    ;;
  replica)
    echo "Running redis-server in replica mode"
    exec redis-server /redis.conf
    ;;
  sentinel)
    if [ -z "$REDIS_MASTER_HOST" ]; then
      echo "ERROR: REDIS_MASTER_HOST is required for sentinel mode" >&2
      exit 1
    fi
    echo "Running redis-sentinel monitoring $REDIS_MASTER_HOST"
    exec redis-sentinel /sentinel.conf
    ;;
  *)
    echo "ERROR: Unsupported REDIS_REPLICATION_MODE: $REDIS_REPLICATION_MODE" >&2
    exit 1
    ;;
esac

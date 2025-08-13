#!/bin/sh
set -e

# 默认配置
REDIS_PASSWORD=${REDIS_PASSWORD:-}
REDIS_APPENDONLY=${REDIS_APPENDONLY:-yes}
REDIS_LOG_LEVEL=${REDIS_LOG_LEVEL:-notice}
REDIS_MAX_CLIENTS=${REDIS_MAX_CLIENTS:-10000}
REDIS_RDB_ENABLED=${REDIS_RDB_ENABLED:-yes}
REDIS_RDB_FILENAME=${REDIS_RDB_FILENAME:-dump.rdb}
REDIS_RDB_SAVE=${REDIS_RDB_SAVE:-"900 1 300 10 60 10000"}

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

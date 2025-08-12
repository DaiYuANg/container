#!/bin/bash
set -e

: "${PGDATA:=/var/lib/postgresql/data}"
: "${POSTGRES_PASSWORD:=postgres}"
: "${POSTGRES_MAX_CONNECTIONS:=100}"
: "${POSTGRES_LOG_LEVEL:=notice}"
: "${POSTGRES_SHARED_BUFFERS:=128MB}"

: "${AUTO_FAILOVER_ROLE:=standalone}" # monitor|primary|secondary|standalone
: "${AUTO_FAILOVER_MONITOR_NODE:=}"
: "${AUTO_FAILOVER_NODE_NAME:=pg-node}"
: "${AUTO_FAILOVER_AUTH_METHOD:=trust}"

INIT_FLAG="$PGDATA/.initialized"

initialize_db() {
  echo "Initializing PostgreSQL database cluster..."

  chown -R postgres:postgres "$PGDATA"
  chmod 700 "$PGDATA"

  gosu postgres initdb --username=postgres

  # 启动数据库临时修改密码
  gosu postgres pg_ctl -D "$PGDATA" -w start

  # 使用 psql 设置密码
  gosu postgres psql --username=postgres -c "ALTER USER postgres WITH PASSWORD '$POSTGRES_PASSWORD';"

  gosu postgres pg_ctl -D "$PGDATA" -m fast -w stop

  # 追加配置
  echo "max_connections = $POSTGRES_MAX_CONNECTIONS" >> "$PGDATA/postgresql.conf"
  echo "log_min_messages = $POSTGRES_LOG_LEVEL" >> "$PGDATA/postgresql.conf"
  echo "shared_buffers = $POSTGRES_SHARED_BUFFERS" >> "$PGDATA/postgresql.conf"

  touch "$INIT_FLAG"
  chown postgres:postgres "$INIT_FLAG"
}

if [ ! -f "$INIT_FLAG" ]; then
  initialize_db
else
  echo "Database already initialized, skipping initdb."
fi

# 启动 PostgreSQL 服务（切换到 postgres 用户）
gosu postgres pg_ctl -D "$PGDATA" -w start

function run_monitor() {
  echo "Starting pg_auto_failover monitor node..."
  exec gosu postgres pg_autoctl create monitor --ssl-self-signed --pgdata "$PGDATA" --auth "$AUTO_FAILOVER_AUTH_METHOD" || echo "Monitor already created"
  exec gosu postgres pg_autoctl run --pgdata "$PGDATA"
}

function run_primary() {
  if [ -z "$AUTO_FAILOVER_MONITOR_NODE" ]; then
    echo "ERROR: AUTO_FAILOVER_MONITOR_NODE must be set for primary node" >&2
    exit 1
  fi
  echo "Starting pg_auto_failover primary node..."
  exec gosu postgres pg_autoctl create postgres --ssl-self-signed --pgdata "$PGDATA" --monitor "$AUTO_FAILOVER_MONITOR_NODE" --auth "$AUTO_FAILOVER_AUTH_METHOD" --name "$AUTO_FAILOVER_NODE_NAME" || echo "Primary node already created"
  exec gosu postgres pg_autoctl run --pgdata "$PGDATA"
}

function run_secondary() {
  if [ -z "$AUTO_FAILOVER_MONITOR_NODE" ]; then
    echo "ERROR: AUTO_FAILOVER_MONITOR_NODE must be set for secondary node" >&2
    exit 1
  fi
  echo "Starting pg_auto_failover secondary node..."
  exec gosu postgres pg_autoctl create postgres --ssl-self-signed --pgdata "$PGDATA" --monitor "$AUTO_FAILOVER_MONITOR_NODE" --auth "$AUTO_FAILOVER_AUTH_METHOD" --name "$AUTO_FAILOVER_NODE_NAME" || echo "Secondary node already created"
  exec gosu postgres pg_autoctl run --pgdata "$PGDATA"
}

case "$AUTO_FAILOVER_ROLE" in
  monitor)
    run_monitor
    ;;
  primary)
    run_primary
    ;;
  secondary)
    run_secondary
    ;;
  standalone)
    echo "Running standalone PostgreSQL..."
    exec gosu postgres postgres -D "$PGDATA" -c config_file="$PGDATA/postgresql.conf"
    ;;
  *)
    echo "Invalid AUTO_FAILOVER_ROLE: $AUTO_FAILOVER_ROLE" >&2
    exit 1
    ;;
esac

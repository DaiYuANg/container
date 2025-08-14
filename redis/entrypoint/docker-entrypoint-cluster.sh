#!/bin/sh
set -e

# -------------------------
# ENV / defaults
# -------------------------
: "${REDIS_PASSWORD:=}"
: "${REDIS_CLUSTER_NODES:=}"      # all nodes for create, space separated host:port (use announced addresses if you want host clients to connect)
: "${REDIS_CLUSTER_REPLICAS:=1}"
: "${REDIS_CLUSTER_CREATOR:=no}"  # yes = this node will run --cluster create
: "${REDIS_CLUSTER_TIMEOUT:=5000}"
: "${REDIS_DATA_DIR:=/data}"      # where nodes.conf lives
: "${FORCE_RESET:=no}"            # yes => forcibly remove nodes.conf if exists and recreate

# Announce / external address settings
: "${REDIS_CLUSTER_ANNOUNCE_IP:=}"         # e.g. 127.0.0.1 or host.docker.internal
: "${REDIS_CLUSTER_ANNOUNCE_PORT:=}"       # e.g. 6379 (the mapped host port for this container)
: "${REDIS_CLUSTER_ANNOUNCE_BUS_PORT:=}"   # e.g. 16379 (optional; default = announce_port + 10000 if announce_port set)

log() { echo "[entrypoint] $*"; }

# If announce_port provided but bus not, compute bus = port + 10000
if [ -n "$REDIS_CLUSTER_ANNOUNCE_PORT" ] && [ -z "$REDIS_CLUSTER_ANNOUNCE_BUS_PORT" ]; then
  # arithmetic
  ANN_PORT=$REDIS_CLUSTER_ANNOUNCE_PORT
  ANN_BUS_PORT=$((ANN_PORT + 10000))
  REDIS_CLUSTER_ANNOUNCE_BUS_PORT="$ANN_BUS_PORT"
fi

# -------------------------
# write fresh redis.conf (overwrite to avoid duplicates)
# -------------------------
cat > /redis.conf <<EOF
port 6379
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout $REDIS_CLUSTER_TIMEOUT
EOF

if [ -n "$REDIS_PASSWORD" ]; then
  cat >> /redis.conf <<EOF
requirepass $REDIS_PASSWORD
masterauth $REDIS_PASSWORD
EOF
fi

# write announce options if provided
if [ -n "$REDIS_CLUSTER_ANNOUNCE_IP" ]; then
  echo "cluster-announce-ip $REDIS_CLUSTER_ANNOUNCE_IP" >> /redis.conf
fi
if [ -n "$REDIS_CLUSTER_ANNOUNCE_PORT" ]; then
  echo "cluster-announce-port $REDIS_CLUSTER_ANNOUNCE_PORT" >> /redis.conf
fi
if [ -n "$REDIS_CLUSTER_ANNOUNCE_BUS_PORT" ]; then
  echo "cluster-announce-bus-port $REDIS_CLUSTER_ANNOUNCE_BUS_PORT" >> /redis.conf
fi

# -------------------------
# start redis in background
# -------------------------
redis-server /redis.conf &
# wait local redis
until redis-cli ping >/dev/null 2>&1; do
  sleep 1
done
log "local redis is up"

# -------------------------
# nodes.conf helpers
# -------------------------
CLUSTER_FILE="$REDIS_DATA_DIR/nodes.conf"

count_nodes_conf_lines() {
  if [ -f "$CLUSTER_FILE" ]; then
    awk 'NF' "$CLUSTER_FILE" | wc -l | tr -d '[:space:]'
  else
    echo 0
  fi
}
count_nodeids_in_nodes_conf() {
  if [ -f "$CLUSTER_FILE" ]; then
    awk 'NF{print $1}' "$CLUSTER_FILE" | sort -u | wc -l | tr -d '[:space:]'
  else
    echo 0
  fi
}
nodes_conf_looks_placeholder() {
  if [ ! -f "$CLUSTER_FILE" ]; then
    return 1
  fi
  lines=$(count_nodes_conf_lines)
  if [ "$lines" -le 1 ]; then
    return 0
  fi
  return 1
}

maybe_clean_nodes_conf() {
  if [ ! -f "$CLUSTER_FILE" ]; then
    return 0
  fi
  if [ "$FORCE_RESET" = "yes" ]; then
    log "FORCE_RESET=yes -> removing existing $CLUSTER_FILE"
    rm -f "$CLUSTER_FILE"
    return 0
  fi
  if nodes_conf_looks_placeholder; then
    log "nodes.conf looks like placeholder (<=1 line). Removing to allow cluster create."
    rm -f "$CLUSTER_FILE"
    return 0
  fi
  if [ -n "$REDIS_CLUSTER_NODES" ]; then
    expected=$(echo "$REDIS_CLUSTER_NODES" | wc -w | tr -d '[:space:]')
    existing=$(count_nodeids_in_nodes_conf)
    if [ "$existing" -lt "$expected" ]; then
      log "nodes.conf exists but contains $existing node(s) < expected $expected. Removing to recreate cluster."
      rm -f "$CLUSTER_FILE"
      return 0
    fi
  fi
  log "nodes.conf exists and appears valid; will NOT remove it."
  return 0
}

# -------------------------
# network wait helper
# -------------------------
wait_for_node() {
  host=$1
  port=${2:-6379}
  log "waiting for $host:$port ..."
  tries=0
  while ! redis-cli -h "$host" -p "$port" ping >/dev/null 2>&1; do
    sleep 1
    tries=$((tries+1))
    if [ "$tries" -gt 120 ]; then
      log "timeout waiting for $host:$port"
      return 1
    fi
  done
  log "$host:$port reachable"
  return 0
}

# -------------------------
# CREATE logic (creator node)
# -------------------------
if [ "$REDIS_CLUSTER_CREATOR" = "yes" ]; then
  if [ -z "$REDIS_CLUSTER_NODES" ]; then
    log "REDIS_CLUSTER_CREATOR=yes but REDIS_CLUSTER_NODES is empty -> aborting"
    exit 1
  fi

  NUM_NODES=$(echo "$REDIS_CLUSTER_NODES" | wc -w | tr -d '[:space:]')
  REPLICAS=$REDIS_CLUSTER_REPLICAS
  MIN_NODES=$((3 * (REPLICAS + 1)))
  if [ "$NUM_NODES" -lt "$MIN_NODES" ]; then
    log "ERROR: need at least $MIN_NODES nodes for --cluster-replicas=$REPLICAS, you provided $NUM_NODES"
    exit 1
  fi

  # maybe clean existing placeholder/invalid nodes.conf
  maybe_clean_nodes_conf

  if [ -f "$CLUSTER_FILE" ]; then
    log "nodes.conf still exists; skipping cluster create (cluster likely initialized)"
  else
    log "will create cluster with nodes: $REDIS_CLUSTER_NODES  replicas=$REPLICAS"

    # wait all nodes reachable (use the addresses you put in REDIS_CLUSTER_NODES)
    for node in $REDIS_CLUSTER_NODES; do
      host=$(echo "$node" | cut -d: -f1)
      port=$(echo "$node" | cut -d: -f2)
      if ! wait_for_node "$host" "$port"; then
        log "ERROR: node $host:$port not reachable; aborting"
        exit 1
      fi
    done

    CREATE_ARGS=""
    for node in $REDIS_CLUSTER_NODES; do
      CREATE_ARGS="$CREATE_ARGS $node"
    done
    if [ -n "$REDIS_PASSWORD" ]; then
      CREATE_ARGS="--pass $REDIS_PASSWORD $CREATE_ARGS"
    fi

    log "running: redis-cli --cluster create $CREATE_ARGS --cluster-replicas $REPLICAS"
    yes yes | redis-cli --cluster create $CREATE_ARGS --cluster-replicas "$REPLICAS"
    log "cluster create finished"
  fi
else
  log "REDIS_CLUSTER_CREATOR != yes -> skipping cluster create on this node"
fi

# -------------------------
# foreground
# -------------------------
wait

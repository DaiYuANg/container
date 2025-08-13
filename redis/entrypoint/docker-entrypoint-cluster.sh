# Cluster 配置
set -e
. /usr/local/bin/redis-setup.sh

echo "cluster-enabled yes" >> /redis.conf
echo "cluster-config-file nodes.conf" >> /redis.conf
echo "cluster-node-timeout 5000" >> /redis.conf

# 启动 Redis
redis-server /redis.conf &

sleep 3

# 只有主节点执行 cluster create
if [ "$REDIS_CLUSTER_ROLE" = "master" ] && [ -n "$REDIS_CLUSTER_NODES" ]; then
    echo "Creating Redis Cluster from master node..."
    CREATE_ARGS=""
    for node in $REDIS_CLUSTER_NODES; do
        CREATE_ARGS="$CREATE_ARGS $node"
    done
    if [ -n "$REDIS_PASSWORD" ]; then
        CREATE_ARGS="--pass $REDIS_PASSWORD $CREATE_ARGS"
    fi
    yes yes | redis-cli --cluster create $CREATE_ARGS
fi

# 保持前台运行
wait
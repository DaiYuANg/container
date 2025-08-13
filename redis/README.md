# Redis Docker Entrypoint Script
这是一个自定义的 Redis 容器入口脚本，支持多种运行模式（standalone、replica、sentinel），并通过环境变量灵活配置 Redis 服务参数。

## 支持的环境变量
变量名	说明	默认值

REDIS_PASSWORD	Redis 访问密码（如果设置，则启用密码认证）	空（无密码）

REDIS_REPLICATION_MODE	运行模式，可选 standalone（单机），replica（从节点），sentinel（哨兵）	standalone

REDIS_MASTER_HOST	主节点地址（replica 和 sentinel 模式必填）	空

REDIS_MASTER_PORT	主节点端口（replica 和 sentinel 模式可选）	6379

REDIS_SENTINEL_QUORUM	Sentinel 集群判定主节点失效的仲裁节点数量	2
REDIS_APPENDONLY	是否启用 AOF 持久化（yes/no）	yes
REDIS_LOG_LEVEL	日志级别，支持 debug, verbose, notice, warning	notice
REDIS_MAX_CLIENTS	最大客户端连接数	10000
REDIS_RDB_ENABLED	是否启用 RDB 持久化（yes/no）	yes
REDIS_RDB_FILENAME	RDB 文件名	dump.rdb
REDIS_RDB_SAVE	RDB 快照触发条件，格式示例："900 1 300 10 60 10000"	"900 1 300 10 60 10000"

运行模式说明
standalone：独立运行的 Redis 实例

replica：作为主节点的从节点，需要指定 REDIS_MASTER_HOST

sentinel：哨兵模式，监控主节点状态，需要指定 REDIS_MASTER_HOST

使用示例
1. 单机模式（Standalone）
```bash
docker run -d \
  -e REDIS_REPLICATION_MODE=standalone \
  -e REDIS_PASSWORD=mysecretpassword \
  your-redis-image
```

2. 从节点模式（Replica）
```shell
bash
docker run -d \
  -e REDIS_REPLICATION_MODE=replica \
  -e REDIS_MASTER_HOST=redis-master-host \
  -e REDIS_PASSWORD=mysecretpassword \
  your-redis-image
```

3. Sentinel 模式
bash
复制
编辑
docker run -d \
  -e REDIS_REPLICATION_MODE=sentinel \
  -e REDIS_MASTER_HOST=redis-master-host \
  -e REDIS_SENTINEL_QUORUM=2 \
  -e REDIS_PASSWORD=mysecretpassword \
  your-redis-image
注意事项
在 replica 和 sentinel 模式下，必须设置 REDIS_MASTER_HOST，否则容器启动失败。

如果设置了 REDIS_PASSWORD，Redis 服务会启用访问密码保护。

RDB 和 AOF 持久化配置可以通过环境变量灵活调整。

Sentinel 模式下会启动 redis-sentinel，监控指定的主节点。

自定义配置
该脚本会根据环境变量自动生成 /redis.conf 和 /sentinel.conf，无需手动管理配置文件。

反馈和贡献
欢迎提出 issues 或 PR 改进脚本和 Docker 镜像。


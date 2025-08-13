# 默认镜像仓库名
IMAGE_NAME := daiyuang/redis

.PHONY: bake bake-push clean build-target

# 默认构建并推送 bake 中的 default 组
bake:
	docker buildx bake --push

# 只构建（不推送）
bake-build:
	docker buildx bake

# 按目标构建某个镜像，比如 make build-target target=redis-7-alpine
build-target:
	@if [ -z "$(target)" ]; then \
		echo "Please specify target, e.g. make build-target target=redis-7-alpine"; \
		exit 1; \
	fi
	docker buildx bake $(target) --push

# 清理本地所有 redis 相关镜像（不一定全，但简单示例）
clean:
	@docker images $(IMAGE_NAME) --format "{{.Repository}}:{{.Tag}}" | xargs -r docker rmi -f

# 默认 Redis 主版本
REDIS_MAJOR ?= 8

# 默认变体，支持 alpine、bookworm 或空（默认 Debian slim）
REDIS_VARIANT ?= alpine

# 生成完整版本标签，例如 8.2.0-alpine3.22, 8-bookworm, 7-alpine 等
# 这里简化为 major + variant，比如 8-alpine，8-bookworm，8（无变体）
# 你可以自己扩展对应版本号

ifeq ($(REDIS_VARIANT),latest)
  # latest 标签直接用 latest
  REDIS_TAG = latest
else ifeq ($(REDIS_VARIANT),)
  REDIS_TAG = $(REDIS_MAJOR)
else
  REDIS_TAG = $(REDIS_MAJOR)-$(REDIS_VARIANT)
endif

IMAGE_NAME := daiyuang/redis

.PHONY: build push clean

build:
	docker build --build-arg REDIS_VERSION=$(REDIS_TAG) -t $(IMAGE_NAME):$(REDIS_TAG) . --push

push:
	docker push $(IMAGE_NAME):$(REDIS_TAG)

clean:
	docker rmi $(IMAGE_NAME):$(REDIS_TAG)

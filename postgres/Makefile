# PostgreSQL 版本大号
POSTGRES_MAJOR ?= 17

POSTGRES_VARIANT ?= bookworm

# 处理 tag
ifeq ($(POSTGRES_VARIANT),latest)
  POSTGRES_TAG = latest
else ifeq ($(POSTGRES_VARIANT),)
  POSTGRES_TAG = $(POSTGRES_MAJOR)
else
  POSTGRES_TAG = $(POSTGRES_MAJOR)-$(POSTGRES_VARIANT)
endif

IMAGE_NAME := daiyuang/postgres-auto-failover

.PHONY: build push clean

build:
	docker build --build-arg POSTGRES_VERSION=$(POSTGRES_TAG) -t $(IMAGE_NAME):$(POSTGRES_TAG) .

push:
	docker push $(IMAGE_NAME):$(POSTGRES_TAG)

clean:
	docker rmi $(IMAGE_NAME):$(POSTGRES_TAG)

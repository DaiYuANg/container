group "default" {
  targets = [
    "redis-7-alpine",
    "redis-7-bookworm",
    "redis-8-alpine",
    "redis-8-bookworm",
    "redis-6-alpine",
    "redis-6-bookworm"
  ]
}

target "redis-7-alpine" {
  context = "."
  dockerfile = "Dockerfile"
  args = { REDIS_VERSION = "7-alpine" }
  tags = ["daiyuang/redis:7-alpine"]
}

target "redis-7-bookworm" {
  context = "."
  dockerfile = "Dockerfile"
  args = { REDIS_VERSION = "7-bookworm" }
  tags = ["daiyuang/redis:7-bookworm"]
}

target "redis-8-alpine" {
  context = "."
  dockerfile = "Dockerfile"
  args = { REDIS_VERSION = "8-alpine" }
  tags = ["daiyuang/redis:8-alpine"]
}

target "redis-8-bookworm" {
  context = "."
  dockerfile = "Dockerfile"
  args = { REDIS_VERSION = "8-bookworm" }
  tags = ["daiyuang/redis:8-bookworm"]
}

target "redis-6-alpine" {
  context = "."
  dockerfile = "Dockerfile"
  args = { REDIS_VERSION = "6-alpine" }
  tags = ["daiyuang/redis:6-alpine"]
}

target "redis-6-bookworm" {
  context = "."
  dockerfile = "Dockerfile"
  args = { REDIS_VERSION = "6-bookworm" }
  tags = ["daiyuang/redis:6-bookworm"]
}

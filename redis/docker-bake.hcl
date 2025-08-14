group "default" {
  targets = [
    "builder",
    "redis-standalone",
    "redis-replica",
    "redis-sentinel",
    "redis-cluster"
  ]
}

target "builder" {
  context = "."
  dockerfile = "dockerfile/Dockerfile.builder"
  tags = ["redis-builder:latest"]
}

target "redis-standalone" {
  name = "redis-standalone-${variant}-${replace(version, ".", "-")}"
  context = "."
  contexts = {
    builder = "target:builder"
  }
  matrix = {
    variant = ["alpine", "debian"]
    version = ["7", "8"]
  }
  target = variant
  args = {
    VERSION = version
  }
  dockerfile = "dockerfile/Dockerfile.standalone"
  tags = [
    "daiyuang/redis-standalone:${variant}-${version}"
  ]
  depends_on = ["builder"]
}

target "redis-replica" {
  name = "redis-replica-${variant}-${replace(version, ".", "-")}"
  context = "."
  contexts = {
    builder = "target:builder"
  }
  matrix = {
    variant = ["alpine", "debian"]
    version = ["7", "8"]
  }
  target = variant
  args = {
    VERSION = version
  }
  dockerfile = "dockerfile/Dockerfile.replica"
  tags = [
    "daiyuang/redis-replica:${variant}-${version}"
  ]
  depends_on = ["builder"]
}

target "redis-sentinel" {
  name = "redis-sentinel-${variant}-${replace(version, ".", "-")}"
  context = "."
  contexts = {
    builder = "target:builder"
  }
  matrix = {
    variant = ["alpine", "debian"]
    version = ["7", "8"]
  }
  target = variant
  args = {
    VERSION = version
  }
  dockerfile = "dockerfile/Dockerfile.sentinel"
  tags = [
    "daiyuang/redis-sentinel:${variant}-${version}"
  ]
  depends_on = ["builder"]
}

target "redis-cluster" {
  name = "redis-cluster-${variant}-${replace(version, ".", "-")}"
  context = "."
  contexts = {
    builder = "target:builder"
  }
  matrix = {
    variant = ["alpine", "debian"]
    version = ["7", "8"]
  }
  target = variant
  args = {
    VERSION = version
  }
  dockerfile = "dockerfile/Dockerfile.cluster"
  tags = [
    "daiyuang/redis-cluster:${variant}-${version}"
  ]
  depends_on = ["builder"]
}
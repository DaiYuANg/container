import docker
from git import Repo


def get_commit_hash(repo_path='.'):
    repo = Repo(repo_path)
    commit = repo.head.commit
    return commit.hexsha, commit.hexsha[:7]

def build_base_debian_image():
  client = docker.from_env()

  image, logs = client.images.build(
    path="./base_debian",  # Dockerfile所在目录
    tag="base-debian:latest",
    rm=True,  # 构建时自动移除中间容器
    pull=True
  )

  print(f"镜像构建成功: {image.tags}")
  full_hash, short_hash = get_commit_hash()
  print(f"Full: {full_hash}")
  print(f"Short: {short_hash}")
  # 输出构建日志
  for chunk in logs:
    if 'stream' in chunk:
      print(chunk['stream'], end='')


if __name__ == "__main__":
  build_base_debian_image()

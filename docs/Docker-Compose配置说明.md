# Docker Compose 配置说明

## 问题

Jenkins Pipeline 中执行 `docker-compose` 命令时报错：`docker-compose: not found`

## 原因

Jenkins 容器内没有安装 `docker-compose`（V1），需要使用 `docker compose`（V2）。

## 解决方案

### 方案一：使用 Docker Compose V2（推荐）

已修改 Jenkinsfile，将 `docker-compose` 改为 `docker compose`：

```groovy
sh """
    docker compose -f ${COMPOSE_FILE} build --no-cache
    docker compose -f ${COMPOSE_FILE} up -d
"""
```

### 方案二：挂载 Docker Compose 插件

已在 `docker-compose.yml` 中添加挂载：

```yaml
volumes:
  - /usr/libexec/docker/cli-plugins:/usr/libexec/docker/cli-plugins:ro
```

### 方案三：如果还是不行，创建别名

在 Jenkinsfile 中添加：

```groovy
sh """
    alias docker-compose='docker compose' || true
    docker compose -f ${COMPOSE_FILE} build --no-cache
    docker compose -f ${COMPOSE_FILE} up -d
"""
```

## 验证

在 Jenkins 容器内测试：

```bash
# 检查 docker compose 是否可用
docker exec jenkins docker compose version

# 如果不可用，检查插件位置
docker exec jenkins ls -la /usr/libexec/docker/cli-plugins/
```

## 已修改的文件

- `ruoyi-deploy/Jenkinsfile` - 已改为使用 `docker compose`
- `RuoYi-Vue/Jenkinsfile` - 已改为使用 `docker compose`
- `docker-compose.yml` - 已添加 Docker Compose 插件挂载

## 注意事项

- Docker Compose V2 是 Docker CLI 的插件，命令格式为 `docker compose`（有空格）
- Docker Compose V1 是独立工具，命令格式为 `docker-compose`（有连字符）
- 推荐使用 V2，因为它是 Docker 官方推荐的版本

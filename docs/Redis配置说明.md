# Redis 配置说明

## 概述

Redis 已添加到 CI/CD 环境中，可以在 Jenkins 流水线中使用。Redis 服务与 Jenkins 在同一个 Docker 网络中，应用容器可以通过网络名称 `redis` 访问 Redis。

## 启动 Redis

### 方式一：使用 Docker Compose（推荐）

```bash
# 启动所有服务（包括 Jenkins 和 Redis）
docker compose up -d

# 只启动 Redis
docker compose up -d redis

# 查看 Redis 日志
docker compose logs -f redis
```

### 方式二：在 Jenkins 流水线中自动启动

Jenkinsfile 已配置自动启动 Redis，在部署阶段会自动检查并启动 Redis 服务。

## 连接信息

### 在容器内连接（应用容器）

- **主机**: `redis`
- **端口**: `6379`
- **连接字符串**: `redis://redis:6379`

### 在宿主机连接

- **主机**: `localhost` 或 `127.0.0.1`
- **端口**: `6379`
- **连接字符串**: `redis://localhost:6379`

### 在 Jenkins 容器内连接

- **主机**: `redis`
- **端口**: `6379`

## 测试 Redis 连接

### 在宿主机测试

```bash
# 使用 redis-cli（需要安装 Redis 客户端）
redis-cli -h localhost -p 6379 ping
# 应该返回: PONG

# 或者使用 Docker
docker exec -it redis redis-cli ping
```

### 在应用容器中测试

```bash
# 进入应用容器
docker exec -it myapp sh

# 如果应用容器安装了 redis-cli
redis-cli -h redis -p 6379 ping
```

### 在 Jenkins 流水线中测试

可以在 Jenkinsfile 中添加测试步骤：

```groovy
stage('测试Redis连接') {
    steps {
        sh '''
            docker run --rm --network cicd-network redis:7-alpine redis-cli -h redis ping
        '''
    }
}
```

## 环境变量

应用容器可以通过以下环境变量配置 Redis 连接：

- `REDIS_HOST=redis` - Redis 主机地址（容器内使用）
- `REDIS_PORT=6379` - Redis 端口
- `REDIS_URL=redis://redis:6379` - Redis 完整连接 URL

## 数据持久化

Redis 数据存储在 Docker 数据卷 `redis_data` 中，即使容器重启数据也不会丢失。

### 查看数据卷

```bash
docker volume ls | grep redis
```

### 备份 Redis 数据

```bash
# 创建备份
docker exec redis redis-cli SAVE
docker cp redis:/data/dump.rdb ./redis-backup-$(date +%Y%m%d).rdb
```

### 恢复 Redis 数据

```bash
# 停止 Redis
docker compose stop redis

# 复制备份文件到容器
docker cp ./redis-backup-20240205.rdb redis:/data/dump.rdb

# 启动 Redis
docker compose start redis
```

## 常用 Redis 命令

### 查看 Redis 信息

```bash
# 进入 Redis 容器
docker exec -it redis redis-cli

# 查看所有键
KEYS *

# 查看 Redis 信息
INFO

# 查看内存使用
INFO memory

# 退出
exit
```

### 清空 Redis 数据

```bash
# 清空所有数据（谨慎操作）
docker exec redis redis-cli FLUSHALL

# 清空当前数据库
docker exec redis redis-cli FLUSHDB
```

## 在应用中使用 Redis

### Node.js 示例

```javascript
const redis = require('redis');

const client = redis.createClient({
    host: process.env.REDIS_HOST || 'redis',
    port: process.env.REDIS_PORT || 6379
});

client.on('error', (err) => {
    console.error('Redis 错误:', err);
});

client.on('connect', () => {
    console.log('Redis 连接成功');
});

// 使用示例
async function example() {
    await client.set('key', 'value');
    const value = await client.get('key');
    console.log(value);
}
```

### 安装 Redis 客户端

在 `package.json` 中添加：

```json
{
  "dependencies": {
    "redis": "^4.6.0"
  }
}
```

## 故障排查

### Redis 无法连接

1. **检查容器是否运行**
   ```bash
   docker ps | grep redis
   ```

2. **检查网络连接**
   ```bash
   # 在应用容器中测试
   docker exec myapp ping redis
   ```

3. **查看 Redis 日志**
   ```bash
   docker compose logs redis
   ```

### Redis 端口被占用

如果 6379 端口被占用，可以修改 `docker-compose.yml` 中的端口映射：

```yaml
ports:
  - "6380:6379"  # 改为其他端口
```

### Redis 数据丢失

- 检查数据卷是否正确挂载：`docker volume inspect redis_data`
- 检查 Redis 配置：`docker exec redis redis-cli CONFIG GET appendonly`

## 性能优化

### 设置 Redis 密码（生产环境推荐）

在 `docker-compose.yml` 中修改 Redis 服务：

```yaml
redis:
  command: redis-server --appendonly yes --requirepass yourpassword
```

然后在应用中连接时提供密码：

```javascript
const client = redis.createClient({
    host: 'redis',
    port: 6379,
    password: 'yourpassword'
});
```

### 内存限制

```yaml
redis:
  command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
```

## 监控

### 使用 Redis Insight（可选）

可以添加 Redis Insight 服务来可视化监控 Redis：

```yaml
redis-insight:
  image: redis/redis-insight:latest
  ports:
    - "8001:8001"
  networks:
    - cicd-network
  depends_on:
    - redis
```

访问：http://localhost:8001

## 相关文件

- `docker-compose.yml` - Redis 服务配置
- `Jenkinsfile` - 流水线中的 Redis 启动步骤

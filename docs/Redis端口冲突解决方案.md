# Redis 端口冲突解决方案

## 问题说明

错误信息：`failed to bind host port 0.0.0.0:6379/tcp: address already in use`

**原因**：6379 端口已经被其他服务占用（可能是另一个 Redis 实例、其他应用或之前的容器）

## 解决方案

### 方案一：检查并停止占用端口的服务（推荐）

#### 步骤 1：检查是什么占用了 6379 端口

```bash
# 查看占用 6379 端口的进程
sudo netstat -tulpn | grep 6379
# 或
sudo lsof -i :6379
# 或
sudo ss -tulpn | grep 6379
```

#### 步骤 2：根据结果处理

**情况 A：如果是 Docker 容器占用的**

```bash
# 查看所有 Redis 相关的容器
docker ps -a | grep redis

# 如果看到有其他 Redis 容器在运行，停止并删除它
docker stop <容器名或ID>
docker rm <容器名或ID>

# 或者停止所有名为 redis 的容器
docker stop redis 2>/dev/null || true
docker rm redis 2>/dev/null || true
```

**情况 B：如果是系统 Redis 服务**

```bash
# 检查 Redis 服务状态
sudo systemctl status redis
# 或
sudo systemctl status redis-server

# 如果正在运行，停止它
sudo systemctl stop redis
# 或
sudo systemctl stop redis-server

# 如果不想让它开机自启
sudo systemctl disable redis
# 或
sudo systemctl disable redis-server
```

**情况 C：如果是其他进程**

```bash
# 找到进程 ID (PID)
sudo lsof -i :6379

# 停止该进程（替换 <PID> 为实际的进程 ID）
sudo kill <PID>

# 如果进程不响应，强制停止
sudo kill -9 <PID>
```

#### 步骤 3：确认端口已释放

```bash
# 再次检查，应该没有输出
sudo lsof -i :6379
```

#### 步骤 4：重新启动 Docker Compose

```bash
docker compose up -d
```

---

### 方案二：修改 Redis 端口映射（如果无法停止占用端口的服务）

如果 6379 端口被其他重要服务占用，无法停止，可以修改 Docker Compose 配置使用其他端口。

#### 步骤 1：编辑 docker-compose.yml

找到 Redis 服务的端口映射部分：

```yaml
redis:
  ports:
    - "6379:6379"  # 改为其他端口，例如 6380
```

修改为：

```yaml
redis:
  ports:
    - "6380:6379"  # 宿主机使用 6380，容器内仍是 6379
```

#### 步骤 2：更新应用连接配置

如果应用需要从宿主机连接 Redis，需要更新连接地址：

- **容器内连接**：仍然是 `redis:6379`（不变）
- **宿主机连接**：改为 `localhost:6380`（新端口）

#### 步骤 3：重新启动服务

```bash
# 先停止并删除旧的容器
docker compose down

# 重新启动
docker compose up -d
```

---

## 快速诊断命令

### 一键检查脚本

```bash
echo "=== 检查 6379 端口占用 ==="
sudo lsof -i :6379 || echo "端口未被占用"

echo ""
echo "=== 检查 Redis 容器 ==="
docker ps -a | grep redis || echo "没有 Redis 容器"

echo ""
echo "=== 检查 Redis 系统服务 ==="
systemctl list-units | grep redis || echo "没有 Redis 系统服务"
```

---

## 常见情况处理

### 情况 1：之前启动失败的 Redis 容器还在

```bash
# 查看所有容器（包括停止的）
docker ps -a

# 删除名为 redis 的容器
docker rm -f redis

# 重新启动
docker compose up -d
```

### 情况 2：Windows 上安装了 Redis

如果是在 Windows 上通过其他方式安装了 Redis：

```bash
# WSL 中检查
ps aux | grep redis

# 如果找到进程，停止它
sudo pkill redis
```

### 情况 3：Docker Desktop 中有其他 Redis 容器

```bash
# 查看所有运行中的容器
docker ps

# 查找占用 6379 的容器
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 6379

# 停止相关容器
docker stop <容器名>
```

---

## 验证 Redis 是否正常启动

启动成功后，验证 Redis 是否正常工作：

```bash
# 检查容器状态
docker ps | grep redis

# 测试 Redis 连接
docker exec redis redis-cli ping
# 应该返回: PONG

# 查看 Redis 日志
docker compose logs redis
```

---

## 预防措施

### 1. 启动前检查端口

```bash
# 在启动前先检查
if sudo lsof -i :6379 > /dev/null 2>&1; then
    echo "警告：6379 端口已被占用"
    sudo lsof -i :6379
else
    echo "6379 端口可用"
    docker compose up -d
fi
```

### 2. 使用不同的端口映射

如果经常遇到端口冲突，可以在 `docker-compose.yml` 中使用非标准端口：

```yaml
redis:
  ports:
    - "6380:6379"  # 使用 6380 而不是 6379
```

---

## 总结

**最简单的解决方法**：

1. 检查是否有其他 Redis 容器：`docker ps -a | grep redis`
2. 删除冲突的容器：`docker rm -f redis`（如果有）
3. 重新启动：`docker compose up -d`

如果还是不行，使用方案二修改端口映射。

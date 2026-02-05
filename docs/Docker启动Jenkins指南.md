# Docker 启动 Jenkins 完整指南

## 快速启动

### 方法一：使用 Docker Compose（推荐）

```bash
# 1. 确保 Docker 正在运行
docker --version
docker info

# 2. 创建数据卷（首次使用）
docker volume create dockerlearn_jenkins_home

# 3. 启动 Jenkins
docker compose up -d

# 4. 查看日志（等待约 30 秒）
docker compose logs -f jenkins

# 5. 获取初始密码
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# 6. 访问 Jenkins
# 浏览器打开：http://localhost:8082
```

### 方法二：使用启动脚本

```bash
# 在 WSL 中执行
chmod +x start.sh
./start.sh
```

### 方法三：纯 Docker 命令

```bash
docker run -d \
  --name jenkins \
  -p 8082:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --restart unless-stopped \
  jenkins/jenkins:lts
```

## 常用管理命令

### 查看状态
```bash
# 查看容器状态
docker ps | grep jenkins

# 查看日志
docker compose logs -f jenkins
# 或
docker logs -f jenkins
```

### 停止和启动
```bash
# 停止 Jenkins
docker compose stop jenkins
# 或
docker stop jenkins

# 启动 Jenkins
docker compose start jenkins
# 或
docker start jenkins

# 重启 Jenkins
docker compose restart jenkins
# 或
docker restart jenkins
```

### 完全删除（注意：会删除所有数据）
```bash
# 停止并删除容器
docker compose down

# 删除数据卷（会丢失所有 Jenkins 配置和数据）
docker volume rm dockerlearn_jenkins_home
```

## 配置说明

### 端口映射
- `8082:8080` - Jenkins Web 界面端口（宿主机 8082 → 容器 8080）
- `50000:50000` - Jenkins Agent 通信端口

### 数据持久化
- `jenkins_home:/var/jenkins_home` - Jenkins 数据卷，保存所有配置、插件、任务等
- `./jenkins-ssh:/var/jenkins_home/.ssh` - SSH 密钥目录（如果配置了）

### Docker Socket 挂载
- `/var/run/docker.sock:/var/run/docker.sock` - 允许 Jenkins 容器使用宿主机 Docker
- `/usr/bin/docker:/usr/bin/docker` - Docker 可执行文件（WSL 环境）

## 首次使用步骤

1. **启动 Jenkins**（见上方快速启动）

2. **获取初始密码**
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```

3. **访问 Web 界面**
   - 打开浏览器：http://localhost:8082
   - 输入初始密码

4. **安装推荐插件**
   - 选择"安装推荐的插件"
   - 等待安装完成

5. **创建管理员账户**
   - 设置用户名、密码、邮箱

6. **完成初始化**
   - 进入 Jenkins 首页

## 故障排查

### 问题：端口被占用
```bash
# 检查端口占用
netstat -tuln | grep 8082
# 或
lsof -i :8082

# 修改 docker-compose.yml 中的端口映射
# 例如改为 8083:8080
```

### 问题：容器无法启动
```bash
# 查看详细错误日志
docker compose logs jenkins

# 检查数据卷
docker volume ls | grep jenkins

# 检查 Docker 是否正常运行
docker info
```

### 问题：无法访问 Web 界面
- 确认容器正在运行：`docker ps`
- 确认端口映射正确：`docker port jenkins`
- 检查防火墙设置
- 在 WSL 中访问：`http://localhost:8082`
- 在 Windows 浏览器中访问：`http://localhost:8082`

### 问题：忘记管理员密码
```bash
# 重置管理员密码（需要进入容器）
docker exec -it jenkins bash
cd /var/jenkins_home
# 编辑 config.xml，将 <useSecurity>true</useSecurity> 改为 false
# 重启容器后可以无密码登录，然后重新设置密码
```

## 备份和恢复

### 备份 Jenkins 数据
```bash
# 备份数据卷
docker run --rm \
  -v dockerlearn_jenkins_home:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/jenkins-backup.tar.gz /data
```

### 恢复 Jenkins 数据
```bash
# 停止 Jenkins
docker compose down

# 恢复数据卷
docker run --rm \
  -v dockerlearn_jenkins_home:/data \
  -v $(pwd):/backup \
  ubuntu tar xzf /backup/jenkins-backup.tar.gz -C /

# 启动 Jenkins
docker compose up -d
```

## 升级 Jenkins

```bash
# 1. 备份数据（见上方备份步骤）

# 2. 停止当前容器
docker compose down

# 3. 拉取新版本镜像
docker pull jenkins/jenkins:lts

# 4. 启动新版本
docker compose up -d

# 5. 检查日志确认升级成功
docker compose logs -f jenkins
```

## 环境变量说明

当前配置中的环境变量：
- `DOCKER_HOST=unix:///var/run/docker.sock` - Docker 连接地址
- `JAVA_OPTS=-Djenkins.install.runSetupWizard=true` - Java 启动参数

## 注意事项

1. **数据持久化**：Jenkins 的所有数据存储在 Docker 数据卷中，删除容器不会丢失数据
2. **权限问题**：容器以 root 用户运行，确保有足够权限访问 Docker socket
3. **WSL 环境**：在 WSL 中使用时，确保 Docker Desktop 已正确配置 WSL 集成
4. **网络访问**：确保防火墙允许访问 8082 端口
5. **资源限制**：Jenkins 需要一定内存，建议至少 512MB 可用内存

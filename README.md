# CI/CD 环境搭建指南

本项目使用 **GitHub**（代码仓库）+ **Jenkins**（流水线）+ **Docker**（构建与运行）搭建完整 CI/CD。

> **在 WSL 下搭建？** 请直接看 **[WSL 搭建步骤](docs/WSL-CICD-搭建步骤.md)**，按文档顺序操作即可。

## 架构说明

- **GitHub**: 代码仓库
- **Jenkins**: CI/CD 自动化工具
- **Docker**: 容器化应用

## 前置要求

1. WSL2 已安装并运行
2. Docker 已安装
3. Docker Compose 已安装
4. Git 已安装

## 快速开始

### 1. 启动 Jenkins

```bash
# 一键启动（推荐）
./start.sh

# 或手动启动
docker compose up -d   # 或 docker-compose up -d

# 查看 Jenkins 日志
docker compose logs -f jenkins
```

### 2. 初始化 Jenkins

1. 访问 http://localhost:8080
2. 获取初始管理员密码：
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```
3. 安装推荐的插件
4. 创建管理员账户

### 3. 安装必要的 Jenkins 插件

在 Jenkins 管理界面安装以下插件：
- **Git Plugin**: GitHub 集成
- **Docker Pipeline Plugin**: Docker 支持
- **Pipeline Plugin**: Pipeline 支持
- **GitHub Plugin**: GitHub 集成增强

### 4. 配置 Jenkins

#### 配置 Docker

1. 进入 Jenkins 管理界面 → 系统管理 → 系统配置
2. 确保 Jenkins 可以访问 Docker（已通过 volume 挂载）

#### 配置 GitHub

1. 进入 Jenkins 管理界面 → 系统管理 → 系统配置
2. 添加 GitHub 凭据（Personal Access Token）

### 5. 创建 Jenkins Pipeline 任务

1. 点击"新建任务"
2. 选择"流水线"（Pipeline）
3. 在 Pipeline 配置中：
   - **定义**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: 你的 GitHub 仓库地址
   - **Credentials**: 添加 GitHub 凭据
   - **Branch Specifier**: `*/main` 或 `*/master`
   - **Script Path**: `Jenkinsfile`

### 6. 测试 CI/CD 流程

1. 推送代码到 GitHub
2. 在 Jenkins 中触发构建
3. 查看构建日志

## 项目结构

```
.
├── docker-compose.yml    # Jenkins 服务配置
├── Jenkinsfile          # CI/CD Pipeline 配置
├── Dockerfile           # 应用 Docker 镜像配置
├── server.js            # 示例 Node.js 应用
├── package.json         # Node.js 依赖配置
└── README.md           # 本文件
```

## 常用命令

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 查看日志
docker-compose logs -f jenkins

# 重启 Jenkins
docker-compose restart jenkins

# 进入 Jenkins 容器
docker exec -it jenkins bash

# 查看 Jenkins 数据卷
docker volume ls
```

## GitHub Webhook 配置（可选）

为了在代码推送时自动触发 Jenkins 构建：

1. 在 GitHub 仓库设置中添加 Webhook
2. URL: `http://your-jenkins-url:8080/github-webhook/`
3. Content type: `application/json`
4. 选择事件: `Just the push event`

注意：如果 Jenkins 在本地运行，需要使用 ngrok 等工具暴露到公网。

## 故障排查

### Jenkins 无法访问 Docker

确保 docker-compose.yml 中正确挂载了 Docker socket：
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
  - /usr/bin/docker:/usr/bin/docker
```

### 权限问题

如果遇到权限问题，可以尝试：
```bash
sudo chmod 666 /var/run/docker.sock
```

### 端口冲突

如果 8080 端口被占用，修改 docker-compose.yml 中的端口映射。

## 下一步

- 添加自动化测试
- 配置多环境部署（开发/测试/生产）
- 集成代码质量检查工具
- 添加通知（邮件/Slack等）

## 参考资源

- [Jenkins 官方文档](https://www.jenkins.io/doc/)
- [Docker 官方文档](https://docs.docker.com/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

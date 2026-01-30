# WSL 下 GitHub + Jenkins + Docker CI/CD 搭建步骤

在 WSL 中按以下顺序操作即可完成整套 CI/CD 环境。

---

## 一、环境准备（WSL 内）

### 1. 确认 Docker 已安装并运行

```bash
# 检查 Docker
docker --version
docker info
```

若未安装：

- **方式 A**：在 Windows 安装 [Docker Desktop](https://www.docker.com/products/docker-desktop/)，并勾选「Use the WSL 2 based engine」和你的 WSL 发行版（如 Ubuntu）。
- **方式 B**：在 WSL 内直接安装 Docker Engine：  
  https://docs.docker.com/engine/install/ubuntu/

### 2. 确认 Docker Compose 可用

```bash
docker compose version
# 或
docker-compose --version
```

### 3. 若拉取镜像超时（context deadline exceeded）

国内访问 Docker Hub 常超时，可配置**镜像加速**后再执行 `./start.sh`。

**优先推荐：使用 Docker Desktop（Windows）时**  
在 Windows 里打开 Docker Desktop → **Settings** → **Docker Engine**，在 JSON 里加上（或合并进已有配置）：

```json
"registry-mirrors": ["https://docker.1ms.run", "https://docker.xuanyuan.me"]
```

点 **Apply & Restart**。这样不会动 WSL 里的 Docker 配置，最稳。

**WSL 内单独安装了 Docker Engine 时**  
编辑 `/etc/docker/daemon.json`，内容只保留下面一段（不要多写别的）：

```json
{
  "registry-mirrors": ["https://docker.1ms.run"]
}
```

保存后执行：`sudo systemctl restart docker`。  
若重启后 Docker 起不来（`systemctl status docker` 报错），先恢复成空配置再重试：

```bash
echo '{}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
```

确认 `docker info` 正常后，再重新按上面添加 `registry-mirrors`（可先只保留一个镜像地址）。

然后再执行 `./start.sh` 拉取 `jenkins/jenkins:lts`。

---

## 二、启动 Jenkins

在项目根目录（`dockerlearn`）执行（**注意：必须写 `./start.sh`，不能只写 `start.sh`**）：

```bash
./start.sh
```

若提示 `Permission denied`，先执行：`chmod +x start.sh`，再运行 `./start.sh`。  
若提示 `cannot execute: required file not found`，多半是 Windows 换行符（CRLF）导致，在 WSL 里执行：`sed -i 's/\r$//' start.sh` 后再运行 `./start.sh`。

或手动启动：

```bash
docker compose up -d
# 等待约 30 秒后获取初始密码
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

浏览器访问：**http://localhost:8080**（若在 Windows 浏览器访问，用 `localhost` 即可）。

---

## 三、初始化 Jenkins

1. 输入上一步得到的**初始管理员密码**，继续。
2. 选择「安装推荐的插件」，等待完成。
3. 创建管理员用户（用户名/密码/邮箱），保存。
4. 进入 Jenkins 首页后，再安装与 GitHub/Docker 相关的插件：
   - **管理 Jenkins** → **管理插件** → **可选插件**
   - 搜索并安装（如未安装）：
     - **Git**
     - **Pipeline**
     - **Docker Pipeline**
     - **GitHub**（或 **GitHub Integration**）
   - 安装后如提示重启，点「重启」。

---

## 四、在 GitHub 创建 Personal Access Token（给 Jenkins 用）

1. 登录 GitHub → 右上角头像 → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**。
2. **Generate new token (classic)**：
   - Note：例如 `Jenkins CI/CD`
   - Expiration：按需选择（如 90 天）
   - 勾选权限：**repo**（完整仓库访问）
3. 生成后**复制 Token**（只显示一次），保存到记事本，后面在 Jenkins 里粘贴。

---

## 五、在 Jenkins 里添加 GitHub 凭据

1. **管理 Jenkins** → **凭据** → **系统** → **全局凭据** → **添加凭据**。
2. 填写：
   - **类型**：Secret text
   - **Secret**：粘贴刚才的 GitHub Token
   - **ID**：例如 `github-token`
   - **描述**：例如 `GitHub PAT`
3. 保存。

---

## 六、创建 Pipeline 任务（从 GitHub 拉代码并跑 Jenkinsfile）

1. Jenkins 首页 → **新建任务**。
2. 输入任务名称（如 `dockerlearn-pipeline`），选择 **流水线**，确定。
3. 在任务配置中：
   - **构建触发器**（可选）：
     - 勾选 **GitHub hook trigger for GITScm polling**（若后面配置了 Webhook）
     - 或勾选 **轮询 SCM**，日程表填 `H/2 * * * *`（每 2 分钟检查一次）
   - **Pipeline** 区域：
     - **定义**：Pipeline script from SCM
     - **SCM**：Git
     - **Repository URL**：你的仓库地址，例如  
       `https://github.com/你的用户名/dockerlearn.git`
     - **凭据**：选择刚才添加的 GitHub 凭据（如 `github-token`）
     - **分支**：`*/main` 或 `*/master`（与仓库默认分支一致）
     - **Script Path**：`Jenkinsfile`
4. 保存。

---

## 七、验证流程（代码 → Jenkins → Docker）

1. 在项目里做一次小改动并推送到 GitHub：
   ```bash
   git add .
   git commit -m "ci: trigger pipeline"
   git push origin main
   ```
2. 若开启了「轮询 SCM」或已配置 Webhook，Jenkins 会自动触发构建；否则在任务页点击「立即构建」。
3. 在「构建历史」里点进本次构建 → **Console Output**，应能看到：
   - 检出代码
   - 构建 Docker 镜像
   - 运行 `npm test`
   - （main 分支）推送镜像、部署等步骤的日志。

至此，**GitHub（代码）→ Jenkins（流水线）→ Docker（构建/运行）** 的 CI/CD 链路已在 WSL 下打通。

---

## 八、可选：GitHub Webhook 自动触发（Jenkins 能被外网访问时）

若 Jenkins 有公网 URL（例如通过 ngrok、内网穿透或云服务器）：

1. GitHub 仓库 → **Settings** → **Webhooks** → **Add webhook**。
2. **Payload URL**：`http://你的Jenkins公网地址/github-webhook/`  
   例如：`https://your-ngrok-url.ngrok.io/github-webhook/`
3. **Content type**：`application/json`。
4. 选择 **Just the push event**，保存。

这样每次 push 到该仓库会自动触发对应 Jenkins 任务；在 WSL 本机只跑 Jenkins 时，用「轮询 SCM」即可。

---

## 九、常用命令

```bash
# 启动
docker compose up -d

# 查看 Jenkins 日志
docker compose logs -f jenkins

# 停止
docker compose down

# 再次查看初始密码（仅首次有用）
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## 十、故障排查

| 现象 | 可能原因 | 处理 |
|------|----------|------|
| `docker.service` 报错：`process with PID xxx is still running` 或 `no sockets found via socket activation` | WSL 里同时存在 **Docker Desktop** 的 daemon 和 **systemd 的 docker.service**，二者冲突 | **不要**再执行 `sudo systemctl start docker`。当前可用的 Docker 多半是 Docker Desktop 提供的，在 WSL 里直接执行 `docker info` 能通即可。镜像加速请在 **Windows → Docker Desktop → Settings → Docker Engine** 里配置。 |
| `docker` 命令在 Pipeline 里报错 | Jenkins 容器访问不到宿主机 Docker | 确认 `docker-compose.yml` 中挂载了 `/var/run/docker.sock` 和 `/usr/bin/docker`，且 Jenkins 以 root 运行 |
| 拉取镜像 `context deadline exceeded` | 国内访问 Docker Hub 超时 | 在 **Docker Desktop → Settings → Docker Engine** 里添加 `registry-mirrors`（见第三节），不要改 WSL 的 `/etc/docker/daemon.json`，以免和 Docker Desktop 冲突。 |
| 8080 无法访问 | 端口被占用或防火墙 | 换端口或检查 WSL/Windows 防火墙 |
| 拉不到 GitHub 代码 | 凭据错误或无权限 | 检查 Token 是否勾选 repo，Jenkins 里凭据是否选对 |
| Webhook 不触发 | Jenkins 在内网 | 使用「轮询 SCM」或为 Jenkins 配置公网访问后再用 Webhook |

按上述步骤在 WSL 中操作即可完成 **GitHub + Jenkins + Docker** 的 CI/CD 搭建。

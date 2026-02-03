# Jenkins SSH 密钥持久化配置说明

## 问题原因

**为什么 SSH 密钥会消失？**

1. **Docker 数据卷问题**：
   - Jenkins 数据存储在 Docker 数据卷 `dockerlearn_jenkins_home` 中
   - 虽然数据卷理论上应该持久化，但在某些情况下（WSL 环境、Docker Desktop 重启等）可能出现问题
   - SSH 密钥存储在 `/var/jenkins_home/.ssh/` 目录中，如果数据卷丢失或重置，密钥也会丢失

2. **权限问题**：
   - 容器以 `root` 用户运行，但 SSH 密钥可能是 `jenkins` 用户创建的
   - 重启后权限可能发生变化

3. **WSL 环境特殊性**：
   - WSL 环境下 Docker 数据卷的持久化可能不如原生 Linux 稳定
   - Windows 重启可能影响 WSL 和 Docker 的状态

## 解决方案

**将 SSH 密钥目录挂载到宿主机文件系统**

通过将 `./jenkins-ssh` 目录挂载到容器内的 `/var/jenkins_home/.ssh`，确保密钥存储在宿主机文件系统中，而不是 Docker 数据卷中。

### 配置步骤

#### 1. 初始化 SSH 密钥（首次使用）

```bash
# 给脚本添加执行权限
chmod +x setup-ssh.sh

# 运行初始化脚本
./setup-ssh.sh
```

脚本会自动：
- 创建 `jenkins-ssh` 目录
- 生成 SSH 密钥对
- 设置正确的权限
- 添加 GitHub 到 known_hosts
- 显示公钥内容（需要添加到 GitHub）

#### 2. 将公钥添加到 GitHub

1. 复制 `setup-ssh.sh` 输出的公钥内容
2. 登录 GitHub → Settings → SSH and GPG keys → New SSH key
3. Title：例如 `Jenkins Docker`
4. Key：粘贴公钥内容
5. 点击 Add SSH key

#### 3. 在 Jenkins 中配置 SSH 凭据

1. 访问 Jenkins：http://localhost:8082
2. 管理 Jenkins → 凭据 → 系统 → 全局凭据 → 添加凭据
3. 填写：
   - **类型**：SSH Username with private key
   - **Username**：`git`
   - **Private Key**：选择 "Enter directly"
   - 执行以下命令获取私钥内容：
     ```bash
     cat ./jenkins-ssh/id_rsa
     ```
     复制输出的内容粘贴到 Jenkins
   - **ID**：例如 `github-ssh-key`
   - **描述**：例如 `GitHub SSH Key`
4. 保存

#### 4. 重启 Jenkins 使配置生效

```bash
docker compose restart
```

#### 5. 测试 SSH 连接

```bash
docker exec jenkins ssh -T git@github.com
```

应该看到类似以下输出：
```
Hi Sean1-rgb! You've successfully authenticated, but GitHub does not provide shell access.
```

## 文件说明

### docker-compose.yml

已添加 SSH 目录挂载：

```yaml
volumes:
  - jenkins_home:/var/jenkins_home
  - ./jenkins-ssh:/var/jenkins_home/.ssh  # SSH 密钥持久化
  - /var/run/docker.sock:/var/run/docker.sock
  - /usr/bin/docker:/usr/bin/docker
```

### .gitignore

已添加 SSH 私钥到忽略列表：

```
jenkins-ssh/id_rsa
jenkins-ssh/*.key
```

**注意**：私钥不会提交到 Git，但公钥和 known_hosts 可以提交（用于文档和团队共享）。

## 验证持久化

重启电脑后验证：

```bash
# 1. 检查密钥文件是否存在
ls -la jenkins-ssh/

# 2. 重启 Jenkins
docker compose restart

# 3. 检查容器内的密钥
docker exec jenkins ls -la /var/jenkins_home/.ssh/

# 4. 测试 SSH 连接
docker exec jenkins ssh -T git@github.com
```

## 故障排查

### 问题：权限错误

```bash
# 修复权限
chmod 700 jenkins-ssh
chmod 600 jenkins-ssh/id_rsa
chmod 644 jenkins-ssh/id_rsa.pub
chmod 644 jenkins-ssh/known_hosts
```

### 问题：known_hosts 丢失

```bash
ssh-keyscan github.com >> ./jenkins-ssh/known_hosts
chmod 644 ./jenkins-ssh/known_hosts
```

### 问题：容器内权限问题

如果容器内文件权限不对，可以进入容器修复：

```bash
docker exec -it jenkins bash
chown -R jenkins:jenkins /var/jenkins_home/.ssh
chmod 700 /var/jenkins_home/.ssh
chmod 600 /var/jenkins_home/.ssh/id_rsa
exit
```

## 优势

✅ **持久化**：密钥存储在宿主机文件系统，不会因容器重启而丢失  
✅ **可备份**：可以直接备份 `jenkins-ssh` 目录  
✅ **可移植**：可以轻松迁移到其他环境  
✅ **安全性**：私钥已添加到 .gitignore，不会意外提交到 Git  

## 注意事项

1. **备份**：定期备份 `jenkins-ssh` 目录
2. **权限**：确保目录和文件权限正确
3. **Git**：不要将私钥提交到 Git（已配置 .gitignore）
4. **多环境**：如果有多台机器，每台机器需要单独生成密钥并添加到 GitHub

# Jenkins Git SSH 主机密钥验证失败解决方案

## 问题说明

错误信息：
```
No ED25519 host key is known for github.com and you have requested strict checking.
Host key verification failed.
```

**原因**：Jenkins 容器内的 `known_hosts` 文件不存在或没有 GitHub 的主机密钥。

## 解决方案

### 方案一：添加 GitHub 到 known_hosts（推荐）

#### 步骤 1：确保 jenkins-ssh 目录存在并添加 GitHub 主机密钥

```bash
# 进入项目目录
cd ~/dockerlearn

# 创建 jenkins-ssh 目录（如果不存在）
mkdir -p jenkins-ssh
chmod 700 jenkins-ssh

# 添加 GitHub 到 known_hosts
ssh-keyscan github.com >> ./jenkins-ssh/known_hosts

# 设置正确的权限
chmod 644 ./jenkins-ssh/known_hosts
```

#### 步骤 2：重启 Jenkins 容器使配置生效

```bash
docker compose restart jenkins
```

#### 步骤 3：验证配置

```bash
# 进入 Jenkins 容器检查
docker exec jenkins cat /var/jenkins_home/.ssh/known_hosts

# 应该能看到 github.com 的主机密钥
```

---

### 方案二：在 Jenkins 中配置 Git Host Key Verification（临时方案）

如果方案一不行，可以在 Jenkins 管理界面配置：

1. **进入 Jenkins 管理界面**
   - 访问：http://localhost:8082
   - 登录管理员账户

2. **配置 Git Host Key Verification**
   - 点击：**管理 Jenkins** → **Security** → **Git Host Key Verification Configuration**
   - 选择：**Accept first connection** 或 **No verification**
   - 保存

**注意**：这个方案安全性较低，建议使用方案一。

---

### 方案三：使用 setup-ssh.sh 脚本（完整配置）

如果还没有配置 SSH 密钥，可以运行完整脚本：

```bash
# 给脚本添加执行权限
chmod +x setup-ssh.sh

# 运行脚本（会自动添加 GitHub 到 known_hosts）
./setup-ssh.sh
```

---

## 快速修复命令（一键执行）

```bash
cd ~/dockerlearn

# 创建目录（如果不存在）
mkdir -p jenkins-ssh
chmod 700 jenkins-ssh

# 添加 GitHub 主机密钥
ssh-keyscan github.com >> ./jenkins-ssh/known_hosts 2>/dev/null

# 设置权限
chmod 644 ./jenkins-ssh/known_hosts

# 重启 Jenkins
docker compose restart jenkins

# 验证
echo "检查 known_hosts 文件："
docker exec jenkins cat /var/jenkins_home/.ssh/known_hosts | grep github.com
```

---

## 验证修复是否成功

修复后，重新运行 Jenkins 任务，应该不再出现主机密钥验证错误。

如果还有问题，检查：

1. **确认 docker-compose.yml 中挂载了 SSH 目录**
   ```yaml
   volumes:
     - ./jenkins-ssh:/var/jenkins_home/.ssh
   ```

2. **检查容器内的文件权限**
   ```bash
   docker exec jenkins ls -la /var/jenkins_home/.ssh/
   ```

3. **检查 known_hosts 文件内容**
   ```bash
   docker exec jenkins cat /var/jenkins_home/.ssh/known_hosts
   ```

---

## 常见问题

### Q: 为什么需要 known_hosts？

A: SSH 协议要求验证远程主机的身份，known_hosts 文件存储了已知主机的公钥，防止中间人攻击。

### Q: 可以禁用主机密钥验证吗？

A: 可以，但不推荐。可以在 Jenkins 的 Git Host Key Verification Configuration 中选择 "No verification"，但这会降低安全性。

### Q: 如果使用 HTTPS 而不是 SSH 呢？

A: 如果使用 HTTPS 方式克隆 Git 仓库，不需要配置 SSH 密钥和 known_hosts，只需要配置用户名和密码（或 Personal Access Token）。

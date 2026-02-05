# SSH 密钥持久化问题解决方案

## 问题描述

**现象**：每次重启 Jenkins 容器后，SSH 密钥丢失，需要重新配置。

## 问题原因

1. **挂载顺序问题**：
   - `jenkins_home` 数据卷先挂载到 `/var/jenkins_home`
   - 如果数据卷中已有 `.ssh` 目录，后续的 `./jenkins-ssh` 挂载可能被覆盖
   - 或者数据卷中的 `.ssh` 目录覆盖了宿主机目录

2. **目录不存在**：
   - `jenkins-ssh` 目录在宿主机上不存在或为空
   - Docker 挂载空目录会覆盖容器内的内容

3. **权限问题**：
   - 容器以 `root` 运行，但文件权限可能不正确
   - 重启后权限可能被重置

## 解决方案

### 方案一：使用宿主机目录挂载（推荐）

**原理**：将 SSH 密钥存储在宿主机文件系统，而不是 Docker 数据卷中。

#### 步骤 1：初始化 SSH 密钥（在宿主机上）

```bash
# 进入项目目录
cd ~/dockerlearn

# 运行初始化脚本
chmod +x setup-ssh-persistent.sh
./setup-ssh-persistent.sh
```

脚本会自动：
- 创建 `jenkins-ssh` 目录
- 生成 SSH 密钥对（如果不存在）
- 添加 GitHub 到 known_hosts
- 设置正确的权限

#### 步骤 2：确保 docker-compose.yml 配置正确

确认 `docker-compose.yml` 中有以下挂载：

```yaml
volumes:
  - jenkins_home:/var/jenkins_home
  - ./jenkins-ssh:/var/jenkins_home/.ssh:rw  # 宿主机目录挂载
```

#### 步骤 3：重启 Jenkins

```bash
docker compose down
docker compose up -d
```

#### 步骤 4：验证密钥持久化

```bash
# 检查宿主机上的密钥
ls -la jenkins-ssh/

# 检查容器内的密钥
docker exec jenkins ls -la /var/jenkins_home/.ssh/

# 测试 SSH 连接
docker exec jenkins ssh -T git@github.com
```

---

### 方案二：使用初始化脚本（备选）

如果方案一不行，可以使用容器启动时初始化脚本：

#### 步骤 1：创建初始化脚本

已创建 `init-ssh-keys.sh`，会在容器启动时自动执行。

#### 步骤 2：修改 docker-compose.yml

添加 entrypoint 包装（已在配置中，但可能影响 Jenkins 启动，不推荐）。

---

## 验证持久化

### 测试 1：重启容器

```bash
# 重启容器
docker compose restart jenkins

# 检查密钥是否还在
docker exec jenkins ls -la /var/jenkins_home/.ssh/
docker exec jenkins ssh -T git@github.com
```

### 测试 2：删除并重建容器

```bash
# 停止并删除容器
docker compose down

# 重新启动
docker compose up -d

# 检查密钥
docker exec jenkins ls -la /var/jenkins_home/.ssh/
```

### 测试 3：重启电脑后验证

```bash
# 重启电脑后
cd ~/dockerlearn

# 检查宿主机上的密钥
ls -la jenkins-ssh/

# 启动 Jenkins
docker compose up -d

# 验证密钥
docker exec jenkins ssh -T git@github.com
```

---

## 故障排查

### 问题 1：密钥仍然丢失

**检查点**：
1. 确认 `jenkins-ssh` 目录在宿主机上存在且有内容
   ```bash
   ls -la jenkins-ssh/
   ```

2. 确认挂载正确
   ```bash
   docker exec jenkins ls -la /var/jenkins_home/.ssh/
   ```

3. 检查挂载点
   ```bash
   docker inspect jenkins | grep -A 10 Mounts
   ```

**解决方法**：
- 确保 `jenkins-ssh` 目录存在且有文件
- 重新运行 `setup-ssh-persistent.sh`
- 重启容器

### 问题 2：权限错误

```bash
# 修复宿主机权限
chmod 700 jenkins-ssh
chmod 600 jenkins-ssh/id_rsa
chmod 644 jenkins-ssh/id_rsa.pub
chmod 644 jenkins-ssh/known_hosts

# 修复容器内权限
docker exec jenkins chmod 700 /var/jenkins_home/.ssh
docker exec jenkins chmod 600 /var/jenkins_home/.ssh/id_rsa
```

### 问题 3：known_hosts 丢失

```bash
# 重新添加 GitHub
ssh-keyscan github.com >> jenkins-ssh/known_hosts
chmod 644 jenkins-ssh/known_hosts

# 重启容器
docker compose restart jenkins
```

---

## 最佳实践

1. **使用宿主机目录挂载**：将敏感数据存储在宿主机文件系统
2. **定期备份**：备份 `jenkins-ssh` 目录
3. **版本控制**：公钥可以提交到 Git，私钥不要提交
4. **权限管理**：确保正确的文件权限（700/600/644）

---

## 一键修复脚本

如果密钥丢失，运行：

```bash
cd ~/dockerlearn
chmod +x setup-ssh-persistent.sh
./setup-ssh-persistent.sh
docker compose restart jenkins
```

---

## 总结

**关键点**：
- ✅ SSH 密钥存储在宿主机 `./jenkins-ssh/` 目录
- ✅ 通过 Docker 卷挂载到容器内
- ✅ 即使容器删除重建，密钥也不会丢失
- ✅ 需要确保宿主机目录存在且有内容

**如果还是丢失**：
1. 检查 `jenkins-ssh` 目录是否存在
2. 检查目录是否有内容
3. 检查挂载是否正确
4. 重新运行初始化脚本

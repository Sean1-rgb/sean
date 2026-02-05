# SSH 配置持久化说明

## 当前状态

✅ SSH 密钥已配置成功，可以连接到 GitHub。

## 持久化方案

由于容器重启后 `/root/.ssh` 目录会丢失，需要在每次容器启动后重新创建符号链接。

### 方法一：手动创建（简单，但需要每次重启后执行）

```bash
# 容器启动后，运行以下命令创建符号链接
docker exec jenkins sh -c "mkdir -p /root/.ssh && ln -sf /var/jenkins_home/.ssh/id_rsa /root/.ssh/id_rsa && ln -sf /var/jenkins_home/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub && ln -sf /var/jenkins_home/.ssh/known_hosts /root/.ssh/known_hosts && chmod 700 /root/.ssh && chmod 600 /root/.ssh/id_rsa && chmod 644 /root/.ssh/id_rsa.pub"

# 测试连接
docker exec jenkins ssh -T git@github.com
```

### 方法二：使用 Jenkins 初始化脚本（推荐）

在 Jenkins 管理界面配置：

1. 访问：http://localhost:8082
2. 管理 Jenkins → 系统配置 → 全局属性
3. 添加环境变量或使用初始化脚本

### 方法三：创建便捷脚本

创建一个脚本文件 `fix-ssh.sh`：

```bash
#!/bin/bash
docker exec jenkins sh -c "mkdir -p /root/.ssh && ln -sf /var/jenkins_home/.ssh/id_rsa /root/.ssh/id_rsa && ln -sf /var/jenkins_home/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub && ln -sf /var/jenkins_home/.ssh/known_hosts /root/.ssh/known_hosts && chmod 700 /root/.ssh && chmod 600 /root/.ssh/id_rsa && chmod 644 /root/.ssh/id_rsa.pub"
docker exec jenkins ssh -T git@github.com
```

每次重启后运行：`./fix-ssh.sh`

## 验证

```bash
# 检查符号链接
docker exec jenkins ls -la /root/.ssh/

# 测试连接
docker exec jenkins ssh -T git@github.com
```

## 注意事项

- SSH 密钥存储在 `jenkins-ssh/` 目录（宿主机），持久化保存
- 符号链接需要在容器启动后重新创建
- 如果使用 Jenkins Pipeline，可以在 Pipeline 中配置使用 `/var/jenkins_home/.ssh/id_rsa` 路径

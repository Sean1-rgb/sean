# Jenkins SSH 密钥目录

此目录用于持久化存储 Jenkins 的 SSH 密钥，确保重启后密钥不会丢失。

## 目录结构

```
jenkins-ssh/
├── id_rsa          # SSH 私钥（已添加到 .gitignore，不会提交）
├── id_rsa.pub      # SSH 公钥（可以提交，用于文档）
└── known_hosts     # 已知主机列表
```

## 初始化

首次使用请运行：

```bash
chmod +x setup-ssh.sh
./setup-ssh.sh
```

## 权限要求

- 目录权限：`700` (drwx------)
- 私钥权限：`600` (-rw-------)
- 公钥权限：`644` (-rw-r--r--)
- known_hosts：`644` (-rw-r--r--)

## 配置说明

在 `docker-compose.yml` 中，此目录已挂载到容器内的 `/var/jenkins_home/.ssh`：

```yaml
volumes:
  - ./jenkins-ssh:/var/jenkins_home/.ssh
```

这样即使容器重启或删除，SSH 密钥也会保留在宿主机上。

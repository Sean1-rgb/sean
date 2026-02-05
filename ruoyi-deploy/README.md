# 若依 RuoYi-Vue 部署文件

本目录下的文件用于 **Jenkins + GitHub + Docker** 部署若依，需复制到 **若依项目根目录** 使用。

## 文件说明

| 文件 | 说明 |
|------|------|
| `Dockerfile.backend` | 后端镜像（Maven 构建 + JRE 运行） |
| `Dockerfile.ui` | 前端镜像（Node 构建 + Nginx 托管） |
| `docker-compose.ruoyi.yml` | 一键启动 MySQL、Redis、后端、前端 |
| `Jenkinsfile` | Jenkins 流水线（检出 → 构建镜像 → 启动） |
| `nginx.conf` | 前端 Nginx 配置（/prod-api 代理到后端） |

## 快速开始

1. 克隆若依到本地，进入项目根目录。
2. 将本目录下除 README.md 外的所有文件复制到若依项目根目录。
3. 推送代码到你的 GitHub 仓库。
4. 在 Jenkins 新建流水线任务，选择「Pipeline script from SCM」，仓库填你的若依仓库，Script Path 填 `Jenkinsfile`。
5. 首次部署前确保若依项目有 `sql/` 目录且内含建表脚本（MySQL 首次启动会自动执行）。
6. 在 Jenkins 中点击「立即构建」，完成后访问 http://localhost（前端）、http://localhost:8080（后端），默认账号 admin / admin123。

详细步骤见：`docs/若依部署步骤.md`。

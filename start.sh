#!/bin/bash

echo "=========================================="
echo "启动 CI/CD 环境"
echo "=========================================="

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "错误: Docker 未运行，请先启动 Docker"
    exit 1
fi

# 启动 Jenkins（兼容 docker compose 与 docker-compose）
echo "启动 Jenkins..."
if docker compose version > /dev/null 2>&1; then
    docker compose up -d
else
    docker-compose up -d
fi

# 等待 Jenkins 启动
echo "等待 Jenkins 启动..."
sleep 10

# 获取初始密码
echo ""
echo "=========================================="
echo "Jenkins 初始管理员密码:"
echo "=========================================="
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "Jenkins 还在启动中，请稍后运行: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"

echo ""
echo "=========================================="
echo "访问 Jenkins: http://localhost:8080"
echo "=========================================="
echo ""
echo "查看日志: docker compose logs -f jenkins 或 docker-compose logs -f jenkins"
echo "停止服务: docker compose down 或 docker-compose down"

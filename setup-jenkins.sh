#!/bin/bash

echo "=========================================="
echo "Jenkins 配置助手"
echo "=========================================="

# 检查 Jenkins 是否运行
if ! docker ps 2>/dev/null | grep -q jenkins; then
    echo "错误: Jenkins 未运行，请先运行 ./start.sh"
    exit 1
fi

echo ""
echo "1. 获取 Jenkins 初始密码:"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

echo ""
echo "2. 访问 Jenkins: http://localhost:8080"
echo ""
echo "3. 安装推荐的插件后，需要安装以下插件:"
echo "   - Git Plugin"
echo "   - Docker Pipeline Plugin"
echo "   - Pipeline Plugin"
echo "   - GitHub Plugin"
echo ""
echo "4. 配置 GitHub 凭据:"
echo "   - 管理 Jenkins -> 凭据 -> 系统 -> 全局凭据"
echo "   - 添加凭据 -> Kind: Secret text"
echo "   - Secret: 你的 GitHub Personal Access Token"
echo ""
echo "5. 创建 Pipeline 任务:"
echo "   - 新建任务 -> 流水线"
echo "   - Pipeline script from SCM"
echo "   - SCM: Git"
echo "   - Repository URL: 你的 GitHub 仓库地址"
echo "   - Script Path: Jenkinsfile"

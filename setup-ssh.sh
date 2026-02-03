#!/bin/bash

echo "=========================================="
echo "配置 Jenkins SSH 密钥（持久化到宿主机）"
echo "=========================================="

# 创建 SSH 目录
mkdir -p jenkins-ssh
chmod 700 jenkins-ssh

# 检查是否已有密钥
if [ -f "jenkins-ssh/id_rsa" ]; then
    echo "检测到已存在的 SSH 密钥"
    echo "公钥内容："
    cat jenkins-ssh/id_rsa.pub
    echo ""
    echo "如果密钥已添加到 GitHub，可以直接使用"
    echo "如果需要重新生成，请删除 jenkins-ssh 目录后重新运行此脚本"
    exit 0
fi

echo ""
echo "生成新的 SSH 密钥对..."
ssh-keygen -t rsa -b 4096 -C "jenkins@docker" -f ./jenkins-ssh/id_rsa -N ""

# 设置正确的权限
chmod 700 jenkins-ssh
chmod 600 jenkins-ssh/id_rsa
chmod 644 jenkins-ssh/id_rsa.pub

# 添加 GitHub 到 known_hosts
echo ""
echo "添加 GitHub 到 known_hosts..."
ssh-keyscan github.com >> ./jenkins-ssh/known_hosts 2>/dev/null
chmod 644 ./jenkins-ssh/known_hosts

echo ""
echo "=========================================="
echo "SSH 密钥生成完成！"
echo "=========================================="
echo ""
echo "请将以下公钥添加到 GitHub："
echo "1. 登录 GitHub → Settings → SSH and GPG keys → New SSH key"
echo "2. 复制下面的公钥内容："
echo ""
cat ./jenkins-ssh/id_rsa.pub
echo ""
echo "=========================================="
echo "下一步："
echo "1. 将上面的公钥添加到 GitHub"
echo "2. 重启 Jenkins: docker compose restart"
echo "3. 在 Jenkins 中配置 SSH 凭据（使用私钥）"
echo "=========================================="

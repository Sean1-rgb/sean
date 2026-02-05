#!/bin/bash

# Jenkins SSH 密钥持久化设置脚本
# 此脚本确保 SSH 密钥在宿主机上正确创建和配置

echo "=========================================="
echo "设置 Jenkins SSH 密钥持久化"
echo "=========================================="

# 进入脚本所在目录
cd "$(dirname "$0")"

# 创建 jenkins-ssh 目录
echo "创建 jenkins-ssh 目录..."
mkdir -p jenkins-ssh
chmod 700 jenkins-ssh

# 检查是否已有密钥
if [ -f "jenkins-ssh/id_rsa" ]; then
    echo "✓ 检测到已存在的 SSH 密钥"
    echo ""
    echo "公钥内容："
    cat jenkins-ssh/id_rsa.pub
    echo ""
    read -p "是否重新生成密钥？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "使用现有密钥"
    else
        echo "删除旧密钥..."
        rm -f jenkins-ssh/id_rsa jenkins-ssh/id_rsa.pub
    fi
fi

# 如果密钥不存在，生成新的密钥
if [ ! -f "jenkins-ssh/id_rsa" ]; then
    echo ""
    echo "生成新的 SSH 密钥..."
    ssh-keygen -t rsa -b 4096 -C "jenkins@docker" -f ./jenkins-ssh/id_rsa -N ""
    echo "✓ SSH 密钥已生成"
fi

# 设置正确的权限
chmod 700 jenkins-ssh
chmod 600 jenkins-ssh/id_rsa
chmod 644 jenkins-ssh/id_rsa.pub

# 确保 known_hosts 存在并包含 GitHub
echo ""
echo "配置 known_hosts..."
if [ ! -f "jenkins-ssh/known_hosts" ] || ! grep -q "github.com" jenkins-ssh/known_hosts 2>/dev/null; then
    echo "添加 GitHub 到 known_hosts..."
    ssh-keyscan github.com >> jenkins-ssh/known_hosts 2>/dev/null
    chmod 644 jenkins-ssh/known_hosts
    echo "✓ GitHub 主机密钥已添加"
else
    echo "✓ known_hosts 已包含 GitHub"
fi

# 创建 .gitkeep 文件（如果目录为空，确保 Git 跟踪目录）
touch jenkins-ssh/.gitkeep

echo ""
echo "=========================================="
echo "SSH 密钥配置完成！"
echo "=========================================="
echo ""
echo "目录结构："
ls -la jenkins-ssh/
echo ""
echo "=========================================="
echo "下一步操作："
echo "=========================================="
echo ""
echo "1. 将以下公钥添加到 GitHub："
echo "   登录 GitHub → Settings → SSH and GPG keys → New SSH key"
echo ""
cat jenkins-ssh/id_rsa.pub
echo ""
echo "2. 重启 Jenkins 容器："
echo "   docker compose restart jenkins"
echo ""
echo "3. 验证 SSH 连接："
echo "   docker exec jenkins ssh -T git@github.com"
echo ""
echo "=========================================="
echo "重要提示："
echo "=========================================="
echo "✓ SSH 密钥已保存在宿主机: ./jenkins-ssh/"
echo "✓ 即使容器重启或删除，密钥也不会丢失"
echo "✓ 密钥已添加到 .gitignore，不会提交到 Git"
echo "=========================================="

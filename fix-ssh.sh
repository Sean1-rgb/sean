#!/bin/bash
echo "=== 设置 SSH 符号链接 ==="
docker exec jenkins sh -c "mkdir -p /root/.ssh && ln -sf /var/jenkins_home/.ssh/id_rsa /root/.ssh/id_rsa && ln -sf /var/jenkins_home/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub && ln -sf /var/jenkins_home/.ssh/known_hosts /root/.ssh/known_hosts && chmod 700 /root/.ssh && chmod 600 /root/.ssh/id_rsa && chmod 644 /root/.ssh/id_rsa.pub"
echo ""
echo "=== 测试 SSH 连接 ==="
docker exec jenkins ssh -T git@github.com

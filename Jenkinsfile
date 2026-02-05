pipeline {
    agent any
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '1'))  // 只保留最新 1 个构建
    }
    
    environment {
        DOCKER_IMAGE = 'myapp'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        DOCKER_REGISTRY = 'localhost:5000' // 可选：使用本地registry
    }
    
    stages {
        stage('检出代码') {
            steps {
                checkout scm
                echo '代码检出完成'
            }
        }
        
        stage('构建Docker镜像') {
            steps {
                script {
                    echo "构建Docker镜像: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }
        
        stage('运行测试') {
            steps {
                // Jenkins 容器内无 Node，在刚构建的镜像里跑测试
                sh 'docker run --rm myapp:latest npm test'
            }
        }
        
        stage('推送镜像') {
            when {
                branch 'main'  // 只在main分支推送
            }
            steps {
                script {
                    echo "推送镜像到Registry: ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}"
                    // 如果使用远程registry，取消注释下面这行
                    // sh "docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }
        
        stage('启动Redis') {
            steps {
                script {
                    echo "启动 Redis 服务..."
                    sh """
                        # 检查 Redis 是否已运行
                        if ! docker ps | grep -q redis; then
                            echo "启动 Redis 容器..."
                            docker run -d \\
                                --name redis \\
                                --network cicd-network \\
                                -p 6379:6379 \\
                                -v redis_data:/data \\
                                --restart unless-stopped \\
                                redis:7-alpine redis-server --appendonly yes
                            echo "等待 Redis 启动..."
                            sleep 5
                        else
                            echo "Redis 已在运行"
                        fi
                    """
                    echo "Redis 已启动，端口: 6379"
                }
            }
        }
        
        stage('部署') {
            // 单分支任务可能没有 BRANCH_NAME，去掉 when 让每次成功构建都部署
            steps {
                script {
                    echo "部署应用 ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    sh """
                        docker stop myapp 2>/dev/null || true
                        docker rm myapp 2>/dev/null || true
                        docker run -d \\
                            -p 5000:3000 \\
                            --name myapp \\
                            --network cicd-network \\
                            -e REDIS_HOST=redis \\
                            -e REDIS_PORT=6379 \\
                            ${DOCKER_IMAGE}:latest
                    """
                    echo "应用已启动，访问 http://localhost:5000"
                    echo "Redis 连接信息: redis:6379 (容器内) 或 localhost:6379 (宿主机)"
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline执行成功！'
        }
        failure {
            echo 'Pipeline执行失败！'
        }
        always {
            echo '清理工作空间...'
            deleteDir()  // 内置方法，无需额外插件
        }
    }
}

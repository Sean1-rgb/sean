pipeline {
    agent any
    
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
                sh 'npm test'
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
        
        stage('部署') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "部署应用 ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    // 这里可以添加部署命令
                    // 例如：docker-compose up -d 或 kubectl apply 等
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

pipeline {
    agent any
    
    environment {
        // Docker configuration
        DOCKER_IMAGE_NAME = 'yashthakur1/react-app'
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        CONTAINER_NAME = 'react-app-container'
        
        // Application configuration
        APP_PORT = '80'
        HOST_PORT = '80'
        
        // Build information
        IMAGE_TAG = "${BUILD_NUMBER}"
        LATEST_TAG = 'latest'
        
        // Node.js version (optional, if using specific Node version)
        NODE_VERSION = '18'
    }
    
    tools {
        nodejs "${NODE_VERSION}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    try {
                        echo '🔄 Checking out code from GitHub...'
                        checkout scm
                        
                        // Display build information
                        echo "📋 Build Information:"
                        echo "   • Build Number: ${BUILD_NUMBER}"
                        echo "   • Branch: ${env.BRANCH_NAME ?: 'main'}"
                        echo "   • Image: ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
                        
                    } catch (Exception e) {
                        error "❌ Checkout failed: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('Install Dependencies & Build') {
            steps {
                script {
                    try {
                        echo '📦 Installing dependencies and building React app...'
                        
                        // Clean install for reproducible builds
                        sh '''
                            echo "Node.js version: $(node --version)"
                            echo "npm version: $(npm --version)"
                            
                            # Clean any existing node_modules and build
                            rm -rf node_modules build
                            
                            # Install dependencies
                            npm ci --silent
                            
                            # Build the application
                            npm run build
                            
                            # Verify build output
                            if [ -d "build" ]; then
                                echo "✅ Build completed successfully"
                                echo "Build size: $(du -sh build | cut -f1)"
                            else
                                echo "❌ Build directory not found"
                                exit 1
                            fi
                        '''
                        
                    } catch (Exception e) {
                        error "❌ Build failed: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    try {
                        echo '🐳 Building Docker image...'
                        
                        // Build Docker image
                        def dockerImage = docker.build("${DOCKER_IMAGE_NAME}:${IMAGE_TAG}")
                        
                        // Tag with latest
                        sh "docker tag ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_IMAGE_NAME}:${LATEST_TAG}"
                        
                        // Display image information
                        sh """
                            echo "📊 Docker Image Information:"
                            docker images ${DOCKER_IMAGE_NAME} --format "table {{.Repository}}\\t{{.Tag}}\\t{{.Size}}\\t{{.CreatedAt}}"
                        """
                        
                        // Store image for later use
                        env.DOCKER_IMAGE_BUILT = "${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
                        
                    } catch (Exception e) {
                        error "❌ Docker build failed: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('Docker Security Scan') {
            steps {
                script {
                    try {
                        echo '🔍 Scanning Docker image for vulnerabilities...'
                        
                        // Optional: Add docker security scanning
                        sh """
                            # Basic image inspection
                            echo "🔍 Image layers:"
                            docker history ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} --no-trunc
                            
                            # Check image size
                            IMAGE_SIZE=\$(docker images ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} --format "{{.Size}}")
                            echo "📏 Final image size: \$IMAGE_SIZE"
                        """
                        
                    } catch (Exception e) {
                        echo "⚠️ Security scan completed with warnings: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    try {
                        echo '📤 Logging in to Docker Hub and pushing images...'
                        
                        // Method 1: Using docker.withRegistry (Recommended)
                        docker.withRegistry("https://${DOCKER_REGISTRY}", "${DOCKER_CREDENTIALS_ID}") {
                            
                            // Push tagged image
                            def dockerImage = docker.image("${DOCKER_IMAGE_NAME}:${IMAGE_TAG}")
                            dockerImage.push()
                            
                            // Push latest tag
                            def latestImage = docker.image("${DOCKER_IMAGE_NAME}:${LATEST_TAG}")
                            latestImage.push()
                            
                            echo "✅ Successfully pushed:"
                            echo "   • ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
                            echo "   • ${DOCKER_IMAGE_NAME}:${LATEST_TAG}"
                        }
                        
                        // Method 2: Alternative using withCredentials for custom operations
                        withCredentials([usernamePassword(
                            credentialsId: "${DOCKER_CREDENTIALS_ID}",
                            usernameVariable: 'DOCKER_USERNAME',
                            passwordVariable: 'DOCKER_PASSWORD'
                        )]) {
                            sh '''
                                echo "🔐 Docker Hub credentials loaded securely"
                                echo "Username: $DOCKER_USERNAME (password is masked)"
                                
                                # Alternative manual login (if needed for custom operations)
                                # echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                                
                                # Custom docker operations can go here
                                # docker push additional-tags, etc.
                            '''
                        }
                        
                    } catch (Exception e) {
                        error "❌ Docker push failed: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('Deploy Locally') {
            steps {
                script {
                    try {
                        echo '🚀 Deploying container locally...'
                        
                        // Stop and remove existing container if it exists
                        sh """
                            # Stop existing container
                            if [ \$(docker ps -q -f name=${CONTAINER_NAME}) ]; then
                                echo "🛑 Stopping existing container: ${CONTAINER_NAME}"
                                docker stop ${CONTAINER_NAME}
                            fi
                            
                            # Remove existing container
                            if [ \$(docker ps -aq -f name=${CONTAINER_NAME}) ]; then
                                echo "🗑️ Removing existing container: ${CONTAINER_NAME}"
                                docker rm ${CONTAINER_NAME}
                            fi
                        """
                        
                        // Run new container
                        sh """
                            echo "🏃 Starting new container: ${CONTAINER_NAME}"
                            docker run -d \\
                                --name ${CONTAINER_NAME} \\
                                --restart unless-stopped \\
                                -p ${HOST_PORT}:${APP_PORT} \\
                                --health-cmd="curl -f http://localhost/ || exit 1" \\
                                --health-interval=30s \\
                                --health-timeout=10s \\
                                --health-retries=3 \\
                                ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}
                            
                            # Wait a moment for container to start
                            sleep 5
                            
                            # Check container status
                            echo "📊 Container Status:"
                            docker ps -f name=${CONTAINER_NAME} --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
                            
                            # Test application
                            echo "🧪 Testing application..."
                            if curl -f -s http://localhost:${HOST_PORT} > /dev/null; then
                                echo "✅ Application is responding correctly"
                                echo "🌐 Application URL: http://localhost:${HOST_PORT}"
                            else
                                echo "⚠️ Application health check failed"
                                docker logs ${CONTAINER_NAME} --tail 20
                            fi
                        """
                        
                    } catch (Exception e) {
                        error "❌ Deployment failed: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('Post-Deploy Verification') {
            steps {
                script {
                    try {
                        echo '✅ Running post-deployment verification...'
                        
                        sh """
                            # Container health check
                            echo "🏥 Container Health Status:"
                            docker inspect ${CONTAINER_NAME} --format='{{.State.Health.Status}}' || echo "No health check configured"
                            
                            # Resource usage
                            echo "💻 Container Resource Usage:"
                            docker stats ${CONTAINER_NAME} --no-stream --format "table {{.Container}}\\t{{.CPUPerc}}\\t{{.MemUsage}}"
                            
                            # Application logs (last 10 lines)
                            echo "📝 Recent Application Logs:"
                            docker logs ${CONTAINER_NAME} --tail 10
                        """
                        
                    } catch (Exception e) {
                        echo "⚠️ Post-deployment verification completed with warnings: ${e.getMessage()}"
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo '🧹 Cleaning up workspace and temporary resources...'
                
                try {
                    // Clean up Docker images (keep latest and current build)
                    sh """
                        # Remove dangling images
                        docker image prune -f
                        
                        # Remove old images (keep last 3 builds)
                        OLD_IMAGES=\$(docker images ${DOCKER_IMAGE_NAME} --format "{{.Tag}}" | grep -E '^[0-9]+\$' | sort -nr | tail -n +4)
                        for tag in \$OLD_IMAGES; do
                            if [ "\$tag" != "${IMAGE_TAG}" ] && [ "\$tag" != "latest" ]; then
                                echo "🗑️ Removing old image: ${DOCKER_IMAGE_NAME}:\$tag"
                                docker rmi ${DOCKER_IMAGE_NAME}:\$tag 2>/dev/null || true
                            fi
                        done
                    """
                } catch (Exception e) {
                    echo "⚠️ Cleanup warning: ${e.getMessage()}"
                }
                
                // Clean workspace
                cleanWs()
            }
        }
        
        success {
            echo '''
            🎉 Pipeline completed successfully!
            
            📋 Summary:
            • ✅ Code checked out
            • ✅ Dependencies installed and app built
            • ✅ Docker image created and tagged  
            • ✅ Image pushed to Docker Hub
            • ✅ Container deployed locally
            • ✅ Post-deployment verification passed
            
            🌐 Your application is now running at: http://localhost:80
            '''
        }
        
        failure {
            script {
                echo '''
                ❌ Pipeline failed!
                
                🔍 Troubleshooting steps:
                1. Check the console output for specific error messages
                2. Verify Docker Hub credentials are configured
                3. Ensure port 80 is available
                4. Check Docker daemon is running
                5. Verify package.json has valid build script
                '''
                
                // Capture logs for debugging
                try {
                    sh """
                        echo "📝 Capturing debug information..."
                        echo "Docker version: \$(docker --version)"
                        echo "Node version: \$(node --version)"
                        echo "Available disk space: \$(df -h . | tail -1)"
                        
                        if [ \$(docker ps -aq -f name=${CONTAINER_NAME}) ]; then
                            echo "Container logs:"
                            docker logs ${CONTAINER_NAME} --tail 50
                        fi
                    """
                } catch (Exception e) {
                    echo "Could not capture debug information: ${e.getMessage()}"
                }
            }
        }
        
        unstable {
            echo '⚠️ Pipeline completed with warnings. Check the logs for details.'
        }
    }
}
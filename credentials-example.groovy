// Jenkins Credentials Usage Examples
// Copy these code snippets into your Jenkinsfile

// 🔐 CREDENTIAL SETUP EXAMPLES

pipeline {
    agent any
    
    environment {
        // ✅ SAFE: Only store credential IDs, not actual secrets
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        GITHUB_CREDENTIALS_ID = 'github-credentials'
        
        // Your actual configuration
        DOCKER_IMAGE_NAME = 'yashthakur1/react-app'
        DOCKER_REGISTRY = 'docker.io'
    }
    
    stages {
        
        // 🐙 GITHUB CREDENTIAL EXAMPLES
        stage('GitHub Operations') {
            steps {
                script {
                    
                    // Example 1: Simple Git checkout with credentials
                    git credentialsId: "${GITHUB_CREDENTIALS_ID}",
                        url: 'https://github.com/yashthakur1/your-repo.git',
                        branch: 'main'
                    
                    // Example 2: Using withCredentials for custom Git operations
                    withCredentials([usernamePassword(
                        credentialsId: "${GITHUB_CREDENTIALS_ID}",
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_TOKEN'
                    )]) {
                        sh '''
                            # These variables are automatically available and masked in logs
                            echo "GitHub Username: $GIT_USERNAME"  # Shows: GitHub Username: ****
                            echo "Token length: ${#GIT_TOKEN}"     # Shows length, not actual token
                            
                            # Configure Git with credentials
                            git config user.name "Jenkins CI"
                            git config user.email "jenkins@yourcompany.com"
                            
                            # Create and push a tag
                            git tag -a "build-${BUILD_NUMBER}" -m "Jenkins build ${BUILD_NUMBER}"
                            git push https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/yashthakur1/your-repo.git --tags
                            
                            # GitHub API call example
                            curl -H "Authorization: token $GIT_TOKEN" \
                                 -H "Content-Type: application/json" \
                                 https://api.github.com/repos/yashthakur1/your-repo/releases
                        '''
                    }
                }
            }
        }
        
        // 🐳 DOCKER HUB CREDENTIAL EXAMPLES  
        stage('Docker Operations') {
            steps {
                script {
                    
                    // Example 1: Using docker.withRegistry (Simplest method)
                    docker.withRegistry("https://${DOCKER_REGISTRY}", "${DOCKER_CREDENTIALS_ID}") {
                        def dockerImage = docker.image("${DOCKER_IMAGE_NAME}:latest")
                        dockerImage.push()
                        echo "✅ Image pushed using docker.withRegistry"
                    }
                    
                    // Example 2: Using withCredentials for manual docker login
                    withCredentials([usernamePassword(
                        credentialsId: "${DOCKER_CREDENTIALS_ID}",
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh '''
                            # Login to Docker Hub
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                            
                            # Push your images
                            docker push ${DOCKER_IMAGE_NAME}:latest
                            docker push ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER}
                            
                            # Logout for security
                            docker logout
                            
                            echo "✅ Manual docker operations completed"
                        '''
                    }
                    
                    // Example 3: Multiple operations with same credentials
                    withCredentials([usernamePassword(
                        credentialsId: "${DOCKER_CREDENTIALS_ID}",
                        usernameVariable: 'DOCKER_USERNAME', 
                        passwordVariable: 'DOCKER_PASSWORD'
                    )]) {
                        sh '''
                            # Login once, do multiple operations
                            echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                            
                            # Build and push multiple tags
                            docker tag ${DOCKER_IMAGE_NAME}:latest ${DOCKER_IMAGE_NAME}:stable
                            docker tag ${DOCKER_IMAGE_NAME}:latest ${DOCKER_IMAGE_NAME}:build-${BUILD_NUMBER}
                            
                            docker push ${DOCKER_IMAGE_NAME}:stable
                            docker push ${DOCKER_IMAGE_NAME}:build-${BUILD_NUMBER}
                            
                            # Check repository info
                            curl -u ${DOCKER_USERNAME}:${DOCKER_PASSWORD} \
                                 https://hub.docker.com/v2/repositories/yashthakur1/react-app/
                            
                            docker logout
                        '''
                    }
                }
            }
        }
        
        // 🔒 MULTIPLE CREDENTIALS EXAMPLE
        stage('Multi-Credential Operations') {
            steps {
                script {
                    
                    // Use multiple different credentials in same stage
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'github-credentials',
                            usernameVariable: 'GIT_USER',
                            passwordVariable: 'GIT_TOKEN'
                        ),
                        usernamePassword(
                            credentialsId: 'dockerhub-credentials', 
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_TOKEN'
                        )
                    ]) {
                        sh '''
                            echo "🔐 Both GitHub and Docker credentials loaded"
                            echo "Git User: $GIT_USER"       # Masked in logs
                            echo "Docker User: $DOCKER_USER" # Masked in logs
                            
                            # Use both credentials in same script
                            # GitHub operations
                            curl -H "Authorization: token $GIT_TOKEN" \
                                 https://api.github.com/user
                            
                            # Docker operations  
                            echo $DOCKER_TOKEN | docker login -u $DOCKER_USER --password-stdin
                            docker push some-image
                            docker logout
                        '''
                    }
                }
            }
        }
        
        // 🔑 OTHER CREDENTIAL TYPES
        stage('Other Credential Examples') {
            steps {
                script {
                    
                    // Secret text (for API keys)
                    withCredentials([string(credentialsId: 'api-key-secret', variable: 'API_KEY')]) {
                        sh '''
                            echo "API Key loaded (masked): $API_KEY"
                            curl -H "X-API-Key: $API_KEY" https://api.example.com/endpoint
                        '''
                    }
                    
                    // SSH agent (for Git operations with SSH keys)
                    sshagent(['github-ssh-key']) {
                        sh '''
                            # SSH key is automatically available
                            git clone git@github.com:yashthakur1/your-repo.git
                            ssh -T git@github.com  # Test SSH connection
                        '''
                    }
                    
                    // Secret file (for config files, certificates)
                    withCredentials([file(credentialsId: 'kubeconfig-file', variable: 'KUBECONFIG')]) {
                        sh '''
                            echo "Kubernetes config file available at: $KUBECONFIG"
                            kubectl --kubeconfig $KUBECONFIG get pods
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                // 🧹 CLEANUP (No credentials needed here)
                sh '''
                    # Clean up any logged-in sessions
                    docker logout || true
                    
                    # Clear any temporary files
                    rm -f ~/.docker/config.json || true
                '''
                
                // Clean workspace
                cleanWs()
            }
        }
        
        failure {
            // 📧 NOTIFICATION WITH CREDENTIALS
            withCredentials([usernamePassword(
                credentialsId: 'github-credentials',
                usernameVariable: 'GIT_USER', 
                passwordVariable: 'GIT_TOKEN'
            )]) {
                sh '''
                    # Send failure notification to GitHub
                    curl -X POST \
                      -H "Authorization: token $GIT_TOKEN" \
                      -H "Content-Type: application/json" \
                      -d "{
                        \\"state\\": \\"failure\\",
                        \\"description\\": \\"Jenkins build failed\\",
                        \\"context\\": \\"continuous-integration/jenkins\\"
                      }" \
                      https://api.github.com/repos/yashthakur1/your-repo/statuses/${GIT_COMMIT}
                '''
            }
        }
    }
}

/*
🔐 CREDENTIAL SECURITY CHECKLIST:

✅ DO:
- Use withCredentials() for temporary credential access
- Use specific credential IDs that match Jenkins configuration
- Always logout from services after use
- Mask sensitive output in logs
- Use appropriate credential types for each service
- Set credential expiration dates

❌ DON'T:
- Put actual passwords/tokens in Jenkinsfile
- Store credentials in environment variables permanently  
- Echo/print credential values directly
- Leave services logged in after operations
- Use overly broad credential permissions
- Share credential IDs across different services

📋 REQUIRED JENKINS CREDENTIALS FOR THIS EXAMPLE:
1. ID: 'github-credentials' (Username with password)
2. ID: 'dockerhub-credentials' (Username with password)  
3. ID: 'github-ssh-key' (SSH Username with private key) [Optional]
4. ID: 'api-key-secret' (Secret text) [Optional]
5. ID: 'kubeconfig-file' (Secret file) [Optional]

🛠️ TO USE THIS:
1. Set up credentials in Jenkins with the exact IDs above
2. Replace 'yashthakur1/your-repo' with your actual repository
3. Copy the relevant code blocks into your Jenkinsfile
4. Test in a safe environment first!
*/
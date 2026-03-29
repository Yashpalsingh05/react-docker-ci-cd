# Jenkins Credentials Configuration Guide

## 🔐 Complete Guide to Jenkins Credentials Management

This guide covers setting up and using credentials securely in Jenkins for GitHub and Docker Hub integration.

---

## 🚀 Part 1: Setting Up Jenkins Credentials

### 📋 Prerequisites
- Jenkins installed and running
- Admin access to Jenkins
- GitHub account
- Docker Hub account

---

## 🐙 GitHub Credentials Configuration

### Method 1: Personal Access Token (Recommended)

#### Step 1: Create GitHub Personal Access Token
1. **Go to GitHub Settings:**
   - GitHub.com → Profile → Settings → Developer settings → Personal access tokens → Tokens (classic)

2. **Generate New Token:**
   - Click "Generate new token (classic)"
   - Name: `Jenkins CI/CD`
   - Expiration: Custom (1 year recommended)
   - **Required Scopes:**
     ```
     ✅ repo (Full control of private repositories)
     ✅ workflow (Update GitHub Action workflows)
     ✅ write:packages (Upload packages to GitHub Package Registry)
     ✅ read:org (Read org and team membership, read org projects)
     ```

3. **Copy the Token:**
   - Copy and save the token immediately (you won't see it again!)

#### Step 2: Add Credentials in Jenkins
1. **Navigate to Credentials:**
   ```
   Jenkins Dashboard → Manage Jenkins → Manage Credentials
   ```

2. **Select Domain:**
   - Click on "System" → "Global credentials (unrestricted)"

3. **Add Credentials:**
   - Click "Add Credentials"
   - **Kind:** `Username with password`
   - **Scope:** `Global`
   - **Username:** Your GitHub username
   - **Password:** The personal access token you copied
   - **ID:** `github-credentials`
   - **Description:** `GitHub Personal Access Token for CI/CD`

### Method 2: SSH Key (Alternative)

#### Step 1: Generate SSH Key Pair
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "jenkins@yourcompany.com" -f ~/.ssh/jenkins_github

# Copy public key
cat ~/.ssh/jenkins_github.pub
```

#### Step 2: Add Public Key to GitHub
- GitHub → Settings → SSH and GPG keys → New SSH key
- Paste the public key content

#### Step 3: Add Private Key to Jenkins
- **Kind:** `SSH Username with private key`
- **ID:** `github-ssh-key`
- **Username:** `git`
- **Private Key:** Paste the private key content
- **Passphrase:** If you set one during key generation

---

## 🐳 Docker Hub Credentials Configuration

### Step 1: Create Docker Hub Access Token (Recommended)

1. **Login to Docker Hub:**
   - Go to https://hub.docker.com
   - Sign in to your account

2. **Generate Access Token:**
   - Account Settings → Security → New Access Token
   - **Access Token Description:** `Jenkins CI/CD`
   - **Permissions:** `Read, Write, Delete` (or `Read, Write` for basic CI/CD)
   - Click "Generate"
   - **Copy the token immediately!**

### Step 2: Add Docker Hub Credentials in Jenkins

1. **Add Credentials:**
   - Jenkins → Manage Jenkins → Manage Credentials → System → Global credentials
   - Click "Add Credentials"

2. **Configure Credential:**
   - **Kind:** `Username with password`
   - **Scope:** `Global`
   - **Username:** Your Docker Hub username (e.g., `yashthakur1`)
   - **Password:** The access token you generated
   - **ID:** `dockerhub-credentials`
   - **Description:** `Docker Hub Access Token for CI/CD`

---

## 📝 Part 2: Using Credentials in Jenkinsfile

### 🔒 Secure Credential Usage with `withCredentials`

Here's how to update your Jenkinsfile to use credentials securely:

```groovy
pipeline {
    agent any
    
    environment {
        // Public configuration (no secrets here!)
        DOCKER_IMAGE_NAME = 'yashthakur1/react-app'
        DOCKER_REGISTRY = 'docker.io'
        CONTAINER_NAME = 'react-app-container'
        
        // Credential IDs (references, not actual secrets)
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        GITHUB_CREDENTIALS_ID = 'github-credentials'
        
        // Build info
        IMAGE_TAG = "${BUILD_NUMBER}"
        LATEST_TAG = 'latest'
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    try {
                        echo '🔄 Checking out code from GitHub...'
                        
                        // Method 1: Using credentials for private repositories
                        git credentialsId: "${GITHUB_CREDENTIALS_ID}",
                            url: 'https://github.com/yourusername/your-repo.git',
                            branch: 'main'
                        
                        // Method 2: Using withCredentials for custom Git operations
                        withCredentials([usernamePassword(
                            credentialsId: "${GITHUB_CREDENTIALS_ID}",
                            usernameVariable: 'GIT_USERNAME',
                            passwordVariable: 'GIT_TOKEN'
                        )]) {
                            // Custom git operations with credentials
                            sh '''
                                git config user.name "Jenkins CI"
                                git config user.email "jenkins@yourcompany.com"
                                echo "Authenticated as: $GIT_USERNAME"
                                # Any git operations here will use the credentials
                            '''
                        }
                        
                    } catch (Exception e) {
                        error "❌ Checkout failed: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    try {
                        echo '🐳 Building Docker image...'
                        
                        // Build without credentials (local operation)
                        def dockerImage = docker.build("${DOCKER_IMAGE_NAME}:${IMAGE_TAG}")
                        
                        // Tag with latest
                        sh "docker tag ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_IMAGE_NAME}:${LATEST_TAG}"
                        
                        env.DOCKER_IMAGE_BUILT = "${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
                        
                    } catch (Exception e) {
                        error "❌ Docker build failed: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    try {
                        echo '📤 Pushing to Docker Hub...'
                        
                        // Method 1: Using docker.withRegistry (Recommended)
                        docker.withRegistry("https://${DOCKER_REGISTRY}", "${DOCKER_CREDENTIALS_ID}") {
                            
                            def dockerImage = docker.image("${DOCKER_IMAGE_NAME}:${IMAGE_TAG}")
                            dockerImage.push()
                            dockerImage.push("${LATEST_TAG}")
                            
                            echo "✅ Successfully pushed images"
                        }
                        
                    } catch (Exception e) {
                        error "❌ Docker push failed: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('Advanced Docker Operations') {
            steps {
                script {
                    try {
                        // Method 2: Using withCredentials for custom docker commands
                        withCredentials([usernamePassword(
                            credentialsId: "${DOCKER_CREDENTIALS_ID}",
                            usernameVariable: 'DOCKER_USERNAME',
                            passwordVariable: 'DOCKER_PASSWORD'
                        )]) {
                            sh '''
                                # Login manually
                                echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                                
                                # Custom docker operations
                                docker push ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}
                                docker push ${DOCKER_IMAGE_NAME}:${LATEST_TAG}
                                
                                # Logout for security
                                docker logout
                                
                                echo "✅ Custom push completed"
                            '''
                        }
                        
                    } catch (Exception e) {
                        echo "⚠️ Advanced operations failed: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('GitHub Operations') {
            when {
                // Only run on main branch
                branch 'main'
            }
            steps {
                script {
                    try {
                        echo '📝 Performing GitHub operations...'
                        
                        withCredentials([usernamePassword(
                            credentialsId: "${GITHUB_CREDENTIALS_ID}",
                            usernameVariable: 'GIT_USERNAME',
                            passwordVariable: 'GIT_TOKEN'
                        )]) {
                            sh '''
                                # Create a deployment tag
                                DEPLOY_TAG="deploy-${BUILD_NUMBER}"
                                
                                # Configure Git with credentials
                                git config user.name "Jenkins CI"
                                git config user.email "jenkins@yourcompany.com"
                                
                                # Create and push tag
                                git tag -a $DEPLOY_TAG -m "Deployment build ${BUILD_NUMBER}"
                                git push https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/yourusername/your-repo.git $DEPLOY_TAG
                                
                                echo "✅ Created deployment tag: $DEPLOY_TAG"
                            '''
                        }
                        
                        // Using GitHub API with credentials
                        withCredentials([usernamePassword(
                            credentialsId: "${GITHUB_CREDENTIALS_ID}",
                            usernameVariable: 'GIT_USERNAME',
                            passwordVariable: 'GIT_TOKEN'
                        )]) {
                            sh '''
                                # Create GitHub release using API
                                curl -X POST \
                                  -H "Authorization: token $GIT_TOKEN" \
                                  -H "Content-Type: application/json" \
                                  -d '{
                                    "tag_name": "v'${BUILD_NUMBER}'",
                                    "name": "Release '${BUILD_NUMBER}'",
                                    "body": "Automated release from Jenkins build '${BUILD_NUMBER}'",
                                    "draft": false,
                                    "prerelease": false
                                  }' \
                                  https://api.github.com/repos/yourusername/your-repo/releases
                                
                                echo "✅ GitHub release created"
                            '''
                        }
                        
                    } catch (Exception e) {
                        echo "⚠️ GitHub operations failed: ${e.getMessage()}"
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Clean up - no credentials needed here
                echo '🧹 Cleaning up...'
                
                // Clean Docker credentials from memory
                sh 'docker logout || true'
                
                cleanWs()
            }
        }
        
        success {
            script {
                // Send success notification to GitHub (optional)
                withCredentials([usernamePassword(
                    credentialsId: "${GITHUB_CREDENTIALS_ID}",
                    usernameVariable: 'GIT_USERNAME',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    sh '''
                        # Update commit status
                        curl -X POST \
                          -H "Authorization: token $GIT_TOKEN" \
                          -H "Content-Type: application/json" \
                          -d '{
                            "state": "success",
                            "description": "Jenkins build succeeded",
                            "context": "continuous-integration/jenkins"
                          }' \
                          https://api.github.com/repos/yourusername/your-repo/statuses/${GIT_COMMIT}
                    '''
                }
            }
        }
        
        failure {
            script {
                // Send failure notification to GitHub (optional)
                withCredentials([usernamePassword(
                    credentialsId: "${GITHUB_CREDENTIALS_ID}",
                    usernameVariable: 'GIT_USERNAME',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    sh '''
                        curl -X POST \
                          -H "Authorization: token $GIT_TOKEN" \
                          -H "Content-Type: application/json" \
                          -d '{
                            "state": "failure",
                            "description": "Jenkins build failed",
                            "context": "continuous-integration/jenkins"
                          }' \
                          https://api.github.com/repos/yourusername/your-repo/statuses/${GIT_COMMIT}
                    '''
                }
            }
        }
    }
}
```

---

## 🛡️ Security Best Practices

### 1. **Credential Scope Management**
```groovy
// ✅ Good - Use specific credential IDs
DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'

// ❌ Bad - Don't hardcode credentials
DOCKER_PASSWORD = 'hardcoded-password'
```

### 2. **Environment Variable Protection**
```groovy
environment {
    // ✅ Safe - References to credential IDs
    DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
    
    // ❌ Dangerous - Actual credentials in environment
    // DOCKER_PASSWORD = credentials('dockerhub-credentials')
}
```

### 3. **Temporary Credential Exposure**
```groovy
// ✅ Good - Credentials only available in block scope
withCredentials([...]) {
    sh 'docker login -u $DOCKER_USER -p $DOCKER_PASS'
    sh 'docker push myimage'
    sh 'docker logout'  // Clean up
}

// ❌ Bad - Credentials in global scope
environment {
    DOCKER_PASS = credentials('docker-creds')
}
```

### 4. **Multiple Credential Types**
```groovy
// Handle different credential types
stage('Multi-Credential Operations') {
    steps {
        // SSH Key for Git operations
        sshagent(['github-ssh-key']) {
            sh 'git clone git@github.com:user/repo.git'
        }
        
        // Username/Password for API calls
        withCredentials([usernamePassword(
            credentialsId: 'github-credentials',
            usernameVariable: 'USER',
            passwordVariable: 'TOKEN'
        )]) {
            sh 'curl -u $USER:$TOKEN https://api.github.com/user'
        }
        
        // Secret Text for API keys
        withCredentials([string(
            credentialsId: 'api-key-secret',
            variable: 'API_KEY'
        )]) {
            sh 'curl -H "X-API-Key: $API_KEY" https://api.example.com'
        }
    }
}
```

---

## 🔧 Troubleshooting Common Issues

### 1. **Credential Not Found**
```
Error: Could not find credentials entry with ID 'dockerhub-credentials'
```
**Solution:**
- Verify credential ID matches exactly
- Check credential scope (Global vs. Project)
- Ensure you have permission to use the credential

### 2. **Authentication Failed**
```
Error: docker login failed
```
**Solution:**
- Verify Docker Hub username/token are correct
- Check if token has required permissions
- Try logging in manually with the same credentials

### 3. **GitHub Access Denied**
```
Error: remote: Repository not found
```
**Solution:**
- Verify GitHub token has `repo` scope
- Check if repository URL is correct
- Ensure token hasn't expired

### 4. **Credentials Showing in Logs**
**Problem:** Credentials appearing in console output

**Solution:**
```groovy
// ✅ Use withCredentials to mask sensitive data
withCredentials([usernamePassword(...)]) {
    sh '''
        # Credentials are automatically masked in logs
        echo "User: $USERNAME"  # Shows: User: ****
    '''
}
```

---

## 📋 Quick Reference

### Common Credential Types in Jenkins:

| Credential Type | Use Case | Jenkinsfile Usage |
|----------------|----------|-------------------|
| Username with password | GitHub, Docker Hub, APIs | `usernamePassword()` |
| SSH Username with private key | Git repositories | `sshagent()` |
| Secret text | API keys, tokens | `string()` |
| Certificate | SSL certificates | `certificate()` |
| Secret file | Config files, keys | `file()` |

### Credential ID Naming Conventions:
```
github-credentials          # GitHub access
dockerhub-credentials      # Docker Hub access  
aws-credentials           # AWS access
kubernetes-config         # K8s config file
ssl-certificate           # SSL certificates
api-key-production        # Production API keys
database-password         # Database access
```

---

## ✅ Final Checklist

- [ ] GitHub Personal Access Token created with correct scopes
- [ ] Docker Hub Access Token generated  
- [ ] Both credentials added to Jenkins with correct IDs
- [ ] Jenkinsfile updated to use `withCredentials`
- [ ] Credential masking working in logs
- [ ] No hardcoded secrets in pipeline code
- [ ] Credentials have appropriate expiration dates
- [ ] Team members have access to shared credentials

---

🎉 **Your Jenkins pipeline now has secure credential management for both GitHub and Docker Hub!**
# Jenkins Setup Guide for React CI/CD Pipeline

## Prerequisites

### 1. Jenkins Installation
Make sure Jenkins is installed with the following plugins:
- **Pipeline** (Pipeline: Groovy)
- **Docker Pipeline**
- **NodeJS**
- **Git**
- **Credentials Binding**
- **Blue Ocean** (optional, for better UI)

### 2. Configure Global Tools

#### Node.js Configuration:
1. Go to **Manage Jenkins** → **Global Tool Configuration**
2. Scroll to **NodeJS**
3. Click **Add NodeJS**
   - Name: `18` (matches the NODE_VERSION in Jenkinsfile)
   - Version: `NodeJS 18.x.x`
   - Check "Install automatically"

#### Docker Configuration:
Docker should be installed on the Jenkins server with Jenkins user having access to Docker daemon.

## Required Credentials Setup

### 1. Docker Hub Credentials
1. Go to **Manage Jenkins** → **Manage Credentials**
2. Choose appropriate domain (usually "Global")
3. Click **Add Credentials**
4. Choose **Username with password**
5. Configure:
   - **ID**: `dockerhub-credentials` (must match DOCKER_CREDENTIALS_ID in Jenkinsfile)
   - **Username**: Your Docker Hub username
   - **Password**: Your Docker Hub password or access token
   - **Description**: "Docker Hub credentials for pushing images"

### 2. GitHub Credentials (if private repository)
1. Add Credentials → **SSH Username with private key** or **Username with password**
2. Configure:
   - **ID**: `github-credentials`
   - **Username**: Your GitHub username
   - **Private Key/Password**: Your GitHub credentials

## Environment Variables Configuration

Update these variables in the Jenkinsfile according to your setup:

```groovy
environment {
    // Update with your Docker Hub username
    DOCKER_IMAGE_NAME = 'yashthakur1/react-app'
    
    // Update if using different registry
    DOCKER_REGISTRY = 'docker.io'
    
    // Must match the credential ID you created
    DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
    
    // Container configuration
    CONTAINER_NAME = 'react-app-container'
    APP_PORT = '80'
    HOST_PORT = '80'  // Change if port 80 is occupied
}
```

## Creating the Jenkins Pipeline Job

### 1. Create New Pipeline Job
1. Go to Jenkins dashboard
2. Click **New Item**
3. Enter name: `react-app-pipeline`
4. Select **Pipeline**
5. Click **OK**

### 2. Configure Pipeline
1. In the **Pipeline** section:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Your GitHub repository URL
   - **Credentials**: Select your GitHub credentials (if private repo)
   - **Branch**: `*/main` (or your default branch)
   - **Script Path**: `Jenkinsfile`

### 3. Optional: Configure Build Triggers
- **GitHub hook trigger for GITScm polling** (for automatic builds)
- **Poll SCM**: `H/5 * * * *` (checks every 5 minutes)

## Testing the Pipeline

### 1. Manual Build
1. Go to your pipeline job
2. Click **Build Now**
3. Monitor the build in **Console Output**

### 2. Verify Each Stage
The pipeline will execute these stages:
1. ✅ **Checkout** - Code retrieval from GitHub
2. ✅ **Install Dependencies & Build** - npm install and build
3. ✅ **Build Docker Image** - Creates Docker image with tags
4. ✅ **Docker Security Scan** - Basic security checks
5. ✅ **Push to Docker Hub** - Uploads to your Docker registry
6. ✅ **Deploy Locally** - Runs container on Jenkins server
7. ✅ **Post-Deploy Verification** - Health checks and verification

## Troubleshooting

### Common Issues:

#### 1. Permission Denied (Docker)
```bash
# On Jenkins server, add jenkins user to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

#### 2. Port Already in Use
Update `HOST_PORT` in Jenkinsfile to use a different port:
```groovy
HOST_PORT = '8080'  // Instead of 80
```

#### 3. Node.js Not Found
- Verify NodeJS tool configuration in Global Tool Configuration
- Ensure NODE_VERSION matches configured tool name

#### 4. Docker Hub Push Fails
- Verify Docker Hub credentials
- Check if repository exists on Docker Hub
- Ensure DOCKER_IMAGE_NAME format is correct: `username/repository`

#### 5. Build Fails
- Check if `package.json` has `build` script
- Verify all dependencies are in package.json
- Check Node.js version compatibility

## Security Best Practices

### 1. Credentials Management
- Never hardcode credentials in Jenkinsfile
- Use Jenkins credentials store
- Rotate Docker Hub tokens regularly

### 2. Resource Limits
Add resource limits to pipeline:
```groovy
options {
    timeout(time: 30, unit: 'MINUTES')
    retry(2)
    skipDefaultCheckout()
}
```

### 3. Docker Security
- Regularly update base images
- Scan images for vulnerabilities
- Use non-root users in containers
- Implement proper secrets management

## Monitoring and Maintenance

### 1. Pipeline Health
- Monitor build success rates
- Set up email notifications for failures
- Use Blue Ocean for better visualization

### 2. Resource Cleanup
The pipeline automatically:
- Cleans dangling Docker images
- Removes old image versions (keeps last 3)
- Cleans workspace after builds

### 3. Scaling Considerations
- Use Jenkins agents for distributed builds
- Implement parallel stages for faster builds
- Consider using Docker registries close to your infrastructure

## Next Steps

1. Set up automated testing stages
2. Implement staging environment deployment
3. Add security scanning with tools like Snyk or Twistlock
4. Configure blue-green deployments
5. Set up monitoring and alerting for production deployments
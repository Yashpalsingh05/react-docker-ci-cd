# 🚀 Quick Jenkins Credentials Setup Checklist

Follow these steps to configure Jenkins credentials for your CI/CD pipeline.

## ⏱️ 15-Minute Setup Guide

### 🔗 Step 1: GitHub Setup (5 minutes)

1. **Create GitHub Personal Access Token:**
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Name: `Jenkins-CI-CD`
   - Select scopes:
     - ✅ `repo` (Full control of repositories)
     - ✅ `workflow` (Update GitHub Action workflows)
     - ✅ `write:packages` (Upload packages)
   - Click "Generate token"
   - **⚠️ COPY TOKEN NOW** (you won't see it again!)

2. **Add to Jenkins:**
   - Jenkins → Manage Jenkins → Manage Credentials
   - System → Global credentials → Add Credentials
   - **Kind:** Username with password
   - **Username:** Your GitHub username
   - **Password:** The token you copied
   - **ID:** `github-credentials`
   - **Description:** `GitHub Personal Access Token`
   - Click "Create"

### 🐳 Step 2: Docker Hub Setup (5 minutes)

1. **Create Docker Hub Access Token:**
   - Go to: https://hub.docker.com/settings/security
   - Click "New Access Token"
   - Name: `Jenkins-CI-CD`
   - Permissions: `Read, Write, Delete`
   - Click "Generate"
   - **⚠️ COPY TOKEN NOW**

2. **Create Docker Hub Repository:**
   - Go to: https://hub.docker.com
   - Click "Create Repository"
   - Name: `react-app`
   - Visibility: Public (for free tier)
   - Click "Create"

3. **Add to Jenkins:**
   - Jenkins → Manage Jenkins → Manage Credentials
   - System → Global credentials → Add Credentials
   - **Kind:** Username with password
   - **Username:** `yashthakur1` (your Docker Hub username)
   - **Password:** The token you copied
   - **ID:** `dockerhub-credentials`
   - **Description:** `Docker Hub Access Token`
   - Click "Create"

### ⚙️ Step 3: Test Jenkins Pipeline (5 minutes)

1. **Verify Credentials:**
   ```groovy
   // Add this test stage to your Jenkinsfile
   stage('Test Credentials') {
       steps {
           script {
               withCredentials([usernamePassword(
                   credentialsId: 'github-credentials',
                   usernameVariable: 'GIT_USER',
                   passwordVariable: 'GIT_TOKEN'
               )]) {
                   sh 'echo "GitHub user: $GIT_USER"'  // Will show ****
               }
               
               withCredentials([usernamePassword(
                   credentialsId: 'dockerhub-credentials', 
                   usernameVariable: 'DOCKER_USER',
                   passwordVariable: 'DOCKER_TOKEN'
               )]) {
                   sh 'echo "Docker user: $DOCKER_USER"'  // Will show ****
               }
           }
       }
   }
   ```

2. **Run a test build** to verify credentials work

## 🔍 Verification Checklist

After setup, verify these work:

### GitHub Integration:
- [ ] ✅ Pipeline can checkout code from your repository
- [ ] ✅ No "authentication failed" errors
- [ ] ✅ Can create tags/releases (if needed)
- [ ] ✅ Credentials are masked in build logs

### Docker Hub Integration:  
- [ ] ✅ Can build Docker images locally
- [ ] ✅ Can push images to Docker Hub
- [ ] ✅ Images appear in your Docker Hub repository
- [ ] ✅ Both `latest` and build number tags are created

### Security:
- [ ] ✅ No actual passwords/tokens visible in Jenkinsfile
- [ ] ✅ Credentials show as `****` in build logs  
- [ ] ✅ Tokens have appropriate expiration dates set
- [ ] ✅ `docker logout` runs after operations

## 🚨 Troubleshooting

### "Credentials not found" error:
```
Solution: Check credential ID matches exactly:
- Jenkinsfile: credentialsId: 'dockerhub-credentials'
- Jenkins UI: ID field must be 'dockerhub-credentials'
```

### "Authentication failed" error:
```
Solution: 
1. Try the credentials manually:
   docker login -u yashthakur1 -p YOUR_TOKEN
2. Check token permissions on Docker Hub
3. Verify token hasn't expired
```

### "Repository not found" error:
```
Solution:
1. Create repository on Docker Hub first
2. Check repository name matches: yashthakur1/react-app
3. Verify repository is public (for free tier)
```

## 📝 Quick Commands for Testing

### Test Docker credentials manually:
```bash
# In terminal (use your actual token):
docker login -u yashthakur1 -p YOUR_DOCKER_TOKEN
docker push yashthakur1/react-app:test
docker logout
```

### Test GitHub credentials manually:
```bash  
# In terminal (use your actual token):
git clone https://YOUR_USERNAME:YOUR_TOKEN@github.com/yashthakur1/your-repo.git
```

## 🎯 Next Steps

Once credentials are working:

1. **Complete your pipeline** - Run full build/push cycle
2. **Set up webhooks** - Auto-trigger builds on Git push  
3. **Add notifications** - Slack/email alerts for build status
4. **Implement staging** - Deploy to staging environment
5. **Add monitoring** - Track deployment success/failures

## 📞 Need Help?

If you encounter issues:
1. Check Jenkins build logs for specific error messages
2. Verify credentials work manually outside Jenkins
3. Confirm credential IDs match between Jenkins and Jenkinsfile
4. Test with a simple pipeline first before complex operations

---

✅ **After completing this checklist, your Jenkins pipeline will have secure credential management for both GitHub and Docker Hub!**
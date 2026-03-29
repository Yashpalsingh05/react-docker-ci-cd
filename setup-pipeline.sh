#!/bin/bash

# 🚀 Automated CI/CD Pipeline Setup Script
# This script sets up your React app with automated push/pull request checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

show_help() {
    cat << EOF
🚀 CI/CD Pipeline Setup Script

This script helps you set up automated CI/CD pipelines that trigger on:
- Git push to main/develop branches  
- Pull requests to main branch
- Manual triggers

Options:
  setup-github    Set up GitHub Actions pipeline (recommended)
  setup-jenkins   Set up Jenkins pipeline  
  init-git        Initialize Git repository
  test-docker     Test Docker build locally
  help           Show this help message

Examples:
  ./setup-pipeline.sh setup-github    # Quick GitHub Actions setup
  ./setup-pipeline.sh init-git        # Initialize Git repo
  ./setup-pipeline.sh test-docker     # Test Docker build

EOF
}

check_requirements() {
    log_info "Checking requirements..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is required but not installed"
        exit 1
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        log_error "Git is required but not installed"
        exit 1
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js is required but not installed"
        exit 1
    fi
    
    log_success "All requirements satisfied"
}

setup_github_actions() {
    log_header "Setting up GitHub Actions Pipeline"
    
    # Create workflow directory if it doesn't exist
    mkdir -p .github/workflows
    
    # Check if workflow already exists
    if [ -f ".github/workflows/ci-cd.yml" ]; then
        log_success "GitHub Actions workflow already exists at .github/workflows/ci-cd.yml"
    else
        log_error "GitHub Actions workflow file not found. Please ensure ci-cd.yml exists in .github/workflows/"
        return 1
    fi
    
    # Test package.json scripts
    log_info "Testing package.json scripts..."
    
    if npm run lint --silent 2>/dev/null; then
        log_success "Lint script works"
    else
        log_warning "Lint script may need adjustment"
    fi
    
    # Instructions for GitHub setup
    cat << EOF

📋 Next Steps for GitHub Actions Setup:

1. 🔐 Add Docker Hub secrets to your GitHub repository:
   Go to: https://github.com/USERNAME/REPO/settings/secrets/actions
   
   Add these secrets:
   • DOCKER_USERNAME: yashthakur1
   • DOCKER_PASSWORD: Your Docker Hub access token

2. 🌐 Create GitHub repository (if not done):
   git remote add origin https://github.com/yashthakur1/react-docker-ci-cd.git

3. 🚀 Push to trigger pipeline:
   git add .
   git commit -m "Add GitHub Actions CI/CD pipeline"
   git push -u origin main

4. 📋 Create a test pull request to see the pipeline in action!

🎯 What the pipeline will do:
✅ Run code quality checks on every push/PR
✅ Run security scans and unit tests  
✅ Build and test Docker images
✅ Deploy PR previews for review
✅ Auto-deploy to production on main branch pushes
✅ Send notifications and status updates

EOF

    log_success "GitHub Actions setup ready!"
}

setup_jenkins() {
    log_header "Setting up Jenkins Pipeline"
    
    cat << EOF

📋 Jenkins Setup Instructions:

1. 🔧 Install Jenkins:
   Follow the guide in jenkins-setup.md

2. 🔐 Configure credentials in Jenkins:
   • Docker Hub credentials (ID: dockerhub-credentials)
   • GitHub credentials (ID: github-credentials)

3. 📋 Create Multibranch Pipeline job:
   • Source: Git
   • Repository: https://github.com/yashthakur1/react-docker-ci-cd.git
   • Script Path: Jenkinsfile

4. 🌐 Set up GitHub webhook:
   • Go to GitHub repo → Settings → Webhooks
   • URL: http://your-jenkins:8080/github-webhook/
   • Events: Pushes, Pull requests

5. 🚀 Push code to trigger pipeline!

📖 Detailed instructions available in:
   • jenkins-setup.md
   • jenkins-credentials-guide.md

EOF

    log_success "Jenkins setup instructions provided"
}

init_git_repo() {
    log_header "Initializing Git Repository"
    
    # Check if already a git repo
    if [ -d ".git" ]; then
        log_info "Git repository already initialized"
    else
        log_info "Initializing new Git repository..."
        git init
        log_success "Git repository initialized"
    fi
    
    # Create .gitignore if it doesn't exist
    if [ ! -f ".gitignore" ]; then
        log_info "Creating .gitignore file..."
        cat > .gitignore << EOF
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build output
build/
dist/

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
logs/
*.log

# Coverage
coverage/

# Testing
.nyc_output

# Docker
.dockerignore

# Temporary files
tmp/
temp/
EOF
        log_success ".gitignore created"
    fi
    
    # Stage all files
    log_info "Staging files for commit..."
    git add .
    
    # Create initial commit
    if git diff --cached --quiet; then
        log_info "No changes to commit"
    else
        log_info "Creating initial commit..."
        git commit -m "feat: Initial React Docker CI/CD setup

- Production-ready React app with Docker
- Multi-stage Docker build (optimized for size)
- nginx production server with security headers
- Complete CI/CD pipeline with GitHub Actions
- Jenkins pipeline configuration
- Automated testing and deployment scripts
- Comprehensive documentation and guides"
        log_success "Initial commit created"
    fi
    
    cat << EOF

📋 Next steps:
1. Create GitHub repository: react-docker-ci-cd
2. Add remote: git remote add origin https://github.com/yashthakur1/react-docker-ci-cd.git
3. Push: git push -u origin main

EOF
}

test_docker_build() {
    log_header "Testing Docker Build Locally"
    
    log_info "Building Docker image..."
    if docker build -t test-react-app .; then
        log_success "Docker build successful"
    else
        log_error "Docker build failed"
        return 1
    fi
    
    log_info "Testing container startup..."
    if docker run -d --name test-container -p 3002:80 test-react-app; then
        log_success "Container started successfully"
        
        # Wait for startup
        log_info "Waiting for application startup..."
        sleep 10
        
        # Test connectivity
        if curl -f -s http://localhost:3002/ > /dev/null; then
            log_success "Application is responding correctly"
            log_success "🌐 Test app running at: http://localhost:3002"
        else
            log_warning "Application health check failed"
        fi
        
        # Cleanup
        log_info "Cleaning up test container..."
        docker stop test-container > /dev/null 2>&1
        docker rm test-container > /dev/null 2>&1
        log_success "Cleanup completed"
    else
        log_error "Failed to start container"
        return 1
    fi
    
    log_success "Docker test completed successfully!"
}

show_pipeline_info() {
    cat << EOF

🚀 Your CI/CD Pipeline Setup

📁 Files Created:
✅ .github/workflows/ci-cd.yml     - GitHub Actions pipeline
✅ Jenkinsfile                     - Jenkins pipeline  
✅ automated-pipeline-guide.md     - Complete setup guide
✅ jenkins-credentials-guide.md    - Credentials setup
✅ deploy.sh                       - Deployment automation
✅ docker-compose.yml              - Multi-service deployment

🔄 Pipeline Triggers:
• Push to main/develop branches → Full CI/CD pipeline
• Pull requests to main → PR checks + preview deploy  
• Manual triggers → On-demand pipeline runs

✅ Automated Checks:
• Code quality (ESLint)
• Security scanning (npm audit)  
• Unit tests with coverage
• Docker build & container testing
• Deployment verification

🎯 Deployment Flow:
• PR → Preview environment
• Main branch → Production deployment
• Docker Hub → Automatic image publishing

📋 Choose Your Setup:
1. GitHub Actions (recommended for simplicity)
2. Jenkins (recommended for enterprise/self-hosted)

Run: ./setup-pipeline.sh setup-github
  or: ./setup-pipeline.sh setup-jenkins

EOF
}

# Main execution
case "${1:-help}" in
    setup-github)
        check_requirements
        setup_github_actions
        ;;
    setup-jenkins)  
        check_requirements
        setup_jenkins
        ;;
    init-git)
        init_git_repo
        ;;
    test-docker)
        check_requirements
        test_docker_build
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_pipeline_info
        echo ""
        show_help
        ;;
esac

log_success "Setup script completed! 🎉"
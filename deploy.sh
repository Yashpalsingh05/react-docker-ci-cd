#!/bin/bash

# React App Deployment Script
# This script automates the build and deployment process

set -e  # Exit on any error

# Configuration
DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-yashthakur1/react-app}"
CONTAINER_NAME="${CONTAINER_NAME:-react-app-container}"
HOST_PORT="${HOST_PORT:-80}"
APP_PORT="${APP_PORT:-80}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

show_help() {
    cat << EOF
React App Deployment Script

Usage: $0 [OPTIONS] COMMAND

COMMANDS:
    build       Build Docker image only
    deploy      Build and deploy locally
    push        Build and push to Docker Hub
    full        Full pipeline: build, push, deploy
    clean       Clean up old images and containers
    logs        Show container logs
    status      Show container status
    stop        Stop the container
    restart     Restart the container

OPTIONS:
    -i, --image NAME        Docker image name (default: $DOCKER_IMAGE_NAME)
    -c, --container NAME    Container name (default: $CONTAINER_NAME)
    -p, --port PORT         Host port (default: $HOST_PORT)
    -t, --tag TAG           Image tag (default: $BUILD_NUMBER)
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    DOCKER_IMAGE_NAME       Docker image name
    CONTAINER_NAME          Container name
    HOST_PORT               Host port
    APP_PORT                App port
    BUILD_NUMBER            Build number for tagging

EXAMPLES:
    $0 build                           # Build image
    $0 deploy -p 8080                  # Deploy on port 8080
    $0 full -i myuser/myapp -t v1.0    # Full pipeline with custom image and tag
    $0 logs                            # Show container logs
    $0 clean                           # Clean up resources

EOF
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running or accessible"
        exit 1
    fi
    
    # Check Node.js (for local builds)
    if ! command -v node &> /dev/null; then
        log_warning "Node.js is not installed - using Docker for builds only"
    fi
    
    log_success "Dependencies check passed"
}

build_image() {
    log_info "Building Docker image: $DOCKER_IMAGE_NAME:$IMAGE_TAG"
    
    # Build the image
    docker build -t "$DOCKER_IMAGE_NAME:$IMAGE_TAG" .
    
    # Tag as latest
    docker tag "$DOCKER_IMAGE_NAME:$IMAGE_TAG" "$DOCKER_IMAGE_NAME:latest"
    
    log_success "Docker image built successfully"
    
    # Show image info
    docker images "$DOCKER_IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
}

push_image() {
    log_info "Pushing image to Docker Hub..."
    
    # Push tagged version
    docker push "$DOCKER_IMAGE_NAME:$IMAGE_TAG"
    
    # Push latest
    docker push "$DOCKER_IMAGE_NAME:latest"
    
    log_success "Image pushed successfully"
}

stop_existing_container() {
    log_info "Checking for existing container..."
    
    # Stop existing container
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        log_info "Stopping existing container: $CONTAINER_NAME"
        docker stop "$CONTAINER_NAME"
    fi
    
    # Remove existing container
    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        log_info "Removing existing container: $CONTAINER_NAME"
        docker rm "$CONTAINER_NAME"
    fi
}

deploy_container() {
    log_info "Deploying container locally..."
    
    # Stop existing container
    stop_existing_container
    
    # Check if port is available
    if netstat -tuln 2>/dev/null | grep -q ":$HOST_PORT "; then
        log_warning "Port $HOST_PORT is already in use. Container may fail to start."
    fi
    
    # Run new container
    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -p "$HOST_PORT:$APP_PORT" \
        --health-cmd="curl -f http://localhost/ || exit 1" \
        --health-interval=30s \
        --health-timeout=10s \
        --health-retries=3 \
        "$DOCKER_IMAGE_NAME:$IMAGE_TAG"
    
    # Wait for container to start
    sleep 3
    
    # Check container status
    if docker ps -f name="$CONTAINER_NAME" | grep -q "$CONTAINER_NAME"; then
        log_success "Container deployed successfully"
        log_info "Container status:"
        docker ps -f name="$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # Test application
        log_info "Testing application..."
        sleep 2
        if curl -f -s "http://localhost:$HOST_PORT" > /dev/null; then
            log_success "Application is responding correctly"
            log_success "🌐 Application URL: http://localhost:$HOST_PORT"
        else
            log_warning "Application health check failed. Check logs with: $0 logs"
        fi
    else
        log_error "Container failed to start"
        docker logs "$CONTAINER_NAME" --tail 20
        exit 1
    fi
}

show_logs() {
    log_info "Container logs for $CONTAINER_NAME:"
    docker logs "$CONTAINER_NAME" --follow
}

show_status() {
    log_info "Container status:"
    
    if docker ps -f name="$CONTAINER_NAME" | grep -q "$CONTAINER_NAME"; then
        # Running container info
        docker ps -f name="$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # Health status
        HEALTH=$(docker inspect "$CONTAINER_NAME" --format='{{.State.Health.Status}}' 2>/dev/null || echo "No health check")
        echo "Health: $HEALTH"
        
        # Resource usage
        log_info "Resource usage:"
        docker stats "$CONTAINER_NAME" --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    else
        log_warning "Container $CONTAINER_NAME is not running"
    fi
}

clean_resources() {
    log_info "Cleaning up Docker resources..."
    
    # Stop and remove container if running
    stop_existing_container
    
    # Remove dangling images
    docker image prune -f
    
    # Remove old images (keep latest and last 3 tagged versions)
    log_info "Cleaning old images for $DOCKER_IMAGE_NAME..."
    OLD_IMAGES=$(docker images "$DOCKER_IMAGE_NAME" --format "{{.Tag}}" | grep -E '^[0-9]+' | sort -nr | tail -n +4)
    for tag in $OLD_IMAGES; do
        if [ "$tag" != "$IMAGE_TAG" ] && [ "$tag" != "latest" ]; then
            log_info "Removing old image: $DOCKER_IMAGE_NAME:$tag"
            docker rmi "$DOCKER_IMAGE_NAME:$tag" 2>/dev/null || true
        fi
    done
    
    log_success "Cleanup completed"
}

# Parse command line arguments
IMAGE_TAG="$BUILD_NUMBER"

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--image)
            DOCKER_IMAGE_NAME="$2"
            shift 2
            ;;
        -c|--container)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        -p|--port)
            HOST_PORT="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        build|deploy|push|full|clean|logs|status|stop|restart)
            COMMAND="$1"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if command is provided
if [ -z "$COMMAND" ]; then
    log_error "No command provided"
    show_help
    exit 1
fi

# Main execution
log_info "🚀 React App Deployment Script"
log_info "Image: $DOCKER_IMAGE_NAME:$IMAGE_TAG"
log_info "Container: $CONTAINER_NAME"
log_info "Port: $HOST_PORT"
echo

case $COMMAND in
    build)
        check_dependencies
        build_image
        ;;
    deploy)
        check_dependencies
        build_image
        deploy_container
        ;;
    push)
        check_dependencies
        build_image
        push_image
        ;;
    full)
        check_dependencies
        build_image
        push_image
        deploy_container
        ;;
    clean)
        clean_resources
        ;;
    logs)
        show_logs
        ;;
    status)
        show_status
        ;;
    stop)
        stop_existing_container
        log_success "Container stopped"
        ;;
    restart)
        stop_existing_container
        deploy_container
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac

log_success "✨ Operation completed successfully!"
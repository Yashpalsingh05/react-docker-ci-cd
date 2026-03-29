# Production-Ready React App Docker Setup

This repository contains optimized Docker configuration for deploying React applications in production.

## Files Overview

- `Dockerfile` - Multi-stage Docker build configuration
- `.dockerignore` - Excludes unnecessary files from Docker build context
- `nginx.conf` - Optional custom nginx configuration
- `package.json.example` - Example React app package.json

## Features

✅ **Multi-stage build** - Reduces final image size by ~80%  
✅ **nginx optimization** - Gzip compression, caching, security headers  
✅ **SPA routing support** - Handles React Router client-side routing  
✅ **Security hardening** - Security headers, non-root user option  
✅ **Health checks** - Built-in container health monitoring  
✅ **Performance optimized** - Static asset caching and compression  

## Usage

### 1. Basic Build & Run

```bash
# Build the Docker image
docker build -t my-react-app .

# Run the container
docker run -p 3000:80 my-react-app
```

Your app will be available at http://localhost:3000

### 2. Production Deployment

```bash
# Build with production tag
docker build -t my-react-app:latest .

# Run with restart policy
docker run -d \
  --name react-app \
  --restart unless-stopped \
  -p 80:80 \
  my-react-app:latest
```

### 3. Docker Compose Example

```yaml
version: '3.8'
services:
  react-app:
    build: .
    ports:
      - "80:80"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

## Using Custom nginx Configuration

To use the separate `nginx.conf` file instead of inline configuration:

1. Uncomment this line in the Dockerfile:
   ```dockerfile
   COPY nginx.conf /etc/nginx/conf.d/default.conf
   ```

2. Remove the inline nginx configuration section

## Image Size Optimization

This setup creates very small production images:

- **Build stage**: ~1.2GB (Node.js + dependencies)
- **Production stage**: ~25MB (nginx + built app)

The multi-stage build discards the Node.js environment, keeping only the compiled React app.

## Environment Variables

Set environment variables during build:

```bash
docker build \
  --build-arg REACT_APP_API_URL=https://api.example.com \
  -t my-react-app .
```

## Security Features

- Security headers (XSS protection, content type sniffing prevention)
- Content Security Policy
- Frame options protection
- Nginx server token hiding
- Gzip compression for performance

## Health Monitoring

The container includes a health check that:
- Runs every 30 seconds
- Times out after 10 seconds
- Retries 3 times before marking as unhealthy
- Waits 5 seconds before first check

Monitor health:
```bash
docker ps  # Shows health status
docker inspect my-container | grep -A 10 Health
```

## Troubleshooting

### Build fails at npm install
- Check your `package.json` and `package-lock.json` are present
- Ensure Node version compatibility

### App not loading
- Check if build folder exists: `docker run --rm my-react-app ls -la /usr/share/nginx/html`
- Verify nginx logs: `docker logs container-name`

### 404 errors on refresh
- The nginx configuration handles React Router - ensure `try_files` directive is present

## Performance Tips

1. **Layer caching**: Copy `package.json` before source code
2. **Multi-arch builds**: Use `docker buildx` for ARM64 support
3. **Build optimization**: Use `npm ci` instead of `npm install`
4. **Registry optimization**: Use smaller base images like `alpine`

## Production Checklist

- [ ] Environment variables configured
- [ ] SSL/TLS termination setup (load balancer/reverse proxy)
- [ ] Logging configured
- [ ] Monitoring setup
- [ ] Backup strategy for volumes
- [ ] Security scanning completed
- [ ] Performance testing done
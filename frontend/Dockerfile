# ================================
# STAGE 1: Dependencies
# ================================
FROM node:20-alpine AS deps

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci --only=production=false

# ================================
# STAGE 2: Builder
# ================================
FROM node:20-alpine AS builder

WORKDIR /app

# Build arguments for environment configuration
# These are injected at build time via docker-compose or CI/CD
ARG PUBLIC_API_URL=https://kgr33n.com
ARG PUBLIC_FRONTEND_URL=https://kgr33n.com
ARG PUBLIC_ENVIRONMENT=production

# Set environment variables for the build process
ENV PUBLIC_API_URL=$PUBLIC_API_URL
ENV PUBLIC_FRONTEND_URL=$PUBLIC_FRONTEND_URL
ENV PUBLIC_ENVIRONMENT=$PUBLIC_ENVIRONMENT

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build the Astro application
RUN npm run build


# ================================
# STAGE 3: Production Runtime (nginx)
# ================================
FROM nginx:alpine AS runtime

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Copy built static files from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Security: Run as non-root user
# Create user and fix nginx to run on port 80 as non-root
RUN addgroup -g 1000 app && \
    adduser -u 1000 -G app -s /bin/sh -D app && \
    chown -R app:app /usr/share/nginx/html && \
    chown -R app:app /var/cache/nginx && \
    chown -R app:app /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R app:app /var/run/nginx.pid && \
    # Allow nginx to bind to privileged ports as non-root
    apk add --no-cache libcap && \
    setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx

# Switch to non-root user
USER app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Expose port
EXPOSE 80

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]

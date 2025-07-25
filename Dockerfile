# Build stage
FROM node:22.15-alpine3.20 AS build

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

WORKDIR /usr/src

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev dependencies for build)
RUN npm ci --prefer-offline --no-audit

# Copy source code and prisma schema
COPY . .

# Generate Prisma client
RUN npx prisma generate

# Install only production dependencies in a clean way
RUN npm ci --only=production --prefer-offline --no-audit && npm cache clean --force

# Production stage
FROM node:22.15-alpine3.20

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /usr/src

# Copy built application from build stage
COPY --from=build --chown=nodejs:nodejs /usr/src/package.json ./package.json
COPY --from=build --chown=nodejs:nodejs /usr/src/node_modules ./node_modules 
COPY --from=build --chown=nodejs:nodejs /usr/src/src ./src
COPY --from=build --chown=nodejs:nodejs /usr/src/prisma ./prisma
COPY --from=build --chown=nodejs:nodejs /usr/src/start.sh ./start.sh

# Make start script executable
RUN chmod +x start.sh

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3333

# Add health check with more reasonable timeouts
HEALTHCHECK --interval=15s --timeout=10s --start-period=60s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3333/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))"

# Use dumb-init for proper signal handling and run the application
ENTRYPOINT ["dumb-init", "--"]
CMD ["./start.sh"]
# Multi-stage Dockerfile for Node.js Todo App
# Build for amd64 architecture (VM target)

# Stage 1: Base
FROM node:18-slim AS base
WORKDIR /usr/src/app
EXPOSE 4000

# Stage 2: Dependencies
FROM base AS dependencies
# Copy package files
COPY package*.json ./
# Install production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Stage 3: Development (with nodemon)
FROM base AS development
COPY package*.json ./
RUN npm ci && \
    npm cache clean --force
COPY . .
USER node
CMD ["npm", "start"]

# Stage 4: Production
FROM base AS production
# Create non-root user directory
RUN chown -R node:node /usr/src/app
USER node
# Copy production dependencies from dependencies stage
COPY --chown=node:node --from=dependencies /usr/src/app/node_modules ./node_modules
# Copy application code
COPY --chown=node:node . .
# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:4000', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"
# Start app directly with node (not npm)
CMD ["node", "index.js"]

FROM node:20-alpine AS builder

WORKDIR /app

# Add build arguments for environment variables
ARG DATABASE_URL
ARG JWT_SECRET

# Set environment variables for the build process
ENV DATABASE_URL=${DATABASE_URL}
ENV JWT_SECRET=${JWT_SECRET}

COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install

COPY . .
RUN pnpm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Add build arguments for environment variables (will be passed through from builder)
ARG DATABASE_URL
ARG JWT_SECRET

# Set environment variables for runtime
ENV DATABASE_URL=${DATABASE_URL}
ENV JWT_SECRET=${JWT_SECRET}
ENV NODE_ENV=production

# Copy built assets from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package.json ./
COPY prisma ./prisma

# Install only production dependencies and generate Prisma client
RUN npm install -g pnpm && \
    pnpm install --prod && \
    npx prisma generate

# Create non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose the port
EXPOSE 4000

# Start the server
CMD ["node", "dist/index.js"] 
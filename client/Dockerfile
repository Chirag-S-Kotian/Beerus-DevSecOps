FROM node:20-alpine AS builder

WORKDIR /app

# Add build arguments for environment variables
ARG NEXT_PUBLIC_API_URL

# Set environment variables for the build process
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}

# Copy package.json and pnpm-lock.yaml
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install

# Copy the rest of the source code
COPY . .

# Build the application
RUN pnpm run build

# Production stage
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# Add build arguments for environment variables
ARG NEXT_PUBLIC_API_URL

# Set environment variables for runtime
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}

# Copy necessary files from builder stage
COPY --from=builder /app/next.config.mjs ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

# Create non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose the port
EXPOSE 3000

# Start the application
CMD ["pnpm", "start"] 
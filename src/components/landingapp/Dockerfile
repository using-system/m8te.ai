# Official node image
FROM node:18-alpine

# Create a working directory
WORKDIR /app

# Copy package.json and package-lock.json files
COPY package.json ./
COPY package-lock.json ./

# Install dependencies
RUN npm install --ignore-scripts

# Copy the rest of the application files
COPY . .

# Build the Next.js application
RUN npm run build \
    && addgroup -g 1001 -S appgroup && adduser  -u 1001 -S appuser -G appgroup \
    && chown -R appuser:appgroup /app

# Run the application as a non-root user
USER appuser

# Expose the port the application will run on
EXPOSE 3000

# Add a health check instruction
# HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:3000/health || exit 1

# Start the application
CMD ["npm", "start"]

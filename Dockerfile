FROM node:20-alpine

# Install build dependencies
RUN apk add --no-cache python3 make g++ git

WORKDIR /app

# Clone and build google-cloud-mcp
RUN git clone https://github.com/krzko/google-cloud-mcp.git && \
    cd google-cloud-mcp && \
    npm install && \
    npm run build

# Create a simple health check endpoint
RUN echo 'const http = require("http"); \
const server = http.createServer((req, res) => { \
  if (req.url === "/health") { \
    res.writeHead(200); \
    res.end("OK"); \
  } \
}); \
server.listen(8080);' > health-server.js

# Copy startup script
COPY <<EOF start.sh
#!/bin/sh
echo "Starting BulleoApp MCP Server..."

# Start health check server
node /app/health-server.js &

# Start MCP server
node /app/google-cloud-mcp/dist/index.js

EOF
RUN chmod +x start.sh

# Expose port for Cloud Run
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["./start.sh"]
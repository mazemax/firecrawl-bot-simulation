#!/bin/bash

# Firecrawl Bot Simulation - Instance Setup Script
# Creates 10 separate Firecrawl instances with different configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_ROOT="/Users/maxsaad/Desktop/mindvalley/firecrawl-bot-simulation"
FIRECRAWL_SOURCE="$PROJECT_ROOT/firecrawl"
INSTANCES_DIR="$PROJECT_ROOT/instances"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Firecrawl Bot Simulation - Setup${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if Docker is running
echo -e "${YELLOW}Checking Docker status...${NC}"
if ! docker ps > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running. Please start Docker Desktop.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is running${NC}\n"

# Instance configurations
# Format: instance_number:port:user_agent:depth:delay:js_enabled:description
declare -a INSTANCES=(
    "01:3002:Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html):3:1:yes:Googlebot"
    "02:3003:Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm):3:1:yes:Bingbot"
)

# Create each instance
for config in "${INSTANCES[@]}"; do
    IFS=':' read -r instance port user_agent depth delay js_enabled description <<< "$config"
    
    INSTANCE_DIR="$INSTANCES_DIR/instance$instance"
    
    echo -e "${BLUE}Setting up Instance $instance - $description${NC}"
    echo -e "  Port: $port | Depth: $depth | Delay: ${delay}s | JS: $js_enabled"
    
    # Create instance directory
    mkdir -p "$INSTANCE_DIR"
    
    # Copy Firecrawl files (excluding node_modules and build artifacts)
    echo -e "  ${YELLOW}Copying Firecrawl files...${NC}"
    rsync -a --exclude='node_modules' --exclude='.git' --exclude='dist' \
          --exclude='build' --exclude='.next' \
          "$FIRECRAWL_SOURCE/" "$INSTANCE_DIR/"
    
    # Create .env file
    echo -e "  ${YELLOW}Creating .env file...${NC}"
    cat > "$INSTANCE_DIR/.env" << EOF
# ===== Required ENVS ======
NUM_WORKERS_PER_QUEUE=8
PORT=$port
HOST=0.0.0.0
REDIS_URL=redis://redis:6379
REDIS_RATE_LIMIT_URL=redis://redis:6379
PLAYWRIGHT_MICROSERVICE_URL=http://playwright-service:3000/scrape

## To turn off DB authentication for self-hosting
USE_DB_AUTHENTICATION=false

# ===== Optional ENVS ======
BULL_AUTH_KEY=firecrawl-test-$instance
LOGGING_LEVEL=INFO

# Instance specific metadata
INSTANCE_NUMBER=$instance
INSTANCE_DESCRIPTION=$description
EOF
    
    # Modify docker-compose.yaml to remove PostgreSQL port exposure (prevents conflicts)
    # and handle JS-disabled instances
    echo -e "  ${YELLOW}Configuring Docker Compose...${NC}"
    
    if [ -f "$INSTANCE_DIR/docker-compose.yaml" ]; then
        # Remove only the PostgreSQL port mapping to avoid conflicts between instances
        # PostgreSQL will still work internally within the Docker network
        # Find the nuq-postgres section and remove its ports section entirely
        awk '
        /^[[:space:]]*nuq-postgres:/ { in_postgres=1 }
        in_postgres && /^[[:space:]]*ports:/ { skip_ports=1; next }
        in_postgres && skip_ports && /^[[:space:]]*-/ { next }
        in_postgres && /^[[:space:]]*[a-zA-Z]/ && !/^[[:space:]]*-/ { skip_ports=0; in_postgres=0 }
        /^[[:space:]]*[a-zA-Z][^:]*:/ && !/^[[:space:]]*nuq-postgres:/ { in_postgres=0; skip_ports=0 }
        !skip_ports { print }
        ' "$INSTANCE_DIR/docker-compose.yaml" > "$INSTANCE_DIR/docker-compose.yaml.tmp" && 
        mv "$INSTANCE_DIR/docker-compose.yaml.tmp" "$INSTANCE_DIR/docker-compose.yaml"
        rm -f "$INSTANCE_DIR/docker-compose.yaml.bak"
        
        # For JS-disabled instances, also remove Playwright service
        if [ "$js_enabled" = "no" ]; then
            echo -e "  ${YELLOW}Disabling JavaScript rendering (no Playwright)...${NC}"
            
            # Create simplified docker-compose for no-JS instances
            cat > "$INSTANCE_DIR/docker-compose.yaml" << 'EOFCOMPOSE'
name: firecrawl

x-common-service: &common-service
  build: apps/api
  ulimits:
    nofile:
      soft: 65535
      hard: 65535
  networks:
    - backend
  extra_hosts:
    - "host.docker.internal:host-gateway"

x-common-env: &common-env
  REDIS_URL: ${REDIS_URL:-redis://redis:6379}
  REDIS_RATE_LIMIT_URL: ${REDIS_URL:-redis://redis:6379}
  NUQ_DATABASE_URL: postgres://postgres:postgres@nuq-postgres:5432/postgres
  USE_DB_AUTHENTICATION: ${USE_DB_AUTHENTICATION}
  BULL_AUTH_KEY: ${BULL_AUTH_KEY}
  LOGGING_LEVEL: ${LOGGING_LEVEL}

services:
  api:
    <<: *common-service
    environment:
      <<: *common-env
      HOST: "0.0.0.0"
      PORT: ${INTERNAL_PORT:-3002}
      EXTRACT_WORKER_PORT: ${EXTRACT_WORKER_PORT:-3004}
      WORKER_PORT: ${WORKER_PORT:-3005}
      ENV: local
    depends_on:
      - redis
      - nuq-postgres
    ports:
      - "${PORT:-3002}:${INTERNAL_PORT:-3002}"
    command: node dist/src/harness.js --start-docker

  redis:
    image: redis:alpine
    networks:
      - backend
    command: redis-server --bind 0.0.0.0
  
  nuq-postgres:
    build: apps/nuq-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
    networks:
      - backend

networks:
  backend:
    driver: bridge
EOFCOMPOSE
        fi
    fi
    
    echo -e "${GREEN}✓ Instance $instance configured${NC}\n"
done

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Build and launch instances: ${YELLOW}./scripts/launch-all.sh${NC}"
echo -e "  2. Or build a single instance: ${YELLOW}cd instances/instance01 && docker compose build${NC}\n"

echo -e "${YELLOW}Note: Building all instances may take 10-20 minutes on first run.${NC}"

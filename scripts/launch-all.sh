#!/bin/bash

# Launch all 10 Firecrawl instances in background with logging

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="/Users/maxsaad/Desktop/mindvalley/firecrawl-bot-simulation"
INSTANCES_DIR="$PROJECT_ROOT/instances"
LOGS_DIR="$PROJECT_ROOT/logs"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Launching All Firecrawl Instances${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check Docker
if ! docker ps > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

# Create logs directory
mkdir -p "$LOGS_DIR"

# Function to launch an instance
launch_instance() {
    local instance=$1
    local instance_dir="$INSTANCES_DIR/instance$instance"
    local log_file="$LOGS_DIR/instance$instance.log"
    
    if [ ! -d "$instance_dir" ]; then
        echo -e "${RED}Error: Instance directory not found: $instance_dir${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Launching Instance $instance...${NC}"
    
    cd "$instance_dir"
    
    # Build if needed (only on first run or if images don't exist)
    if ! docker images | grep -q "instance$instance"; then
        echo -e "  ${YELLOW}Building Docker images for instance $instance...${NC}"
        docker compose -p "firecrawl-instance$instance" build > "$log_file" 2>&1
    fi
    
    # Start in background with logging
    docker compose -p "firecrawl-instance$instance" up -d >> "$log_file" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Instance $instance launched (logging to logs/instance$instance.log)${NC}"
    else
        echo -e "${RED}✗ Failed to launch instance $instance${NC}"
        return 1
    fi
}

# Launch all instances
for i in $(seq -f "%02g" 1 2); do
    launch_instance "$i"
    sleep 2  # Small delay between launches to avoid overwhelming system
done

echo -e "\n${BLUE}Waiting for instances to initialize...${NC}"
sleep 10

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Instance Status Check${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check status of all instances
for i in $(seq -f "%02g" 1 2); do
    port=$((3001 + 10#$i))
    
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" | grep -q "404\|200"; then
        echo -e "${GREEN}✓ Instance $i responding on port $port${NC}"
    else
        echo -e "${YELLOW}⚠ Instance $i may still be starting on port $port${NC}"
    fi
done

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}All instances launched!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Start crawls: ${YELLOW}./scripts/start-crawls.sh${NC}"
echo -e "  2. Monitor logs: ${YELLOW}tail -f logs/instance*.log${NC}"
echo -e "  3. View all containers: ${YELLOW}docker ps${NC}\n"

echo -e "${YELLOW}Note: It may take 1-2 minutes for all services to be fully ready.${NC}"

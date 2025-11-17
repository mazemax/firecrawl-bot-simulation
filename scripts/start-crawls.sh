#!/bin/bash

# Start crawls on all 10 Firecrawl instances

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="/Users/maxsaad/Desktop/mindvalley/firecrawl-bot-simulation"
CONFIGS_DIR="$PROJECT_ROOT/configs"
LOGS_DIR="$PROJECT_ROOT/logs"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Starting Crawls on All Instances${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Create crawl responses directory
mkdir -p "$LOGS_DIR/crawl-responses"

# Function to start a crawl
start_crawl() {
    local instance=$1
    local port=$((3001 + 10#$instance))
    local config_file="$CONFIGS_DIR/instance$instance-config.json"
    local response_file="$LOGS_DIR/crawl-responses/instance$instance-response.json"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Error: Config file not found: $config_file${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Starting crawl on Instance $instance (port $port)...${NC}"
    
    # Send crawl request
    response=$(curl -s -X POST "http://localhost:$port/v2/crawl" \
        -H "Content-Type: application/json" \
        -d @"$config_file" 2>&1)
    
    # Save response
    echo "$response" > "$response_file"
    
    # Check if successful
    if echo "$response" | grep -q '"success":true'; then
        crawl_id=$(echo "$response" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
        echo -e "${GREEN}✓ Instance $instance crawl started (ID: $crawl_id)${NC}"
        
        # Log crawl start with timestamp
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Crawl started - ID: $crawl_id" >> "$LOGS_DIR/instance$instance.log"
    else
        echo -e "${RED}✗ Failed to start crawl on instance $instance${NC}"
        echo "Response: $response"
        return 1
    fi
}

# Start all crawls in rapid succession
echo -e "${BLUE}Initiating crawls...${NC}\n"

for i in $(seq -f "%02g" 1 2); do
    start_crawl "$i" &
    sleep 0.5  # Small stagger to avoid exact simultaneity
done

# Wait for all background jobs to complete
wait

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}All Crawls Initiated!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}Monitoring Information:${NC}"
echo -e "  • Crawl responses saved in: ${YELLOW}logs/crawl-responses/${NC}"
echo -e "  • Monitor instance logs: ${YELLOW}tail -f logs/instance*.log${NC}"
echo -e "  • Watch Docker containers: ${YELLOW}docker ps${NC}"
echo -e "  • Check specific instance: ${YELLOW}docker logs firecrawl-instance01-api-1${NC}\n"

echo -e "${YELLOW}Note: Crawls will run for several minutes depending on site size and depth.${NC}"
echo -e "${YELLOW}Use Ctrl+C to stop monitoring, but crawls will continue in background.${NC}\n"

# Optional: Start monitoring in the background
read -p "Would you like to start live log monitoring? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Starting live log monitoring (Ctrl+C to stop)...${NC}\n"
    tail -f "$LOGS_DIR"/instance*.log
fi

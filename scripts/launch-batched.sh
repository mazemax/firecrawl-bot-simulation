#!/bin/bash

# Launch Firecrawl instances in batches to avoid resource exhaustion

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="/Users/maxsaad/Desktop/mindvalley/firecrawl-bot-simulation"
INSTANCES_DIR="$PROJECT_ROOT/instances"
LOGS_DIR="$PROJECT_ROOT/logs"

# Configuration
BATCH_SIZE=2  # Number of instances to run simultaneously (now only 2 total)
WAIT_TIME=15  # Seconds to wait between batches

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Launching Firecrawl Instances (Batched)${NC}"
echo -e "${BLUE}========================================${NC}\n"
echo -e "${YELLOW}Running $BATCH_SIZE instances at a time${NC}\n"

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
    
    # Start in background with logging
    docker compose -p "firecrawl-instance$instance" up -d >> "$log_file" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Instance $instance launched${NC}"
    else
        echo -e "${RED}✗ Failed to launch instance $instance${NC}"
        return 1
    fi
}

# Function to check instance health
check_instance_health() {
    local instance=$1
    local port=$((3001 + 10#$instance))
    
    # Check if API container is running
    if docker ps | grep -q "firecrawl-instance$instance-api"; then
        return 0
    else
        return 1
    fi
}

# Launch instances in batches
batch_num=1
for start in $(seq 1 $BATCH_SIZE 2); do
    end=$((start + BATCH_SIZE - 1))
    if [ $end -gt 2 ]; then
        end=2
    fi
    
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}Batch $batch_num: Instances $(printf "%02d" $start) to $(printf "%02d" $end)${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    # Launch instances in this batch
    for i in $(seq $start $end); do
        instance=$(printf "%02d" $i)
        launch_instance "$instance"
        sleep 2  # Small delay between launches
    done
    
    echo -e "\n${YELLOW}Waiting for batch to stabilize ($WAIT_TIME seconds)...${NC}"
    sleep $WAIT_TIME
    
    # Check health of instances in this batch
    echo -e "\n${BLUE}Checking batch health...${NC}"
    for i in $(seq $start $end); do
        instance=$(printf "%02d" $i)
        if check_instance_health "$instance"; then
            echo -e "${GREEN}✓ Instance $instance is running${NC}"
        else
            echo -e "${YELLOW}⚠ Instance $instance may be having issues${NC}"
        fi
    done
    
    batch_num=$((batch_num + 1))
    
    if [ $end -lt 2 ]; then
        echo -e "\n${YELLOW}Pausing before next batch...${NC}"
        sleep 5
    fi
done

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}All batches launched!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}Checking overall status...${NC}\n"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep firecrawl | grep api

echo -e "\n${BLUE}Next steps:${NC}"
echo -e "  1. Monitor logs: ${YELLOW}tail -f logs/instance*.log${NC}"
echo -e "  2. Check containers: ${YELLOW}docker ps | grep firecrawl${NC}"
echo -e "  3. Start crawls: ${YELLOW}./scripts/start-crawls.sh${NC}\n"

echo -e "${YELLOW}Note: Monitor system resources with 'docker stats'${NC}"

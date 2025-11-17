#!/bin/bash

# Cleanup script - Stop all instances and remove containers

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="/Users/maxsaad/Desktop/mindvalley/firecrawl-bot-simulation"
INSTANCES_DIR="$PROJECT_ROOT/instances"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Cleanup - Stopping All Instances${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Function to stop an instance
stop_instance() {
    local instance=$1
    local instance_dir="$INSTANCES_DIR/instance$instance"
    
    if [ ! -d "$instance_dir" ]; then
        return 0
    fi
    
    echo -e "${YELLOW}Stopping Instance $instance...${NC}"
    
    cd "$instance_dir"
    docker compose -p "firecrawl-instance$instance" down --volumes 2>&1 | grep -v "^$"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Instance $instance stopped${NC}"
    else
        echo -e "${YELLOW}⚠ Instance $instance may not have been running${NC}"
    fi
}

# Stop all instances
for i in $(seq -f "%02g" 1 2); do
    stop_instance "$i"
done

echo -e "\n${BLUE}Checking for remaining containers...${NC}"
remaining=$(docker ps -a | grep "firecrawl-instance" | wc -l | tr -d ' ')

if [ "$remaining" -gt 0 ]; then
    echo -e "${YELLOW}Found $remaining related containers. Cleaning up...${NC}"
    docker ps -a | grep "firecrawl-instance" | awk '{print $1}' | xargs docker rm -f 2>/dev/null
    echo -e "${GREEN}✓ Containers removed${NC}"
else
    echo -e "${GREEN}✓ No containers remaining${NC}"
fi

echo -e "\n${BLUE}Checking for Docker networks...${NC}"
networks=$(docker network ls | grep "firecrawl-instance" | wc -l | tr -d ' ')

if [ "$networks" -gt 0 ]; then
    echo -e "${YELLOW}Found $networks related networks. Cleaning up...${NC}"
    docker network ls | grep "firecrawl-instance" | awk '{print $1}' | xargs docker network rm 2>/dev/null
    echo -e "${GREEN}✓ Networks removed${NC}"
else
    echo -e "${GREEN}✓ No networks remaining${NC}"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Cleanup Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}System status:${NC}"
echo -e "  • All Firecrawl instances stopped"
echo -e "  • Docker containers removed"
echo -e "  • Docker networks cleaned up"
echo -e "  • Log files preserved in: ${YELLOW}logs/${NC}\n"

echo -e "${YELLOW}Optional cleanup actions:${NC}"
echo -e "  • Remove Docker images: ${BLUE}docker system prune -a${NC}"
echo -e "  • Remove instance directories: ${BLUE}rm -rf $INSTANCES_DIR${NC}"
echo -e "  • Remove logs: ${BLUE}rm -rf $PROJECT_ROOT/logs${NC}\n"

read -p "Would you like to remove Docker images to free space? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Removing Docker images...${NC}"
    docker system prune -a -f
    echo -e "${GREEN}✓ Docker images removed${NC}\n"
fi

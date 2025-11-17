#!/bin/bash

# Fix PostgreSQL port conflicts in all existing instances

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="/Users/maxsaad/Desktop/mindvalley/firecrawl-bot-simulation"
INSTANCES_DIR="$PROJECT_ROOT/instances"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Fixing PostgreSQL Port Conflicts${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Fix each instance
for i in $(seq -f "%02g" 1 10); do
    INSTANCE_DIR="$INSTANCES_DIR/instance$i"
    
    if [ ! -d "$INSTANCE_DIR" ]; then
        echo -e "${YELLOW}⚠ Instance $i directory not found, skipping${NC}"
        continue
    fi
    
    if [ ! -f "$INSTANCE_DIR/docker-compose.yaml" ]; then
        echo -e "${YELLOW}⚠ Instance $i docker-compose.yaml not found, skipping${NC}"
        continue
    fi
    
    echo -e "${BLUE}Fixing Instance $i...${NC}"
    
    # Remove PostgreSQL port mapping line
    # This prevents port 5432 conflicts between instances
    # PostgreSQL will still work internally within each Docker network
    sed -i.bak '/- "5432:5432"/d' "$INSTANCE_DIR/docker-compose.yaml"
    sed -i.bak '/- \"5432:5432\"/d' "$INSTANCE_DIR/docker-compose.yaml"
    
    # Remove backup files
    rm -f "$INSTANCE_DIR/docker-compose.yaml.bak"
    
    echo -e "${GREEN}✓ Instance $i fixed${NC}\n"
done

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All instances fixed!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${YELLOW}PostgreSQL port 5432 is no longer exposed externally.${NC}"
echo -e "${YELLOW}Each instance has its own isolated PostgreSQL within its Docker network.${NC}\n"

echo -e "${BLUE}You can now run:${NC}"
echo -e "  ${GREEN}./scripts/launch-all.sh${NC}\n"

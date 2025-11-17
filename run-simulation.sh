#!/bin/bash

# Master Control Script - Complete Simulation Workflow
# Runs the entire bot traffic simulation from setup to analysis

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_ROOT="/Users/maxsaad/Desktop/mindvalley/firecrawl-bot-simulation"

clear

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   FIRECRAWL BOT TRAFFIC SIMULATION                           ║
║   High-Traffic Bot Testing for mindvalley.com                ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

# Menu function
show_menu() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Main Menu${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    echo -e "  ${GREEN}1)${NC} Complete Workflow (Setup → Launch → Crawl → Analyze)"
    echo -e "  ${GREEN}2)${NC} Setup Instances Only"
    echo -e "  ${GREEN}3)${NC} Launch All Instances"
    echo -e "  ${GREEN}4)${NC} Start Crawls"
    echo -e "  ${GREEN}5)${NC} Analyze Logs"
    echo -e "  ${GREEN}6)${NC} View System Status"
    echo -e "  ${GREEN}7)${NC} Cleanup & Stop All"
    echo -e "  ${YELLOW}8)${NC} View Documentation"
    echo -e "  ${RED}9)${NC} Exit\n"
}

# Status check function
check_status() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}System Status${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    # Docker status
    if docker ps > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Docker is running${NC}"
    else
        echo -e "${RED}✗ Docker is not running${NC}"
        return 1
    fi
    
    # Check if instances exist
    if [ -d "$PROJECT_ROOT/instances/instance01" ]; then
        echo -e "${GREEN}✓ Instances are configured${NC}"
        instance_count=$(ls -d "$PROJECT_ROOT/instances"/instance* 2>/dev/null | wc -l | tr -d ' ')
        echo -e "  Found $instance_count instance(s)"
    else
        echo -e "${YELLOW}⚠ Instances not yet configured${NC}"
    fi
    
    # Check running containers
    running=$(docker ps | grep "firecrawl-instance" | wc -l | tr -d ' ')
    if [ "$running" -gt 0 ]; then
        echo -e "${GREEN}✓ $running Firecrawl container(s) running${NC}"
    else
        echo -e "${YELLOW}⚠ No Firecrawl containers running${NC}"
    fi
    
    # Check logs
    if [ -d "$PROJECT_ROOT/logs" ] && [ -n "$(ls -A "$PROJECT_ROOT/logs"/*.log 2>/dev/null)" ]; then
        log_count=$(ls "$PROJECT_ROOT/logs"/*.log 2>/dev/null | wc -l | tr -d ' ')
        echo -e "${GREEN}✓ $log_count log file(s) present${NC}"
    else
        echo -e "${YELLOW}⚠ No logs found${NC}"
    fi
    
    echo ""
}

# Complete workflow
run_complete_workflow() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Running Complete Workflow${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    echo -e "${YELLOW}This will run the entire simulation:${NC}"
    echo -e "  1. Setup all instances"
    echo -e "  2. Launch Docker containers"
    echo -e "  3. Start crawls on all instances"
    echo -e "  4. Wait for completion (you can skip this)"
    echo -e "  5. Analyze logs\n"
    
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi
    
    echo -e "\n${BLUE}Step 1/5: Setting up instances...${NC}"
    "$PROJECT_ROOT/scripts/setup-instances.sh"
    
    echo -e "\n${BLUE}Step 2/5: Launching instances...${NC}"
    "$PROJECT_ROOT/scripts/launch-all.sh"
    
    echo -e "\n${BLUE}Step 3/5: Starting crawls...${NC}"
    "$PROJECT_ROOT/scripts/start-crawls.sh" < /dev/null
    
    echo -e "\n${BLUE}Step 4/5: Monitoring crawls...${NC}"
    echo -e "${YELLOW}Crawls are now running in the background.${NC}"
    echo -e "You can:"
    echo -e "  • Wait for completion (typically 10-15 minutes)"
    echo -e "  • Monitor logs: tail -f logs/instance*.log"
    echo -e "  • Check Docker: docker ps\n"
    
    read -p "Wait for crawls to complete before analyzing? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Waiting 15 minutes for crawls to complete...${NC}"
        echo -e "${YELLOW}(Press Ctrl+C to skip and analyze current logs)${NC}\n"
        sleep 900  # 15 minutes
    fi
    
    echo -e "\n${BLUE}Step 5/5: Analyzing logs...${NC}"
    "$PROJECT_ROOT/scripts/analyze-logs.sh" < /dev/null
    
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}Workflow Complete!${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    
    echo -e "Analysis report saved to: ${CYAN}logs/analysis-report.txt${NC}\n"
}

# Main loop
cd "$PROJECT_ROOT"

while true; do
    show_menu
    read -p "Select option (1-9): " choice
    echo ""
    
    case $choice in
        1)
            run_complete_workflow
            ;;
        2)
            "$PROJECT_ROOT/scripts/setup-instances.sh"
            ;;
        3)
            "$PROJECT_ROOT/scripts/launch-all.sh"
            ;;
        4)
            "$PROJECT_ROOT/scripts/start-crawls.sh"
            ;;
        5)
            "$PROJECT_ROOT/scripts/analyze-logs.sh"
            ;;
        6)
            check_status
            ;;
        7)
            "$PROJECT_ROOT/scripts/cleanup-all.sh"
            ;;
        8)
            echo -e "${BLUE}Opening documentation...${NC}\n"
            if command -v less &> /dev/null; then
                less "$PROJECT_ROOT/QUICKSTART.md"
            else
                cat "$PROJECT_ROOT/QUICKSTART.md"
            fi
            ;;
        9)
            echo -e "${GREEN}Exiting...${NC}\n"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please select 1-9.${NC}\n"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    clear
done

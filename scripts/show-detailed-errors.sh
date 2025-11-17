#!/usr/bin/env bash

# Show detailed logs and list all errors encountered during scraping

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   FIRECRAWL BOT SIMULATION - DETAILED ERROR ANALYSIS${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}\n"

# Check if Docker is running
if ! docker ps &> /dev/null; then
    echo -e "${RED}Error: Docker is not running or not accessible${NC}"
    exit 1
fi

# Get list of running instances
echo -e "${BLUE}▶ Checking Firecrawl instances...${NC}\n"
instances=$(docker ps --filter "name=firecrawl-instance.*-api" --format "{{.Names}}" | sort)

if [ -z "$instances" ]; then
    echo -e "${RED}No Firecrawl API instances found running${NC}"
    exit 1
fi

echo -e "${GREEN}Found instances:${NC}"
echo "$instances" | sed 's/^/  - /'
echo

# Function to extract instance number from container name
get_instance_num() {
    echo "$1" | grep -oE "instance[0-9]+" | grep -oE "[0-9]+"
}

# Summary counters
total_500_errors=0
total_429_errors=0
total_403_errors=0
total_timeouts=0
total_warnings=0

# Process each instance
for container in $instances; do
    instance_num=$(get_instance_num "$container")
    
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}   INSTANCE $instance_num - ${container}${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}\n"
    
    # Count errors in API container
    echo -e "${YELLOW}→ Analyzing API container logs...${NC}\n"
    
    # HTTP 500 Internal Server Errors
    echo -e "${RED}━━━ HTTP 500 INTERNAL SERVER ERRORS ━━━${NC}"
    errors_500=$(docker logs "$container" 2>&1 | grep -E "\"status\":500|response.*500" | wc -l | tr -d ' ')
    total_500_errors=$((total_500_errors + errors_500))
    echo -e "${RED}Count: $errors_500${NC}\n"
    
    if [ "$errors_500" -gt 0 ]; then
        echo -e "${MAGENTA}Sample errors (first 3):${NC}"
        docker logs "$container" 2>&1 | grep -B 3 -A 5 "\"status\":500" | head -40 | sed 's/^/  /'
        echo
        
        echo -e "${MAGENTA}Affected URLs:${NC}"
        docker logs "$container" 2>&1 | grep -B 10 "\"status\":500" | grep -oE "\"url\":\"https://[^\"]+\"" | sort -u | sed 's/\"url\":\"/  • /' | sed 's/\"//' | head -15
        echo
    fi
    
    # HTTP 429 Rate Limit Errors
    echo -e "${YELLOW}━━━ HTTP 429 RATE LIMIT ERRORS ━━━${NC}"
    errors_429=$(docker logs "$container" 2>&1 | grep -iE "429|Too Many Requests|rate.?limit" | wc -l | tr -d ' ')
    total_429_errors=$((total_429_errors + errors_429))
    echo -e "${YELLOW}Count: $errors_429${NC}\n"
    
    if [ "$errors_429" -gt 0 ]; then
        echo -e "${MAGENTA}Sample occurrences:${NC}"
        docker logs "$container" 2>&1 | grep -iE "429|Too Many Requests|rate.?limit" | head -5 | sed 's/^/  /'
        echo
    fi
    
    # HTTP 403 Forbidden Errors
    echo -e "${YELLOW}━━━ HTTP 403 FORBIDDEN ERRORS ━━━${NC}"
    errors_403=$(docker logs "$container" 2>&1 | grep -iE "403|Forbidden" | wc -l | tr -d ' ')
    total_403_errors=$((total_403_errors + errors_403))
    echo -e "${YELLOW}Count: $errors_403${NC}\n"
    
    if [ "$errors_403" -gt 0 ]; then
        echo -e "${MAGENTA}Sample occurrences:${NC}"
        docker logs "$container" 2>&1 | grep -iE "403|Forbidden" | head -5 | sed 's/^/  /'
        echo
    fi
    
    # Playwright Service Errors
    playwright_container="${container/-api-/-playwright-service-}"
    echo -e "${YELLOW}→ Analyzing Playwright service logs...${NC}\n"
    
    # Timeouts
    echo -e "${RED}━━━ PLAYWRIGHT TIMEOUT ERRORS ━━━${NC}"
    timeouts=$(docker logs "$playwright_container" 2>&1 | grep -i "timeout" | wc -l | tr -d ' ')
    total_timeouts=$((total_timeouts + timeouts))
    echo -e "${RED}Count: $timeouts${NC}\n"
    
    if [ "$timeouts" -gt 0 ]; then
        echo -e "${MAGENTA}Timeout details (first 10):${NC}"
        docker logs "$playwright_container" 2>&1 | grep -B 2 -i "timeout" | head -30 | sed 's/^/  /'
        echo
        
        echo -e "${MAGENTA}URLs that timed out:${NC}"
        docker logs "$playwright_container" 2>&1 | grep -B 2 -i "timeout" | grep -oE "https://[^ ]+" | sort -u | sed 's/^/  • /' | head -15
        echo
    fi
    
    # Warnings
    echo -e "${YELLOW}━━━ WARNINGS ━━━${NC}"
    warnings=$(docker logs "$playwright_container" 2>&1 | grep -iE "⚠️|WARNING|warn" | wc -l | tr -d ' ')
    total_warnings=$((total_warnings + warnings))
    echo -e "${YELLOW}Count: $warnings${NC}\n"
    
    if [ "$warnings" -gt 0 ]; then
        echo -e "${MAGENTA}Unique warnings:${NC}"
        docker logs "$playwright_container" 2>&1 | grep -iE "⚠️|WARNING|warn" | sort -u | sed 's/^/  /' | head -10
        echo
    fi
    
    # Strategy failures
    echo -e "${YELLOW}━━━ STRATEGY FAILURES ━━━${NC}"
    strategy_failures=$(docker logs "$playwright_container" 2>&1 | grep -i "strategy.*failed" | wc -l | tr -d ' ')
    echo -e "${YELLOW}Count: $strategy_failures${NC}\n"
    
    if [ "$strategy_failures" -gt 0 ]; then
        echo -e "${MAGENTA}Sample strategy failures:${NC}"
        docker logs "$playwright_container" 2>&1 | grep -A 2 -i "strategy.*failed" | head -20 | sed 's/^/  /'
        echo
    fi
    
    echo
done

# Overall Summary
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   OVERALL SUMMARY${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}\n"

echo -e "${BLUE}Total Errors Across All Instances:${NC}"
echo -e "  ${RED}• HTTP 500 Errors: $total_500_errors${NC}"
echo -e "  ${YELLOW}• HTTP 429 Errors: $total_429_errors${NC}"
echo -e "  ${YELLOW}• HTTP 403 Errors: $total_403_errors${NC}"
echo -e "  ${RED}• Playwright Timeouts: $total_timeouts${NC}"
echo -e "  ${YELLOW}• Warnings: $total_warnings${NC}"
echo

# Root cause analysis
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   ROOT CAUSE ANALYSIS${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}\n"

if [ "$total_500_errors" -gt 0 ]; then
    echo -e "${RED}⚠ HTTP 500 Errors Detected:${NC}"
    echo -e "  The Playwright service is returning 500 errors when attempting to"
    echo -e "  scrape certain pages. This is typically caused by:"
    echo -e "    1. Page load timeouts (15 second timeout exceeded)"
    echo -e "    2. JavaScript execution errors on target pages"
    echo -e "    3. Resource-intensive pages causing Playwright to fail"
    echo -e "    4. Network issues or blocked requests"
    echo
fi

if [ "$total_timeouts" -gt 0 ]; then
    echo -e "${RED}⚠ Playwright Timeout Issues:${NC}"
    echo -e "  Pages are timing out after 15 seconds. This suggests:"
    echo -e "    1. Target website has slow response times"
    echo -e "    2. Heavy JavaScript execution on pages"
    echo -e "    3. Network latency or connectivity issues"
    echo -e "    4. Pages waiting for resources that never load"
    echo
    echo -e "${GREEN}  → Firecrawl falls back to fetch() method after Playwright fails"
    echo -e "     which allows scraping to continue but without JavaScript rendering${NC}"
    echo
fi

if [ "$total_warnings" -gt 0 ]; then
    echo -e "${YELLOW}⚠ Proxy Warnings:${NC}"
    echo -e "  The Playwright service is reporting no proxy server configured."
    echo -e "  This may lead to IP blocking by the target website under heavy load."
    echo
fi

echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   RECOMMENDATIONS${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}\n"

echo -e "${GREEN}1. Increase Playwright timeout:${NC}"
echo -e "   Set PLAYWRIGHT_TIMEOUT to 30000ms or higher in configs"
echo
echo -e "${GREEN}2. Configure proxy rotation:${NC}"
echo -e "   Add proxy configuration to prevent IP blocking"
echo
echo -e "${GREEN}3. Reduce crawl concurrency:${NC}"
echo -e "   Lower NUM_WORKERS to reduce load on target website"
echo
echo -e "${GREEN}4. Add delays between requests:${NC}"
echo -e "   Increase crawlDelay in configuration to be more respectful"
echo
echo -e "${GREEN}5. Monitor specific failing URLs:${NC}"
echo -e "   Some URLs consistently fail - consider excluding them or handling separately"
echo

echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Analysis complete!${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}\n"

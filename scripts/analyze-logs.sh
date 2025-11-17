#!/usr/bin/env bash

# Analyze logs for HTTP 500 errors and generate report

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="/Users/maxsaad/Desktop/mindvalley/firecrawl-bot-simulation"
LOGS_DIR="$PROJECT_ROOT/logs"
REPORT_FILE="$LOGS_DIR/analysis-report.txt"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Log Analysis - HTTP 500 Error Detection${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if logs exist
if [ ! -d "$LOGS_DIR" ] || [ -z "$(ls -A "$LOGS_DIR"/instance*.log 2>/dev/null)" ]; then
    echo -e "${RED}Error: No log files found in $LOGS_DIR${NC}"
    exit 1
fi

# Create report header
cat > "$REPORT_FILE" << EOF
================================================================================
FIRECRAWL BOT SIMULATION - LOG ANALYSIS REPORT
================================================================================
Generated: $(date '+%Y-%m-%d %H:%M:%S')
Target: https://www.mindvalley.com

This report summarizes HTTP 500 Internal Server Errors encountered during
the high-traffic bot simulation test.

================================================================================
SUMMARY
================================================================================

EOF

echo -e "${YELLOW}Analyzing log files...${NC}\n"

total_500_errors=0
instances_with_errors=0

# Arrays to store findings (using simple indexed arrays with instance number as suffix)
declare -a error_counts
declare -a error_urls
declare -a error_timestamps

# Analyze each instance log
for i in $(seq -f "%02g" 1 2); do
    log_file="$LOGS_DIR/instance$i.log"
    
    if [ ! -f "$log_file" ]; then
        echo -e "${YELLOW}⚠ Log file not found: instance$i.log${NC}"
        continue
    fi
    
    echo -e "${BLUE}Analyzing Instance $i...${NC}"
    
    # Search for 500 errors (various patterns)
    error_count=$(grep -E "(500|Internal Server Error|status.*500|\"status\":500)" "$log_file" 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$error_count" -gt 0 ]; then
        instances_with_errors=$((instances_with_errors + 1))
        total_500_errors=$((total_500_errors + error_count))
        # Store with instance number as index (01-10)
        eval "error_count_$i=$error_count"
        
        echo -e "  ${RED}Found $error_count error(s)${NC}"
        
        # Extract URLs with errors (if present in logs)
        urls=$(grep -E "(500|Internal Server Error)" "$log_file" 2>/dev/null | grep -oE "https?://[^\s]+" | sort -u)
        if [ ! -z "$urls" ]; then
            eval "error_url_$i=\"$urls\""
        fi
        
        # Extract timestamps
        timestamps=$(grep -E "(500|Internal Server Error)" "$log_file" 2>/dev/null | grep -oE "\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\]" | head -5)
        if [ ! -z "$timestamps" ]; then
            eval "error_timestamp_$i=\"$timestamps\""
        fi
    else
        echo -e "  ${GREEN}No errors found${NC}"
    fi
done

# Write summary to report
cat >> "$REPORT_FILE" << EOF
Total Instances Analyzed: 2
Instances with Errors: $instances_with_errors
Total HTTP 500 Errors: $total_500_errors

================================================================================
DETAILED BREAKDOWN BY INSTANCE
================================================================================

EOF

# Detailed breakdown
for i in $(seq -f "%02g" 1 2); do
    # Convert to decimal safely (remove leading zeros)
    i_decimal=$(echo "$i" | sed 's/^0*//')
    [ -z "$i_decimal" ] && i_decimal=0
    port=$((3001 + i_decimal))
    
    # Get instance description from config
    description="Unknown"
    case $i in
        01) description="Googlebot (Depth: 3, Delay: 1s, JS: Yes)" ;;
        02) description="Bingbot (Depth: 3, Delay: 1s, JS: Yes)" ;;
    esac
    
    cat >> "$REPORT_FILE" << EOF
--- Instance $i (Port $port) ---
Configuration: $description
EOF
    
    # Get error count for this instance
    eval "instance_error_count=\${error_count_$i:-0}"
    
    if [ "$instance_error_count" -gt 0 ]; then
        cat >> "$REPORT_FILE" << EOF
HTTP 500 Errors: $instance_error_count

EOF
        
        # Add URLs if found
        eval "instance_urls=\${error_url_$i}"
        if [ ! -z "$instance_urls" ]; then
            cat >> "$REPORT_FILE" << EOF
Problematic URLs:
$instance_urls

EOF
        fi
        
        # Add timestamps if found
        eval "instance_timestamps=\${error_timestamp_$i}"
        if [ ! -z "$instance_timestamps" ]; then
            cat >> "$REPORT_FILE" << EOF
Sample Error Timestamps:
$instance_timestamps

EOF
        fi
    else
        cat >> "$REPORT_FILE" << EOF
HTTP 500 Errors: 0
Status: No errors detected

EOF
    fi
done

# Add analysis insights
cat >> "$REPORT_FILE" << EOF
================================================================================
ANALYSIS INSIGHTS
================================================================================

EOF

# Determine patterns
if [ "$total_500_errors" -eq 0 ]; then
    cat >> "$REPORT_FILE" << EOF
No HTTP 500 Internal Server Errors were detected during the simulation.
This indicates that mindvalley.com handled the bot traffic load without
server-side failures.

EOF
else
    cat >> "$REPORT_FILE" << EOF
HTTP 500 errors were detected. Key observations:

EOF
    
    # Note: With only 2 instances (both with JS enabled), no special pattern analysis needed
fi

# Add other HTTP errors section
cat >> "$REPORT_FILE" << EOF
================================================================================
OTHER HTTP ERRORS (429, 403, etc.)
================================================================================

EOF

for i in $(seq -f "%02g" 1 2); do
    log_file="$LOGS_DIR/instance$i.log"
    
    if [ ! -f "$log_file" ]; then
        continue
    fi
    
    # Check for rate limiting (429)
    error_429=$(grep -c "429\|Too Many Requests" "$log_file" 2>/dev/null || echo "0")
    error_429=$(echo "$error_429" | tr -d '\n\r ')
    
    # Check for forbidden (403)
    error_403=$(grep -c "403\|Forbidden" "$log_file" 2>/dev/null || echo "0")
    error_403=$(echo "$error_403" | tr -d '\n\r ')
    
    if [ "$error_429" -gt 0 ] 2>/dev/null || [ "$error_403" -gt 0 ] 2>/dev/null; then
        cat >> "$REPORT_FILE" << EOF
Instance $i:
  - 429 (Rate Limit) errors: $error_429
  - 403 (Forbidden) errors: $error_403

EOF
    fi
done

# Footer
cat >> "$REPORT_FILE" << EOF
================================================================================
END OF REPORT
================================================================================

For detailed logs, see individual instance log files in: $LOGS_DIR
EOF

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Analysis Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}Summary:${NC}"
echo -e "  Total HTTP 500 Errors: ${RED}$total_500_errors${NC}"
echo -e "  Instances with Errors: ${YELLOW}$instances_with_errors${NC} / 2"
echo -e "  Report saved to: ${GREEN}$REPORT_FILE${NC}\n"

echo -e "${YELLOW}View full report with:${NC}"
echo -e "  ${BLUE}cat $REPORT_FILE${NC}\n"

# Optionally display report
read -p "Display full report now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat "$REPORT_FILE"
fi

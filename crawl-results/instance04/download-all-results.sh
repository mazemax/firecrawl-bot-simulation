#!/bin/bash

# Download all paginated results from Firecrawl
CRAWL_ID="fe3efe1a-84a1-4b12-88a0-e4b268d809e0"
BASE_URL="http://localhost:3005/v1/crawl/${CRAWL_ID}"
OUTPUT_DIR="$(dirname "$0")/pages"

mkdir -p "$OUTPUT_DIR"

# Get total count
TOTAL=$(curl -s "$BASE_URL" | jq -r '.total')
echo "Total pages to fetch: $TOTAL"

# Fetch pages in batches of 100
SKIP=0
PAGE_NUM=0

while [ $SKIP -lt $TOTAL ]; do
    echo "Fetching pages $SKIP to $((SKIP + 100))..."
    curl -s "${BASE_URL}?skip=${SKIP}" > "${OUTPUT_DIR}/page_${PAGE_NUM}.json"
    
    # Extract just the data array
    cat "${OUTPUT_DIR}/page_${PAGE_NUM}.json" | jq '.data' > "${OUTPUT_DIR}/data_${PAGE_NUM}.json"
    
    SKIP=$((SKIP + 100))
    PAGE_NUM=$((PAGE_NUM + 1))
    
    # Small delay to avoid overwhelming the API
    sleep 0.5
done

echo "Done! Downloaded $PAGE_NUM pages to $OUTPUT_DIR"
echo ""
echo "To combine all results:"
echo "jq -s 'add' ${OUTPUT_DIR}/data_*.json > all_results.json"

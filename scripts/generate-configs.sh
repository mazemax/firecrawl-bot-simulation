#!/bin/bash

# Generate crawler configuration JSON files for each instance

PROJECT_ROOT="/Users/maxsaad/Desktop/mindvalley/firecrawl-bot-simulation"
CONFIGS_DIR="$PROJECT_ROOT/configs"

echo "Generating crawler configuration files for 2 instances..."

# Instance 01 - Googlebot
cat > "$CONFIGS_DIR/instance01-config.json" << 'EOF'
{
  "url": "https://www.mindvalley.com",
  "maxDiscoveryDepth": 3,
  "delay": 1,
  "scrapeOptions": {
    "headers": {
      "User-Agent": "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
    },
    "formats": ["markdown"]
  }
}
EOF

# Instance 02 - Bingbot
cat > "$CONFIGS_DIR/instance02-config.json" << 'EOF'
{
  "url": "https://www.mindvalley.com",
  "maxDiscoveryDepth": 3,
  "delay": 1,
  "scrapeOptions": {
    "headers": {
      "User-Agent": "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
    },
    "formats": ["markdown"]
  }
}
EOF

echo "✓ Created 2 configuration files in $CONFIGS_DIR"

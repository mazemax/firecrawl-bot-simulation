# Firecrawl Bot Traffic Simulation

This project sets up concurrent Firecrawl instances to simulate high bot traffic against mindvalley.com.

## Project Structure

```
firecrawl-bot-simulation/
├── firecrawl/              # Cloned Firecrawl repository (base)
├── instances/              # 10 separate instance directories
│   ├── instance01/         # Googlebot simulation
│   ├── instance02/         # Bingbot simulation
├── configs/                # Crawler configuration JSON files
├── scripts/                # Launch, monitor, and analysis scripts
├── logs/                   # Log output from all instances
└── README.md
```

## Instance Configurations

| Instance | Type | Port | User-Agent | Depth | Delay | JS Enabled |
|----------|------|------|------------|-------|-------|------------|
| 01 | Googlebot | 3002 | Googlebot/2.1 | 3 | 1s | Yes |
| 02 | Bingbot | 3003 | bingbot/2.0 | 3 | 1s | Yes |

## Prerequisites

- macOS (Intel or Apple Silicon)
- Docker Desktop installed and running
- At least 16GB RAM recommended
- Stable internet connection

## Quick Start

1. **Verify Docker is running:**
   ```bash
   docker ps
   ```

2. **Set up all instances:**
   ```bash
   ./scripts/setup-instances.sh
   ```

3. **Launch all instances:**
   ```bash
   ./scripts/launch-all.sh
   ```

4. **Start crawls:**
   ```bash
   ./scripts/start-crawls.sh
   ```

5. **Monitor progress:**
   - Watch logs in `logs/` directory
   - Each instance logs to `logs/instanceXX.log`

6. **Analyze results:**
   ```bash
   ./scripts/analyze-logs.sh
   ```

7. **Cleanup:**
   ```bash
   ./scripts/cleanup-all.sh
   ```

## Manual Operations

### Launch Single Instance
```bash
cd instances/instance01
docker compose -p firecrawl-instance01 up 2>&1 | tee ../../logs/instance01.log
```

### Trigger Single Crawl
```bash
curl -X POST http://localhost:3002/v2/crawl \
  -H "Content-Type: application/json" \
  -d @../../configs/instance01-config.json
```

### Stop Single Instance
```bash
cd instances/instance01
docker compose -p firecrawl-instance01 down
```

## Log Analysis

After the test, the `analyze-logs.sh` script will:
- Search all logs for HTTP 500 errors
- Count errors per instance
- Identify problematic URLs
- Generate a summary report in `logs/analysis-report.txt`

## Notes

- Each instance runs in isolated Docker Compose project
- All instances target https://www.mindvalley.com
- Logs are captured with timestamps for correlation
- System resource usage may be high with all instances running

## Troubleshooting

- **Port conflicts:** Ensure ports 3002-3011 are available
- **Docker memory:** Increase Docker Desktop memory allocation if needed
- **Failed builds:** Run `docker system prune` and rebuild
- **Rate limiting:** Expect 429 errors from aggressive instances

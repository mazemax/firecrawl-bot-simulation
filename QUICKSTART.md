# Firecrawl Bot Simulation - Quick Start Guide

## 📋 Overview

This setup simulates 2 concurrent bot crawlers targeting mindvalley.com to test server response under high bot traffic. Each crawler has different characteristics (user agent, crawl depth, request delay, JavaScript enabled/disabled).

## 🚀 Quick Start (5 Steps)

### 1. Verify Prerequisites

```bash
# Check Docker is running
docker ps

# You should see Docker containers or at least no error
```

### 2. Set Up All Instances (~2-3 minutes)

```bash
cd /Users/maxsaad/Desktop/mindvalley/firecrawl-bot-simulation
./scripts/setup-instances.sh
```

This will:
- Create 2 separate Firecrawl instance directories
- Copy and configure each with unique ports and settings
- Set up JS-disabled instances for realistic bot simulation

### 3. Launch All Instances (~10-15 minutes first time)

```bash
./scripts/launch-all.sh
```

**Note:** First launch will build Docker images, which takes time. Subsequent launches are much faster.

### 4. Start Crawls (Immediate)

```bash
./scripts/start-crawls.sh
```

This initiates crawling on all 2 instances simultaneously against mindvalley.com. You'll be prompted to monitor logs in real-time.

### 5. Analyze Results (After crawls complete)

```bash
./scripts/analyze-logs.sh
```

Generates a detailed report of HTTP 500 errors and other issues found during the simulation.

## 📊 What Gets Tested

### Bot Configurations

| Instance | Type | Behavior |
|----------|------|----------|
| 01-02 | Search Engine Bots | Deep crawl, polite delays, JS enabled |

### Metrics Captured

- ✅ HTTP 500 Internal Server Errors
- ✅ HTTP 429 Rate Limiting Responses
- ✅ HTTP 403 Forbidden Responses
- ✅ Timestamps of all errors
- ✅ Problematic URLs
- ✅ Patterns by bot type

## 🔍 Monitoring During Test

### Watch All Logs
```bash
tail -f logs/instance*.log
```

### Watch Specific Instance
```bash
tail -f logs/instance01.log
```

### Check Docker Containers
```bash
docker ps | grep firecrawl
```

### View Crawl Status (if API is up)
```bash
# Check instance 01
curl http://localhost:3002/v2/crawl/<crawl_id>
```

## 🧹 Cleanup

### Stop All Instances
```bash
./scripts/cleanup-all.sh
```

This will:
- Stop all running containers
- Remove Docker networks
- Optionally clean up images
- Preserve logs for analysis

### Remove Everything
```bash
./scripts/cleanup-all.sh
cd ..
rm -rf firecrawl-bot-simulation
```

## 📁 Directory Structure

```
firecrawl-bot-simulation/
├── README.md                    # Full documentation
├── QUICKSTART.md               # This file
├── firecrawl/                  # Base Firecrawl clone
├── instances/                  # 2 configured instances
│   ├── instance01/            # Each has its own Docker setup
│   ├── instance02/
│   └── ...
├── configs/                    # Crawler JSON configurations
│   ├── instance01-config.json
│   └── ...
├── scripts/                    # Automation scripts
│   ├── setup-instances.sh     # Initial setup
│   ├── launch-all.sh          # Start all instances
│   ├── start-crawls.sh        # Initiate crawling
│   ├── analyze-logs.sh        # Analyze results
│   └── cleanup-all.sh         # Cleanup
└── logs/                       # Output logs
    ├── instance01.log
    ├── instance02.log
    ├── ...
    └── analysis-report.txt    # Generated after analysis
```

## ⚠️ Important Notes

1. **System Resources**: Running 2 instances requires significant CPU/RAM. Monitor your system.

2. **First Build Time**: Initial Docker build takes 10-20 minutes. Be patient.

3. **Mindvalley Impact**: This test generates real traffic to mindvalley.com. Use responsibly.

4. **Rate Limiting**: Aggressive instances (04-06) may trigger rate limiting (429 errors). This is expected.

5. **Test Duration**: Crawls typically run 5-15 minutes depending on depth and site size.

6. **Logs**: Logs can grow large. Check disk space before running.

## 🐛 Troubleshooting

### Ports Already in Use
```bash
# Check what's using ports 3002-3011
lsof -i :3002
# Kill process if needed
kill -9 <PID>
```

### Docker Out of Memory
```bash
# Increase Docker memory in Docker Desktop preferences
# Or reduce concurrent instances in scripts
```

### Instance Won't Start
```bash
# Check instance logs
cd instances/instance01
docker compose -p firecrawl-instance01 logs
```

### Build Failures
```bash
# Clean Docker system
docker system prune -a
# Rebuild specific instance
cd instances/instance01
docker compose build --no-cache
```

## 📞 Getting Help

- Check logs in `logs/` directory
- View Docker logs: `docker logs <container_name>`
- Verify Docker: `docker ps` and `docker images`

## 🎯 Expected Outcomes

After running the simulation, you should have:
- ✅ Log files from all 2 instances
- ✅ Analysis report with error counts
- ✅ Identification of problematic URLs (if any)
- ✅ Insights on bot behavior patterns
- ✅ Understanding of mindvalley.com's bot handling

The analysis report (`logs/analysis-report.txt`) will show:
- Total HTTP 500 errors encountered
- Which bot types caused errors
- Specific URLs that returned errors
- Whether rate limiting was triggered
- Recommendations based on patterns

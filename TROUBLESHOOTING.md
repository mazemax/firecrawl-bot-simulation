# Troubleshooting Guide

## PostgreSQL Port Conflict (Port 5432)

### Problem
```
Error response from daemon: failed to set up container networking: driver failed programming 
external connectivity on endpoint firecrawl-instance02-nuq-postgres-1: 
Bind for 0.0.0.0:5432 failed: port is already allocated
```

### Cause
Multiple Firecrawl instances were trying to expose PostgreSQL on the same port (5432), causing conflicts.

### Solution - Already Fixed! ✅

The PostgreSQL port exposure has been removed from all instances. Each instance now has its own isolated PostgreSQL database that works internally within its Docker network, without exposing port 5432 externally.

### What Was Done

1. **Fixed all existing instances** - Ran `./scripts/fix-postgres-ports.sh` to remove PostgreSQL port mappings
2. **Updated setup script** - Future instances created by `setup-instances.sh` will automatically have this fix applied

### If You Still See the Error

If you encounter this error, run:

```bash
# Stop all instances
./scripts/cleanup-all.sh

# Re-run the fix (just in case)
./scripts/fix-postgres-ports.sh

# Launch again
./scripts/launch-all.sh
```

### Verification

To verify the fix worked, check that PostgreSQL ports are NOT exposed:

```bash
# Should show NO results for 5432
docker ps | grep 5432
```

---

## Other Common Issues

### Issue: Port Already in Use (3002-3011)

**Problem:** One of the Firecrawl API ports is already in use

**Solution:**
```bash
# Find what's using the port (example for port 3002)
lsof -i :3002

# Kill the process
kill -9 <PID>

# Or stop all firecrawl instances
./scripts/cleanup-all.sh
```

### Issue: Docker Out of Memory

**Problem:** Docker runs out of memory when running 10 instances

**Solution:**
1. Increase Docker memory allocation:
   - Open Docker Desktop
   - Go to Settings > Resources
   - Increase memory to 8GB+ (16GB recommended)

2. Or reduce concurrent instances by modifying scripts

### Issue: Build Failures

**Problem:** Docker build fails or hangs

**Solution:**
```bash
# Clean Docker system
docker system prune -a

# Remove all firecrawl images
docker images | grep firecrawl | awk '{print $3}' | xargs docker rmi -f

# Rebuild from scratch
cd instances/instance01
docker compose -p firecrawl-instance01 build --no-cache
```

### Issue: Containers Not Starting

**Problem:** Containers start but immediately exit

**Solution:**
```bash
# Check logs for specific instance
docker compose -p firecrawl-instance01 logs

# Or check specific container
docker logs firecrawl-instance01-api-1

# Common causes:
# 1. Missing .env file - run ./scripts/setup-instances.sh
# 2. Build failed - rebuild with --no-cache
# 3. Port conflict - check with lsof -i :PORT
```

### Issue: Crawls Not Starting

**Problem:** Crawl requests return errors or timeout

**Solution:**
```bash
# Check if instance is actually running
curl http://localhost:3002/health

# Check instance logs
tail -f logs/instance01.log

# Verify containers are up
docker ps | grep firecrawl-instance01

# Common causes:
# 1. Instance still building - wait 1-2 minutes after launch
# 2. Port mismatch - verify PORT in .env matches config
# 3. Network issues - check Docker network: docker network ls
```

### Issue: Slow Performance

**Problem:** System becomes very slow with all 10 instances

**Solution:**
1. **Reduce concurrent instances**: Edit scripts to launch fewer (e.g., 5)
2. **Stagger launches**: Add longer delays in `launch-all.sh`
3. **Disable unused features**: Remove Playwright from more instances

### Issue: Disk Space

**Problem:** Running out of disk space

**Solution:**
```bash
# Check Docker disk usage
docker system df

# Clean up unused images/containers
docker system prune -a

# Remove log files (after backing up)
rm -f logs/*.log

# Remove instance directories you don't need
rm -rf instances/instance06 instances/instance07
```

---

## Quick Fixes Summary

| Issue | Quick Fix Command |
|-------|------------------|
| Port conflicts | `./scripts/cleanup-all.sh && ./scripts/fix-postgres-ports.sh` |
| Start over | `./scripts/cleanup-all.sh && rm -rf instances/* && ./scripts/setup-instances.sh` |
| Check status | `docker ps \| grep firecrawl` |
| View logs | `tail -f logs/instance*.log` |
| Clean Docker | `docker system prune -a` |

---

## Getting Help

### Check Logs First
```bash
# All instances
tail -f logs/instance*.log

# Specific instance
tail -f logs/instance01.log

# Docker container logs
docker logs firecrawl-instance01-api-1
```

### System Status
```bash
# Docker containers
docker ps -a | grep firecrawl

# Docker networks
docker network ls | grep firecrawl

# Port usage
lsof -i :3002-3011

# System resources
docker stats
```

### Debug Mode

To run a single instance in foreground for debugging:

```bash
cd instances/instance01
docker compose -p firecrawl-instance01 up
# Watch output in real-time, Ctrl+C to stop
```

---

## Prevention Tips

1. **Always use cleanup script** before restarting
2. **Monitor system resources** - keep Activity Monitor open
3. **Start with fewer instances** - test with 2-3 before scaling to 10
4. **Check logs regularly** - catch issues early
5. **Keep Docker updated** - latest version has best performance

---

## Still Having Issues?

If none of these solutions work:

1. **Complete reset**:
   ```bash
   ./scripts/cleanup-all.sh
   docker system prune -a
   rm -rf instances/
   ./scripts/setup-instances.sh
   ./scripts/launch-all.sh
   ```

2. **Check documentation**:
   - `README.md` - Full project documentation
   - `QUICKSTART.md` - Step-by-step guide
   - `WORKFLOW.md` - Visual workflow

3. **Verify environment**:
   - macOS version compatible with Docker Desktop
   - At least 16GB RAM available
   - Sufficient disk space (10GB+)
   - Ports 3002-3011 not used by other services

# Firecrawl Instance04 Crawl Results

## Crawl ID: fe3efe1a-84a1-4b12-88a0-e4b268d809e0

## Summary
- **Status**: Scraping (in progress)
- **Origin URL**: https://www.mindvalley.com
- **Completed Pages**: 742 / 2,007 total
- **Progress**: ~37%
- **Visited URLs**: 2,128 unique URLs discovered
- **Expires At**: 2025-11-16T19:23:15.000Z

## Configuration
- **Max Crawled Links**: 10,000
- **Max Depth**: 9,999
- **Limit**: 10,000
- **Max Discovery Depth**: 2
- **Delay**: 0.1 seconds
- **Deduplicate Similar URLs**: Yes
- **Allow Subdomains**: No
- **Output Format**: Markdown

## Files
- `crawl-status.json` - Full API response with scraped content
- `summary.json` - Quick overview of crawl status
- `visited-urls.txt` - List of all visited URLs
- `README.md` - This file

## Accessing Results

### View in Browser
Open http://localhost:3005/v1/crawl/fe3efe1a-84a1-4b12-88a0-e4b268d809e0

### Fetch Next Page
```bash
curl "http://localhost:3005/v1/crawl/fe3efe1a-84a1-4b12-88a0-e4b268d809e0?skip=100"
```

### Check Latest Status
```bash
curl -s "http://localhost:3005/v1/crawl/fe3efe1a-84a1-4b12-88a0-e4b268d809e0" | jq '{status, completed, total}'
```

## Redis Data
The crawl data is stored in Redis under keys:
- `crawl:fe3efe1a-84a1-4b12-88a0-e4b268d809e0` - Main crawl config
- `crawl:fe3efe1a-84a1-4b12-88a0-e4b268d809e0:jobs_done` - Completed jobs (688 items)
- `crawl:fe3efe1a-84a1-4b12-88a0-e4b268d809e0:visited` - Visited URLs set

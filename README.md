# Render Service Scaling Scripts

Automated scripts to scale Render services using the Render API.

## Overview

This repository contains two scripts for scaling Render services:
1. **scale_service.py** - Full-featured Python script with advanced options
2. **scale_service.sh** - Quick bash wrapper for simple scaling operations

## Prerequisites

- Render API Key (get from your Render dashboard)
- For Python script: Python 3.6+ (uses only standard library)
- For Bash script: bash, curl (jq optional for pretty output)

## Authentication

Set your Render API key as an environment variable:

```bash
export RENDER_API_KEY="rnd_your_api_key_here"
```

Or pass it directly via the `--api-key` flag (Python script only).

## Python Script (scale_service.py)

### Features

- Absolute scaling (set to specific instance count)
- Relative scaling (increase/decrease by N instances)
- Dry-run mode to preview changes
- Verbose output for debugging
- Fetches current service state before scaling
- Comprehensive error handling

### Usage Examples

**Scale to absolute number of instances:**
```bash
python scale_service.py --service-id srv-abc123 --num-instances 5
```

**Increase by relative number:**
```bash
python scale_service.py --service-id srv-abc123 --increase-by 2
```

**Decrease by relative number:**
```bash
python scale_service.py --service-id srv-abc123 --decrease-by 1
```

**Dry run (preview without making changes):**
```bash
python scale_service.py --service-id srv-abc123 --num-instances 10 --dry-run
```

**Verbose output:**
```bash
python scale_service.py --service-id srv-abc123 --num-instances 5 --verbose
```

**With explicit API key:**
```bash
python scale_service.py --service-id srv-abc123 --num-instances 5 --api-key rnd_xyz789
```

### Command-line Options

```
--service-id        Render service ID (required)
--num-instances     Absolute number of instances to scale to
--increase-by       Number of instances to increase by
--decrease-by       Number of instances to decrease by
--api-key           Render API key (or use RENDER_API_KEY env var)
--dry-run           Preview changes without executing
--verbose, -v       Enable verbose output
```

## Bash Script (scale_service.sh)

### Features

- Simple and fast
- Single command scaling
- Minimal dependencies

### Usage

```bash
./scale_service.sh <service-id> <num-instances>
```

### Example

```bash
export RENDER_API_KEY="rnd_xyz789"
./scale_service.sh srv-abc123 5
```

## Finding Your Service ID

Your service ID can be found in the Render Dashboard URL when viewing a service:
```
https://dashboard.render.com/web/srv-abc123def456
                                    ^^^^^^^^^^^^^^^
                                    This is your service ID
```

Or use the Render API to list your services:
```bash
curl -H "Authorization: Bearer $RENDER_API_KEY" \
     https://api.render.com/v1/services
```

## Automation Examples

### Cron Job
Scale up during business hours, scale down at night:

```bash
# Scale up at 8 AM to 5 instances
0 8 * * * /path/to/scale_service.sh srv-abc123 5

# Scale down at 6 PM to 1 instance
0 18 * * * /path/to/scale_service.sh srv-abc123 1
```

### CI/CD Pipeline
Scale before deployment, scale back after:

```yaml
# Example GitHub Actions
- name: Scale up before deployment
  run: |
    python scale_service.py --service-id ${{ secrets.SERVICE_ID }} --num-instances 5
  env:
    RENDER_API_KEY: ${{ secrets.RENDER_API_KEY }}
```

### Auto-scaling Script
Combine with monitoring to auto-scale based on load:

```bash
#!/bin/bash
# Check CPU usage and scale accordingly
CPU_USAGE=$(get_cpu_usage_from_monitoring)

if [ "$CPU_USAGE" -gt 80 ]; then
    python scale_service.py --service-id srv-abc123 --increase-by 2
elif [ "$CPU_USAGE" -lt 20 ]; then
    python scale_service.py --service-id srv-abc123 --decrease-by 1
fi
```

## API Reference

The scripts use the Render API v1:
- **Endpoint:** `POST https://api.render.com/v1/services/{serviceId}/scale`
- **Headers:**
  - `Authorization: Bearer {apiKey}`
  - `Content-Type: application/json`
- **Body:** `{"numInstances": <number>}`

Documentation: https://api-docs.render.com/

## Error Handling

Both scripts provide clear error messages for common issues:
- Missing or invalid API key
- Service not found
- Invalid instance count
- API rate limiting
- Network errors

## Troubleshooting

**Authentication Failed:**
- Verify your API key is correct
- Check that the key has not expired
- Ensure the key has appropriate permissions

**Service Not Found:**
- Verify the service ID is correct
- Confirm the service exists in your account

**Rate Limiting:**
- The Render API has rate limits
- Add delays between multiple scaling operations

## Security Notes

- Never commit API keys to version control
- Use environment variables or secret management systems
- Restrict API key permissions to minimum required
- Rotate API keys regularly

## License

These scripts are provided as-is for internal use.

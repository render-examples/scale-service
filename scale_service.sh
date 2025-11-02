#!/bin/bash
# Quick wrapper script for scaling Render services
#
# Usage:
#   ./scale_service.sh <service-id> <num-instances>
#
# Example:
#   export RENDER_API_KEY="rnd_xyz789"
#   ./scale_service.sh srv-abc123 5

set -euo pipefail

SERVICE_ID="${1:-}"
NUM_INSTANCES="${2:-}"

if [ -z "$SERVICE_ID" ] || [ -z "$NUM_INSTANCES" ]; then
    echo "Usage: $0 <service-id> <num-instances>" >&2
    echo "" >&2
    echo "Example: $0 srv-abc123 5" >&2
    echo "" >&2
    echo "Set RENDER_API_KEY environment variable for authentication" >&2
    exit 1
fi

if [ -z "${RENDER_API_KEY:-}" ]; then
    echo "Error: RENDER_API_KEY environment variable is not set" >&2
    exit 1
fi

# Use curl for the API call
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Authorization: Bearer ${RENDER_API_KEY}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "{\"numInstances\": ${NUM_INSTANCES}}" \
    "https://api.render.com/v1/services/${SERVICE_ID}/scale")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo "✓ Successfully scaled service ${SERVICE_ID} to ${NUM_INSTANCES} instances"
    if command -v jq &> /dev/null; then
        echo "$BODY" | jq '.'
    else
        echo "$BODY"
    fi
    exit 0
else
    echo "✗ Failed to scale service (HTTP ${HTTP_CODE})" >&2
    echo "$BODY" >&2
    exit 1
fi

#!/bin/bash
# Example automation script showing various auto-scaling scenarios
# This is a reference implementation - customize based on your needs

set -euo pipefail

# Configuration
SERVICE_ID="${SERVICE_ID:-}"
MIN_INSTANCES="${MIN_INSTANCES:-1}"
MAX_INSTANCES="${MAX_INSTANCES:-10}"
SCALE_UP_THRESHOLD="${SCALE_UP_THRESHOLD:-80}"
SCALE_DOWN_THRESHOLD="${SCALE_DOWN_THRESHOLD:-20}"

# Ensure required environment variables are set
if [ -z "${SERVICE_ID}" ]; then
    echo "Error: SERVICE_ID environment variable is required" >&2
    exit 1
fi

if [ -z "${RENDER_API_KEY:-}" ]; then
    echo "Error: RENDER_API_KEY environment variable is required" >&2
    exit 1
fi

# Get current service state
get_current_instances() {
    local service_id=$1
    curl -s \
        -H "Authorization: Bearer ${RENDER_API_KEY}" \
        -H "Accept: application/json" \
        "https://api.render.com/v1/services/${service_id}" \
        | jq -r '.serviceDetails.numInstances'
}

# Scale service
scale_service() {
    local service_id=$1
    local target_instances=$2

    echo "Scaling service ${service_id} to ${target_instances} instances..."

    ./scale_service.sh "${service_id}" "${target_instances}"
}

# Example 1: Time-based scaling
time_based_scaling() {
    local current_hour
    current_hour=$(date +%H)

    # Scale up during business hours (8 AM - 6 PM)
    if [ "$current_hour" -ge 8 ] && [ "$current_hour" -lt 18 ]; then
        echo "Business hours detected - ensuring minimum 3 instances"
        local current
        current=$(get_current_instances "${SERVICE_ID}")
        if [ "$current" -lt 3 ]; then
            scale_service "${SERVICE_ID}" 3
        fi
    else
        echo "Off-hours detected - scaling down to minimum"
        scale_service "${SERVICE_ID}" "${MIN_INSTANCES}"
    fi
}

# Example 2: Day-of-week based scaling
day_based_scaling() {
    local day_of_week
    day_of_week=$(date +%u)  # 1=Monday, 7=Sunday

    # Reduce instances on weekends
    if [ "$day_of_week" -ge 6 ]; then
        echo "Weekend detected - scaling to minimum"
        scale_service "${SERVICE_ID}" "${MIN_INSTANCES}"
    else
        echo "Weekday detected - ensuring normal capacity"
        local current
        current=$(get_current_instances "${SERVICE_ID}")
        if [ "$current" -lt 2 ]; then
            scale_service "${SERVICE_ID}" 2
        fi
    fi
}

# Example 3: Metric-based scaling (requires metrics from your monitoring system)
metric_based_scaling() {
    # This is a placeholder - integrate with your monitoring system
    # Examples: CloudWatch, Datadog, Prometheus, etc.

    # Simulated metric fetch (replace with actual monitoring integration)
    # local cpu_usage=$(fetch_cpu_metric "${SERVICE_ID}")
    # local memory_usage=$(fetch_memory_metric "${SERVICE_ID}")
    # local request_rate=$(fetch_request_rate "${SERVICE_ID}")

    echo "Metric-based scaling would check CPU, memory, and request rates"
    echo "Integration with monitoring system required"

    # Example logic:
    # if [ "$cpu_usage" -gt "$SCALE_UP_THRESHOLD" ]; then
    #     local current=$(get_current_instances "${SERVICE_ID}")
    #     local target=$((current + 1))
    #     if [ "$target" -le "$MAX_INSTANCES" ]; then
    #         scale_service "${SERVICE_ID}" "$target"
    #     fi
    # elif [ "$cpu_usage" -lt "$SCALE_DOWN_THRESHOLD" ]; then
    #     local current=$(get_current_instances "${SERVICE_ID}")
    #     local target=$((current - 1))
    #     if [ "$target" -ge "$MIN_INSTANCES" ]; then
    #         scale_service "${SERVICE_ID}" "$target"
    #     fi
    # fi
}

# Example 4: Gradual scaling
gradual_scale_up() {
    local target=$1
    local current
    current=$(get_current_instances "${SERVICE_ID}")

    echo "Gradually scaling from ${current} to ${target} instances"

    while [ "$current" -lt "$target" ]; do
        current=$((current + 1))
        scale_service "${SERVICE_ID}" "$current"
        echo "Waiting 30 seconds before next increment..."
        sleep 30
    done

    echo "Gradual scale-up complete"
}

# Example 5: Safe scale down (gradually)
gradual_scale_down() {
    local target=$1
    local current
    current=$(get_current_instances "${SERVICE_ID}")

    echo "Gradually scaling from ${current} to ${target} instances"

    while [ "$current" -gt "$target" ]; do
        current=$((current - 1))
        scale_service "${SERVICE_ID}" "$current"
        echo "Waiting 60 seconds before next decrement..."
        sleep 60
    done

    echo "Gradual scale-down complete"
}

# Main menu
show_usage() {
    cat << EOF
Usage: $0 <command>

Commands:
  time-based          Scale based on time of day
  day-based           Scale based on day of week
  metric-based        Scale based on metrics (requires monitoring integration)
  gradual-up <N>      Gradually scale up to N instances
  gradual-down <N>    Gradually scale down to N instances
  status              Show current instance count

Environment Variables:
  SERVICE_ID                Render service ID (required)
  RENDER_API_KEY            Render API key (required)
  MIN_INSTANCES             Minimum instances (default: 1)
  MAX_INSTANCES             Maximum instances (default: 10)
  SCALE_UP_THRESHOLD        CPU % to trigger scale up (default: 80)
  SCALE_DOWN_THRESHOLD      CPU % to trigger scale down (default: 20)

Example:
  export SERVICE_ID="srv-abc123"
  export RENDER_API_KEY="rnd_xyz789"
  $0 time-based
EOF
}

# Parse command
case "${1:-}" in
    time-based)
        time_based_scaling
        ;;
    day-based)
        day_based_scaling
        ;;
    metric-based)
        metric_based_scaling
        ;;
    gradual-up)
        if [ -z "${2:-}" ]; then
            echo "Error: Target instance count required" >&2
            exit 1
        fi
        gradual_scale_up "$2"
        ;;
    gradual-down)
        if [ -z "${2:-}" ]; then
            echo "Error: Target instance count required" >&2
            exit 1
        fi
        gradual_scale_down "$2"
        ;;
    status)
        current=$(get_current_instances "${SERVICE_ID}")
        echo "Current instances: ${current}"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac

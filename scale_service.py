#!/usr/bin/env python3
"""
Script to automatically increase instance count for a Render service using the Render API.

Usage:
    python scale_service.py --service-id <service-id> --num-instances <count> --api-key <api-key>

    Or using environment variables:
    export RENDER_API_KEY=<your-api-key>
    python scale_service.py --service-id <service-id> --num-instances <count>

Examples:
    # Scale to 5 instances
    python scale_service.py --service-id srv-abc123 --num-instances 5 --api-key rnd_xyz789

    # Increase by 2 instances (relative scaling)
    python scale_service.py --service-id srv-abc123 --increase-by 2 --api-key rnd_xyz789
"""

import argparse
import os
import sys
import json
import urllib.request
import urllib.error
from typing import Optional


class RenderAPIClient:
    """Client for interacting with the Render API."""

    BASE_URL = "https://api.render.com/v1"

    def __init__(self, api_key: str):
        """Initialize the Render API client.

        Args:
            api_key: Render API key for authentication
        """
        self.api_key = api_key
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }

    def get_service(self, service_id: str) -> dict:
        """Get service details from Render API.

        Args:
            service_id: The Render service ID

        Returns:
            dict: Service details

        Raises:
            Exception: If the API request fails
        """
        url = f"{self.BASE_URL}/services/{service_id}"

        req = urllib.request.Request(url, headers=self.headers, method="GET")

        try:
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read().decode())
                return data
        except urllib.error.HTTPError as e:
            error_body = e.read().decode() if e.fp else "No error details"
            raise Exception(f"Failed to get service: {e.code} {e.reason}\n{error_body}")
        except Exception as e:
            raise Exception(f"Failed to get service: {str(e)}")

    def scale_service(self, service_id: str, num_instances: int) -> dict:
        """Scale a Render service to the specified number of instances.

        Args:
            service_id: The Render service ID
            num_instances: The desired number of instances

        Returns:
            dict: Updated service details

        Raises:
            Exception: If the API request fails
        """
        url = f"{self.BASE_URL}/services/{service_id}/scale"

        data = json.dumps({"numInstances": num_instances}).encode('utf-8')

        req = urllib.request.Request(url, data=data, headers=self.headers, method="POST")

        try:
            with urllib.request.urlopen(req) as response:
                result = json.loads(response.read().decode())
                return result
        except urllib.error.HTTPError as e:
            error_body = e.read().decode() if e.fp else "No error details"
            raise Exception(f"Failed to scale service: {e.code} {e.reason}\n{error_body}")
        except Exception as e:
            raise Exception(f"Failed to scale service: {str(e)}")


def main():
    """Main function to handle CLI arguments and scale the service."""
    parser = argparse.ArgumentParser(
        description="Scale a Render service by changing the number of instances",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )

    parser.add_argument(
        "--service-id",
        required=True,
        help="Render service ID (e.g., srv-abc123)"
    )

    scale_group = parser.add_mutually_exclusive_group(required=True)
    scale_group.add_argument(
        "--num-instances",
        type=int,
        help="Absolute number of instances to scale to"
    )
    scale_group.add_argument(
        "--increase-by",
        type=int,
        help="Number of instances to increase by (relative scaling)"
    )
    scale_group.add_argument(
        "--decrease-by",
        type=int,
        help="Number of instances to decrease by (relative scaling)"
    )

    parser.add_argument(
        "--api-key",
        help="Render API key (can also be set via RENDER_API_KEY environment variable)"
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without actually scaling"
    )

    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose output"
    )

    args = parser.parse_args()

    # Get API key from args or environment
    api_key = args.api_key or os.environ.get("RENDER_API_KEY")
    if not api_key:
        print("Error: API key is required. Provide via --api-key or RENDER_API_KEY environment variable.", file=sys.stderr)
        sys.exit(1)

    try:
        client = RenderAPIClient(api_key)

        # Get current service details
        if args.verbose:
            print(f"Fetching service details for {args.service_id}...")

        service = client.get_service(args.service_id)
        current_instances = service.get("serviceDetails", {}).get("numInstances", 0)
        service_name = service.get("service", {}).get("name", args.service_id)

        if args.verbose:
            print(f"Service: {service_name}")
            print(f"Current instances: {current_instances}")

        # Calculate target instance count
        if args.num_instances is not None:
            target_instances = args.num_instances
        elif args.increase_by is not None:
            target_instances = current_instances + args.increase_by
        elif args.decrease_by is not None:
            target_instances = max(0, current_instances - args.decrease_by)

        # Validate target instance count
        if target_instances < 0:
            print(f"Error: Target instance count cannot be negative: {target_instances}", file=sys.stderr)
            sys.exit(1)

        print(f"Scaling service '{service_name}' (ID: {args.service_id})")
        print(f"  Current instances: {current_instances}")
        print(f"  Target instances:  {target_instances}")

        if target_instances == current_instances:
            print("Service is already at the target instance count. No action needed.")
            sys.exit(0)

        if args.dry_run:
            print("\n[DRY RUN] Would scale service but --dry-run flag is set. Exiting.")
            sys.exit(0)

        # Perform the scaling operation
        print(f"\nScaling service...")
        result = client.scale_service(args.service_id, target_instances)

        print(f"✓ Successfully scaled service to {target_instances} instances")

        if args.verbose:
            print(f"\nAPI Response:")
            print(json.dumps(result, indent=2))

    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

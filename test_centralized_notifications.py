#!/usr/bin/env python3
"""
Centralized Notification Test Script for DriveOn Platform

Now supports three production-like scenarios:
1) single  -> single user test
2) multicast -> ad-hoc targeted list of users (batched client-side)
3) topic   -> broadcast to an FCM topic (e.g., promotions.city.nairobi)
"""

import requests
import json
import sys
import argparse
from typing import Dict, Any, List

# Configuration
BASE_URL = "http://localhost"
ALERT_SERVICE_PORT = 8006


def test_notification_status() -> Dict[str, Any]:
    url = f"{BASE_URL}:{ALERT_SERVICE_PORT}/alerts/test/fcm/status"
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        return {"error": str(e), "service": "centralized-notifications"}


def send_single(user_id: int, title: str, message: str) -> Dict[str, Any]:
    """Use production route to send a single alert notification."""
    url = f"{BASE_URL}:{ALERT_SERVICE_PORT}/alerts/send"
    payload = {
        "user_id": user_id,
        "title": title,
        "message": message,
        "alert_type": "INFO",
        "channels": ["PUSH", "IN_APP"]
    }
    try:
        response = requests.post(url, json=payload, timeout=30)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        return {"error": str(e)}


def send_multicast(user_ids: List[int], title: str, message: str) -> Dict[str, Any]:
    url = f"{BASE_URL}:{ALERT_SERVICE_PORT}/alerts/social/multicast"
    data = {
        "user_ids": user_ids,
        "title": title,
        "message": message,
        "notification_type": "multicast_test"
    }
    try:
        response = requests.post(url, json=data, timeout=60)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        return {"error": str(e)}


def send_topic(topic: str, title: str, message: str, data: Dict[str, Any] | None = None) -> Dict[str, Any]:
    """Use production route for broadcasts if backend supports topic sends via /alerts/send."""
    url = f"{BASE_URL}:{ALERT_SERVICE_PORT}/alerts/send"
    payload = {
        "topic": topic,
        "title": title,
        "message": message,
        "data": data or {},
        "alert_type": "PROMOTIONAL",
        "channels": ["PUSH"]
    }
    try:
        response = requests.post(url, json=payload, timeout=30)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        return {"error": str(e)}


def chunk(lst: List[int], size: int) -> List[List[int]]:
    return [lst[i:i + size] for i in range(0, len(lst), size)]


def print_result(test_name: str, result: Dict[str, Any]):
    print(f"\n{'='*60}")
    print(f"🔔 CENTRALIZED NOTIFICATIONS - {test_name.upper()}")
    print(f"{'='*60}")
    if "error" in result:
        print(f"❌ Error: {result['error']}")
    else:
        print("✅ Success!")
        for key, value in result.items():
            print(f"   {key}: {value}")


def main():
    parser = argparse.ArgumentParser(description="DriveOn Centralized Notifications Tester")
    parser.add_argument("scenario", choices=["single", "multicast", "topic"],
                        help="Which send scenario to test")
    parser.add_argument("--user-id", type=int, dest="user_id", help="User ID for single scenario")
    parser.add_argument("--user-ids", type=str, dest="user_ids_csv",
                        help="Comma-separated user IDs for multicast scenario")
    parser.add_argument("--topic", type=str, dest="topic", help="FCM topic name for topic scenario")
    parser.add_argument("--title", type=str, default="DriveOn Test Notification")
    parser.add_argument("--message", type=str, default="This is a test notification from DriveOn")
    args = parser.parse_args()

    status = test_notification_status()
    print_result("Service Status Check", status)
    if not status.get("fcm_initialized", False):
        print("❌ FCM not initialized on alert-service. Aborting.")
        sys.exit(1)

    if args.scenario == "single":
        if not args.user_id:
            print("❌ --user-id is required for single scenario")
            sys.exit(1)
        res = send_single(args.user_id, args.title, args.message)
        print_result("Single", res)

    elif args.scenario == "multicast":
        if not args.user_ids_csv:
            print("❌ --user-ids is required for multicast scenario (comma-separated)")
            sys.exit(1)
        try:
            ids = [int(x.strip()) for x in args.user_ids_csv.split(",") if x.strip()]
        except ValueError:
            print("❌ Invalid --user-ids. Must be comma-separated integers.")
            sys.exit(1)
        if not ids:
            print("❌ No valid user IDs provided.")
            sys.exit(1)

        # FCM limit: 500 tokens per multicast call. Batch client-side for this test.
        batches = chunk(ids, 500)
        total_success = 0
        total_failure = 0
        for i, batch in enumerate(batches, 1):
            res = send_multicast(batch, args.title, args.message)
            print_result(f"Multicast Batch {i}/{len(batches)}", res)
            total_success += int(res.get("success_count", 0))
            total_failure += int(res.get("failure_count", 0))
        print(f"\n➡️  Multicast totals: success={total_success}, failure={total_failure}")

    elif args.scenario == "topic":
        if not args.topic:
            print("❌ --topic is required for topic scenario (e.g., promotions.city.nairobi)")
            sys.exit(1)
        res = send_topic(args.topic, args.title, args.message)
        print_result("Topic", res)


if __name__ == "__main__":
    main()

#!/usr/bin/env bash

set -euo pipefail

# Simple helper to test alert-service multicast and topic sends via real routes
#
# Usage examples:
#   # Multicast to users 2,3,4
#   ./scripts/bash/test_notifications.sh multicast \
#     --host http://localhost:8006 \
#     --user-ids 1,2,3,4 \
#     --title "Promo" \
#     --message "Big sale" \
#     --type multicast_test
#
#   # Topic broadcast (requires backend support for topic on /alerts/send)
#   ./scripts/bash/test_notifications.sh topic \
#     --host http://localhost:8006 \
#     --topic promotions.city.nairobi \
#     --title "Road Alert" \
#     --message "Accident on A104"

MODE=""
HOST="http://localhost:8006"
USER_IDS=""
TITLE="DriveOn Notification"
MESSAGE="This is a DriveOn notification"
NOTIF_TYPE="broadcast"
TOPIC=""

die() { echo "Error: $*" >&2; exit 1; }

[ $# -ge 1 ] || die "Usage: $0 <multicast|topic> [--host URL] [--user-ids CSV] [--topic NAME] [--title T] [--message M] [--type NT]"
MODE="$1"; shift

while [ $# -gt 0 ]; do
  case "$1" in
    --host) HOST="$2"; shift 2;;
    --user-ids) USER_IDS="$2"; shift 2;;
    --topic) TOPIC="$2"; shift 2;;
    --title) TITLE="$2"; shift 2;;
    --message) MESSAGE="$2"; shift 2;;
    --type) NOTIF_TYPE="$2"; shift 2;;
    *) die "Unknown arg: $1";;
  esac
done

case "$MODE" in
  multicast)
    [ -n "$USER_IDS" ] || die "--user-ids required (comma-separated)"
    # Build JSON array from CSV
    IFS=',' read -r -a IDS_ARR <<< "$USER_IDS"
    JSON_IDS="$(printf '"%s",' "${IDS_ARR[@]}")"; JSON_IDS="[${JSON_IDS%,}]"

    echo "-> Sending multicast to $USER_IDS via $HOST/alerts/social/multicast?title=...&message=...&notification_type=..."
    QTITLE=$(printf %s "$TITLE" | sed 's/\ /%20/g')
    QMSG=$(printf %s "$MESSAGE" | sed 's/\ /%20/g')
    QTYPE=$(printf %s "$NOTIF_TYPE" | sed 's/\ /%20/g')
    BODY_PAYLOAD="{\"user_ids\": $JSON_IDS}"
    TMP_BODY=$(mktemp)
    echo "$BODY_PAYLOAD" > "$TMP_BODY"
    curl -i -sS -X POST "$HOST/alerts/social/multicast?title=$QTITLE&message=$QMSG&notification_type=$QTYPE" \
      -H "Content-Type: application/json" \
      --data-binary @"$TMP_BODY"
    rm -f "$TMP_BODY"
    ;;

  topic)
    [ -n "$TOPIC" ] || die "--topic required"
    echo "-> Broadcasting to topic $TOPIC via $HOST/alerts/broadcast/topic"
    curl -i -sS -X POST "$HOST/alerts/broadcast/topic" \
      -H "Content-Type: application/json" \
      -d "{\"topic\": \"$TOPIC\", \"title\": \"$TITLE\", \"message\": \"$MESSAGE\" }"
    ;;

  *)
    die "Unknown mode: $MODE (use multicast|topic)"
    ;;
esac

echo


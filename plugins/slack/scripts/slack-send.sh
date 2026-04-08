#!/usr/bin/env bash
# slack-send.sh — Send a message to a Slack channel or thread
# Usage: slack-send.sh CHANNEL MESSAGE [--thread THREAD_TS]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/slack-common.sh"
load_config

CHANNEL=""
MESSAGE=""
THREAD_TS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --thread) THREAD_TS="$2"; shift 2 ;;
    *)
      if [[ -z "$CHANNEL" ]]; then
        CHANNEL="$1"; shift
      elif [[ -z "$MESSAGE" ]]; then
        MESSAGE="$1"; shift
      else
        # Append remaining args to message
        MESSAGE="$MESSAGE $1"; shift
      fi
      ;;
  esac
done

if [[ -z "$CHANNEL" ]]; then
  echo "ERROR: Channel name or ID is required." >&2
  echo "Usage: slack-send.sh CHANNEL MESSAGE [--thread THREAD_TS]" >&2
  exit 1
fi

if [[ -z "$MESSAGE" ]]; then
  echo "ERROR: Message text is required." >&2
  exit 1
fi

# Resolve channel name to ID
CHANNEL_ID=$(resolve_channel "$CHANNEL")

# Build API arguments
ARGS=("chat.postMessage" "channel=$CHANNEL_ID" "text=$MESSAGE")

if [[ -n "$THREAD_TS" ]]; then
  ARGS+=("thread_ts=$THREAD_TS")
fi

RESPONSE=$(slack_api_form "${ARGS[@]}")

# Extract posted message details
TS=$(echo "$RESPONSE" | jq -r '.ts // ""')
POSTED_CHANNEL=$(echo "$RESPONSE" | jq -r '.channel // ""')

echo "Message sent successfully."
echo "  Channel: #${CHANNEL#\#} ($POSTED_CHANNEL)"
if [[ -n "$THREAD_TS" ]]; then
  echo "  Thread: $THREAD_TS"
fi
echo "  Timestamp: $TS"

#!/usr/bin/env bash
# slack-read.sh — Read channel history or thread replies
# Usage: slack-read.sh CHANNEL [--thread THREAD_TS] [--limit N] [--since DAYS]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/slack-common.sh"
load_config

CHANNEL=""
THREAD_TS=""
LIMIT=30
SINCE_DAYS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --thread) THREAD_TS="$2"; shift 2 ;;
    --limit)  LIMIT="$2"; shift 2 ;;
    --since)  SINCE_DAYS="$2"; shift 2 ;;
    *)
      if [[ -z "$CHANNEL" ]]; then
        CHANNEL="$1"; shift
      else
        echo "Unknown option: $1" >&2; exit 1
      fi
      ;;
  esac
done

if [[ -z "$CHANNEL" ]]; then
  echo "ERROR: Channel name or ID is required." >&2
  echo "Usage: slack-read.sh CHANNEL [--thread THREAD_TS] [--limit N] [--since DAYS]" >&2
  exit 1
fi

# Resolve channel name to ID
CHANNEL_ID=$(resolve_channel "$CHANNEL")

if [[ -n "$THREAD_TS" ]]; then
  # ── Read thread replies ──────────────────────────────────────
  RESPONSE=$(slack_api_form "conversations.replies" \
    "channel=$CHANNEL_ID" \
    "ts=$THREAD_TS" \
    "limit=$LIMIT")

  echo "## Thread in #${CHANNEL#\#}"
  echo ""

  echo "$RESPONSE" | jq -r --arg cache "$USER_CACHE_FILE" '
    .messages[] |
    "**" + (.user // "unknown") + "** — " + (.ts | split(".")[0] | tonumber | strftime("%Y-%m-%d %H:%M")) +
    "\n" + (.text // "(empty)") + "\n"'

  # Resolve user IDs to names in output
  # (handled by Claude interpreting the output)

else
  # ── Read channel history ─────────────────────────────────────
  ARGS=("conversations.history" "channel=$CHANNEL_ID" "limit=$LIMIT")

  # Apply time filter
  if [[ -n "$SINCE_DAYS" ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      OLDEST=$(date -v-"${SINCE_DAYS}"d +%s)
    else
      OLDEST=$(date -d "${SINCE_DAYS} days ago" +%s)
    fi
    ARGS+=("oldest=$OLDEST")
  fi

  RESPONSE=$(slack_api_form "${ARGS[@]}")

  MSG_COUNT=$(echo "$RESPONSE" | jq '.messages | length')
  echo "## #${CHANNEL#\#} — Recent Messages ($MSG_COUNT)"
  echo ""

  if [[ "$MSG_COUNT" == "0" ]]; then
    echo "No messages found."
    exit 0
  fi

  # Display messages (newest last for natural reading)
  echo "$RESPONSE" | jq -r '
    .messages | reverse | .[] |
    "---",
    "**" + (.user // "bot") + "** — " + (.ts | split(".")[0] | tonumber | strftime("%Y-%m-%d %H:%M")) +
    (if .reply_count then " (" + (.reply_count | tostring) + " replies)" else "" end),
    "",
    (.text // "(empty)"),
    (if .thread_ts and .thread_ts == .ts and .reply_count then "\n_Thread ts: " + .thread_ts + "_" else "" end),
    ""'
fi

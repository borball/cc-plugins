#!/usr/bin/env bash
# slack-search.sh — Search Slack messages across the workspace
# Usage: slack-search.sh [--sort relevance|timestamp] [--count N] [--channel CHANNEL] QUERY...

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/slack-common.sh"
load_config

SORT="relevance"
COUNT=20
CHANNEL=""
QUERY_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sort)    SORT="$2"; shift 2 ;;
    --count)   COUNT="$2"; shift 2 ;;
    --channel) CHANNEL="$2"; shift 2 ;;
    *)         QUERY_ARGS+=("$1"); shift ;;
  esac
done

QUERY="${QUERY_ARGS[*]}"

if [[ -z "$QUERY" ]]; then
  echo "ERROR: Search query is required." >&2
  echo "Usage: slack-search.sh [--sort relevance|timestamp] [--count N] [--channel CHANNEL] QUERY..." >&2
  exit 1
fi

# Prepend channel filter if specified
if [[ -n "$CHANNEL" ]]; then
  CHANNEL="${CHANNEL#\#}"
  QUERY="in:#${CHANNEL} ${QUERY}"
fi

RESPONSE=$(slack_api_form "search.messages" \
  "query=$QUERY" \
  "sort=$SORT" \
  "count=$COUNT" \
  "highlight=false")

TOTAL=$(echo "$RESPONSE" | jq -r '.messages.total // 0')
echo "## Search: \"${QUERY_ARGS[*]}\" ($TOTAL results)"
echo ""

if [[ "$TOTAL" == "0" ]]; then
  echo "No messages found."
  exit 0
fi

# Learn channel IDs from search results (builds cache for enterprise workspaces)
echo "$RESPONSE" | jq -r '.messages.matches[] | .channel | "\(.id) \(.name)"' | while read -r cid cname; do
  learn_channel_from_search "$cid" "$cname"
done

# Display results
echo "$RESPONSE" | jq -r '.messages.matches[] |
  "---",
  "**#" + .channel.name + "** (`" + .channel.id + "`) — " + (.username // "unknown") + " — " + (.ts | split(".")[0] | tonumber | strftime("%Y-%m-%d %H:%M")),
  "",
  (.text // "(empty)"),
  "",
  "Thread: " + (if .permalink then .permalink else "—" end),
  ""'

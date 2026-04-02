#!/usr/bin/env bash
# slack-channels.sh — List or search Slack channels
# Usage: slack-channels.sh [--refresh] [FILTER]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/slack-common.sh"
load_config

REFRESH=false
FILTER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --refresh) REFRESH=true; shift ;;
    *)         FILTER="$1"; shift ;;
  esac
done

# Refresh cache if requested or missing
if [[ "$REFRESH" == true ]] || [[ ! -f "$CHANNEL_CACHE_FILE" ]]; then
  refresh_channel_cache
fi

COUNT=$(jq 'length' "$CHANNEL_CACHE_FILE" 2>/dev/null || echo 0)

echo "## Slack Channels"
echo ""

if [[ "$COUNT" == "0" ]]; then
  echo "Channel cache is empty."
  echo ""
  echo "This can happen on enterprise Slack workspaces where \`conversations.list\` is restricted."
  echo ""
  echo "**Alternatives:**"
  echo "- Use \`/slack search <query>\` — channel IDs are learned automatically from search results"
  echo "- Use channel IDs directly from Slack URLs (e.g., \`C0123ABCDEF\`)"
  echo ""
  if [[ -f "$CHANNEL_CACHE_FILE" ]]; then
    LEARNED=$(jq 'length' "$CHANNEL_CACHE_FILE")
    if [[ "$LEARNED" -gt 0 ]]; then
      echo "**Channels discovered from searches ($LEARNED):**"
      echo ""
      jq -r '.[] | "- #" + .name + " (\`" + .id + "\`)"' "$CHANNEL_CACHE_FILE"
    fi
  fi
  exit 0
fi

if [[ -n "$FILTER" ]]; then
  RESULTS=$(jq -r --arg f "$FILTER" '[.[] | select(.name | contains($f))]' "$CHANNEL_CACHE_FILE")
  FCOUNT=$(echo "$RESULTS" | jq 'length')
  echo "Filter: \"$FILTER\" ($FCOUNT matches)"
  echo ""

  if [[ "$FCOUNT" == "0" ]]; then
    echo "No channels matching \"$FILTER\"."
    exit 0
  fi

  echo "$RESULTS" | jq -r '.[] | "- #" + .name + " (`" + .id + "`)"'
else
  echo "Total: $COUNT channels"
  echo ""
  jq -r '.[] | "- #" + .name + " (`" + .id + "`)"' "$CHANNEL_CACHE_FILE" | head -50

  if [[ "$COUNT" -gt 50 ]]; then
    echo ""
    echo "_Showing first 50. Use a filter to narrow: \`slack-channels.sh FILTER\`_"
  fi
fi

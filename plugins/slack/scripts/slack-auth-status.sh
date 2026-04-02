#!/usr/bin/env bash
# slack-auth-status.sh — Check Slack authentication status and config
# Usage: slack-auth-status.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/slack-common.sh"

echo "## Slack — Configuration Status"
echo ""

# Check config
if ! load_config 2>/dev/null; then
  echo "**Config**: NOT CONFIGURED"
  echo ""
  echo "Run \`/slack init\` to set up credentials."
  exit 0
fi

echo "**Config source**: $SLACK_CONFIG_SOURCE"
echo "**Workspace**: ${SLACK_WORKSPACE:-_(not set)_}"
echo ""

# Test auth
echo -n "**Authentication**: "
RESPONSE=$(slack_api_form "auth.test" 2>/dev/null) || {
  echo "FAILED — tokens may be expired"
  echo ""
  echo "Run \`/slack init\` to refresh your tokens."
  exit 0
}

USER=$(echo "$RESPONSE" | jq -r '.user // "unknown"')
TEAM=$(echo "$RESPONSE" | jq -r '.team // "unknown"')
USER_ID=$(echo "$RESPONSE" | jq -r '.user_id // "unknown"')

echo "OK"
echo "**User**: $USER ($USER_ID)"
echo "**Team**: $TEAM"

# Check channel cache
if [[ -f "$CHANNEL_CACHE_FILE" ]]; then
  COUNT=$(jq 'length' "$CHANNEL_CACHE_FILE")
  echo "**Channel cache**: $COUNT channels cached"
else
  echo "**Channel cache**: not built yet (will auto-build on first use)"
fi

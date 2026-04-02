#!/usr/bin/env bash
# rh-case-auth-status.sh — Check Red Hat API authentication status and config
# Usage: rh-case-auth-status.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/rh-case-common.sh"

echo "## Red Hat Support Case — Configuration Status"
echo ""

# Check config
if ! load_config 2>/dev/null; then
  echo "**Config**: NOT CONFIGURED"
  echo ""
  echo "Run \`/rh-case:init\` to set up credentials."
  exit 0
fi

echo "**Config source**: $RH_CONFIG_SOURCE"
echo "**Account filter**: ${RH_ACCOUNT_NUMBER:-_(none)_}"
echo ""

# Test auth
echo -n "**Authentication**: "
if TOKEN=$(get_access_token 2>/dev/null); then
  echo "OK (token obtained successfully)"

  # Quick API test — use Hydra search to verify case access
  TEST_BODY='{"q":"*:*","start":0,"rows":1,"partnerSearch":false,"expression":"fl=case_number"}'
  TEST=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "$TEST_BODY" \
    "https://access.redhat.com/hydra/rest/search/v2/cases" 2>/dev/null || echo "000")

  if [[ "$TEST" == "200" ]]; then
    echo "**API access**: OK"
  else
    echo "**API access**: HTTP $TEST (may indicate permission issues)"
  fi
else
  echo "FAILED — check your offline token"
fi

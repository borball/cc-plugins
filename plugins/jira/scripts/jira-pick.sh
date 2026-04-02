#!/usr/bin/env bash
# Pick a Jira ticket to work on. Fetches assigned tickets and lets you choose.
# Usage: ./jira-pick.sh [TICKET-KEY]
#   If TICKET-KEY is provided, selects it directly.
#   Otherwise, lists your tickets and prompts for selection.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-common.sh"

# If a ticket key is passed directly, use it
if [[ "${1:-}" != "" ]]; then
  TICKET_KEY="$1"
  echo "Fetching ticket $TICKET_KEY..."
  ISSUE_JSON=$(jira_api GET "issue/$TICKET_KEY?fields=summary,status")

  SUMMARY=$(echo "$ISSUE_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['fields']['summary'])")
  STATUS=$(echo "$ISSUE_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['fields']['status']['name'])")

  set_current_task "$TICKET_KEY" "$SUMMARY" "$STATUS"
  echo "Selected: [$TICKET_KEY] $SUMMARY (Status: $STATUS)"
  exit 0
fi

# Fetch tickets using JQL
JQL="${JIRA_JQL_FILTER:-"assignee = currentUser() AND status != Done ORDER BY updated DESC"}"
ENCODED_JQL=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$JQL'))")

echo "Fetching your tickets..."
RESPONSE=$(jira_api GET "search/jql?jql=$ENCODED_JQL&maxResults=20&fields=summary,status,priority")

# Parse and display tickets
TICKET_COUNT=$(echo "$RESPONSE" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('issues',[])))")

if [[ "$TICKET_COUNT" == "0" ]]; then
  echo "No tickets found matching your filter."
  echo "JQL: $JQL"
  exit 1
fi

echo ""
echo "Your tickets:"
echo "─────────────────────────────────────────────────────────"

echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for i, issue in enumerate(data['issues'], 1):
    key = issue['key']
    summary = issue['fields']['summary']
    status = issue['fields']['status']['name']
    priority = issue['fields'].get('priority', {})
    pname = priority.get('name', 'None') if priority else 'None'
    print(f'  {i:2d}. [{key}] {summary}')
    print(f'      Status: {status} | Priority: {pname}')
"

echo "─────────────────────────────────────────────────────────"

# If not interactive (e.g. called by Claude), just list and exit
if [[ ! -t 0 ]]; then
  exit 0
fi

echo ""
read -rp "Select ticket number (or 'q' to quit): " SELECTION

if [[ "$SELECTION" == "q" ]]; then
  echo "No ticket selected."
  exit 0
fi

# Get selected ticket details
SELECTED=$(echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
idx = int('$SELECTION') - 1
if 0 <= idx < len(data['issues']):
    issue = data['issues'][idx]
    print(issue['key'])
    print(issue['fields']['summary'])
    print(issue['fields']['status']['name'])
else:
    print('INVALID')
")

TICKET_KEY=$(echo "$SELECTED" | sed -n '1p')
SUMMARY=$(echo "$SELECTED" | sed -n '2p')
STATUS=$(echo "$SELECTED" | sed -n '3p')

if [[ "$TICKET_KEY" == "INVALID" ]]; then
  echo "Invalid selection."
  exit 1
fi

set_current_task "$TICKET_KEY" "$SUMMARY" "$STATUS"
echo ""
echo "Selected: [$TICKET_KEY] $SUMMARY"
echo "Status: $STATUS"
echo "Task tracking started at $(date)"

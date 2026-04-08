#!/usr/bin/env bash
# Show the currently active task and its Jira status.
# Usage: ./jira-status.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-common.sh"

CURRENT=$(get_current_task)

if [[ -z "$CURRENT" ]]; then
  echo "No active task. Run /jira start to select one."
  exit 0
fi

KEY=$(echo "$CURRENT" | python3 -c "import sys,json; print(json.load(sys.stdin)['key'])")
SUMMARY=$(echo "$CURRENT" | python3 -c "import sys,json; print(json.load(sys.stdin)['summary'])")
STATUS=$(echo "$CURRENT" | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])")
STARTED=$(echo "$CURRENT" | python3 -c "import sys,json; print(json.load(sys.stdin)['started_at'])")

# Calculate elapsed time
ELAPSED=$(python3 -c "
from datetime import datetime, timezone
start = datetime.strptime('$STARTED', '%Y-%m-%dT%H:%M:%S.000+0000').replace(tzinfo=timezone.utc)
now = datetime.now(timezone.utc)
diff = now - start
hours = int(diff.total_seconds() // 3600)
minutes = int((diff.total_seconds() % 3600) // 60)
if hours > 0:
    print(f'{hours}h {minutes}m')
else:
    print(f'{minutes}m')
")

# Determine which config is active
if [[ -f "./.env.jira" ]]; then
  CONFIG_SOURCE="./.env.jira (project)"
else
  CONFIG_SOURCE="$JIRA_DATA_DIR/.env (global)"
fi

echo "Current Task"
echo "════════════════════════════════════════════════"
echo "  Ticket:  $KEY"
echo "  Summary: $SUMMARY"
echo "  Status:  $STATUS"
echo "  Started: $STARTED"
echo "  Elapsed: $ELAPSED"
echo "────────────────────────────────────────────────"
echo "  Jira:    $JIRA_URL"
echo "  Project: $JIRA_PROJECT_KEY"
echo "  User:    $JIRA_USERNAME"
echo "  Config:  $CONFIG_SOURCE"
echo "════════════════════════════════════════════════"

# Optionally fetch live status from Jira
if [[ "${1:-}" == "--live" ]]; then
  echo ""
  echo "Fetching live status from Jira..."
  LIVE=$(jira_api GET "issue/$KEY?fields=status,summary,assignee")
  LIVE_STATUS=$(echo "$LIVE" | python3 -c "import sys,json; print(json.load(sys.stdin)['fields']['status']['name'])")
  LIVE_SUMMARY=$(echo "$LIVE" | python3 -c "import sys,json; print(json.load(sys.stdin)['fields']['summary'])")
  echo "  Live status: $LIVE_STATUS"
  if [[ "$LIVE_SUMMARY" != "$SUMMARY" ]]; then
    echo "  Live title:  $LIVE_SUMMARY"
    # Update local cache, preserving started_at
    LIVE_SUMMARY="$LIVE_SUMMARY" LIVE_STATUS="$LIVE_STATUS" TASK_FILE="$CURRENT_TASK_FILE" python3 -c "
import json, os
with open(os.environ['TASK_FILE']) as f:
    task = json.load(f)
task['summary'] = os.environ['LIVE_SUMMARY']
task['status'] = os.environ['LIVE_STATUS']
with open(os.environ['TASK_FILE'], 'w') as f:
    json.dump(task, f, indent=2)
"
  fi
fi

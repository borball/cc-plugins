#!/usr/bin/env bash
# Hook: runs at the end of a Claude Code session.
# Reminds about logging work if there's an active task.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
JIRA_DATA_DIR="${CLAUDE_PLUGIN_DATA:-${PLUGIN_DIR}}"
CURRENT_TASK_FILE="$JIRA_DATA_DIR/.current-task.json"

if [[ -f "$CURRENT_TASK_FILE" ]]; then
  KEY=$(python3 -c "import json; d=json.load(open('$CURRENT_TASK_FILE')); print(d['key'])")
  SUMMARY=$(python3 -c "import json; d=json.load(open('$CURRENT_TASK_FILE')); print(d['summary'])")
  STARTED=$(python3 -c "import json; d=json.load(open('$CURRENT_TASK_FILE')); print(d['started_at'])")

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

  echo ""
  echo "Session ending with active task: [$KEY] $SUMMARY"
  echo "Time elapsed: $ELAPSED"
  echo ""
  echo "Don't forget to log your work:"
  echo "  /jira log your summary here"
  echo "  /jira done   # if task is complete"
fi

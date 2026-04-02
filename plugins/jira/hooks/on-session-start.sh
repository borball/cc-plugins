#!/usr/bin/env bash
# Hook: runs at the start of a Claude Code session.
# Checks for an active task and reminds the user, or prompts to pick one.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
JIRA_DATA_DIR="${CLAUDE_PLUGIN_DATA:-${PROJECT_ROOT}}"
CURRENT_TASK_FILE="$JIRA_DATA_DIR/.current-task.json"

if [[ -f "$CURRENT_TASK_FILE" ]]; then
  KEY=$(python3 -c "import json; d=json.load(open('$CURRENT_TASK_FILE')); print(d['key'])")
  SUMMARY=$(python3 -c "import json; d=json.load(open('$CURRENT_TASK_FILE')); print(d['summary'])")
  STATUS=$(python3 -c "import json; d=json.load(open('$CURRENT_TASK_FILE')); print(d['status'])")
  echo "Active task: [$KEY] $SUMMARY (Status: $STATUS)"
  echo "Use ./scripts/jira-status.sh for details, or pick a new task with ./scripts/jira-pick.sh"
else
  echo "No active Jira task. Run ./scripts/jira-pick.sh to select one."
fi

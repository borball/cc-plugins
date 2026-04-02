#!/usr/bin/env bash
# Transition a Jira ticket to a new status.
# Usage: ./jira-transition.sh [TICKET-KEY] [STATUS]
#   STATUS can be: "todo", "progress", "review", "done"
#   If TICKET-KEY is omitted, uses the current active task.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-common.sh"

# Determine ticket key
TICKET_KEY="${1:-}"
TARGET_STATUS="${2:-}"

if [[ -z "$TICKET_KEY" ]]; then
  CURRENT=$(get_current_task)
  if [[ -z "$CURRENT" ]]; then
    echo "Error: No active task and no ticket key provided."
    echo "Usage: $0 [TICKET-KEY] [STATUS]"
    exit 1
  fi
  TICKET_KEY=$(echo "$CURRENT" | python3 -c "import sys,json; print(json.load(sys.stdin)['key'])")
fi

# Get available transitions
echo "Fetching transitions for $TICKET_KEY..."
TRANSITIONS=$(jira_api GET "issue/$TICKET_KEY/transitions")

if [[ -z "$TARGET_STATUS" ]]; then
  # Show available transitions
  echo ""
  echo "Available transitions for $TICKET_KEY:"
  echo "─────────────────────────────────────"
  echo "$TRANSITIONS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for t in data['transitions']:
    print(f\"  {t['id']:>3s}. {t['name']} -> {t['to']['name']}\")
"
  echo "─────────────────────────────────────"
  read -rp "Enter transition name or ID: " TARGET_STATUS
fi

# Map common aliases to transition names
map_status() {
  local input
  input=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  case "$input" in
    todo|"to do"|backlog) echo "To Do" ;;
    progress|"in progress"|start|wip) echo "In Progress" ;;
    review|"in review"|"code review") echo "In Review" ;;
    done|complete|resolve|closed|close) echo "Done|Closed" ;;
    *) echo "$1" ;;
  esac
}

MAPPED_STATUS=$(map_status "$TARGET_STATUS")

# Find matching transition ID
TRANSITION_ID=$(echo "$TRANSITIONS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
target = '$MAPPED_STATUS'
targets = [t.strip().lower() for t in target.split('|')]
# Try exact match first, then partial match
for tgt in targets:
    for t in data['transitions']:
        if t['name'].lower() == tgt or t['to']['name'].lower() == tgt:
            print(t['id'])
            sys.exit(0)
for tgt in targets:
    for t in data['transitions']:
        if tgt in t['name'].lower() or tgt in t['to']['name'].lower():
            print(t['id'])
            sys.exit(0)
# Try as direct ID
try:
    tid = str(int(target))
    for t in data['transitions']:
        if t['id'] == tid:
            print(t['id'])
            sys.exit(0)
except ValueError:
    pass
print('NOT_FOUND')
")

if [[ "$TRANSITION_ID" == "NOT_FOUND" ]]; then
  echo "Error: No matching transition found for '$TARGET_STATUS'"
  exit 1
fi

# Execute transition
echo "Transitioning $TICKET_KEY..."
RESULT=$(jira_api POST "issue/$TICKET_KEY/transitions" "{\"transition\":{\"id\":\"$TRANSITION_ID\"}}")

echo "Done. $TICKET_KEY transitioned successfully."

# Update current task file if this is the active task
CURRENT=$(get_current_task)
if [[ -n "$CURRENT" ]]; then
  CURRENT_KEY=$(echo "$CURRENT" | python3 -c "import sys,json; print(json.load(sys.stdin)['key'])")
  if [[ "$CURRENT_KEY" == "$TICKET_KEY" ]]; then
    CURRENT_SUMMARY=$(echo "$CURRENT" | python3 -c "import sys,json; print(json.load(sys.stdin)['summary'])")
    set_current_task "$TICKET_KEY" "$CURRENT_SUMMARY" "$MAPPED_STATUS"
  fi
fi

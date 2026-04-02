#!/usr/bin/env bash
# Post a work log entry to a Jira ticket.
# Usage: ./jira-log.sh [TICKET-KEY] [--file LOG_FILE | --message "log text"]
#   If TICKET-KEY is omitted, uses the current active task.
#   --file: read log content from a file
#   --message: provide log content inline
#   --time: time spent (e.g., "2h", "30m", "1h 30m") — optional
#   --comment: also post as a comment (not just worklog)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-common.sh"

TICKET_KEY=""
LOG_FILE=""
LOG_MESSAGE=""
TIME_SPENT=""
POST_COMMENT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      LOG_FILE="$2"
      shift 2
      ;;
    --message)
      LOG_MESSAGE="$2"
      shift 2
      ;;
    --time)
      TIME_SPENT="$2"
      shift 2
      ;;
    --comment)
      POST_COMMENT=true
      shift
      ;;
    *)
      if [[ -z "$TICKET_KEY" ]]; then
        TICKET_KEY="$1"
      fi
      shift
      ;;
  esac
done

# Fallback to current task
if [[ -z "$TICKET_KEY" ]]; then
  CURRENT=$(get_current_task)
  if [[ -z "$CURRENT" ]]; then
    echo "Error: No active task and no ticket key provided."
    exit 1
  fi
  TICKET_KEY=$(echo "$CURRENT" | python3 -c "import sys,json; print(json.load(sys.stdin)['key'])")
fi

# Calculate time spent from current task if not provided
if [[ -z "$TIME_SPENT" ]]; then
  CURRENT=$(get_current_task)
  if [[ -n "$CURRENT" ]]; then
    STARTED=$(echo "$CURRENT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('started_at',''))")
    if [[ -n "$STARTED" ]]; then
      TIME_SPENT=$(python3 -c "
from datetime import datetime, timezone
start = datetime.strptime('$STARTED', '%Y-%m-%dT%H:%M:%S.000+0000').replace(tzinfo=timezone.utc)
now = datetime.now(timezone.utc)
diff = now - start
hours = int(diff.total_seconds() // 3600)
minutes = int((diff.total_seconds() % 3600) // 60)
if hours > 0 and minutes > 0:
    print(f'{hours}h {minutes}m')
elif hours > 0:
    print(f'{hours}h')
else:
    print(f'{max(minutes, 1)}m')
")
    fi
  fi
fi

# Determine input source
if [[ -n "$LOG_FILE" ]]; then
  if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: File not found: $LOG_FILE"
    exit 1
  fi
  INPUT_SOURCE="$LOG_FILE"
elif [[ -n "$LOG_MESSAGE" ]]; then
  TMPFILE=$(mktemp)
  echo "$LOG_MESSAGE" > "$TMPFILE"
  INPUT_SOURCE="$TMPFILE"
  trap "rm -f '$TMPFILE'" EXIT
else
  echo "Error: No log content provided. Use --file or --message."
  exit 1
fi

ADF_BUILDER="$SCRIPT_DIR/build-adf.py"

echo "Posting work log to $TICKET_KEY..."
echo "Time spent: ${TIME_SPENT:-not specified}"

# Post worklog
WORKLOG_PAYLOAD=$(python3 "$ADF_BUILDER" "comment" "$TIME_SPENT" < "$INPUT_SOURCE")
RESULT=$(jira_api POST "issue/$TICKET_KEY/worklog" "$WORKLOG_PAYLOAD")

if echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'id' in d else 1)" 2>/dev/null; then
  WORKLOG_ID=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
  echo "Work log posted successfully (ID: $WORKLOG_ID)"
else
  echo "Warning: Worklog may have failed. Response:"
  echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"
fi

# Optionally post as a comment too
if [[ "$POST_COMMENT" == true ]]; then
  echo "Also posting as comment..."

  COMMENT_PAYLOAD=$(python3 "$ADF_BUILDER" "body" < "$INPUT_SOURCE")
  COMMENT_RESULT=$(jira_api POST "issue/$TICKET_KEY/comment" "$COMMENT_PAYLOAD")

  if echo "$COMMENT_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'id' in d else 1)" 2>/dev/null; then
    echo "Comment posted successfully."
  else
    echo "Warning: Comment may have failed. Response:"
    echo "$COMMENT_RESULT" | python3 -m json.tool 2>/dev/null || echo "$COMMENT_RESULT"
  fi
fi

echo "Done."

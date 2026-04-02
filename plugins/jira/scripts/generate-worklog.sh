#!/usr/bin/env bash
# Generate a work log summary from git activity and current task context.
# This script gathers data; Claude generates the actual summary.
# Usage: ./generate-worklog.sh [--since TIMESTAMP]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-common.sh"

CURRENT=$(get_current_task)
if [[ -z "$CURRENT" ]]; then
  echo "Error: No active task."
  exit 1
fi

KEY=$(echo "$CURRENT" | python3 -c "import sys,json; print(json.load(sys.stdin)['key'])")
SUMMARY=$(echo "$CURRENT" | python3 -c "import sys,json; print(json.load(sys.stdin)['summary'])")
STATUS=$(echo "$CURRENT" | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])")
STARTED=$(echo "$CURRENT" | python3 -c "import sys,json; print(json.load(sys.stdin)['started_at'])")
WORKING_DIR=$(echo "$CURRENT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('working_dir','.'))")

SINCE="${1:-$STARTED}"

# Gather git activity from the working directory
GIT_LOG=""
GIT_DIFF_STAT=""
if [[ -d "$WORKING_DIR/.git" ]] || git -C "$WORKING_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  GIT_LOG=$(git -C "$WORKING_DIR" log --oneline --since="$SINCE" 2>/dev/null || echo "No commits in timeframe")
  GIT_DIFF_STAT=$(git -C "$WORKING_DIR" diff --stat HEAD~5 HEAD 2>/dev/null || echo "Unable to get diff stat")
fi

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

# Output structured context for Claude to summarize
cat <<EOF
=== WORKLOG CONTEXT ===
Ticket: $KEY
Summary: $SUMMARY
Status: $STATUS
Started: $STARTED
Elapsed: $ELAPSED

=== GIT COMMITS (since $SINCE) ===
$GIT_LOG

=== FILES CHANGED ===
$GIT_DIFF_STAT

=== INSTRUCTIONS ===
Please generate a concise work log entry based on the above context and our
conversation. Use this format:

## What was done
- (bullet points of completed work)

## Files changed
- (list key files and what changed)

## Key decisions
- (any architectural or design decisions made)

## Blockers / Open questions
- (anything unresolved)

## Next steps
- (what should happen next)
EOF

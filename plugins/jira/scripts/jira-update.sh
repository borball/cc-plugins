#!/usr/bin/env bash
# Update fields on a Jira ticket.
# Usage: ./jira-update.sh [TICKET-KEY] [--desc-file FILE | --desc "text"] [--summary "text"]
#   If TICKET-KEY is omitted, uses the current active task.
#   --desc-file: read description from a markdown file
#   --desc: provide description inline
#   --summary: update the ticket summary/title

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-common.sh"

TICKET_KEY=""
DESCRIPTION=""
DESC_FILE=""
SUMMARY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --desc-file)
      DESC_FILE="$2"
      shift 2
      ;;
    --desc)
      DESCRIPTION="$2"
      shift 2
      ;;
    --summary)
      SUMMARY="$2"
      shift 2
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

# If desc-file provided, read it
if [[ -n "$DESC_FILE" ]]; then
  if [[ ! -f "$DESC_FILE" ]]; then
    echo "Error: File not found: $DESC_FILE"
    exit 1
  fi
  DESCRIPTION=$(cat "$DESC_FILE")
fi

if [[ -z "$DESCRIPTION" && -z "$SUMMARY" ]]; then
  echo "Error: Nothing to update. Provide --desc, --desc-file, or --summary."
  echo "Usage: $0 [TICKET-KEY] [--desc-file FILE | --desc \"text\"] [--summary \"text\"]"
  exit 1
fi

ADF_BUILDER="$SCRIPT_DIR/build-adf.py"

echo "Updating $TICKET_KEY..."

PAYLOAD=$(DESCRIPTION="$DESCRIPTION" SUMMARY="$SUMMARY" python3 -c "
import json, os, subprocess, sys

description = os.environ['DESCRIPTION']
summary = os.environ['SUMMARY']

fields = {}

if summary:
    fields['summary'] = summary

if description:
    adf_builder = '$ADF_BUILDER'
    result = subprocess.run(
        ['python3', adf_builder, 'description'],
        input=description, capture_output=True, text=True
    )
    if result.returncode != 0:
        print('Error building ADF: ' + result.stderr, file=sys.stderr)
        sys.exit(1)
    wrapper = json.loads(result.stdout)
    fields['description'] = wrapper['description']

print(json.dumps({'fields': fields}))
")

RESULT=$(jira_api PUT "issue/$TICKET_KEY" "$PAYLOAD")

# PUT /issue returns 204 No Content on success (empty body)
if [[ -z "$RESULT" ]]; then
  echo "Updated $TICKET_KEY successfully."
  [[ -n "$SUMMARY" ]] && echo "  Summary: $SUMMARY"
  [[ -n "$DESCRIPTION" ]] && echo "  Description: updated"
else
  # Check if it's an error response
  if echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'errors' in d or 'errorMessages' in d else 1)" 2>/dev/null; then
    echo "Error updating ticket:"
    echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"
    exit 1
  else
    echo "Updated $TICKET_KEY successfully."
  fi
fi

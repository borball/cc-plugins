#!/usr/bin/env bash
# Create a new Jira ticket.
# Usage: ./jira-create.sh "Summary" ["Description"] [options]
#   --type Task|Story|Bug|Sub-task   Issue type (default: Task, or JIRA_DEFAULT_TYPE)
#   --parent PROJ-123                Parent ticket (default: JIRA_DEFAULT_PARENT)
#   --desc-file FILE                 Read description from a markdown file

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-common.sh"

SUMMARY=""
DESCRIPTION=""
DESC_FILE=""
ISSUE_TYPE="${JIRA_DEFAULT_TYPE:-Task}"
PARENT="${JIRA_DEFAULT_PARENT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      ISSUE_TYPE="$2"
      shift 2
      ;;
    --parent)
      PARENT="$2"
      shift 2
      ;;
    --desc-file)
      DESC_FILE="$2"
      shift 2
      ;;
    *)
      if [[ -z "$SUMMARY" ]]; then
        SUMMARY="$1"
      elif [[ -z "$DESCRIPTION" ]]; then
        DESCRIPTION="$1"
      fi
      shift
      ;;
  esac
done

# If desc-file provided, read it
if [[ -n "$DESC_FILE" && -f "$DESC_FILE" ]]; then
  DESCRIPTION=$(cat "$DESC_FILE")
fi

if [[ -z "$SUMMARY" ]]; then
  echo "Error: Summary is required."
  echo "Usage: $0 \"Ticket summary\" [\"Description\"] [--type Type] [--parent KEY]"
  exit 1
fi

echo "Creating ticket in $JIRA_PROJECT_KEY..."
[[ -n "$PARENT" ]] && echo "  Parent: $PARENT"

ADF_BUILDER="$SCRIPT_DIR/build-adf.py"

# Build description ADF via build-adf.py (handles markdown formatting)
DESC_ADF=$(echo "$DESCRIPTION" | python3 "$ADF_BUILDER" "description")
# Extract just the ADF doc from the wrapper
DESC_DOC=$(echo "$DESC_ADF" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin)['description']))")

PAYLOAD=$(SUMMARY="$SUMMARY" PROJECT_KEY="$JIRA_PROJECT_KEY" \
  ISSUE_TYPE="$ISSUE_TYPE" PARENT="$PARENT" DESC_DOC="$DESC_DOC" python3 -c "
import json, os

summary = os.environ['SUMMARY']
project_key = os.environ['PROJECT_KEY']
issue_type = os.environ['ISSUE_TYPE']
parent = os.environ['PARENT']
desc_doc = json.loads(os.environ['DESC_DOC'])

payload = {
    'fields': {
        'project': {'key': project_key},
        'summary': summary,
        'issuetype': {'name': issue_type},
        'description': desc_doc
    }
}

if parent:
    payload['fields']['parent'] = {'key': parent}

print(json.dumps(payload))
")

RESULT=$(jira_api POST "issue" "$PAYLOAD")

if echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'key' in d else 1)" 2>/dev/null; then
  NEW_KEY=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['key'])")
  # Auto-assign to current user
  ACCOUNT_ID=$(jira_api GET "myself" | python3 -c "import sys,json; print(json.load(sys.stdin)['accountId'])")
  jira_api PUT "issue/$NEW_KEY/assignee" "{\"accountId\":\"$ACCOUNT_ID\"}" > /dev/null 2>&1 || true
  echo "Created: $NEW_KEY — $SUMMARY"
  echo "$NEW_KEY"
else
  echo "Error creating ticket:"
  echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"
  exit 1
fi

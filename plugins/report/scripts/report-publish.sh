#!/usr/bin/env bash
# report-publish.sh — Publish an HTML report to Confluence
# Usage: report-publish.sh <input.html> [space_id] [title]
# Requires: Jira/Atlassian credentials from jira plugin

set -euo pipefail

INPUT="${1:?Usage: report-publish.sh <input.html|input.xml> [space_id] [parent_id] [title]}"
SPACE_ID="${2:-}"
PARENT_ID="${3:-}"
TITLE="${4:-}"

if [[ ! -f "$INPUT" ]]; then
  echo "ERROR: File not found: $INPUT" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load Jira/Atlassian credentials
JIRA_ENV=""
for env_file in "$PWD/.env.jira" ~/.claude/plugins/data/jira-*/.env; do
  if [[ -f "$env_file" ]]; then
    JIRA_ENV="$env_file"
    break
  fi
done

if [[ -z "$JIRA_ENV" ]]; then
  echo "ERROR: Jira credentials not found. Run /jira init first." >&2
  exit 1
fi

set -a
source "$JIRA_ENV"
set +a

JIRA_URL="${JIRA_URL%/}"
WIKI_URL="${JIRA_URL}/wiki"

# Auto-detect personal space if not provided
if [[ -z "$SPACE_ID" ]]; then
  SPACE_ID=$(curl -s -S -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
    "${WIKI_URL}/api/v2/spaces?type=personal&limit=50" 2>/dev/null | \
    jq -r --arg user "$JIRA_USERNAME" '.results[] | select(.name | test("(?i)borball|bzhai")) | .id' | head -1)

  if [[ -z "$SPACE_ID" ]]; then
    echo "ERROR: Could not find personal space. Provide space_id as second argument." >&2
    echo "Find your space ID: curl -u user:token '${WIKI_URL}/api/v2/spaces?type=personal'" >&2
    exit 1
  fi
  echo "Using personal space (ID: $SPACE_ID)" >&2
fi

# Auto-detect "Weekly Report" folder if parent not provided
if [[ -z "$PARENT_ID" ]]; then
  # Look for a folder named "Weekly Report" in the space
  PARENT_ID=$(curl -s -S -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
    "${WIKI_URL}/api/v2/spaces/${SPACE_ID}/pages?title=Weekly%20Report&limit=5" 2>/dev/null | \
    jq -r '.results[0].id // empty')

  # Also check folders
  if [[ -z "$PARENT_ID" ]]; then
    PARENT_ID=$(curl -s -S -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
      "${WIKI_URL}/api/v2/spaces/${SPACE_ID}/folders?title=Weekly%20Report&limit=5" 2>/dev/null | \
      jq -r '.results[0].id // empty' 2>/dev/null)
  fi

  if [[ -n "$PARENT_ID" ]]; then
    echo "Publishing under 'Weekly Report' folder (ID: $PARENT_ID)" >&2
  fi
fi

# Auto-generate title from filename if not provided
if [[ -z "$TITLE" ]]; then
  basename_no_ext=$(basename "$INPUT" .html)
  TITLE=$(echo "$basename_no_ext" | sed 's/report-/Activity Report: /; s/-to-/ to /; s/-/\//g' | sed 's/Activity Report: /Activity Report: /')
  # Clean up: extract dates and format nicely
  TITLE=$(echo "$basename_no_ext" | sed -E 's/report-([0-9]{4})-([0-9]{2})-([0-9]{2})-to-([0-9]{4})-([0-9]{2})-([0-9]{2})/Activity Report: \1-\2-\3 to \4-\5-\6/')
fi

# Get body content — if XML (Confluence format), use as-is; if HTML, extract body
if [[ "$INPUT" == *.xml ]]; then
  BODY=$(cat "$INPUT")
else
  BODY=$(sed -n '/<body>/,/<\/body>/p' "$INPUT" | sed '1s/.*<body>//' | sed '$s/<\/body>.*//')
fi

# Create the page via Confluence v2 API
if [[ -n "$PARENT_ID" ]]; then
  PAYLOAD=$(jq -n \
    --arg spaceId "$SPACE_ID" \
    --arg parentId "$PARENT_ID" \
    --arg title "$TITLE" \
    --arg body "$BODY" \
    '{
      spaceId: $spaceId,
      status: "current",
      title: $title,
      parentId: $parentId,
      body: {
        representation: "storage",
        value: $body
      }
    }')
else
  PAYLOAD=$(jq -n \
    --arg spaceId "$SPACE_ID" \
    --arg title "$TITLE" \
    --arg body "$BODY" \
    '{
      spaceId: $spaceId,
      status: "current",
      title: $title,
      body: {
        representation: "storage",
        value: $body
      }
    }')
fi

response=$(curl -s -S -X POST \
  -H "Content-Type: application/json" \
  -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  "${WIKI_URL}/api/v2/pages" \
  -d "$PAYLOAD" 2>/dev/null)

# Check result
page_id=$(echo "$response" | jq -r '.id // empty')
if [[ -n "$page_id" ]]; then
  page_webui=$(echo "$response" | jq -r '._links.webui // empty')
  page_url="${WIKI_URL}${page_webui}"
  echo "Published: $TITLE"
  echo "URL: $page_url"
else
  error=$(echo "$response" | jq -r '.message // .errors // "Unknown error"' 2>/dev/null)
  echo "ERROR: Failed to publish: $error" >&2
  exit 1
fi

#!/usr/bin/env bash
# Shared Jira API helpers — sourced by other scripts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# Persistent data directory (survives plugin updates)
JIRA_DATA_DIR="${CLAUDE_PLUGIN_DATA:-${PLUGIN_DIR}}"

# Load .env: local project override > plugin data dir
# Priority: ./.env.jira > JIRA_DATA_DIR/.env
if [[ -f "./.env.jira" ]]; then
  set -a
  source "./.env.jira"
  set +a
elif [[ -f "$JIRA_DATA_DIR/.env" ]]; then
  set -a
  source "$JIRA_DATA_DIR/.env"
  set +a
fi

# Validate required env vars
: "${JIRA_URL:?Set JIRA_URL in .env or .env.jira}"
: "${JIRA_USERNAME:?Set JIRA_USERNAME in .env or .env.jira}"
: "${JIRA_API_TOKEN:?Set JIRA_API_TOKEN in .env or .env.jira}"
: "${JIRA_PROJECT_KEY:?Set JIRA_PROJECT_KEY in .env or .env.jira}"

# Strip trailing slash from base URL
JIRA_URL="${JIRA_URL%/}"

# Task file: use local project dir if .env.jira exists, otherwise data dir
if [[ -f "./.env.jira" ]]; then
  CURRENT_TASK_FILE="./.current-task.json"
else
  CURRENT_TASK_FILE="$JIRA_DATA_DIR/.current-task.json"
fi

jira_api() {
  local method="$1"
  local endpoint="$2"
  shift 2
  local data="${1:-}"

  local args=(
    -s -S
    -X "$method"
    -H "Content-Type: application/json"
    -u "$JIRA_USERNAME:$JIRA_API_TOKEN"
  )

  if [[ -n "$data" ]]; then
    args+=(-d "$data")
  fi

  curl "${args[@]}" "$JIRA_URL/rest/api/3/$endpoint"
}

get_current_task() {
  if [[ -f "$CURRENT_TASK_FILE" ]]; then
    cat "$CURRENT_TASK_FILE"
  else
    echo ""
  fi
}

set_current_task() {
  local key="$1"
  local summary="$2"
  local status="$3"

  cat > "$CURRENT_TASK_FILE" <<EOF
{
  "key": "$key",
  "summary": "$summary",
  "status": "$status",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%S.000+0000)",
  "working_dir": "$(pwd)"
}
EOF
}

clear_current_task() {
  rm -f "$CURRENT_TASK_FILE"
}

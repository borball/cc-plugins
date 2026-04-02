#!/usr/bin/env bash
# Interactive setup for Jira credentials.
# Usage: ./scripts/jira-init.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Persistent data directory (survives plugin updates)
JIRA_DATA_DIR="${CLAUDE_PLUGIN_DATA:-${PROJECT_ROOT}}"
mkdir -p "$JIRA_DATA_DIR"
ENV_FILE="$JIRA_DATA_DIR/.env"

echo "Claude-Code-Jira Setup"
echo "═════════════════════════════════════════════"
echo ""

if [[ -f "$ENV_FILE" ]]; then
  echo "Existing .env file found."
  read -rp "Overwrite? (y/N): " OVERWRITE
  if [[ "${OVERWRITE,,}" != "y" ]]; then
    echo "Keeping existing config. Done."
    exit 0
  fi
  echo ""
fi

echo "Create an API token at:"
echo "  https://id.atlassian.com/manage-profile/security/api-tokens"
echo ""

read -rp "Jira URL (e.g. https://mycompany.atlassian.net): " JIRA_URL
read -rp "Jira Username (email): " JIRA_USERNAME
read -rp "Jira API Token: " JIRA_API_TOKEN
read -rp "Jira Project Key (e.g. PROJ, ENG): " JIRA_PROJECT_KEY

cat > "$ENV_FILE" <<EOF
JIRA_URL=$JIRA_URL
JIRA_USERNAME=$JIRA_USERNAME
JIRA_API_TOKEN=$JIRA_API_TOKEN
JIRA_PROJECT_KEY=$JIRA_PROJECT_KEY
JIRA_JQL_FILTER="assignee = currentUser() AND status != Done ORDER BY updated DESC"
EOF

echo ""
echo "Config saved to .env"
echo ""
echo "Testing connection..."
echo ""

if "$SCRIPT_DIR/jira-pick.sh" 2>&1; then
  echo ""
  echo "Setup complete! You can now use:"
  echo "  /jira start       — pick a ticket and start working"
  echo "  /jira start KEY   — start a specific ticket"
else
  echo ""
  echo "Connection failed. Check your credentials:"
  echo "  - Is the URL correct? (include https://)"
  echo "  - Is the email the one you log into Jira with?"
  echo "  - Is the API token valid? (not your password)"
  echo ""
  echo "Edit .env to fix, then run this again."
fi

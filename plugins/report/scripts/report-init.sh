#!/usr/bin/env bash
# report-init.sh — Initialize report plugin configuration
# Usage: report-init.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

REPORT_DATA_DIR="${CLAUDE_PLUGIN_DATA:-${PLUGIN_DIR}}"

echo "Report Plugin Setup"
echo "==================="
echo ""

ENV_FILE="$REPORT_DATA_DIR/.env"

# Read inputs from arguments
REPOS="${1:-}"
GIT_AUTHOR="${2:-}"
REPORT_AUTHOR="${3:-}"
REPORT_ROLE="${4:-}"

if [[ -z "$REPOS" ]]; then
  echo "Error: REPORT_REPOS is required."
  echo "Usage: report-init.sh <repos> [git_author]"
  echo ""
  echo "  repos: comma-separated paths to git repos or parent directories"
  echo "  git_author: git author email for filtering commits (auto-detected if omitted)"
  echo ""
  echo "Example:"
  echo "  report-init.sh ~/workspace"
  echo "  report-init.sh ~/project-a,~/project-b user@example.com"
  exit 1
fi

if [[ -z "$GIT_AUTHOR" ]]; then
  # Try to detect from git config
  GIT_AUTHOR=$(git config --global user.email 2>/dev/null || echo "")
  if [[ -z "$GIT_AUTHOR" ]]; then
    echo "Error: Could not detect git author email. Provide it as second argument."
    exit 1
  fi
  echo "Detected git author: $GIT_AUTHOR"
fi

cat > "$ENV_FILE" <<EOF
# Report Plugin Configuration
# Generated: $(date '+%Y-%m-%d %H:%M:%S')

# Repos to scan — comma-separated paths
# Each path can be a git repo or a parent directory containing repos
REPORT_REPOS=$REPOS

# Git author email (for filtering commits)
REPORT_GIT_AUTHOR=$GIT_AUTHOR

# Author name and role (shown in report header)
REPORT_AUTHOR=${REPORT_AUTHOR:-$GIT_AUTHOR}
REPORT_ROLE=$REPORT_ROLE
EOF

echo ""
echo "Config saved to: $ENV_FILE"
echo "  - Repos: $REPOS"
echo "  - Git author: $GIT_AUTHOR"

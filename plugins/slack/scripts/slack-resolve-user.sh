#!/usr/bin/env bash
# slack-resolve-user.sh — Resolve a Slack user ID to display name
# Usage: slack-resolve-user.sh <user_id>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/slack-common.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: slack-resolve-user.sh <user_id>" >&2
  exit 1
fi

load_config
resolve_user "$1"

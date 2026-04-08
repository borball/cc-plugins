#!/usr/bin/env bash
# report-status.sh — Show current report plugin configuration

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/report-common.sh"

load_config

echo "Report Plugin Status"
echo "===================="
echo ""
echo "Config: $REPORT_CONFIG_SOURCE"
echo "Git author: $REPORT_GIT_AUTHOR"
echo ""
echo "Configured repos: $REPORT_REPOS"
echo ""

# Discover and list repos
echo "Discovered repositories:"
repos=$(discover_repos)
if [[ -z "$repos" ]]; then
  echo "  (none found)"
else
  while IFS= read -r repo; do
    repo_name=$(basename "$repo")
    remote=$(cd "$repo" && git remote get-url origin 2>/dev/null || echo "local")
    branch=$(cd "$repo" && git branch --show-current 2>/dev/null || echo "unknown")
    echo "  - $repo_name ($branch) [$remote]"
  done <<< "$repos"
fi

echo ""

# Check Jira plugin
jira_found=false
for d in ~/.claude/plugins/cache/*/jira/*/scripts/ \
         ~/.claude/plugins/marketplaces/*/plugins/jira/scripts/; do
  if [[ -f "${d}jira-common.sh" ]]; then
    jira_found=true
    break
  fi
done

if [[ "$jira_found" == true ]]; then
  # Check if configured
  if [[ -f "$PWD/.env.jira" ]]; then
    echo "Jira plugin: configured (project override)"
  else
    jira_env=""
    for d in ~/.claude/plugins/data/jira-*/; do
      if [[ -f "$d/.env" ]]; then
        jira_env="$d/.env"
        break
      fi
    done
    if [[ -n "$jira_env" ]]; then
      echo "Jira plugin: configured ($jira_env)"
    else
      echo "Jira plugin: installed but not configured (run: /jira init)"
    fi
  fi
else
  echo "Jira plugin: not installed (Jira data will be skipped)"
fi

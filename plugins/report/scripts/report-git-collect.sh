#!/usr/bin/env bash
# report-git-collect.sh — Collect git activity across repos
# Usage: report-git-collect.sh <since> <until>
# Output: JSON array of commit records

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/report-common.sh"

load_config

SINCE="${1:?Usage: report-git-collect.sh <since> <until>}"
UNTIL="${2:?Usage: report-git-collect.sh <since> <until>}"

repos=$(discover_repos)

if [[ -z "$repos" ]]; then
  echo "[]"
  exit 0
fi

all_commits="[]"

while IFS= read -r repo; do
  repo_name=$(basename "$repo")

  # Get remote URL, convert git@ to https
  remote_url=$(cd "$repo" && git remote get-url origin 2>/dev/null || echo "")
  remote_url=$(echo "$remote_url" | sed -E 's#^git@([^:]+):#https://\1/#; s#\.git$##')

  # Get commits in date range by this author
  # Use tab delimiter to safely handle special characters in subjects
  commits=$(cd "$repo" && git log \
    --author="$REPORT_GIT_AUTHOR" \
    --since="$SINCE" \
    --until="$UNTIL" \
    --format=$'%h\t%ad\t%s' \
    --date=format:'%Y-%m-%d' \
    --no-merges 2>/dev/null || echo "")

  if [[ -z "$commits" ]]; then
    continue
  fi

  # Convert to JSON safely using jq for proper escaping
  repo_commits=$(echo "$commits" | while IFS=$'\t' read -r hash date subject; do
    jq -n --arg h "$hash" --arg d "$date" --arg s "$subject" --arg r "$repo_name" --arg u "$remote_url" \
      '{hash: $h, date: $d, subject: $s, repo: $r, url: $u}'
  done | jq -s '.')
  all_commits=$(echo "$all_commits $repo_commits" | jq -s 'add')
done <<< "$repos"

# Sort by date descending
echo "$all_commits" | jq 'sort_by(.date) | reverse'

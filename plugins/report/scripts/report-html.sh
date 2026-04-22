#!/usr/bin/env bash
# report-html.sh — Generate a compact styled HTML report from git and Jira JSON data
# Usage: report-html.sh <output.html> <since> <until> <git.json> [jira.json] [jira_url] [author] [min_commits] [highlights] [summary_file]

set -euo pipefail

OUTPUT="${1:?Usage: report-html.sh <output.html> <since> <until> <git.json> [jira.json] [jira_url] [author] [min_commits] [highlights] [summary_file]}"
SINCE="${2:?}"
UNTIL="${3:?}"
GIT_JSON="${4:?}"
JIRA_JSON="${5:-}"
JIRA_URL="${6:-}"
AUTHOR="${7:-}"
MIN_COMMITS="${8:-3}"
HIGHLIGHTS="${9:-3}"
SUMMARY_FILE="${10:-}"

# ── HTML escaping ─────────────────────────────────────────────────
html_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  echo "$s"
}

# Auto-detect Jira URL from jira plugin if not provided
if [[ -z "$JIRA_URL" && -n "$JIRA_JSON" ]]; then
  for env_file in "$PWD/.env.jira" ~/.claude/plugins/data/jira-*/.env; do
    if [[ -f "$env_file" ]]; then
      JIRA_URL=$(grep -E '^JIRA_URL=' "$env_file" | head -1 | cut -d= -f2-)
      break
    fi
  done
fi
JIRA_URL="${JIRA_URL%/}"

if [[ -n "$JIRA_URL" && ! "$JIRA_URL" =~ ^https?:// ]]; then
  JIRA_URL=""
fi

if [[ -z "$AUTHOR" ]]; then
  AUTHOR=$(git config --global user.name 2>/dev/null || echo "")
fi

# ── Build Jira table rows ────────────────────────────────────────
jira_html=""
ticket_count=0
if [[ -n "$JIRA_JSON" && -f "$JIRA_JSON" ]]; then
  # Deduplicate by summary, map status to badge class
  jira_rows_json=$(jq -r '
    (if .issues then
      [.issues[] | {key: .key, summary: .fields.summary, status_key: .fields.status.statusCategory.key, status_name: .fields.status.name}]
    elif type == "array" then .
    else [] end) |
    # Deduplicate by summary
    reduce .[] as $t ([]; if [.[] | select(.summary == $t.summary)] | length == 0 then . + [$t] else . end)
  ' "$JIRA_JSON" 2>/dev/null)

  ticket_count=$(echo "$jira_rows_json" | jq 'length')

  if [[ "$ticket_count" -gt 0 ]]; then
    jira_rows=""
    idx=0
    while IFS= read -r row; do
      key=$(echo "$row" | jq -r '.key')
      summary=$(html_escape "$(echo "$row" | jq -r '.summary')")
      status_key=$(echo "$row" | jq -r '.status_key')

      case "$status_key" in
        done)          badge_cls="done"; badge_txt="Done" ;;
        indeterminate) badge_cls="wip";  badge_txt="WIP" ;;
        *)             badge_cls="new";  badge_txt="New" ;;
      esac

      hl=""
      if [[ $idx -lt $HIGHLIGHTS ]]; then
        hl=' class="hl"'
      fi

      if [[ -n "$JIRA_URL" ]]; then
        key_cell="<a href=\"${JIRA_URL}/browse/${key}\">${key}</a>"
      else
        key_cell="${key}"
      fi

      jira_rows+="<tr${hl}><td>${key_cell}</td><td class=\"s\"><span class=\"badge ${badge_cls}\">${badge_txt}</span></td><td>${summary}</td></tr>
"
      idx=$((idx + 1))
    done < <(echo "$jira_rows_json" | jq -c '.[]')

    jira_html="
<h2>Jira</h2>
<table>
<tr><th>Ticket</th><th class=\"s\"></th><th>Summary</th></tr>
${jira_rows}</table>"
  fi
fi

# ── Build Git table rows ─────────────────────────────────────────
git_html=""
total_commits=0
repo_count=0
if [[ -f "$GIT_JSON" ]]; then
  # Group by repo, filter by min commits, sort by count desc
  git_repos_json=$(jq --argjson min "$MIN_COMMITS" '
    group_by(.repo) |
    [.[] | {
      repo: .[0].repo,
      url: .[0].url,
      count: length,
      subjects: [.[].subject] | unique | .[0:3]
    }] |
    [.[] | select(.count >= $min)] |
    sort_by(-.count)
  ' "$GIT_JSON" 2>/dev/null)

  total_commits=$(jq 'length' "$GIT_JSON" 2>/dev/null || echo 0)
  repo_count=$(echo "$git_repos_json" | jq 'length')

  if [[ "$repo_count" -gt 0 ]]; then
    git_rows=""
    idx=0
    while IFS= read -r row; do
      repo_name=$(html_escape "$(echo "$row" | jq -r '.repo')")
      url=$(echo "$row" | jq -r '.url')
      count=$(echo "$row" | jq -r '.count')
      highlights_text=$(html_escape "$(echo "$row" | jq -r '.subjects | join(", ")')")

      hl=""
      if [[ $idx -lt $HIGHLIGHTS ]]; then
        hl=' class="hl"'
      fi

      git_rows+="<tr${hl}><td class=\"repo\">${repo_name}</td><td class=\"commits\">${count}</td><td>${highlights_text}</td></tr>
"
      idx=$((idx + 1))
    done < <(echo "$git_repos_json" | jq -c '.[]')

    git_html="
<h2>Git Activity</h2>
<table>
<tr><th>Repository</th><th class=\"commits\">#</th><th>Highlights</th></tr>
${git_rows}</table>"
  fi
fi

# ── Build Summary ────────────────────────────────────────────────
summary_html=""
if [[ -n "$SUMMARY_FILE" && -f "$SUMMARY_FILE" ]]; then
  summary_text=$(html_escape "$(cat "$SUMMARY_FILE")")
  summary_html="
<h2>Summary</h2>
<div class=\"summary\">${summary_text}</div>"
fi

# ── Format dates for display ─────────────────────────────────────
since_display=$(date -j -f "%Y-%m-%d" "$SINCE" "+%b %-d" 2>/dev/null || date -d "$SINCE" "+%b %-d" 2>/dev/null || echo "$SINCE")
until_display=$(date -j -f "%Y-%m-%d" "$UNTIL" "+%b %-d, %Y" 2>/dev/null || date -d "$UNTIL" "+%b %-d, %Y" 2>/dev/null || echo "$UNTIL")
author_escaped=$(html_escape "$AUTHOR")

# ── Write HTML ────────────────────────────────────────────────────
cat > "$OUTPUT" << HTMLEOF
<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Activity Report: ${SINCE} — ${UNTIL}</title><style>
*{margin:0;padding:0;box-sizing:border-box}body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:#f5f5f5;color:#1a1a1a;padding:24px;max-width:960px;margin:0 auto;font-size:14px;line-height:1.5}
h1{font-size:20px;margin-bottom:4px;color:#1a1a1a}h2{font-size:15px;margin:20px 0 8px;color:#555;text-transform:uppercase;letter-spacing:.5px;border-bottom:2px solid #e0e0e0;padding-bottom:4px}
.meta{color:#888;font-size:12px;margin-bottom:16px}.summary{background:#fff;border-left:3px solid #0066cc;padding:12px 16px;margin-bottom:8px;border-radius:0 4px 4px 0;font-size:13px;color:#333}
table{width:100%;border-collapse:collapse;background:#fff;border-radius:6px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,.08);margin-bottom:8px}
th{background:#f8f9fa;text-align:left;padding:8px 12px;font-size:11px;text-transform:uppercase;letter-spacing:.5px;color:#666;border-bottom:2px solid #e0e0e0}
td{padding:6px 12px;border-bottom:1px solid #f0f0f0;font-size:13px}tr:last-child td{border-bottom:none}tr:hover{background:#f8f9fb}
.s{text-align:center;width:32px}a{color:#0066cc;text-decoration:none}a:hover{text-decoration:underline}
.badge{display:inline-block;padding:1px 8px;border-radius:10px;font-size:11px;font-weight:600}
.done{background:#e6f4ea;color:#1e7e34}.wip{background:#fff3cd;color:#856404}.new{background:#e2e3e5;color:#495057}
.commits{text-align:center;width:60px;font-weight:600;color:#0066cc}.repo{white-space:nowrap}
tr.hl{background:#fffbe6}tr.hl td:first-child{border-left:3px solid #f0c040}tr.hl:hover{background:#fff8d6}
</style></head><body>
<h1>Activity Report</h1>
<div class="meta">${since_display} — ${until_display} · ${author_escaped} · ${total_commits} commits · ${ticket_count} tickets</div>
${summary_html}
${jira_html}
${git_html}
</body></html>
HTMLEOF

echo "Generated: $OUTPUT"

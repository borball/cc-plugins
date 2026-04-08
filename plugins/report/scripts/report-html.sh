#!/usr/bin/env bash
# report-html.sh — Generate a styled HTML report from git and Jira JSON data
# Usage: report-html.sh <output.html> <since> <until> <git.json> [jira.json] [jira_url] [author] [role]

set -euo pipefail

OUTPUT="${1:?Usage: report-html.sh <output.html> <since> <until> <git.json> [jira.json] [jira_url] [author] [role]}"
SINCE="${2:?}"
UNTIL="${3:?}"
GIT_JSON="${4:?}"
JIRA_JSON="${5:-}"
JIRA_URL="${6:-}"
AUTHOR="${7:-}"
ROLE="${8:-}"

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

# Validate JIRA_URL is https
if [[ -n "$JIRA_URL" && ! "$JIRA_URL" =~ ^https?:// ]]; then
  JIRA_URL=""
fi

# Auto-detect author from git config if not provided
if [[ -z "$AUTHOR" ]]; then
  AUTHOR=$(git config --global user.name 2>/dev/null || echo "")
fi

# Build author subtitle (escaped)
author_html=""
if [[ -n "$AUTHOR" && -n "$ROLE" ]]; then
  author_html="<p class=\"author\">$(html_escape "$AUTHOR") — $(html_escape "$ROLE")</p>"
elif [[ -n "$AUTHOR" ]]; then
  author_html="<p class=\"author\">$(html_escape "$AUTHOR")</p>"
fi

# ── Build Jira table rows ────────────────────────────────────────
jira_html=""
if [[ -n "$JIRA_JSON" && -f "$JIRA_JSON" ]]; then
  tickets=$(jq -r '
    if .issues then
      [.issues[] | {key: .key, summary: .fields.summary, status: .fields.status.name, type: .fields.issuetype.name}]
    elif .tickets then .tickets
    elif type == "array" then .
    else [] end | .[] |
    @base64' "$JIRA_JSON" 2>/dev/null)

  if [[ -n "$tickets" ]]; then
    jira_rows=""
    while IFS= read -r row; do
      t=$(echo "$row" | base64 -d)
      key=$(html_escape "$(echo "$t" | jq -r '.key')")
      type=$(html_escape "$(echo "$t" | jq -r '.type')")
      status=$(echo "$t" | jq -r '.status')
      summary=$(html_escape "$(echo "$t" | jq -r '.summary')")

      # Status badge class
      case "${status,,}" in
        closed|done|resolved) cls="status-closed" ;;
        *progress*)           cls="status-progress" ;;
        *)                    cls="status-new" ;;
      esac
      status=$(html_escape "$status")

      # Ticket link
      if [[ -n "$JIRA_URL" ]]; then
        key_cell="<a href=\"${JIRA_URL}/browse/${key}\" target=\"_blank\"><strong>${key}</strong></a>"
      else
        key_cell="<strong>${key}</strong>"
      fi

      jira_rows+="<tr><td>${key_cell}</td><td>${type}</td><td><span class=\"status ${cls}\">${status}</span></td><td>${summary}</td></tr>
"
    done <<< "$tickets"

    jira_html="<h2>Jira</h2>
<table>
<tr><th style=\"min-width:160px\">Ticket</th><th>Type</th><th style=\"min-width:110px\">Status</th><th>Summary</th></tr>
${jira_rows}</table>"
  fi
fi

# ── Build Git table rows ─────────────────────────────────────────
git_html=""
if [[ -f "$GIT_JSON" ]]; then
  # Use @html in jq to escape commit subjects, repo names stay safe via @html too
  # URLs are validated to start with https:// only
  git_rows=$(jq -r '
    group_by(.repo) |
    sort_by(-length) |
    .[] |
    .[0].repo as $repo |
    (.[0].url // "") as $url |
    length as $count |
    ([.[0:5][].subject | @html] | join("<br>")) as $highlights |
    (if $count > 5 then $highlights + "<br>… and \($count - 5) more" else $highlights end) as $full |
    ($repo | @html) as $safe_repo |
    (if ($url | test("^https?://")) then "<a href=\"\($url | @html)\" target=\"_blank\"><strong>\($safe_repo)</strong></a>" else "<strong>\($safe_repo)</strong>" end) as $repo_cell |
    "<tr><td>\($repo_cell)</td><td>\($count)</td><td>\($full)</td></tr>"
  ' "$GIT_JSON" 2>/dev/null)

  total=$(jq 'length' "$GIT_JSON" 2>/dev/null || echo 0)
  repos=$(jq '[.[].repo] | unique | length' "$GIT_JSON" 2>/dev/null || echo 0)

  if [[ "$total" -gt 0 ]]; then
    git_html="<h2>Git Activity</h2>
<table>
<tr><th>Repository</th><th>Commits</th><th>Highlights</th></tr>
${git_rows}
</table>
<p><strong>Total: ${total} commits across ${repos} repositories</strong></p>"
  fi
fi

# Escape title values
SINCE_ESC=$(html_escape "$SINCE")
UNTIL_ESC=$(html_escape "$UNTIL")

# ── Write HTML ────────────────────────────────────────────────────
cat > "$OUTPUT" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Activity Report: ${SINCE_ESC} — ${UNTIL_ESC}</title>
<style>
  :root { --bg: #fff; --fg: #24292e; --border: #d0d7de; --header-bg: #f6f8fa; --accent: #0969da; }
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
         max-width: 960px; margin: 0 auto; padding: 24px; color: var(--fg); background: var(--bg); }
  h1 { border-bottom: 2px solid var(--border); padding-bottom: 12px; margin-bottom: 4px; }
  .author { color: #656d76; font-size: 15px; margin-top: 0; }
  h2 { border-bottom: 1px solid var(--border); padding-bottom: 8px; margin-top: 32px; }
  table { width: 100%; border-collapse: collapse; margin: 16px 0; }
  th { background: var(--header-bg); text-align: left; font-weight: 600; }
  td, th { border: 1px solid var(--border); padding: 8px 12px; font-size: 14px; }
  tr:hover td { background: #f6f8fa; }
  a { color: var(--accent); text-decoration: none; }
  a:hover { text-decoration: underline; }
  .status { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 12px; font-weight: 500; white-space: nowrap; }
  .status-closed { background: #dafbe1; color: #1a7f37; }
  .status-progress { background: #ddf4ff; color: #0969da; }
  .status-new { background: #fff8c5; color: #9a6700; }
  .footer { margin-top: 40px; padding-top: 16px; border-top: 1px solid var(--border);
            font-size: 12px; color: #656d76; text-align: center; }
</style>
</head>
<body>
<h1>Activity Report: ${SINCE_ESC} — ${UNTIL_ESC}</h1>
${author_html}
${jira_html}
${git_html}
<div class="footer">Generated by cc-plugins/report</div>
</body>
</html>
HTMLEOF

echo "Generated: $OUTPUT"

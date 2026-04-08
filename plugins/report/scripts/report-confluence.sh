#!/usr/bin/env bash
# report-confluence.sh — Generate Confluence storage format from git and Jira JSON data
# Usage: report-confluence.sh <output.xml> <since> <until> <git.json> [jira.json] [jira_url] [author] [role]
# Output: Confluence storage format XML suitable for the v2 API

set -euo pipefail

OUTPUT="${1:?Usage: report-confluence.sh <output.xml> <since> <until> <git.json> [jira.json] [jira_url] [author] [role]}"
SINCE="${2:?}"
UNTIL="${3:?}"
GIT_JSON="${4:?}"
JIRA_JSON="${5:-}"
JIRA_URL="${6:-}"
AUTHOR="${7:-}"
ROLE="${8:-}"

html_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  echo "$s"
}

# Auto-detect Jira URL
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

# Auto-detect author
if [[ -z "$AUTHOR" ]]; then
  AUTHOR=$(git config --global user.name 2>/dev/null || echo "")
fi

# Start building body
body=""


# ── Jira section ──────────────────────────────────────────────────
if [[ -n "$JIRA_JSON" && -f "$JIRA_JSON" ]]; then
  tickets=$(jq -r '
    if .issues then
      [.issues[] | {key: .key, summary: .fields.summary, status: .fields.status.name}]
    elif .tickets then .tickets
    elif type == "array" then .
    else [] end | .[] |
    @base64' "$JIRA_JSON" 2>/dev/null)

  if [[ -n "$tickets" ]]; then
    body+="<h2>Jira</h2>"
    body+="<table data-layout=\"default\"><colgroup><col style=\"width: 20%;\" /><col style=\"width: 12%;\" /><col style=\"width: 68%;\" /></colgroup><tbody>"
    body+="<tr><th>Ticket</th><th>Status</th><th>Summary</th></tr>"

    while IFS= read -r row; do
      t=$(echo "$row" | base64 -d)
      key=$(html_escape "$(echo "$t" | jq -r '.key')")
      status=$(echo "$t" | jq -r '.status')
      summary=$(html_escape "$(echo "$t" | jq -r '.summary')")

      # Confluence status macro
      case "${status,,}" in
        closed|done|resolved) color="Green" ;;
        *progress*)           color="Blue" ;;
        *)                    color="Yellow" ;;
      esac
      status_macro="<ac:structured-macro ac:name=\"status\"><ac:parameter ac:name=\"title\">$(html_escape "$status")</ac:parameter><ac:parameter ac:name=\"colour\">${color}</ac:parameter></ac:structured-macro>"

      # Ticket link
      if [[ -n "$JIRA_URL" ]]; then
        key_cell="<a href=\"${JIRA_URL}/browse/${key}\">${key}</a>"
      else
        key_cell="${key}"
      fi

      body+="<tr><td>${key_cell}</td><td>${status_macro}</td><td>${summary}</td></tr>"
    done <<< "$tickets"

    body+="</tbody></table>"
  fi
fi

# ── Git section ───────────────────────────────────────────────────
if [[ -f "$GIT_JSON" ]]; then
  git_rows=$(jq -r '
    group_by(.repo) |
    [.[] | {data: ., latest: ([.[].date] | max)}] | sort_by(.latest) | reverse | [.[].data] |
    .[] |
    .[0].repo as $repo |
    (.[0].url // "") as $url |
    ([.[].subject] | unique) as $unique_subjects |
    ($unique_subjects | length) as $unique_count |
    ([$unique_subjects[0:5][] | @html] | join("\n")) as $highlights |
    (if $unique_count > 5 then $highlights + "\n… and \($unique_count - 5) more" else $highlights end) as $full |
    [$repo, $url, $full] | @tsv
  ' "$GIT_JSON" 2>/dev/null)

  if [[ -n "$git_rows" ]]; then
    body+="<h2>Git Activity</h2>"
    body+="<table data-layout=\"default\"><colgroup><col style=\"width: 25%;\" /><col style=\"width: 75%;\" /></colgroup><tbody>"
    body+="<tr><th>Repository</th><th>Highlights</th></tr>"

    while IFS=$'\t' read -r repo url highlights; do
      # Convert newlines to <br/>
      highlights=$(echo "$highlights" | sed 's/\\n/<br\/>/g')

      if [[ -n "$url" && "$url" =~ ^https?:// ]]; then
        repo_cell="<a href=\"$(html_escape "$url")\">$(html_escape "$repo")</a>"
      else
        repo_cell="$(html_escape "$repo")"
      fi

      body+="<tr><td><strong>${repo_cell}</strong></td><td>${highlights}</td></tr>"
    done <<< "$git_rows"

    body+="</tbody></table>"
  fi
fi

echo "$body" > "$OUTPUT"
echo "Generated: $OUTPUT"

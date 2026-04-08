---
description: "Generate an activity report for a custom time period"
---

Generate an activity report. Arguments: $ARGUMENTS

## Step-by-step flow

### Step 1: Determine date range

Parse from arguments:
- A number of days (default 7): e.g. `14` means last 14 days
- `--since YYYY-MM-DD` and/or `--until YYYY-MM-DD` for custom range
- `--format md|html` — output format (default: md)

If no dates given, default to last 7 days.

**Important:** Git's `--until` is exclusive — add one day to the until date when passing to `report-git-collect.sh`.

### Step 2: Collect git data

```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/report-git-collect.sh <since> <until+1day>
```

This returns a JSON array of commits across all configured repos (GitHub, GitLab, or any local git repos).

### Step 3: Collect Jira data (if jira plugin is available)

If the jira plugin is installed and configured, query tickets updated in the date range. Source the jira plugin's credentials from `~/.claude/plugins/data/jira-*/.env` and call:
```bash
source <jira-env-file>
curl -s -S -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/3/search/jql?jql=<encoded-jql>&fields=summary,status,issuetype,updated,created,resolutiondate"
```

JQL: `assignee = currentUser() AND updated >= "YYYY-MM-DD" AND updated <= "YYYY-MM-DD" ORDER BY updated DESC`

If the jira plugin is not installed or not configured, skip this step.

### Step 4: Format the report

Generate a concise markdown report:

```markdown
# Activity Report: {since} — {until}

## Summary

Brief 2-3 sentence overview of what was accomplished.

## Jira

| Ticket | Type | Status | Summary |
|--------|------|--------|---------|
| KEY-123 | Task | Done   | Summary |

## Git Activity

| Repository | Commits | Highlights |
|------------|---------|------------|
| repo-name  | N       | Key changes |
```

Guidelines:
- Keep it concise — summary, not changelog
- Group commits by repo with count and key highlights
- Omit sections with no data entirely
- Write a human-readable summary that captures overall themes
- Save the report as `report-{since}-to-{until}.md` in the current directory

### Step 5: Generate HTML (if requested)

If the user requests HTML format (`--format html`):

1. Save the git JSON to a temp file and optionally the Jira JSON
2. Run the HTML generator:
```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/report-html.sh <output.html> "<since display>" "<until display>" <git.json> [jira.json] [jira_url] [author] [role]
```

Parameters: jira_url is auto-detected from jira plugin config, author from git config. The HTML report uses a built-in styled template with tables and status badges.

# report — Activity report generator for Claude Code

Generate concise activity reports from git commits and Jira tickets across multiple repositories.

## IMPORTANT: Running scripts

When running any script from this plugin, always export `CLAUDE_PLUGIN_DATA` so scripts can find credentials:
```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/<script>.sh [args]
```

## Commands

- `/report` — Main command router (dispatches to subcommands)
- `/report init` — Configure repos and git author
- `/report generate [days] [--since/--until]` — Generate a report for a custom period
- `/report daily` — Yesterday's activity (standup prep)
- `/report weekly` — Last 7 days report
- `/report biweekly` — Last 14 days report
- `/report monthly` — Last 30 days report
- `/report status` — Show configuration and detected repos

## Architecture

- **`skills/`** — Skill definitions with data collection instructions
- **`scripts/`** — Shell scripts for git data collection and configuration
  - `report-common.sh` — Shared helpers: config loading, date math, repo discovery
  - `report-init.sh` — Configuration setup
  - `report-git-collect.sh` — Collect git commits across repos (outputs JSON)
  - `report-html.sh` — Generate compact styled HTML report from JSON data
  - `report-status.sh` — Show configuration and detected repos

## Data Sources

- **Git** — commits from configured repos (GitHub, GitLab, or any local repos), filtered by author
- **Jira** — tickets updated in period (via jira plugin if installed and configured)

## Cross-Plugin Dependencies

- **Jira** (optional): If the jira plugin is installed and configured (`/jira init`), Jira data is included. If not, the Jira section is skipped.

## Report Formatting Rules

Both markdown and HTML reports follow these rules:

### Jira section
- **No Type column** — only Ticket, Status, Summary
- **Linked tickets** — ticket IDs link to Jira browse URL
- **Status icons** — emoji in markdown (✅ Done, 🔄 WIP, 📋 New), colored badges in HTML
- **Deduplication** — tickets with identical summaries are shown only once

### Git section
- **Minimum commits filter** — repos below threshold (default 3) are hidden
- **Sorted by commit count** descending
- **Highlights** — top 3 commit subjects per repo

### HTML-specific
- **Compact single-file** — inline CSS, no external dependencies
- **Highlighted rows** — top N Jira tickets and git repos get a yellow accent
- **Status badges** — colored pills (green Done, yellow WIP, gray New)
- **Wide repo column** — `white-space: nowrap` prevents wrapping

### report-html.sh usage
```bash
report-html.sh <output.html> <since> <until> <git.json> [jira.json] [jira_url] [author] [min_commits] [highlights] [summary_file]
```

The `summary_file` is a plain text file containing the summary paragraph (same 2-3 sentences as in the markdown). It renders as a blue-accented box at the top of the HTML report.

## Repo Discovery

`REPORT_REPOS` accepts comma-separated paths. Each path can be:
- A git repository (has `.git/` directory) — used directly
- A parent directory — all git repos one level deep are discovered automatically

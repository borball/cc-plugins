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
- `/report monthly` — Last 30 days report
- `/report status` — Show configuration and detected repos

## Architecture

- **`skills/`** — Skill definitions with data collection instructions
- **`scripts/`** — Shell scripts for git data collection and configuration
  - `report-common.sh` — Shared helpers: config loading, date math, repo discovery
  - `report-init.sh` — Configuration setup
  - `report-git-collect.sh` — Collect git commits across repos (outputs JSON)
  - `report-html.sh` — Generate styled HTML report from JSON data
  - `report-status.sh` — Show configuration and detected repos

## Data Sources

- **Git** — commits from configured repos (GitHub, GitLab, or any local repos), filtered by author email
- **Jira** — tickets updated in period (via jira plugin if installed and configured)

## Cross-Plugin Dependencies

- **Jira** (optional): If the jira plugin is installed and configured (`/jira init`), Jira data is included. If not, the Jira section is skipped.

## Report Format

Reports can be generated in markdown or HTML format. Claude formats the collected data into concise markdown with:
- A brief summary paragraph
- Tables for git activity and Jira tickets
- Sections are omitted when empty

For HTML output, use `report-html.sh` which renders a styled report with stats cards, tables, and status badges directly from JSON data.

## Repo Discovery

`REPORT_REPOS` accepts comma-separated paths. Each path can be:
- A git repository (has `.git/` directory) — used directly
- A parent directory — all git repos one level deep are discovered automatically

# report

[Claude Code](https://claude.ai/code) plugin for generating activity reports from git and Jira.

Aggregate your work across multiple repositories into concise markdown and HTML reports — daily standups, weekly summaries, bi-weekly reviews, or custom date ranges.

## Commands

| Command | Description |
|---------|-------------|
| `/report init` | Configure repos and git author |
| `/report generate [days]` | Generate a report for a custom period |
| `/report daily` | Yesterday's activity (standup prep) |
| `/report weekly` | Last 7 days report |
| `/report biweekly` | Last 14 days report |
| `/report monthly` | Last 30 days report |
| `/report status` | Show configuration and detected repos |

## Prerequisites

- [Claude Code](https://claude.ai/code) CLI
- `jq` available on your system
- jira plugin installed and configured for Jira activity (optional, `/plugin install jira@cc-plugins`)

## Setup

```
/report init
```

Claude will ask for:
1. **Repository paths** — parent directories or individual repos (GitHub, GitLab, or any local git repos)
2. **Git author name** — auto-detected from `git config`

## Usage

### Natural language

```
> generate my weekly report
> what did I work on last week?
> give me a summary of the last 14 days
> generate a report from March 1 to March 15
> prepare my daily standup notes
```

### Slash commands

```
/report weekly
/report biweekly
/report daily
/report generate 14
/report generate --since 2026-03-01 --until 2026-03-15
/report generate 7 --format html
/report generate 14 --min-commits 5 --highlights 5
```

## Report Formatting

Reports are generated in both markdown and HTML by default.

### Jira section
- **Linked tickets** — ticket IDs link to Jira browse URL
- **Status icons** — ✅ Done, 🔄 In Progress, 📋 New (emoji in markdown, colored badges in HTML)
- **No Type column** — only Ticket, Status, Summary
- **Deduplication** — tickets with identical summaries are shown only once

### Git section
- **Minimum commits filter** — repos with fewer than N commits are hidden (default: 3)
- **Sorted by commit count** descending
- **Highlights** — top 3 commit subjects per repo

### HTML-specific
- **Compact single-file** — inline CSS, no external dependencies
- **Highlighted rows** — top N Jira tickets and git repos get a yellow accent
- **Status badges** — colored pills (green Done, yellow WIP, gray New)
- **Wide repo column** — prevents wrapping on long repo names

### Markdown example

```markdown
# Activity Report: 2026-04-08 — 2026-04-22

## Summary

Productive sprint focused on policy updates and tooling improvements.
47 commits across 7 repos, 10 Jira tickets.

## Jira

| Ticket | Status | Summary |
|--------|--------|---------|
| [PROJ-101](https://jira.example.com/browse/PROJ-101) | 🔄 | Upgrade database driver |
| [PROJ-102](https://jira.example.com/browse/PROJ-102) | ✅ | Fix connection pool timeout |

## Git Activity

| Repository | Commits | Highlights |
|------------|---------|------------|
| my-app     | 12      | API refactoring, new endpoints, auth middleware |
| infra-tools | 3      | CI pipeline updates, deploy script fix |
```

## Repo Discovery

`REPORT_REPOS` accepts comma-separated paths:

```
# Parent directory — discovers all git repos inside
REPORT_REPOS=~/Documents/github-workspace

# Individual repos
REPORT_REPOS=~/projects/myapp,~/projects/backend

# Mix of both
REPORT_REPOS=~/Documents/github-workspace,~/other-projects/special-repo
```

## Data Sources

| Source | Requirement | What it collects |
|--------|------------|------------------|
| Git | Local repos | Commits by author in date range |
| Jira | jira plugin installed & configured | Tickets updated in date range |

## Project Structure

```
report/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── report/SKILL.md        # /report (router)
│   ├── init/SKILL.md          # /report:init
│   ├── generate/SKILL.md      # /report:generate
│   ├── daily/SKILL.md         # /report:daily
│   ├── weekly/SKILL.md        # /report:weekly
│   ├── biweekly/SKILL.md      # /report:biweekly
│   ├── monthly/SKILL.md       # /report:monthly
│   └── status/SKILL.md        # /report:status
├── scripts/
│   ├── report-common.sh       # Shared helpers, config, repo discovery
│   ├── report-init.sh         # Configuration setup
│   ├── report-git-collect.sh  # Git commit collection across repos
│   ├── report-html.sh         # Compact HTML report generator
│   └── report-status.sh       # Show configuration
├── CLAUDE.md
└── README.md
```

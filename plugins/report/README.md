# report

[Claude Code](https://claude.ai/code) plugin for generating activity reports from git and Jira.

Aggregate your work across multiple repositories into concise markdown reports — daily standups, weekly summaries, or custom date ranges.

## Commands

| Command | Description |
|---------|-------------|
| `/report init` | Configure repos and git author |
| `/report generate [days]` | Generate a report for a custom period |
| `/report daily` | Yesterday's activity (standup prep) |
| `/report weekly` | Last 7 days report |
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
2. **Git author email** — auto-detected from `git config`

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
/report daily
/report generate 14
/report generate --since 2026-03-01 --until 2026-03-15
/report generate 7 --format html
```

## Report Output

Reports are formatted as concise markdown:

```markdown
# Activity Report: Mar 31 — Apr 06

## Summary

Focused on plugin development and infrastructure updates.
15 commits across 2 repos, 2 Jira tickets closed.

## Jira

| Ticket    | Type | Status      | Summary                     |
|-----------|------|-------------|------------------------------|
| PROJ-101  | Task | Done        | Upgrade database driver      |
| PROJ-102  | Bug  | In Progress | Fix connection pool timeout  |

## Git Activity

| Repository  | Commits | Highlights                          |
|-------------|---------|-------------------------------------|
| my-app      | 12      | API refactoring, new endpoints      |
| infra-tools | 3       | CI pipeline updates                 |
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
│   ├── monthly/SKILL.md       # /report:monthly
│   └── status/SKILL.md        # /report:status
├── scripts/
│   ├── report-common.sh       # Shared helpers, config, repo discovery
│   ├── report-init.sh         # Configuration setup
│   ├── report-git-collect.sh  # Git commit collection across repos
│   ├── report-html.sh         # HTML report generator
│   └── report-status.sh       # Show configuration
├── CLAUDE.md
└── README.md
```

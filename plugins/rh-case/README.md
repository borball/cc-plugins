# Red Hat Support Case Manager — Claude Code Plugin

A [Claude Code](https://claude.ai/code) standalone plugin for managing Red Hat support cases directly from your terminal.

> **Disclaimer:** This is an unofficial community tool. It is **not** a Red Hat product and is **not** supported, endorsed, or affiliated with Red Hat, Inc. It interacts with the [Red Hat Customer Portal API](https://access.redhat.com/articles/3626371) and [Red Hat SSO](https://sso.redhat.com) using publicly documented endpoints and your own credentials. Support cases may contain sensitive or confidential data — it is your responsibility to ensure this data is not exposed. Use at your own risk.

## Installation

Install from the marketplace:

```
/plugin marketplace add borball/cc-plugins
/plugin install rh-case@cc-plugins
```

Then set up your credentials:

```
/rh-case:init
```

## Commands

| Command | Description |
|---------|-------------|
| `/rh-case:init` | Set up Red Hat API credentials |
| `/rh-case:list` | List/filter support cases |
| `/rh-case:show <CASE#>` | Show case details and comments |
| `/rh-case:search <query>` | Search cases or KCS knowledge base |
| `/rh-case:analyze <CASE#>` | AI analysis with attachment inspection, KCS/Jira correlation |
| `/rh-case:comment <CASE#> <text>` | Add a comment to a case |
| `/rh-case:export <CASE#>` | Export case to markdown, optionally download attachments |
| `/rh-case:status` | Check auth & config status |

## Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed
- `curl` and `jq` available on your system
- A Red Hat Customer Portal account with API access

## Setup

1. Get an offline token from https://access.redhat.com/management/api
2. Run `/rh-case:init` and paste your token
3. Verify with `/rh-case:status`

Credentials are stored in `${CLAUDE_PLUGIN_DATA}/.env` (persistent directory that survives plugin updates).

## Plugin Structure

```
rh-case/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── commands/                  # User-invoked commands
│   ├── init.md
│   ├── list.md
│   ├── show.md
│   ├── search.md
│   ├── analyze.md
│   ├── comment.md
│   ├── export.md
│   └── status.md
├── skills/                    # AI-invoked skills
│   └── analyze/
│       └── SKILL.md
└── scripts/                   # Shell scripts for API calls
    ├── rh-case-common.sh
    ├── rh-case-auth-status.sh
    ├── rh-case-list.sh
    ├── rh-case-show.sh
    ├── rh-case-search.sh
    ├── rh-case-comment.sh
    └── rh-case-export.sh
```

## Optional: Jira Integration

The `/rh-case:analyze` command can search Red Hat Jira (issues.redhat.com / redhat.atlassian.net) for related bugs if you configure a Jira MCP server:

```bash
claude mcp add -s user \
  -e "JIRA_URL=https://redhat.atlassian.net" \
  -e "JIRA_USERNAME=your-email@redhat.com" \
  -e "JIRA_API_TOKEN=your-token" \
  -e "JIRA_SSL_VERIFY=true" \
  jira -- uvx mcp-atlassian
```

Generate your API token at: https://id.atlassian.com/manage-profile/security/api-tokens

## Usage

See **[USAGE.md](USAGE.md)** for a full guide with examples of AI-native workflows — natural language case triage, analysis, Jira correlation, and more.

## APIs Used

- **Red Hat SSO** (`sso.redhat.com`) — OAuth2 token exchange (offline token to access token)
- **Red Hat Customer Portal API** (`api.access.redhat.com`) — Cases, comments, attachments, KCS articles
- **Hydra Search API** (`access.redhat.com/hydra/rest/search/v2/cases`) — Case listing and filtering

## How It Works

- Scripts use `curl` + `jq` for API calls (no external dependencies beyond these)
- Access tokens are cached in `$TMPDIR/.rh-access-token-cache` (15-min TTL, auto-refresh)
- Credentials stored in `${CLAUDE_PLUGIN_DATA}/.env` — persistent directory that survives plugin updates

## Migration

If you previously stored credentials at `~/.config/claude-code/rh-case.env` or `~/.local/share/cc-redhat-support-case/.env`, they will still be found (legacy fallback). Run `/rh-case:init` to migrate to the new `${CLAUDE_PLUGIN_DATA}` location.

## Related Projects

- **[claude-code-jira](https://github.com/borball/claude-code-jira)** — Claude Code plugin for Jira task management
- **[claude-code-slack](https://github.com/borball/claude-code-slack)** — Claude Code plugin for Slack workspace management

## Acknowledgments

Inspired by [agcm](https://github.com/atgreen/agcm) — Anthony Green's AI-powered Red Hat support case management tool.

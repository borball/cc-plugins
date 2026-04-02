# Red Hat Support Case Manager

Claude Code standalone plugin for Red Hat support case management.

## Installation

Load as standalone plugin:
```bash
claude --plugin-dir ./cc-redhat-support-case
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

## Architecture

- **Commands** (`commands/`) — User-invoked plugin commands
- **Skills** (`skills/`) — AI-invoked analysis skill
- **Scripts** (`scripts/`) — Shell scripts that call Red Hat APIs via `curl` + `jq`
- **Credentials** — Stored at `${CLAUDE_PLUGIN_DATA}/.env`
- **Token cache** — `$TMPDIR/.rh-access-token-cache` (15-min TTL, auto-refresh)

## APIs Used

- **Red Hat SSO** (`sso.redhat.com`) — OAuth2 token exchange (offline token → access token)
- **Red Hat Customer Portal API** (`api.access.redhat.com`) — Cases, comments, attachments, KCS
- **Hydra Search API** (`access.redhat.com/hydra/rest/search/v2/cases`) — Case listing and filtering

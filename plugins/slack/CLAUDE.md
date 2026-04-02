# claude-code-slack — Read and search Slack messages from Claude Code

A Claude Code slash command plugin for reading and searching Slack messages directly from your terminal.

> **Disclaimer:** This is an unofficial community tool. It uses browser session tokens (xoxc/xoxd) to access Slack's API. These tokens provide full user-level access — treat them as secrets. This tool is not endorsed by or affiliated with Slack Technologies.

## Commands

- `/slack` — Main command router (dispatches to subcommands)
- `/slack init` — Set up Slack credentials (xoxc/xoxd tokens)
- `/slack status` — Check auth & config status
- `/slack search <query>` — Search messages across all channels
- `/slack read <channel> [--thread THREAD_TS]` — Read channel history or a specific thread
- `/slack channels [filter]` — List or search cached channels

## Architecture

- **`skills/`** — Skill definitions (SKILL.md per skill)
- **`scripts/`** — Shell scripts that call Slack APIs
  - `slack-common.sh` — Shared helpers: config loading, API wrapper, channel name→ID lookup
  - `slack-auth-status.sh` — Verify authentication
  - `slack-search.sh` — Search messages across workspace
  - `slack-read.sh` — Read channel history or thread replies
  - `slack-channels.sh` — List and lookup channels

## API Used

- **Slack Web API** (`slack.com/api/`) — All endpoints use xoxc token + xoxd cookie
  - `auth.test` — Verify authentication
  - `search.messages` — Full-text search across workspace
  - `conversations.history` — Channel message history
  - `conversations.replies` — Thread replies
  - `conversations.list` — List channels (for name→ID lookup, may be restricted on enterprise)

## Setup

1. Open Slack in your browser and extract xoxc/xoxd tokens from DevTools
2. Run `/slack init` and paste your tokens
3. Verify with `/slack status`

## Development Notes

- Scripts use `curl` + `jq` for API calls (no external dependencies beyond these)
- Channel name→ID mapping cached in `${CLAUDE_PLUGIN_DATA}/.slack-channel-cache.json`
- On enterprise workspaces, `conversations.list` may be restricted — channel IDs are learned automatically from search results as a fallback
- Auth uses xoxc token as Bearer + xoxd as cookie `d=` value
- Never log or echo tokens in output
- Both channel names and channel IDs are accepted in `/slack read`

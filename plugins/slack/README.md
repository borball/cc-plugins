# slack

[Claude Code](https://claude.ai/code) slash commands for reading, searching, and sending Slack messages — search conversations, read channels, follow threads, send messages, all without leaving your terminal.

> **Disclaimer:** This is an unofficial community tool. It uses browser session tokens (xoxc/xoxd) to access Slack's Web API with your user-level permissions. These tokens provide full account access — treat them as secrets. This tool is **not** endorsed by or affiliated with Slack Technologies. Use at your own risk.

## Commands

| Command | Description |
|---------|-------------|
| `/slack init` | Set up Slack credentials (xoxc/xoxd tokens) |
| `/slack status` | Check auth & config status |
| `/slack search <query>` | Search messages across all channels |
| `/slack read <channel> [--thread TS]` | Read channel history or a specific thread |
| `/slack channels [filter]` | List or search channels |
| `/slack send <channel> <message> [--thread TS]` | Send a message to a channel or thread |

## Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed
- `curl` and `jq` available on your system
- A Slack workspace you can access via browser

## Install

```
/plugin marketplace add borball/cc-plugins
/plugin install slack@cc-plugins
```

Then run:

```
/slack init
```

## Setup

### 1. Extract tokens from your browser

Open Slack in your **browser** (not the desktop app) and log in.

**Get the xoxc token:**
- Open DevTools (F12) → **Console** tab
- Run:
  ```js
  JSON.parse(localStorage.localConfig_v2).teams[Object.keys(JSON.parse(localStorage.localConfig_v2).teams)[0]].token
  ```
- Or: **Network** tab → filter by `api` → find `token=xoxc-...` in any request payload

**Get the xoxd token:**
- DevTools → **Application** tab → **Cookies** → `https://app.slack.com`
- Find the cookie named **`d`** (value starts with `xoxd-...`)

### 2. Configure

```
/slack init
```

Claude will walk you through pasting both tokens. They are written to `${CLAUDE_PLUGIN_DATA}/.env` (persistent directory that survives plugin updates).

### 3. Verify

```
/slack status
```

## Usage

See **[USAGE.md](USAGE.md)** for a full guide with examples — searching conversations, reading threads, navigating enterprise workspaces, and combining with other Claude Code tools.

### Quick examples

```
/slack search database connection timeout
/slack read team-backend
/slack read team-backend --thread 1234567890.123456
/slack read C0123ABCDEF --limit 10
/slack channels platform
/slack send #team-backend "Deploy is complete"
/slack send team-backend "Looks good" --thread 1234567890.123456
```

## Enterprise Slack Workspaces

On enterprise Slack instances, the `conversations.list` API may be restricted by workspace admins. This tool handles it gracefully:

- **Channel name resolution** falls back to searching (`in:#channel-name`) to discover channel IDs automatically
- **Channel IDs are learned** from search results and cached for future use
- **Direct channel IDs** always work — find them in Slack URLs or search results

## Token Lifecycle

Browser session tokens (xoxc/xoxd) don't expire on a fixed schedule. They remain valid as long as your browser session is active — typically **weeks to months**. They are invalidated by:

- Logging out of Slack in the browser
- Password changes
- SSO/SAML re-authentication forced by admin

When tokens expire, commands will show a clear error message. Run `/slack init` to refresh.

## Works Well With

This tool is designed to complement other Claude Code plugins:

- **[jira](../jira/)** — Jira task tracking (pick tickets, track time, post work logs)
- **[rh-case](../rh-case/)** — Red Hat support case management

When all three are installed, Claude can cross-reference data across systems — find Slack discussions about a Jira ticket, look up support cases mentioned in a channel thread, or search for context across all three tools at once.

## How It Works

- Scripts use `curl` + `jq` for API calls (no external dependencies beyond these)
- Channel name→ID mapping cached in `${CLAUDE_PLUGIN_DATA}/.slack-channel-cache.json`
- Credentials stored in `${CLAUDE_PLUGIN_DATA}/.env` — persistent directory that survives plugin updates
- All API calls use xoxc token as `Authorization: Bearer` header + xoxd as cookie `d=` value

## Project Structure

```
slack/
├── .claude-plugin/
│   └── plugin.json            # Plugin manifest
├── skills/                    # Skill definitions
│   ├── slack/SKILL.md         # Main /slack router
│   ├── init/SKILL.md          # /slack:init
│   ├── status/SKILL.md        # /slack:status
│   ├── search/SKILL.md        # /slack:search
│   ├── read/SKILL.md          # /slack:read
│   ├── send/SKILL.md          # /slack:send
│   └── channels/SKILL.md      # /slack:channels
├── scripts/
│   ├── slack-common.sh        # Shared auth, API helpers, channel/user caching
│   ├── slack-auth-status.sh   # Verify authentication
│   ├── slack-search.sh        # Search messages across workspace
│   ├── slack-read.sh          # Read channel history or thread replies
│   ├── slack-channels.sh     # List and lookup channels
│   └── slack-send.sh          # Send messages to channels/threads
└── CLAUDE.md                  # Project instructions for Claude
```

## License

MIT

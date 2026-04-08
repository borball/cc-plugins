# jira

Claude Code slash commands for Jira integration — pick tickets, track time, post work logs, and update status without leaving your terminal.

## Install

```
/plugin marketplace add borball/cc-plugins
/plugin install jira@cc-plugins
```

Then run:

```
/jira init
```

### Prerequisites

- [Claude Code](https://claude.ai/claude-code) CLI
- `curl`, `python3`, `bash` (no extra packages)
- A Jira Cloud account with an [API token](https://id.atlassian.com/manage-profile/security/api-tokens)

## Commands

| Command | Description |
|---|---|
| `/jira init` | Setup Jira credentials |
| `/jira start [KEY]` | Pick or create a ticket, move to In Progress |
| `/jira status` | Show current task with elapsed time |
| `/jira log [message]` | Post a progress update (ticket stays open) |
| `/jira done [message]` | Post final log and transition to Done |

## Workflow

```
/jira start PROJ-123        <- pick a ticket, clock starts
    ... write code with Claude's help ...
/jira log fixed the auth bug <- post an update mid-session
    ... keep working ...
/jira done                   <- auto-summarize, post log, close ticket
```

### Starting a task

```
/jira start PROJ-123       # start a specific ticket
/jira start                # browse your assigned tickets
                           # if none found, offers to create a new one
```

Picks the ticket, transitions it to "In Progress", and starts tracking time.

### Posting updates

```
/jira log Refactored the auth middleware
/jira log                  # auto-generates summary from git + conversation
```

Posts a comment and worklog entry to Jira. Ticket stays open — use this for progress updates throughout the day.

### Finishing a task

```
/jira done Completed API migration with tests
/jira done                 # auto-generates summary from git + conversation
```

Posts the work log, then asks if you want to transition the ticket to Done.

### Checking status

```
/jira status               # shows ticket, elapsed time, live Jira status
```

## Features

- **Auto time tracking** — starts when you `/jira start`, logged when you `/jira log` or `/jira done`
- **Auto work log generation** — omit the message and Claude summarizes from git diffs and your conversation
- **Rich formatting** — tables, code blocks, lists, and headings render properly in Jira
- **Ticket creation** — `/jira start` with no key can create a new ticket on the spot, auto-assigned to you
- **Cross-session persistence** — `.current-task.json` persists on disk, pick up where you left off
- **Live sync** — `/jira status` fetches live title and status from Jira, updating local cache
- **Attribution** — all posted comments and ticket descriptions include a *Posted via claude-code-jira* footer

## Configuration

### Option A: `/jira init` (recommended)

Run `/jira init` in a Claude Code session. Claude will ask for:

1. **Jira Base URL** — `https://redhat.atlassian.net` (default)
2. **Email** — your Jira account email
3. **API Token** — from [Atlassian API tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
4. **Project Key** — e.g., `PROJ`, `ENG`
5. **Default Parent** *(optional)* — parent ticket for new issues (e.g., `PROJ-100`)
6. **Default Issue Type** *(optional)* — `Task`, `Story`, `Bug`, or `Sub-task` (defaults to `Task`)

Credentials are stored in `${CLAUDE_PLUGIN_DATA}/.env` — a persistent directory that survives plugin updates.

## Project structure

```
jira/
├── .claude-plugin/
│   └── plugin.json            # Plugin manifest
├── skills/                    # Skill definitions
│   ├── jira/SKILL.md          # Main /jira router
│   ├── init/SKILL.md          # /jira:init
│   ├── start/SKILL.md         # /jira:start
│   ├── status/SKILL.md        # /jira:status
│   ├── log/SKILL.md           # /jira:log
│   └── done/SKILL.md          # /jira:done
├── scripts/
│   ├── jira-common.sh         # Shared auth & API helpers
│   ├── jira-init.sh           # Interactive credential setup
│   ├── jira-pick.sh           # Interactive ticket picker
│   ├── jira-create.sh         # Create new tickets
│   ├── jira-transition.sh     # Transition ticket status
│   ├── jira-log.sh            # Post work logs & comments
│   ├── jira-status.sh         # Show current task
│   ├── generate-worklog.sh    # Gather git context for summaries
│   └── build-adf.py           # Markdown to Jira ADF converter
├── hooks/                     # Optional session hooks
├── templates/                 # Work log templates
├── CLAUDE.md                  # Project instructions for Claude
└── LICENSE
```

## License

MIT

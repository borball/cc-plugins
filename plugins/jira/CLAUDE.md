# Claude-Code-Jira: Daily Task Tracker

This project integrates Claude Code sessions with Jira for automatic task tracking.

## IMPORTANT: Running scripts

When running any script from this plugin, always export `CLAUDE_PLUGIN_DATA` so scripts can find credentials:
```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/<script>.sh [args]
```

## Slash commands

```
/jira init            — setup Jira credentials
/jira start [KEY]     — pick/create a ticket and start working
/jira status          — show current task
/jira log [message]   — post a status update
/jira done [message]  — log work and close ticket
```

## Project structure

- `scripts/` — Shell scripts for Jira API interaction
  - `jira-common.sh` — Shared helpers, auth, API wrapper
  - `jira-pick.sh` — Pick a ticket to work on
  - `jira-create.sh` — Create a new Jira ticket
  - `jira-transition.sh` — Transition ticket status
  - `jira-log.sh` — Post work logs / comments to Jira
  - `jira-status.sh` — Show current active task
  - `generate-worklog.sh` — Gather git context for work log generation
  - `build-adf.py` — Convert markdown to Jira ADF format
- `hooks/` — Claude Code hook scripts
- `templates/` — Work log templates
- `.current-task.json` — Tracks the active Jira ticket (gitignored)

## When user asks to start a task

1. If ticket key given, run `CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/jira-pick.sh KEY`
2. If no key, run `CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/jira-pick.sh` to list tickets
3. If no tickets found, offer to create one with `CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/jira-create.sh`
   - New tickets are auto-assigned to the creator
   - Descriptions include "Posted via claude-code-jira" attribution
4. Run `CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/jira-transition.sh "" progress` to move it to In Progress

## When user asks to wrap up / end a task

1. Run `CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/generate-worklog.sh` to gather context
2. Generate a work log summary based on the context and conversation
3. Save the summary to `/tmp/jira-worklog-TICKET_KEY.md` and run `CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/jira-log.sh --file /tmp/jira-worklog-TICKET_KEY.md --comment`
4. Ask user if the ticket should be transitioned to Done
5. If yes, run `CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/jira-transition.sh "" done`
   - Supports both "Done" and "Closed" workflow states

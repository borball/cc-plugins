---
description: "Jira task management. Usage: /jira <subcommand> [args]"
---

Jira task management command. Parse the subcommand and arguments from: $ARGUMENTS

## Subcommand routing

Based on the first word of the arguments, dispatch as follows:

- **init** → Run `/jira:init`
- **start** [TICKET-KEY] → Run `/jira:start` with the remaining arguments
- **status** → Run `/jira:status`
- **log** [message] → Run `/jira:log` with the remaining arguments
- **done** [message] → Run `/jira:done` with the remaining arguments
- **update** [KEY] [description] → Run `/jira:update` with the remaining arguments
- **help** or empty → Show available subcommands listed below

## Available subcommands

```
/jira init              — Set up Jira credentials
/jira start [KEY]       — Pick/create a ticket and start working
/jira status            — Show current active task
/jira log [message]     — Post a status update
/jira done [message]    — Log work and close ticket
/jira update [KEY]      — Update ticket description or summary
```

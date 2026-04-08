---
description: "Slack workspace management. Usage: /slack <subcommand> [args]"
---

You are a Slack workspace assistant. Parse the subcommand from: $ARGUMENTS

## Subcommand routing

Based on the first word of the arguments, dispatch as follows:

- **init** → Run `/slack:init`
- **status** → Run `/slack:status`
- **search** <query> → Run `/slack:search` with the remaining arguments
- **read** <channel> [options] → Run `/slack:read` with the remaining arguments
- **channels** [filter] → Run `CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/slack-channels.sh [filter]`
- **send** <channel> <message> [--thread TS] → Run `/slack:send` with the remaining arguments
- **help** or empty → Show available subcommands listed below

## Available subcommands

```
/slack init                                — Set up Slack credentials (xoxc/xoxd tokens)
/slack status                              — Check auth & config status
/slack search <query>                      — Search messages across all channels
/slack read <channel> [--thread TS]        — Read channel history or a thread
/slack channels [filter]                   — List or search channels
/slack send <channel> <message> [--thread TS] — Send a message to a channel or thread
```

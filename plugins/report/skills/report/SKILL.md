---
description: "Activity report generation. Usage: /report <subcommand> [args]"
---

Activity report command. Parse the subcommand and arguments from: $ARGUMENTS

## Subcommand routing

Based on the first word of the arguments, dispatch as follows:

- **init** → Run `/report:init`
- **generate** [days] [options] → Run `/report:generate` with the remaining arguments
- **daily** → Run `/report:daily`
- **weekly** → Run `/report:weekly`
- **biweekly** → Run `/report:biweekly`
- **monthly** → Run `/report:monthly`
- **status** → Run `/report:status`
- **help** or empty → Show available subcommands listed below

## Available subcommands

```
/report init                               — Configure repos, git author, and features
/report generate [days] [--since/--until]  — Generate a report for a custom period
/report daily                              — Generate yesterday's activity report
/report weekly                             — Generate last 7 days report
/report biweekly                           — Generate last 14 days report
/report monthly                            — Generate last 30 days report
/report status                             — Show current configuration
```

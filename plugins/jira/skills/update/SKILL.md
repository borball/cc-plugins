---
description: "Update a Jira ticket's description or summary"
---

Update the description (and/or summary) of a Jira ticket.

Arguments: $ARGUMENTS

Parse the arguments for an optional ticket key and the new description content.

If a ticket key is provided (e.g., `PROJ-123`), use it. Otherwise the script falls back to the current active task.

If the user provides description content in the arguments:
1. Save the description to `/tmp/jira-update-desc-TICKET_KEY.md`
2. Run: `CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/jira-update.sh TICKET_KEY --desc-file /tmp/jira-update-desc-TICKET_KEY.md`

If the user asks to update the summary/title as well, add `--summary "New title"` to the command.

If no description content is provided:
1. Ask the user what the new description should be
2. Once provided, save it to `/tmp/jira-update-desc-TICKET_KEY.md`
3. Run: `CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/jira-update.sh TICKET_KEY --desc-file /tmp/jira-update-desc-TICKET_KEY.md`

The description content supports markdown formatting (headings, bullet lists, numbered lists, bold text).

Show the user the update result after the script completes.

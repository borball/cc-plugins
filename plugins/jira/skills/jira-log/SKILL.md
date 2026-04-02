---
description: "Post a Jira status update without closing the ticket"
---

Post a status update or work log comment to the current Jira ticket without closing it.

Arguments: $ARGUMENTS

If a message is provided in the arguments:
1. Save the message to `/tmp/jira-worklog-TICKET_KEY.md`
2. Run: `${CLAUDE_PLUGIN_ROOT}/scripts/jira-log.sh --file /tmp/jira-worklog-TICKET_KEY.md --comment`

If no arguments:
1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/generate-worklog.sh` to gather git and session context
2. Generate a concise progress update based on the context and our conversation
3. Show the update to the user for review
4. Save it to `/tmp/jira-worklog-TICKET_KEY.md`
5. Run: `${CLAUDE_PLUGIN_ROOT}/scripts/jira-log.sh --file /tmp/jira-worklog-TICKET_KEY.md --comment`

This does NOT transition the ticket — use `/jira done` when the task is complete.

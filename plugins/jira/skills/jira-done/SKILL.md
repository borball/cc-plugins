---
description: "Log work and close the current Jira ticket"
---

Wrap up the current Jira task: log work and transition the ticket.

Arguments: $ARGUMENTS

If a message is provided in the arguments:
1. Save the message to `/tmp/jira-worklog-TICKET_KEY.md`
2. Run: `${CLAUDE_PLUGIN_ROOT}/scripts/jira-log.sh --file /tmp/jira-worklog-TICKET_KEY.md --comment`

If no arguments:
1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/generate-worklog.sh` to gather git and session context
2. Generate a concise work log summary based on the context and our conversation. Include:
   - What was done (bullet points)
   - Files changed
   - Key decisions made
   - Any blockers or open questions
   - Next steps
3. Show the summary to the user for review
4. Save it to `/tmp/jira-worklog-TICKET_KEY.md`
5. Run: `${CLAUDE_PLUGIN_ROOT}/scripts/jira-log.sh --file /tmp/jira-worklog-TICKET_KEY.md --comment`

Then:
6. Ask the user if the ticket should be transitioned to "Done"
7. If yes, run: `${CLAUDE_PLUGIN_ROOT}/scripts/jira-transition.sh "" done`
8. Confirm completion

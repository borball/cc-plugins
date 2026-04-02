---
description: "Start working on a Jira ticket"
---

Start working on a Jira ticket.

Arguments: $ARGUMENTS

If a TICKET-KEY is provided:
1. Run: `${CLAUDE_PLUGIN_ROOT}/scripts/jira-pick.sh $ARGUMENTS`
2. Run: `${CLAUDE_PLUGIN_ROOT}/scripts/jira-transition.sh "" progress`
3. Run: `${CLAUDE_PLUGIN_ROOT}/scripts/jira-status.sh` to confirm

If no arguments:
1. Run: `${CLAUDE_PLUGIN_ROOT}/scripts/jira-pick.sh` to list assigned tickets
2. If tickets are found, let user pick one, then transition to In Progress
3. If no tickets found, ask user if they want to create a new ticket
4. If yes, ask for: summary, description (optional), type (Task/Story/Bug), and parent ticket (optional)
5. Run: `${CLAUDE_PLUGIN_ROOT}/scripts/jira-create.sh "Summary" "Description" --type Type --parent PARENT-KEY`
   Note: --type defaults to JIRA_DEFAULT_TYPE env var, --parent defaults to JIRA_DEFAULT_PARENT env var
6. Pick the newly created ticket: `${CLAUDE_PLUGIN_ROOT}/scripts/jira-pick.sh NEW-KEY`
7. Transition to In Progress: `${CLAUDE_PLUGIN_ROOT}/scripts/jira-transition.sh "" progress`

---
description: "Initialize Jira credentials"
---

Initialize Jira configuration. Collect credentials and write the config file.

Arguments (optional): $ARGUMENTS

First, ask the user where to save the config:
- **Global** (default) — saves to the claude-code-jira install directory, shared across all projects
- **Project** — saves to `.env.jira` in the current directory, overrides global config for this project only

Then ask for the required values:

1. **JIRA_URL** — Atlassian URL (e.g., https://mycompany.atlassian.net)
2. **JIRA_USERNAME** — Jira account email
3. **JIRA_API_TOKEN** — API token from https://id.atlassian.com/manage-profile/security/api-tokens
4. **JIRA_PROJECT_KEY** — Default project key (e.g., PROJ, ENG)

Then ask for optional defaults (user can skip these):

5. **JIRA_DEFAULT_PARENT** — Default parent ticket key for new issues (e.g., PROJ-100). Leave blank for none.
6. **JIRA_DEFAULT_TYPE** — Default issue type for new tickets (e.g., Task, Story, Bug, Sub-task). Defaults to Task.

Once you have them, write the `.env` file to the plugin data directory:
```bash
mkdir -p ${CLAUDE_PLUGIN_DATA}
```
Write to `${CLAUDE_PLUGIN_DATA}/.env`:

Config content:
```
JIRA_URL=<value>
JIRA_USERNAME=<value>
JIRA_API_TOKEN=<value>
JIRA_PROJECT_KEY=<value>
JIRA_JQL_FILTER="assignee = currentUser() AND status != Done ORDER BY updated DESC"

# Optional: defaults for ticket creation
JIRA_DEFAULT_PARENT=<value or omit if blank>
JIRA_DEFAULT_TYPE=<value or omit if blank>
```

Only include JIRA_DEFAULT_PARENT and JIRA_DEFAULT_TYPE lines if the user provided values.

Then test the connection by running:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/jira-pick.sh
```

The config file contains secrets — remind the user it won't be committed.

**IMPORTANT**: Never echo or log the API token in output. Treat it as a secret.

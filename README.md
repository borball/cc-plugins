# cc-plugins

A Claude Code plugin marketplace hosting enterprise tool integrations.

## Plugins

| Plugin                        | Version | Description |
|-------------------------------|---------|-------------|
| [rh-case](plugins/rh-case/) | 0.3.0 | Red Hat support case management — list, show, search, analyze, and comment on cases |
| [jira](plugins/jira/) | 0.2.0 | Jira integration — pick tickets, track time, post work logs, and update status |
| [slack](plugins/slack/) | 0.4.0 | Read, search, and send Slack messages — search conversations, read channels, follow threads, send messages |
| [report](plugins/report/) | 0.3.0 | Generate activity reports from git and Jira — daily standups, weekly/bi-weekly summaries, compact HTML |

## Install

Add this marketplace to Claude Code:

```
/plugin marketplace add borball/cc-plugins
```

Then install individual plugins:

```
/plugin install rh-case@cc-plugins
/plugin install jira@cc-plugins
/plugin install slack@cc-plugins
/plugin install report@cc-plugins
```

## Update

Update the marketplace to fetch the latest plugin versions:

```
/plugin marketplace update cc-plugins
```

Then update individual plugins:

```
/plugin install rh-case@cc-plugins
/plugin install jira@cc-plugins
/plugin install slack@cc-plugins
/plugin install report@cc-plugins
```

If plugins don't update, clear the local cache and reinstall:

```bash
rm -rf ~/.claude/plugins/cache/cc-plugins
```

Then restart Claude Code and reinstall the plugins.

> **Note:** Plugin credentials and configuration stored in `~/.claude/plugins/data/` are preserved across updates.

## Prerequisites

- [Claude Code](https://claude.ai/code) CLI
- `curl` and `jq` available on your system
- Credentials for the respective services (Red Hat Portal, Jira, Slack)

## Plugin Details

### rh-case

Manage Red Hat support cases via the Customer Portal API. Commands: `/rh-case:init`, `/rh-case:list`, `/rh-case:show`, `/rh-case:search`, `/rh-case:analyze`, `/rh-case:comment`, `/rh-case:export`, `/rh-case:status`.

See [plugins/rh-case/README.md](plugins/rh-case/README.md) for details.

### jira

Jira task tracking with automatic time logging. Commands: `/jira init`, `/jira start`, `/jira status`, `/jira log`, `/jira done`.

See [plugins/jira/README.md](plugins/jira/README.md) for details.

### slack

Read, search, and send Slack messages from your terminal. Commands: `/slack init`, `/slack status`, `/slack search`, `/slack read`, `/slack channels`, `/slack send`.

See [plugins/slack/README.md](plugins/slack/README.md) for details.

### report

Generate activity reports from git and Jira in markdown and compact HTML. Commands: `/report init`, `/report generate`, `/report daily`, `/report weekly`, `/report biweekly`, `/report monthly`, `/report status`. Features Jira ticket links, status badges, deduplication, highlighted top items, and configurable min-commits filter.

See [plugins/report/README.md](plugins/report/README.md) for details.

## Usage Examples

You don't need to memorize slash commands — just talk to Claude naturally. Here are some examples:

### Support Cases

```
> show me my open support cases
> what's the latest on case 12345678?
> search for cases about connection timeout
> find KCS articles about OpenShift upgrade failures
> analyze case 12345678 and suggest next steps
> add a comment to case 12345678 saying we applied the workaround
> export case 12345678 to markdown
```

### Jira

```
> what am I working on?
> start working on PROJ-456
> create a task for upgrading the database driver
> log my progress — finished the API refactoring and unit tests
> I'm done with this ticket, close it out
> pick up a new ticket from my backlog
```

### Slack

```
> search Slack for discussions about the deploy failure
> what's been happening in #team-backend?
> read the thread about the outage in #incidents
> has anyone mentioned PROJ-789 in Slack?
> send a message to #team-backend saying the deploy is complete
> DM John saying I'll look into the issue
```

### Reports

```
> generate my weekly report
> generate my bi-weekly report
> what did I work on last week?
> give me a summary of the last 14 days
> prepare my daily standup notes
> generate a report from March 1 to March 15
```

### Cross-Plugin Workflows

The real power is combining plugins in a single conversation:

```
> search Slack for messages about connection pool exhaustion
  (finds a thread mentioning case 12345678 and PROJ-789)

> show me case 12345678
  (reads the support case details)

> what's the status of PROJ-789?
  (checks the Jira ticket)

> summarize everything we know about this issue
  (Claude synthesizes information from all three sources)

> send a summary to #team-backend
  (posts the findings to Slack)
```

## Repository Structure

```
cc-plugins/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace manifest
├── plugins/
│   ├── rh-case/                  # Red Hat support case plugin
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── skills/
│   │   └── scripts/
│   ├── jira/                     # Jira integration plugin
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── skills/
│   │   ├── scripts/
│   │   ├── hooks/
│   │   └── templates/
│   ├── slack/                    # Slack messaging plugin
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── skills/
│   │   └── scripts/
│   └── report/                   # Activity report plugin
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── skills/
│       └── scripts/
└── README.md
```

## Related

- [Plugin Marketplaces Documentation](https://code.claude.com/docs/en/plugin-marketplaces)

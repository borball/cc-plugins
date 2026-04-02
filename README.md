# cc-plugins

A Claude Code plugin marketplace hosting enterprise tool integrations.

## Plugins

| Plugin | Description |
|--------|-------------|
| [rh-case](plugins/rh-case/) | Red Hat support case management — list, show, search, analyze, and comment on cases |
| [jira](plugins/jira/) | Jira integration — pick tickets, track time, post work logs, and update status |
| [slack](plugins/slack/) | Read and search Slack messages — search conversations, read channels, follow threads |

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
```

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

Read and search Slack messages from your terminal. Commands: `/slack init`, `/slack status`, `/slack search`, `/slack read`, `/slack channels`.

See [plugins/slack/README.md](plugins/slack/README.md) for details.

## Repository Structure

```
cc-plugins/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace manifest
├── plugins/
│   ├── rh-case/                  # Red Hat support case plugin
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── commands/
│   │   ├── skills/
│   │   └── scripts/
│   ├── jira/                     # Jira integration plugin
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── skills/
│   │   ├── scripts/
│   │   ├── hooks/
│   │   └── templates/
│   └── slack/                    # Slack messaging plugin
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── skills/
│       └── scripts/
└── README.md
```

## Related

- [Plugin Marketplaces Documentation](https://code.claude.com/docs/en/plugin-marketplaces)
- [cc-redhat-support-case](https://github.com/borball/cc-redhat-support-case) (standalone repo)
- [claude-code-jira](https://github.com/borball/claude-code-jira) (standalone repo)
- [claude-code-slack](https://github.com/borball/claude-code-slack) (standalone repo)

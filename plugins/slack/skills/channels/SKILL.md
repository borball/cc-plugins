---
description: "List or search cached Slack channels"
---

List or search cached Slack channels.

Arguments: $ARGUMENTS

## Usage

Run:
```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/slack-channels.sh $ARGUMENTS
```

If no filter is provided, lists all cached channels. If a filter is provided, shows only matching channels.

## Examples

- `/slack channels` — List all cached channels
- `/slack channels platform` — Search for channels matching "platform"
- `/slack channels infra` — Search for channels matching "infra"

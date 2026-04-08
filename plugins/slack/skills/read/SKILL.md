---
description: "Read Slack channel history or a specific thread"
---

Read messages from a Slack channel or thread. Parse from: $ARGUMENTS

The first argument should be a channel name (with or without #). Additional flags:
- `--thread THREAD_TS` — read a specific thread
- `--limit N` — number of messages (default 30)
- `--since DAYS` — only messages from the last N days

Run:
```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/slack-read.sh CHANNEL [--thread THREAD_TS] [--limit N] [--since DAYS]
```

**Interpreting user intent:**
- "read team-backend" → `CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/slack-read.sh team-backend`
- "read #incidents last 3 days" → `CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/slack-read.sh incidents --since 3`
- "read thread 1234567890.123456 in team-backend" → `CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/slack-read.sh team-backend --thread 1234567890.123456`

**Channel resolution:** Both channel names and channel IDs work. On enterprise workspaces, channel name lookup may fail — if so, use the channel ID directly (e.g., `C0123ABCDEF`). Channel IDs are shown in search results and Slack URLs.

When presenting results:
- Messages show raw user IDs (e.g., `U0483C0SFUM`). Mention them as-is — don't try to resolve them unless the user asks
- Summarize long conversations, highlighting key points and decisions
- For threads with many replies, provide a concise summary
- If messages reference Jira ticket keys or support case numbers, point them out
- If a message has replies (shown by reply count), offer to read the full thread

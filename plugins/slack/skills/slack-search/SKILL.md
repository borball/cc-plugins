---
description: "Search Slack messages across the workspace"
---

Search Slack messages. Parse from: $ARGUMENTS

Run:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/slack-search.sh [--sort relevance|timestamp] [--count N] [--channel CHANNEL] QUERY
```

**Interpreting user intent:**
- "search for upgrade failures" → `${CLAUDE_PLUGIN_ROOT}/scripts/slack-search.sh upgrade failures`
- "search deploy in team-platform" → `${CLAUDE_PLUGIN_ROOT}/scripts/slack-search.sh --channel team-platform deploy`
- "find recent messages about PROJ-12345" → `${CLAUDE_PLUGIN_ROOT}/scripts/slack-search.sh --sort timestamp PROJ-12345`
- "search for API timeout issues" → `${CLAUDE_PLUGIN_ROOT}/scripts/slack-search.sh API timeout issues`

Present results clearly. For each message:
- Highlight the channel name and who posted it
- Note the channel ID shown in parentheses — useful for `/slack read` on enterprise workspaces
- Summarize long messages rather than dumping raw text
- If a thread permalink is available, mention it
- Offer to read the full thread with `/slack read <channel-id> --thread <ts>` if relevant

If results mention Jira ticket keys or support case numbers, point them out — the user may want to cross-reference with other tools.

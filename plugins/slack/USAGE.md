# Usage Guide

This plugin is designed for **AI-native** interaction — you talk to Claude Code in natural language, and slash commands handle the API calls behind the scenes. You don't need to memorize flags or syntax.

## Getting Started

```
> /slack init
```

Claude will walk you through extracting tokens from your browser and writing the `.env` file. Then verify:

```
> /slack status
```

## Everyday Examples

### Search for messages

```
> /slack search database connection timeout
> /slack search PROJ-12345
> /slack search deploy failure --channel team-platform
> /slack search "memory leak" --sort timestamp
```

Or just ask Claude directly:

```
> find Slack messages about connection pool exhaustion
> has anyone discussed the v2.5 upgrade issue in Slack?
> search for messages mentioning ticket PROJ-456
```

### Read a channel

```
> /slack read team-backend
> /slack read team-backend --since 3
> /slack read C0123ABCDEF --limit 10
```

Or conversationally:

```
> what's been happening in #team-backend?
> show me the last 3 days from #incidents
```

### Follow a thread

When you see an interesting message with replies, read the full thread:

```
> /slack read team-backend --thread 1773943155.346989
```

Thread timestamps (`ts`) are shown in search results and channel history. Claude will often suggest reading a thread when it spots one with replies.

### List channels

```
> /slack channels
> /slack channels platform
> /slack channels infra
```

On enterprise workspaces, the channel list builds gradually from search results. The more you search, the more channels are discovered and cached.

## Working with Enterprise Slack

On enterprise Slack instances, the channel listing API is often restricted. This tool handles it automatically:

1. **Search first** — `/slack search` always works and discovers channel IDs
2. **Channel names resolve via search** — when you use a channel name, the tool searches `in:#channel-name` to find the ID
3. **IDs are cached** — once a channel is discovered, it's remembered for future use
4. **Direct IDs always work** — use channel IDs from Slack URLs (e.g., `C0123ABCDEF`)

Typical workflow:

```
> /slack search deploy failure
  (results show channels with IDs: #team-platform (C012ABC), #incidents (C034DEF))

> /slack read C012ABC --limit 10
  (read directly by ID)

> /slack read team-platform
  (now works by name — the ID was cached from search)
```

## Combining with Other Tools

### Slack + Jira

Search Slack for discussions about a Jira ticket:

```
> /slack search PROJ-789

  (Claude finds Slack threads discussing this ticket)

> /jira start PROJ-789

  (pick up the ticket and start working)
```

Or discover Jira tickets mentioned in Slack conversations:

```
> /slack read team-backend --thread 1773943155.346989

  Claude: "This thread mentions PROJ-789 and INFRA-234.
           Want me to look them up?"

> yes, check their status
```

### Slack + Support Cases

Find Slack context for a support case:

```
> /rh-case show 12345678

  (read the case details)

> /slack search 12345678

  (find internal Slack discussions about this case)

> /slack search "connection timeout" database pool

  (search for the error message from the case)
```

### Three-Way Triage

A complete investigation using all three tools:

```
> /slack search "connection pool exhaustion"

  (find the original discussion)

> /slack read team-backend --thread 1773943155.346989

  (read the full thread — discover PROJ-789 and case 12345678)

> /rh-case show 12345678 --comments

  (read the support case)

> /rh-case search --type kcs connection pool timeout

  (check if there's a knowledge base article)

  Claude: "Based on the Slack thread, Jira ticket, and support case:
           The issue is caused by a connection leak in v2.5.1.
           Fix is in PR #841, release in progress.
           Workaround: increase pool max_connections to 50."
```

## Workflow Example: Morning Triage

```
> /slack search "from:me" --sort timestamp --count 5

  (check your recent messages)

> /slack read team-standup --since 1

  (what did the team post yesterday?)

> /jira status

  (your current Jira task)

> /rh-case list urgent

  (any hot support cases?)
```

## Tips

- **Be conversational** — You don't need exact command syntax. Claude understands intent like "search Slack for deploy issues" or "read the backend channel."
- **Follow up** — After any search or read, ask Claude to summarize, compare messages, draft a response, or dig into a thread.
- **Channel IDs are your friend** — On enterprise Slack, use channel IDs from search results or Slack URLs. They're more reliable than names.
- **Cross-reference** — When Claude spots Jira tickets or case numbers in Slack messages, ask it to look them up. That's the power of having all three tools in one session.
- **Stay in context** — Once messages are loaded, Claude remembers them. You can ask follow-up questions without re-searching.

# Usage Guide: AI-Native Task Tracking with Claude Code

This guide shows how the jira plugin works in practice — real conversational workflows where Claude handles your Jira tickets while you focus on code.

## Setup (one time)

```
> /jira init
```

Claude will ask for your Jira URL, email, API token, and project key interactively. No need to manually edit config files.

## Daily Workflow

### 1. Start your day — pick a ticket

```
> /jira start
```

Claude lists your assigned tickets:

```
Your tickets:
─────────────────────────────────────────────────────────
   1. [PROJ-291] Upgrade database connection pool
      Status: Review | Priority: Normal
   2. [PROJ-341] Fix authentication timeout in API gateway
      Status: In Progress | Priority: Normal
   3. [PROJ-330] Add rate limiting to public endpoints
      Status: In Progress | Priority: Undefined
─────────────────────────────────────────────────────────
```

Tell Claude which one: "start PROJ-341" and it transitions the ticket to In Progress and starts the clock.

Or start a specific ticket directly:

```
> /jira start PROJ-341
```

### 2. No ticket? Create one on the fly

```
> /jira start
```

If no assigned tickets are found, Claude asks if you want to create one:

```
> yes, create "Fix authentication timeout in API gateway"
```

Claude creates the ticket, auto-assigns it to you, transitions to In Progress, and starts tracking time — all in one step.

### 3. Work with Claude as usual

Now just work normally. Ask Claude to write code, debug issues, review files — everything is tracked in context.

```
> look at the auth middleware in src/middleware/auth.ts and fix the timeout handling

> also add retry logic for token refresh

> run the tests
```

### 4. Post a mid-session update

When you hit a milestone or want to share progress:

```
> /jira log
```

Claude auto-generates a structured update from your git commits and conversation:

```
## What was done
- Fixed timeout handling in auth middleware
- Added retry logic for token refresh (3 attempts with exponential backoff)

## Files changed
- src/middleware/auth.ts — timeout config, retry wrapper
- tests/auth.test.ts — new test cases for retry scenarios

## Next steps
- Load test the retry logic under high concurrency
```

This gets posted as both a Jira comment and worklog entry with elapsed time.

Or provide your own message:

```
> /jira log Fixed the auth timeout, moving on to rate limiting
```

### 5. Wrap up the task

```
> /jira done
```

Claude generates a final summary from the full session, posts it to Jira, and asks:

```
Should I transition PROJ-341 to Done?
```

Say yes, and the ticket is closed. Say no, and it stays In Progress for the next session.

### 6. Check status anytime

```
> /jira status
```

```
Current Task
════════════════════════════════════════════════
  Ticket:  PROJ-341
  Summary: Fix authentication timeout in API gateway
  Status:  In Progress
  Started: 2026-03-28T09:15:00.000+0000
  Elapsed: 2h 34m
════════════════════════════════════════════════
```

## AI-Native Features

### Auto-generated work logs

The killer feature. Just run `/jira log` or `/jira done` without a message, and Claude:

1. Reads your git commits since the task started
2. Reviews the conversation history
3. Generates a structured summary with sections: what was done, files changed, key decisions, blockers, next steps
4. Posts it to Jira with proper formatting (headings, bullet lists, bold text)

You never write a status update manually.

### Natural language ticket creation

When creating tickets, describe them naturally:

```
> /jira start
No tickets found. Want to create one?
> yes, "Investigate memory leak in worker pool" — it's a bug,
  workers aren't releasing connections after timeout
```

Claude creates the ticket with:
- Proper issue type (Bug)
- Formatted description with markdown rendered as Jira ADF
- Auto-assigned to you
- Parent ticket set from your defaults

### Context-aware updates

Because Claude has full context of your conversation, the work logs it generates are accurate and detailed. It knows:
- What code you changed and why
- What approaches you tried and rejected
- What decisions you made and the reasoning
- What's still unfinished

This is something a generic Jira API tool can't do — it doesn't have your session context.

### Conversational task management

You can also just talk to Claude naturally:

```
> list all my tasks
> create a new ticket for the DNS resolution bug
> what's my current ticket?
> log that we fixed the race condition in the connection pool
> close this ticket, we're done
```

Claude understands the intent and runs the right commands.

## Multi-Session Support

### Pick up where you left off

The current task persists between sessions. Start a new Claude Code session and:

```
> /jira status
```

Your ticket, elapsed time, and status are right there.

### Concurrent sessions

Each session uses per-ticket temp files (`/tmp/jira-worklog-PROJ-341.md`), so multiple sessions working on different tickets won't conflict.

## Example: Full Session

```
> /jira start PROJ-456

Selected: [PROJ-456] Migrate user service to async handlers
Status: In Progress
Task tracking started.

> read src/services/user.ts and convert the sync handlers to async

  [Claude reads the file, refactors to async/await, runs tests]

> /jira log

Posting work log to PROJ-456...
Time spent: 45m
Work log posted successfully.
Comment posted successfully.

> now update the API tests to use async assertions

  [Claude updates tests, all pass]

> /jira done

## What was done
- Converted 12 sync handlers to async/await in user service
- Updated 8 test files with async assertions
- Removed callback-based error handling

## Files changed
- src/services/user.ts — async conversion
- tests/services/user.test.ts — async test patterns

## Key decisions
- Used native async/await over Promise chains for readability
- Kept backward-compatible sync wrappers for 2 external consumers

Posting work log to PROJ-456...
Time spent: 1h 12m
Work log posted successfully.

Should I transition PROJ-456 to Done? yes

PROJ-456 transitioned successfully.
```

## Comparison: Slash Commands vs Natural Language

Both work. Use whichever feels natural:

| Slash command | Natural language equivalent |
|---|---|
| `/jira start PROJ-123` | "start working on PROJ-123" |
| `/jira start` | "list my tickets" or "what should I work on?" |
| `/jira status` | "what am I working on?" |
| `/jira log` | "post an update to Jira" |
| `/jira log fixed the bug` | "log that I fixed the bug" |
| `/jira done` | "wrap up this ticket" |

The slash commands are faster (single keystroke with tab completion). Natural language is more flexible and allows combining actions.

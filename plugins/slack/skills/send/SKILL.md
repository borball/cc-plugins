---
description: "Send a message to a Slack channel or thread"
---

Send a message to a Slack channel or thread.

Arguments: $ARGUMENTS

## Step-by-step flow

Follow these steps in order:

### Step 1: Parse arguments

Determine from $ARGUMENTS:
- **Channel**: Channel name, channel ID, or user ID (required)
- **Message**: The message text (required)
- **Thread**: Optional thread timestamp for replies

### Step 2: Resolve the target display name

**ALWAYS run this step before showing the confirmation.**

If the target starts with `U` (user ID), resolve the display name:
```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/slack-resolve-user.sh <user_id>
```

Use the resolved name in the confirmation (e.g. "DM to **John Smith**").

For channel names/IDs, use the channel name directly.

### Step 3: Confirm with the user

**NEVER send a message without explicit user confirmation.** Show:

1. **Target**: The resolved display name (NOT raw user IDs like U0123...)
2. **Message preview**: The exact text that will be posted
3. **Ask**: "Send this message? (yes/no)"

Only proceed to Step 4 if the user confirms.

### Step 4: Send the message

```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/slack-send.sh <channel> "<message>" [--thread THREAD_TS]
```

## Examples

- `/slack send #team-backend "Deploy is complete, all tests passing"`
- `/slack send team-backend "Looks good to me" --thread 1234567890.123456`
- `/slack send C0123ABCDEF "FYI: updated the config"`
- `/slack send U0123ABCDEF "Hey, quick question"` (DM by user ID)

**IMPORTANT**: Always confirm with the user before sending. Messages are posted as the user and cannot be unsent.

---
description: "Publish a report to Confluence"
---

Publish a generated HTML report to Confluence. Arguments: $ARGUMENTS

## Step-by-step flow

### Step 1: Find the report file

Look for the most recent HTML report file in the current directory, or use the file specified in arguments.

### Step 2: Confirm with the user

Show:
1. **File**: the HTML report to publish
2. **Destination**: Confluence personal space
3. **Title**: auto-generated from filename or user-specified

Ask for confirmation before publishing.

### Step 3: Publish

```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/report-publish.sh <report.html> [space_id] [title]
```

The script uses Jira/Atlassian credentials from the jira plugin. Space ID defaults to the user's personal space.

### Step 4: Share the URL

Show the Confluence page URL from the script output.

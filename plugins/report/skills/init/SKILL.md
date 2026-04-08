---
description: "Configure report plugin — repos and git author"
---

Set up the report plugin configuration.

## Step-by-step flow

### Step 1: Gather information

Ask the user for:
1. **Repository paths** — paths to git repos or parent directories containing repos
   - Example: `~/Documents/github-workspace` (parent dir with multiple repos inside)
   - Example: `~/projects/myapp,~/projects/backend` (specific repos, comma-separated)
2. **Git author email** — for filtering commits (try detecting from `git config --global user.email` first)

### Step 2: Save configuration

```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/report-init.sh "<repos>" "<git_author>"
```

### Step 3: Verify

Run status to confirm:
```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/report-status.sh
```

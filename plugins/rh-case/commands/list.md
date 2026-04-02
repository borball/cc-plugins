---
description: "List Red Hat support cases with optional filters"
argument-hint: "[--status S] [--severity S] [--product P]"
---

## Name
rh-case:list

## Synopsis
```
/rh-case:list [filters]
```

## Description
List Red Hat support cases using the Hydra search API. Supports filtering by status, severity, product, account, and group.

## Implementation

Run the listing script with appropriate flags parsed from the user's natural language input:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-list.sh [OPTIONS]
```

**Available filters** (parse from arguments):
- `--status "Open"` or `--status "Open,Waiting on Red Hat"` (comma-separated)
- `--severity "1 (Urgent)"` or `--severity "2 (High)"`
- `--product "OpenShift Container Platform"`
- `--account "12345"`
- `--group "67890"`
- `--rows 100` (default: 50)

**Natural language mapping:**
- "list open cases" -> `--status "Open"`
- "list critical cases" -> `--severity "1 (Urgent)"`
- "list high and urgent" -> `--severity "1 (Urgent)"` then separately `--severity "2 (High)"`
- "list active cases" -> `--status "Open,Waiting on Red Hat,Waiting on Customer"`
- "list openshift cases" -> `--product "OpenShift Container Platform"`
- "list all" -> no filters

Present the output as a formatted table. If there are many results, offer to filter further.

## Examples

```
/rh-case:list
/rh-case:list open cases
/rh-case:list --status "Open" --severity "1 (Urgent)"
```

---
description: "Show Red Hat API auth and configuration status"
argument-hint: ""
---

## Name
rh-case:status

## Synopsis
```
/rh-case:status
```

## Description
Check the current Red Hat API configuration and authentication status. Shows config source, account filter, auth status, and API access.

## Implementation

Run:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-auth-status.sh
```

Present the results clearly. If not configured, guide the user to run `/rh-case:init`.

## Examples

```
/rh-case:status
```

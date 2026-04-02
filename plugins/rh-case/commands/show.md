---
description: "Show details of a Red Hat support case"
argument-hint: "<CASE#> [--comments] [--attachments]"
---

## Name
rh-case:show

## Synopsis
```
/rh-case:show <CASE#> [--comments] [--attachments]
```

## Description
Show details of a specific Red Hat support case including metadata, description, comments, and attachment listing.

## Implementation

Parse the case number from the first argument. Additional flags:
- `--comments` — include case comments (default: include unless user says otherwise)
- `--attachments` — include attachment listing

Run:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-show.sh CASE_NUMBER [--comments] [--attachments]
```

By default, include `--comments` unless the user explicitly says they don't want them.

Present the output in a clear, readable format. If the case has many comments, summarize the conversation timeline and highlight key points.

## Examples

```
/rh-case:show 04401234
/rh-case:show 04401234 --comments --attachments
```

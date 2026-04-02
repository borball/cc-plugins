---
description: "Add a comment to a Red Hat support case"
argument-hint: "<CASE#> <message>"
---

## Name
rh-case:comment

## Synopsis
```
/rh-case:comment <CASE#> <message>
```

## Description
Add a public or internal comment to a Red Hat support case. Always confirms with the user before posting.

## Implementation

The first argument is the case number. The rest is the comment text.

**IMPORTANT**: Before posting, always show the user:
1. The case number and summary (fetch with `${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-show.sh CASE_NUMBER` first)
2. The comment text that will be posted
3. Whether it will be public or internal

Ask for confirmation before posting.

To post:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-comment.sh CASE_NUMBER --message "comment text"
```

Or save to a temp file first for longer comments:
```bash
echo "comment text" > /tmp/rh-comment-CASE.txt
${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-comment.sh CASE_NUMBER --file /tmp/rh-comment-CASE.txt
```

Add `--internal` flag if the user wants an internal/private comment.

## Examples

```
/rh-case:comment 04401234 Investigating the etcd leader election issue
/rh-case:comment 04401234 --internal This appears related to OCPBUGS-12345
```

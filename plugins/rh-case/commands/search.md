---
description: "Search Red Hat support cases and KCS knowledge base"
argument-hint: "[--type cases|kcs|solutions|articles] <query>"
---

## Name
rh-case:search

## Synopsis
```
/rh-case:search [--type TYPE] <query>
```

## Description
Search Red Hat support cases or KCS knowledge base (solutions and articles).

## Implementation

Run:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-search.sh [--type TYPE] [--rows N] QUERY
```

**Search types:**
- `cases` (default) — search support cases by keyword
- `kcs` — search KCS knowledge base (solutions + articles)
- `solutions` — search only solutions
- `articles` — search only articles

**Interpreting user intent:**
- "search for upgrade failures" -> `--type cases upgrade failures`
- "find KCS about etcd" -> `--type kcs etcd`
- "any solutions for OCP upgrade?" -> `--type solutions OCP upgrade`

Present results clearly. For KCS results, include links. Offer to show more details on specific results.

## Examples

```
/rh-case:search etcd leader election
/rh-case:search --type kcs OCP upgrade failure
/rh-case:search --type solutions node NotReady
```

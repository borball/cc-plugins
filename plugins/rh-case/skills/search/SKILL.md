---
description: "Search Red Hat support cases and KCS knowledge base"
---

Search Red Hat support cases or KCS articles. Arguments: $ARGUMENTS

Run:
```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-search.sh $ARGUMENTS
```

Options: `--type kcs` for KCS articles, `--type cases` for support cases.

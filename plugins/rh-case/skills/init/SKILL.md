---
description: "Configure Red Hat API credentials for support case access"
---

Set up Red Hat API credentials.

Ask the user for their Red Hat offline token (from https://access.redhat.com/management/api).

Save to `${CLAUDE_PLUGIN_DATA}/.env`:
```
RH_OFFLINE_TOKEN=<token>
```

Then verify:
```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" ${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-auth-status.sh
```

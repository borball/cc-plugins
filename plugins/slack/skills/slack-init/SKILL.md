---
description: "Initialize Slack credentials"
---

Help the user set up their Slack API credentials. You need to collect two browser session tokens.

## How to extract tokens

Guide the user through these steps:

1. **Open Slack in your browser** (not the desktop app) — e.g., https://app.slack.com
2. **Log in** to your workspace
3. **Open DevTools** (F12 or Cmd+Option+I)

### Getting the xoxc token (SLACK_XOXC_TOKEN):
- Go to the **Console** tab
- Paste and run:
  ```js
  JSON.parse(localStorage.localConfig_v2).teams[Object.keys(JSON.parse(localStorage.localConfig_v2).teams)[0]].token
  ```
- Or: Go to **Network** tab → filter by `api` → click any Slack API request → look in the request payload for `token=xoxc-...`

### Getting the xoxd token (SLACK_XOXD_TOKEN):
- Go to **Application** tab → **Cookies** → `https://app.slack.com`
- Find the cookie named **`d`**
- The value starts with `xoxd-...`

## After collecting tokens

Once the user provides both tokens, write the `.env` file to the plugin data directory:
```bash
mkdir -p ${CLAUDE_PLUGIN_DATA}
```
Write to `${CLAUDE_PLUGIN_DATA}/.env`:

The file contents:

```
SLACK_XOXC_TOKEN=<the xoxc token>
SLACK_XOXD_TOKEN=<the xoxd token>
SLACK_WORKSPACE=<workspace name if known>
```

After writing the file, verify the setup by running:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/slack-auth-status.sh
```

If authentication succeeds, confirm setup is complete and suggest running `/slack channels` to build the channel cache.

**IMPORTANT**: Never echo or log the tokens in output. Treat them as secrets.

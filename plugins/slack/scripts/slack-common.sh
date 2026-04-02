#!/usr/bin/env bash
# slack-common.sh — Shared helpers for Slack scripts
# Sourced by all other scripts in this directory.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Persistent data directory (survives plugin updates)
SLACK_DATA_DIR="${CLAUDE_PLUGIN_DATA:-${PROJECT_DIR}}"

# ── Config loading ──────────────────────────────────────────────
load_config() {
  local env_file=""

  # Project-local override first, then plugin data dir, then legacy plugin root
  if [[ -f "$PWD/.env.slack" ]]; then
    env_file="$PWD/.env.slack"
  elif [[ -f "$SLACK_DATA_DIR/.env" ]]; then
    env_file="$SLACK_DATA_DIR/.env"
  elif [[ -f "$PROJECT_DIR/.env" ]]; then
    env_file="$PROJECT_DIR/.env"
  fi

  if [[ -z "$env_file" ]]; then
    echo "ERROR: No .env.slack or .env found." >&2
    echo "Run /slack init to configure credentials." >&2
    return 1
  fi

  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a

  # Validate required vars
  for var in SLACK_XOXC_TOKEN SLACK_XOXD_TOKEN; do
    if [[ -z "${!var:-}" ]]; then
      echo "ERROR: $var is not set in $env_file" >&2
      return 1
    fi
  done

  export SLACK_CONFIG_SOURCE="$env_file"
}

# ── API helper ─────────────────────────────────────────────────
# slack_api METHOD ENDPOINT [DATA]
# Calls Slack Web API with xoxc token + xoxd cookie
slack_api() {
  local method="$1"
  local endpoint="$2"
  local data="${3:-}"

  local url="https://slack.com/api/${endpoint}"

  local curl_args=(
    -s -X "$method"
    -H "Authorization: Bearer ${SLACK_XOXC_TOKEN}"
    -b "d=${SLACK_XOXD_TOKEN}"
    -H "Accept: application/json"
  )

  if [[ -n "$data" ]]; then
    curl_args+=(-H "Content-Type: application/json; charset=utf-8" -d "$data")
  fi

  local response
  response=$(curl "${curl_args[@]}" "$url")

  # Check Slack API-level errors
  local ok
  ok=$(echo "$response" | jq -r '.ok // false')

  if [[ "$ok" != "true" ]]; then
    local error
    error=$(echo "$response" | jq -r '.error // "unknown_error"')
    if [[ "$error" == "invalid_auth" || "$error" == "token_expired" || "$error" == "not_authed" ]]; then
      echo "ERROR: Authentication failed ($error). Your tokens may have expired." >&2
      echo "Run /slack init to refresh your tokens." >&2
      return 1
    fi
    echo "ERROR: Slack API error: $error" >&2
    echo "$response" | jq -r '.response_metadata.messages[]?' >&2 2>/dev/null
    return 1
  fi

  echo "$response"
}

# slack_api_form ENDPOINT KEY1=VAL1 KEY2=VAL2 ...
# POST with application/x-www-form-urlencoded (some Slack endpoints prefer this)
slack_api_form() {
  local endpoint="$1"
  shift

  local url="https://slack.com/api/${endpoint}"

  local curl_args=(
    -s -X POST
    -H "Authorization: Bearer ${SLACK_XOXC_TOKEN}"
    -b "d=${SLACK_XOXD_TOKEN}"
  )

  for kv in "$@"; do
    curl_args+=(--data-urlencode "$kv")
  done

  local response
  response=$(curl "${curl_args[@]}" "$url")

  local ok
  ok=$(echo "$response" | jq -r '.ok // false')

  if [[ "$ok" != "true" ]]; then
    local error
    error=$(echo "$response" | jq -r '.error // "unknown_error"')
    if [[ "$error" == "invalid_auth" || "$error" == "token_expired" || "$error" == "not_authed" ]]; then
      echo "ERROR: Authentication failed ($error). Your tokens may have expired." >&2
      echo "Run /slack init to refresh your tokens." >&2
      return 1
    fi
    echo "ERROR: Slack API error: $error" >&2
    return 1
  fi

  echo "$response"
}

# ── Channel name → ID lookup ──────────────────────────────────
CHANNEL_CACHE_FILE="${SLACK_DATA_DIR}/.slack-channel-cache.json"

# Refresh channel cache by fetching all channels
# Falls back gracefully on enterprise workspaces where conversations.list is restricted
refresh_channel_cache() {
  echo "Refreshing channel cache..." >&2

  local all_channels="[]"
  local cursor=""
  local page=0

  while true; do
    local args=("conversations.list" "types=public_channel,private_channel" "limit=999" "exclude_archived=true")
    if [[ -n "$cursor" ]]; then
      args+=("cursor=$cursor")
    fi

    local response
    response=$(slack_api_form "${args[@]}" 2>/dev/null) || {
      echo "WARNING: conversations.list not available (enterprise restriction)." >&2
      echo "Use channel IDs directly or /slack search to discover them." >&2
      # Ensure cache file exists (empty) so we don't retry every call
      if [[ ! -f "$CHANNEL_CACHE_FILE" ]]; then
        echo "[]" > "$CHANNEL_CACHE_FILE"
      fi
      return 0
    }

    local channels
    channels=$(echo "$response" | jq '[.channels[] | {id: .id, name: .name}]')
    all_channels=$(echo "$all_channels $channels" | jq -s 'add')

    cursor=$(echo "$response" | jq -r '.response_metadata.next_cursor // ""')
    page=$((page + 1))

    if [[ -z "$cursor" || "$cursor" == "null" ]]; then
      break
    fi
  done

  local count
  count=$(echo "$all_channels" | jq 'length')
  echo "$all_channels" > "$CHANNEL_CACHE_FILE"
  echo "Cached $count channels." >&2
}

# Learn channel name→ID mapping from search results
# Called automatically to build cache from search hits
learn_channel_from_search() {
  local channel_id="$1"
  local channel_name="$2"

  if [[ -z "$channel_id" || -z "$channel_name" ]]; then
    return
  fi

  # Ensure cache file exists
  if [[ ! -f "$CHANNEL_CACHE_FILE" ]]; then
    echo "[]" > "$CHANNEL_CACHE_FILE"
  fi

  # Check if already cached
  local existing
  existing=$(jq -r --arg id "$channel_id" '.[] | select(.id == $id) | .id' "$CHANNEL_CACHE_FILE")
  if [[ -n "$existing" ]]; then
    return
  fi

  # Add to cache
  local updated
  updated=$(jq --arg id "$channel_id" --arg name "$channel_name" '. + [{id: $id, name: $name}]' "$CHANNEL_CACHE_FILE")
  echo "$updated" > "$CHANNEL_CACHE_FILE"
}

# Resolve channel name (with or without #) to channel ID
resolve_channel() {
  local input="$1"

  # Strip leading # if present
  input="${input#\#}"

  # If it looks like a channel ID already (starts with C/G), return it
  if [[ "$input" =~ ^[CG][A-Z0-9]+$ ]]; then
    echo "$input"
    return 0
  fi

  # Ensure cache exists
  if [[ ! -f "$CHANNEL_CACHE_FILE" ]]; then
    refresh_channel_cache
  fi

  # Lookup in cache
  local channel_id
  channel_id=$(jq -r --arg name "$input" '.[] | select(.name == $name) | .id' "$CHANNEL_CACHE_FILE")

  if [[ -n "$channel_id" ]]; then
    echo "$channel_id"
    return 0
  fi

  # Cache miss — try a search to discover channel ID
  local search_response
  search_response=$(slack_api_form "search.messages" "query=in:#${input}" "count=1" 2>/dev/null) || true

  if [[ -n "$search_response" ]]; then
    channel_id=$(echo "$search_response" | jq -r '.messages.matches[0].channel.id // ""')
    local channel_name
    channel_name=$(echo "$search_response" | jq -r '.messages.matches[0].channel.name // ""')
    if [[ -n "$channel_id" && "$channel_id" != "null" ]]; then
      learn_channel_from_search "$channel_id" "$channel_name"
      echo "$channel_id"
      return 0
    fi
  fi

  # Last resort — try refreshing full channel list
  refresh_channel_cache
  channel_id=$(jq -r --arg name "$input" '.[] | select(.name == $name) | .id' "$CHANNEL_CACHE_FILE")

  if [[ -n "$channel_id" ]]; then
    echo "$channel_id"
    return 0
  fi

  echo "ERROR: Channel '$input' not found." >&2
  echo "Tip: Use the channel ID directly (e.g., C0123ABCDEF from the channel URL)." >&2
  return 1
}

# ── User ID → display name lookup ────────────────────────────
USER_CACHE_FILE="${SLACK_DATA_DIR}/.slack-user-cache.json"

resolve_user() {
  local user_id="$1"

  # Ensure cache exists
  if [[ ! -f "$USER_CACHE_FILE" ]]; then
    echo "{}" > "$USER_CACHE_FILE"
  fi

  # Check cache
  local cached
  cached=$(jq -r --arg id "$user_id" '.[$id] // ""' "$USER_CACHE_FILE")
  if [[ -n "$cached" ]]; then
    echo "$cached"
    return 0
  fi

  # Fetch from API
  local response
  response=$(slack_api_form "users.info" "user=$user_id" 2>/dev/null) || true

  local name
  name=$(echo "$response" | jq -r '.user.profile.display_name // .user.profile.real_name // .user.name // ""' 2>/dev/null)

  if [[ -z "$name" || "$name" == "null" ]]; then
    name="$user_id"
  fi

  # Update cache
  local updated
  updated=$(jq --arg id "$user_id" --arg name "$name" '. + {($id): $name}' "$USER_CACHE_FILE")
  echo "$updated" > "$USER_CACHE_FILE"

  echo "$name"
}

# ── Formatting helpers ──────────────────────────────────────────
format_ts() {
  local ts="$1"
  # Slack timestamps are Unix epoch with decimal (e.g., 1234567890.123456)
  local epoch="${ts%%.*}"
  if [[ -z "$epoch" ]]; then
    echo "$ts"
    return
  fi
  # macOS/BSD
  date -r "$epoch" "+%Y-%m-%d %H:%M" 2>/dev/null && return
  # GNU date
  date -d "@$epoch" "+%Y-%m-%d %H:%M" 2>/dev/null && return
  echo "$ts"
}

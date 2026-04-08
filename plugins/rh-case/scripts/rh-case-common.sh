#!/usr/bin/env bash
# rh-case-common.sh — Shared helpers for Red Hat Support Case scripts
# Sourced by all other scripts in this directory.

set -euo pipefail

# Guard: must be sourced from bash, not run directly or from zsh
if [[ -z "${BASH_SOURCE[0]:-}" ]]; then
  echo "ERROR: rh-case-common.sh must be sourced from a bash script." >&2
  return 1 2>/dev/null || exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Persistent data directory (survives plugin updates)
RH_DATA_DIR="${CLAUDE_PLUGIN_DATA:-${PLUGIN_DIR}}"

# ── Config loading ──────────────────────────────────────────────
load_config() {
  local env_file=""

  # Search order:
  # 1. Project-local .env.redhat (user override per-project)
  # 2. Plugin data directory
  if [[ -f "$PWD/.env.redhat" ]]; then
    env_file="$PWD/.env.redhat"
  elif [[ -f "${RH_DATA_DIR}/.env" ]]; then
    env_file="${RH_DATA_DIR}/.env"
  fi

  if [[ -z "$env_file" ]]; then
    echo "ERROR: No credentials found." >&2
    echo "Run /rh-case:init to configure credentials." >&2
    return 1
  fi

  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a

  # Validate required vars
  for var in RH_OFFLINE_TOKEN; do
    if [[ -z "${!var:-}" ]]; then
      echo "ERROR: $var is not set in $env_file" >&2
      return 1
    fi
  done

  export RH_CONFIG_SOURCE="$env_file"
}

# ── Token management ───────────────────────────────────────────
# Cache file for the short-lived access token
TOKEN_CACHE_FILE="${TMPDIR:-/tmp}/.rh-access-token-cache"

get_access_token() {
  # Check cache: token file contains "TOKEN EXPIRY_EPOCH"
  if [[ -f "$TOKEN_CACHE_FILE" ]]; then
    local cached
    cached=$(cat "$TOKEN_CACHE_FILE")
    local cached_token cached_expiry
    cached_token=$(echo "$cached" | cut -d' ' -f1)
    cached_expiry=$(echo "$cached" | cut -d' ' -f2)
    local now
    now=$(date +%s)
    # Use cached token if it has >60s remaining
    if [[ "$cached_expiry" -gt $((now + 60)) ]]; then
      echo "$cached_token"
      return 0
    fi
  fi

  # Request new access token
  local response
  response=$(curl -s -X POST \
    "https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token" \
    -d "grant_type=refresh_token&client_id=rhsm-api&refresh_token=${RH_OFFLINE_TOKEN}")

  local token
  token=$(echo "$response" | jq -r '.access_token // empty')
  if [[ -z "$token" ]]; then
    echo "ERROR: Failed to obtain access token. Check your offline token." >&2
    echo "$response" | jq -r '.error_description // .error // "Unknown error"' >&2
    return 1
  fi

  local expires_in
  expires_in=$(echo "$response" | jq -r '.expires_in // 900')
  local expiry_epoch
  expiry_epoch=$(( $(date +%s) + expires_in ))

  # Cache it
  echo "$token $expiry_epoch" > "$TOKEN_CACHE_FILE"
  chmod 600 "$TOKEN_CACHE_FILE"

  echo "$token"
}

# ── API helpers ─────────────────────────────────────────────────
# rh_api METHOD ENDPOINT [DATA]
# For the standard REST API (api.access.redhat.com)
rh_api() {
  local method="$1"
  local endpoint="$2"
  local data="${3:-}"
  local token
  token=$(get_access_token)

  local base_url="https://api.access.redhat.com"
  local url="${base_url}${endpoint}"

  local curl_args=(
    -s -X "$method"
    -H "Authorization: Bearer $token"
    -H "Accept: application/json"
  )

  if [[ -n "$data" ]]; then
    curl_args+=(-H "Content-Type: application/json" -d "$data")
  fi

  local response http_code
  response=$(curl -w "\n%{http_code}" "${curl_args[@]}" "$url")
  http_code=$(echo "$response" | tail -1)
  response=$(echo "$response" | sed '$d')

  # Retry once on 401 (token expired)
  if [[ "$http_code" == "401" ]]; then
    rm -f "$TOKEN_CACHE_FILE"
    token=$(get_access_token)
    local retry_args=(
      -s -w "\n%{http_code}" -X "$method"
      -H "Authorization: Bearer $token"
      -H "Accept: application/json"
    )
    if [[ -n "$data" ]]; then
      retry_args+=(-H "Content-Type: application/json" -d "$data")
    fi
    response=$(curl "${retry_args[@]}" "$url")
    http_code=$(echo "$response" | tail -1)
    response=$(echo "$response" | sed '$d')
  fi

  if [[ "$http_code" -ge 400 ]]; then
    echo "ERROR: API returned HTTP $http_code for $method $endpoint" >&2
    echo "$response" >&2
    return 1
  fi

  echo "$response"
}

# rh_hydra_api METHOD ENDPOINT [DATA]
# For the Hydra search API (access.redhat.com)
rh_hydra_api() {
  local method="$1"
  local endpoint="$2"
  local data="${3:-}"
  local token
  token=$(get_access_token)

  local base_url="https://access.redhat.com"
  local url="${base_url}${endpoint}"

  local response http_code
  if [[ -n "$data" ]]; then
    response=$(curl -s -w "\n%{http_code}" -X "$method" \
      -H "Authorization: Bearer $token" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -d "$data" \
      "$url")
  else
    response=$(curl -s -w "\n%{http_code}" -X "$method" \
      -H "Authorization: Bearer $token" \
      -H "Accept: application/json" \
      "$url")
  fi

  http_code=$(echo "$response" | tail -1)
  response=$(echo "$response" | sed '$d')

  # Retry on 401
  if [[ "$http_code" == "401" ]]; then
    rm -f "$TOKEN_CACHE_FILE"
    token=$(get_access_token)
    if [[ -n "$data" ]]; then
      response=$(curl -s -w "\n%{http_code}" -X "$method" \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "$url")
    else
      response=$(curl -s -w "\n%{http_code}" -X "$method" \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/json" \
        "$url")
    fi
    http_code=$(echo "$response" | tail -1)
    response=$(echo "$response" | sed '$d')
  fi

  if [[ "$http_code" -ge 400 ]]; then
    echo "ERROR: Hydra API returned HTTP $http_code for $method $endpoint" >&2
    echo "$response" >&2
    return 1
  fi

  echo "$response"
}

# rh_download URL OUTPUT_FILE
# Download a file from Red Hat API (attachments, etc.)
rh_download() {
  local url="$1"
  local output="$2"
  local token
  token=$(get_access_token)

  local http_code
  http_code=$(curl -s -w "%{http_code}" \
    -H "Authorization: Bearer $token" \
    -o "$output" \
    "$url")

  if [[ "$http_code" == "401" ]]; then
    rm -f "$TOKEN_CACHE_FILE"
    token=$(get_access_token)
    http_code=$(curl -s -w "%{http_code}" \
      -H "Authorization: Bearer $token" \
      -o "$output" \
      "$url")
  fi

  if [[ "$http_code" -ge 400 ]]; then
    echo "ERROR: Download failed (HTTP $http_code): $url" >&2
    rm -f "$output"
    return 1
  fi
}

# ── Formatting helpers ──────────────────────────────────────────
format_date() {
  local date_str="$1"
  # Try to format ISO date to readable format; fall back to raw
  if command -v gdate &>/dev/null; then
    gdate -d "$date_str" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$date_str"
  elif date -j -f "%Y-%m-%dT%H:%M:%SZ" "$date_str" "+%Y-%m-%d %H:%M" 2>/dev/null; then
    :
  else
    echo "${date_str%%T*}"
  fi
}

severity_icon() {
  case "$1" in
    *Urgent*) echo "!!!" ;;
    *High*)   echo "!!" ;;
    *Normal*) echo "!" ;;
    *Low*)    echo "." ;;
    *)        echo "-" ;;
  esac
}

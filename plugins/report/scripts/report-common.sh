#!/usr/bin/env bash
# report-common.sh — Shared helpers for report scripts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Persistent data directory (survives plugin updates)
REPORT_DATA_DIR="${CLAUDE_PLUGIN_DATA:-${PLUGIN_DIR}}"

# ── Config loading ──────────────────────────────────────────────
load_config() {
  local env_file=""

  if [[ -f "$PWD/.env.report" ]]; then
    env_file="$PWD/.env.report"
  elif [[ -f "$REPORT_DATA_DIR/.env" ]]; then
    env_file="$REPORT_DATA_DIR/.env"
  fi

  if [[ -z "$env_file" ]]; then
    echo "ERROR: No .env.report or .env found." >&2
    echo "Run /report init to configure." >&2
    return 1
  fi

  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a

  # Validate required vars
  if [[ -z "${REPORT_GIT_AUTHOR:-}" ]]; then
    echo "ERROR: REPORT_GIT_AUTHOR is not set in $env_file" >&2
    return 1
  fi

  if [[ -z "${REPORT_REPOS:-}" ]]; then
    echo "ERROR: REPORT_REPOS is not set in $env_file" >&2
    return 1
  fi

  export REPORT_CONFIG_SOURCE="$env_file"
}

# ── Date helpers ────────────────────────────────────────────────
# Compute date N days ago in YYYY-MM-DD format
days_ago() {
  local n="$1"
  # macOS/BSD
  date -v-"${n}d" "+%Y-%m-%d" 2>/dev/null && return
  # GNU date
  date -d "$n days ago" "+%Y-%m-%d" 2>/dev/null && return
  echo "ERROR: Cannot compute date" >&2
  return 1
}

# Format date for display
format_date() {
  local d="$1"
  # macOS/BSD
  date -j -f "%Y-%m-%d" "$d" "+%b %d, %Y" 2>/dev/null && return
  # GNU date
  date -d "$d" "+%b %d, %Y" 2>/dev/null && return
  echo "$d"
}

# ── Repo discovery ──────────────────────────────────────────────
# Resolve REPORT_REPOS (comma-separated) into list of git repo paths.
# Each entry can be a git repo or a parent directory containing repos.
discover_repos() {
  local repos=()

  IFS=',' read -ra entries <<< "$REPORT_REPOS"
  for entry in "${entries[@]}"; do
    # Expand ~ and trim whitespace
    entry="${entry## }"
    entry="${entry%% }"
    entry="${entry/#\~/$HOME}"

    if [[ ! -d "$entry" ]]; then
      echo "WARNING: $entry does not exist, skipping" >&2
      continue
    fi

    # Check for git repos one level deep first
    local found_sub=false
    for subdir in "$entry"/*/; do
      if [[ -d "$subdir/.git" ]]; then
        repos+=("${subdir%/}")
        found_sub=true
      fi
    done

    # If no sub-repos found but entry itself is a git repo, use it directly
    if [[ "$found_sub" == false && -d "$entry/.git" ]]; then
      repos+=("$entry")
    fi
  done

  if [[ ${#repos[@]} -gt 0 ]]; then
    printf '%s\n' "${repos[@]}"
  fi
}

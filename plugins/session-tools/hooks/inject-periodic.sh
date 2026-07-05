#!/usr/bin/env bash
#
# UserPromptSubmit hook for the session-tools plugin.
# Re-injects the self-check reminder every Nth prompt of a session to counter
# attention decay in long sessions. N defaults to 10 and can be overridden via
# SESSION_TOOLS_SELF_CHECK_INTERVAL. State is a per-session counter file under
# the Claude config dir. Any failure degrades to a silent no-op so the user's
# prompt is never blocked.

set -euo pipefail

readonly DEFAULT_INTERVAL=10

# main: increment the per-session counter and, on every Nth call, emit the
#   reminder as additionalContext JSON.
# Arguments: none (JSON payload on stdin)
# Outputs: UserPromptSubmit hookSpecificOutput JSON on inject, otherwise nothing
# Returns: always 0 (fail-safe)
main() {
  local script_dir input session_id interval config_dir counter_dir counter_file count reminder
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

  command -v jq >/dev/null 2>&1 || return 0

  input="$(cat)"
  session_id="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)"
  [[ -n "$session_id" ]] || return 0
  session_id="${session_id//[^A-Za-z0-9_-]/_}"

  interval="${SESSION_TOOLS_SELF_CHECK_INTERVAL:-$DEFAULT_INTERVAL}"
  [[ "$interval" =~ ^[1-9][0-9]*$ ]] || interval="$DEFAULT_INTERVAL"

  config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  counter_dir="${config_dir}/session-tools/counters"
  mkdir -p -- "$counter_dir" 2>/dev/null || return 0
  counter_file="${counter_dir}/${session_id}.count"

  prune_stale "$counter_dir"

  count=0
  if [[ -f "$counter_file" ]]; then
    count="$(cat -- "$counter_file" 2>/dev/null || printf '0')"
  fi
  [[ "$count" =~ ^[0-9]+$ ]] || count=0
  count=$((count + 1))
  printf '%s' "$count" > "$counter_file" 2>/dev/null || return 0

  if (( count % interval == 0 )); then
    reminder="$(cat -- "${script_dir}/reminder.md" 2>/dev/null || true)"
    [[ -n "$reminder" ]] || return 0
    jq -n --arg ctx "$reminder" \
      '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}' \
      2>/dev/null || true
  fi
}

# prune_stale: best-effort deletion of counter files older than ~1 day to bound
#   accumulation under the config dir.
# Arguments:
#   $1 - counter directory path
# Outputs: none
# Returns: 0 (best-effort; failures ignored)
prune_stale() {
  local dir="${1:-}"
  [[ -d "$dir" ]] || return 0
  find "$dir" -type f -name '*.count' -mtime +0 -delete 2>/dev/null || true
}

main "$@" || true
exit 0

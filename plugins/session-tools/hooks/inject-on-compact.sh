#!/usr/bin/env bash
#
# SessionStart hook for the session-tools plugin.
# Re-injects the self-check reminder after a compaction or on resuming a
# session, where the rule's salience in context is likely to have dropped.
# Injects only when the SessionStart `source` is `compact` or `resume`.
# Any failure degrades to a silent no-op so the session is never disrupted.

set -euo pipefail

# main: read the hook payload from stdin and, when the SessionStart source is
#   `compact` or `resume`, emit the reminder as additionalContext JSON.
# Arguments: none (JSON payload on stdin)
# Outputs: SessionStart hookSpecificOutput JSON on inject, otherwise nothing
# Returns: always 0 (fail-safe)
main() {
  local script_dir input start_source reminder
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

  command -v jq >/dev/null 2>&1 || return 0

  input="$(cat)"
  start_source="$(printf '%s' "$input" | jq -r '.source // empty' 2>/dev/null || true)"

  case "$start_source" in
    compact | resume) ;;
    *) return 0 ;;
  esac

  reminder="$(cat -- "${script_dir}/reminder.md" 2>/dev/null || true)"
  [[ -n "$reminder" ]] || return 0

  jq -n --arg ctx "$reminder" \
    '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}' \
    2>/dev/null || true
}

main "$@" || true
exit 0

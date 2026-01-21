#!/usr/bin/env bash
set -euo pipefail

# Stops a running Android emulator.
#
# Usage: ./stop-emulator.sh [avd_name]
#
# Arguments:
#   avd_name (optional): The name of the AVD to stop
#
# Outputs:
#   JSON object with result information

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../utils.sh"

# Main entry point
#
# Arguments:
#   $1: AVD name (optional)
main() {
  local target_avd=${1:-}

  local adb
  adb=$(find_adb) || true

  if [[ -z "$adb" ]]; then
    cat <<'EOF'
{
  "success": false,
  "error": "adb not found",
  "hint": "Set ANDROID_HOME or ANDROID_SDK_ROOT environment variable",
  "running": []
}
EOF
    exit 1
  fi

  local running_data
  running_data=$(get_running_emulators "$adb")

  local running_count=0
  if [[ -n "$running_data" ]]; then
    running_count=$(echo "$running_data" | grep -c .)
  fi

  # No AVD specified
  if [[ -z "$target_avd" ]]; then
    if [[ "$running_count" -eq 0 ]]; then
      output_error "no running emulator" "Start an emulator first using start-emulator skill"
      exit 1
    elif [[ "$running_count" -eq 1 ]]; then
      local serial avd
      read -r serial avd <<< "$running_data"
      stop_emulator "$adb" "$serial" "$avd"
      exit 0
    else
      # Multiple running, ask user to select
      output_select_emulator "$running_data"
      exit 0
    fi
  fi

  # AVD specified - find it in running emulators
  local found_serial=""
  while IFS=' ' read -r serial avd; do
    [[ -z "$serial" ]] && continue
    if [[ "$avd" == "$target_avd" ]]; then
      found_serial=$serial
      break
    fi
  done <<< "$running_data"

  if [[ -n "$found_serial" ]]; then
    stop_emulator "$adb" "$found_serial" "$target_avd"
    exit 0
  else
    output_error "cannot find emulator '$target_avd'" "Available running emulators listed below" "$running_data"
    exit 1
  fi
}

# Gets the AVD name for a running emulator
#
# Arguments:
#   $1: adb executable path
#   $2: emulator serial (e.g., emulator-5554)
#
# Outputs:
#   Prints the AVD name
get_avd_name() {
  local adb=$1
  local serial=$2
  "$adb" -s "$serial" emu avd name 2>/dev/null | head -1 | tr -d '\r'
}

# Gets list of running emulators with their AVD names
#
# Arguments:
#   $1: adb executable path
#
# Outputs:
#   Prints lines of "serial avd_name" pairs
get_running_emulators() {
  local adb=$1
  local serials avd_name

  serials=$("$adb" devices 2>/dev/null | grep '^emulator-' | cut -f1) || true

  if [[ -z "$serials" ]]; then
    return 0
  fi

  while IFS= read -r serial; do
    [[ -z "$serial" ]] && continue
    avd_name=$(get_avd_name "$adb" "$serial")
    if [[ -n "$avd_name" ]]; then
      echo "$serial $avd_name"
    fi
  done <<< "$serials"
}

# Stops an emulator by serial number
#
# Arguments:
#   $1: adb executable path
#   $2: emulator serial
#   $3: AVD name
#
# Outputs:
#   Prints JSON success message
stop_emulator() {
  local adb=$1
  local serial=$2
  local avd=$3

  "$adb" -s "$serial" emu kill &>/dev/null || true

  cat <<EOF
{
  "success": true,
  "message": "Emulator stopped",
  "avd": "$(json_escape "$avd")",
  "serial": "$(json_escape "$serial")"
}
EOF
}

# Outputs error JSON with running emulators hint
#
# Arguments:
#   $1: error message
#   $2: hint message
#   $3: running emulators data (optional)
#
# Outputs:
#   Prints JSON error object
output_error() {
  local error=$1
  local hint=$2
  local running_data=${3:-}

  local running_json="[]"
  if [[ -n "$running_data" ]]; then
    running_json="["
    local first=true
    while IFS=' ' read -r serial avd; do
      [[ -z "$serial" ]] && continue
      if [[ "$first" == "true" ]]; then
        first=false
      else
        running_json+=","
      fi
      running_json+="{\"avd\":\"$(json_escape "$avd")\",\"serial\":\"$(json_escape "$serial")\"}"
    done <<< "$running_data"
    running_json+="]"
  fi

  cat <<EOF
{
  "success": false,
  "error": "$(json_escape "$error")",
  "hint": "$(json_escape "$hint")",
  "running": $running_json
}
EOF
}

# Outputs JSON for multiple running emulators (for user selection)
#
# Arguments:
#   $1: running emulators data
#
# Outputs:
#   Prints JSON with action: select_emulator
output_select_emulator() {
  local running_data=$1

  local running_json="["
  local first=true
  while IFS=' ' read -r serial avd; do
    [[ -z "$serial" ]] && continue
    if [[ "$first" == "true" ]]; then
      first=false
    else
      running_json+=","
    fi
    running_json+="{\"avd\":\"$(json_escape "$avd")\",\"serial\":\"$(json_escape "$serial")\"}"
  done <<< "$running_data"
  running_json+="]"

  cat <<EOF
{
  "success": true,
  "action": "select_emulator",
  "running": $running_json
}
EOF
}

main "$@"

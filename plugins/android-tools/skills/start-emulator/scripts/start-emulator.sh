#!/usr/bin/env bash
set -euo pipefail

# Starts an Android emulator (AVD).
#
# Usage: ./start-emulator.sh [avd_name] [boot_type]
#
# Arguments:
#   avd_name  - (optional) Name of the AVD to start
#   boot_type - (optional) "quick" or "cold" (default: quick)
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
#   $2: boot type (optional)
main() {
  local avd_name=${1:-""}
  local boot_type=${2:-"quick"}

  local emulator
  emulator=$(find_emulator) || true

  if [[ -z "$emulator" ]]; then
    output_error "emulator not found" "Set ANDROID_HOME or ANDROID_SDK_ROOT environment variable"
  fi

  local avd_list
  avd_list=$(list_avds "$emulator")

  if [[ -z "$avd_list" ]]; then
    output_error "no available emulator" "Create an AVD using Android Studio or avdmanager"
  fi

  local avd_json
  avd_json=$(avd_list_to_json "$avd_list")

  # No AVD name specified - return list for Claude to ask user
  if [[ -z "$avd_name" ]]; then
    output_select_emulator "$avd_json"
    exit 0
  fi

  # AVD name specified, check if it exists
  if echo "$avd_list" | grep -qx "$avd_name"; then
    launch_emulator "$emulator" "$avd_name" "$boot_type"
  else
    output_error "cannot find emulator '$avd_name'" "Available emulators are listed below" "$avd_json"
  fi
}

# Lists available AVDs
#
# Arguments:
#   $1: emulator executable path
#
# Outputs:
#   Prints list of AVD names, one per line
list_avds() {
  local emulator=$1
  "$emulator" -list-avds 2>/dev/null || true
}

# Outputs error JSON and exits
#
# Arguments:
#   $1: error message
#   $2: hint message
#   $3: (optional) emulators array as JSON string
#
# Outputs:
#   Prints JSON error object
output_error() {
  local error=$1
  local hint=$2
  local emulators=${3:-"[]"}

  cat <<EOF
{
  "success": false,
  "error": "$(json_escape "$error")",
  "hint": "$(json_escape "$hint")",
  "emulators": $emulators
}
EOF
  exit 1
}

# Outputs success JSON for emulator launch
#
# Arguments:
#   $1: AVD name
#   $2: cold_boot (true or false)
#
# Outputs:
#   Prints JSON success object
output_launch_success() {
  local avd=$1
  local cold_boot=$2

  cat <<EOF
{
  "success": true,
  "message": "Emulator started",
  "avd": "$(json_escape "$avd")",
  "cold_boot": $cold_boot
}
EOF
}

# Outputs JSON for emulator selection
#
# Arguments:
#   $1: emulators array as JSON string
#
# Outputs:
#   Prints JSON object with action: select_emulator
output_select_emulator() {
  local emulators=$1

  cat <<EOF
{
  "success": true,
  "action": "select_emulator",
  "emulators": $emulators
}
EOF
}

# Converts AVD list to JSON array
#
# Arguments:
#   $1: AVD list (newline-separated)
#
# Outputs:
#   Prints JSON array string
avd_list_to_json() {
  local avd_list=$1
  local json="["
  local first=true

  while IFS= read -r avd_name; do
    [[ -z "$avd_name" ]] && continue
    if [[ "$first" == "true" ]]; then
      first=false
    else
      json+=", "
    fi
    json+="\"$(json_escape "$avd_name")\""
  done <<< "$avd_list"

  json+="]"
  echo "$json"
}

# Launches the emulator
#
# Arguments:
#   $1: emulator executable path
#   $2: AVD name
#   $3: boot_type ("quick" or "cold")
#
# Outputs:
#   Prints JSON success object
launch_emulator() {
  local emulator=$1
  local avd_name=$2
  local boot_type=$3

  local cold_boot="false"

  if [[ "$boot_type" == "cold" ]]; then
    cold_boot="true"
    "$emulator" "@$avd_name" -no-snapshot-load &>/dev/null &
  else
    "$emulator" "@$avd_name" &>/dev/null &
  fi

  disown

  output_launch_success "$avd_name" "$cold_boot"
}

main "$@"

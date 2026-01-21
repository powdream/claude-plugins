#!/usr/bin/env bash
set -euo pipefail

# Lists available Android emulators (AVDs) with their properties.
#
# Usage: ./list-emulators.sh
#
# Outputs:
#   JSON object with emulator information

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../utils.sh"

# Main entry point
main() {
  local emulator
  emulator=$(find_emulator) || true

  if [[ -z "$emulator" ]]; then
    cat <<'EOF'
{
  "success": false,
  "error": "emulator not found",
  "hint": "Set ANDROID_HOME or ANDROID_SDK_ROOT environment variable",
  "emulators": []
}
EOF
    exit 1
  fi

  local avd_list
  avd_list=$("$emulator" -list-avds 2>/dev/null) || true

  if [[ -z "$avd_list" ]]; then
    cat <<'EOF'
{
  "success": true,
  "count": 0,
  "emulators": []
}
EOF
    exit 0
  fi

  print_emulators "$avd_list"
}

# Gets a value from AVD config.ini file
#
# Arguments:
#   $1: config file path
#   $2: key name
#
# Outputs:
#   Prints the value for the key
get_config_value() {
  local config_file=$1
  local key=$2
  grep "^${key}=" "$config_file" 2>/dev/null | cut -d'=' -f2-
}

# Extracts API level from image.sysdir.1 path
#
# Arguments:
#   $1: sysdir path string
#
# Outputs:
#   Prints the API level number
extract_api_level() {
  local sysdir=$1
  echo "$sysdir" | grep -oE 'android-[0-9]+' | grep -oE '[0-9]+' | head -1
}

# Prints emulator information as JSON
#
# Arguments:
#   $1: AVD list from emulator -list-avds
#
# Outputs:
#   Prints JSON object with emulator information
print_emulators() {
  local avd_list=$1
  local avd_dir="$HOME/.android/avd"

  echo "{"
  echo "  \"success\": true,"

  local emulators_json=""
  local first=true
  local avd_name config_file device sysdir width height tag_id playstore api resolution has_playstore

  while IFS= read -r avd_name; do
    [[ -z "$avd_name" ]] && continue

    config_file="$avd_dir/${avd_name}.avd/config.ini"

    if [[ -f "$config_file" ]]; then
      device=$(get_config_value "$config_file" "hw.device.name")
      sysdir=$(get_config_value "$config_file" "image.sysdir.1")
      width=$(get_config_value "$config_file" "hw.lcd.width")
      height=$(get_config_value "$config_file" "hw.lcd.height")
      tag_id=$(get_config_value "$config_file" "tag.id")
      playstore=$(get_config_value "$config_file" "PlayStore.enabled")

      api=$(extract_api_level "$sysdir")

      if [[ -n "$width" && -n "$height" ]]; then
        resolution="${width}x${height}"
      else
        resolution=""
      fi

      has_playstore="false"
      [[ "$playstore" == "true" ]] && has_playstore="true"
    else
      device=""
      api=""
      resolution=""
      tag_id=""
      has_playstore="false"
    fi

    if [[ "$first" == "true" ]]; then
      first=false
    else
      emulators_json+=","
    fi

    emulators_json+="
    {
      \"name\": \"$(json_escape "$avd_name")\",
      \"device\": \"$(json_escape "$device")\",
      \"api\": \"$(json_escape "$api")\",
      \"resolution\": \"$(json_escape "$resolution")\",
      \"image\": \"$(json_escape "$tag_id")\",
      \"playstore\": $has_playstore
    }"
  done <<< "$avd_list"

  local avd_count
  avd_count=$(echo "$avd_list" | grep -c .)

  echo "  \"count\": $avd_count,"
  echo "  \"emulators\": [$emulators_json"
  echo "  ]"
  echo "}"
}

main "$@"

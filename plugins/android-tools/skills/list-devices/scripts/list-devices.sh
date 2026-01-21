#!/usr/bin/env bash
set -euo pipefail

# Lists connected Android devices with their properties.
#
# Usage: ./list-devices.sh
#
# Outputs:
#   JSON object with device information

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../utils.sh"

# Main entry point
main() {
  local adb
  adb=$(find_adb) || true

  if [[ -z "$adb" ]]; then
    cat <<'EOF'
{
  "success": false,
  "error": "adb not found",
  "hint": "Set ANDROID_HOME or ANDROID_SDK_ROOT environment variable",
  "devices": []
}
EOF
    exit 1
  fi

  local devices
  devices=$("$adb" devices 2>/dev/null | tail -n +2 | grep -v '^$') || true

  if [[ -z "$devices" ]]; then
    cat <<'EOF'
{
  "success": true,
  "count": 0,
  "devices": []
}
EOF
    exit 0
  fi

  print_devices "$adb" "$devices"
}

# Gets a device property using adb shell getprop
#
# Arguments:
#   $1: adb executable path
#   $2: device serial number
#   $3: property name
#
# Outputs:
#   Prints the property value
get_prop() {
  local adb=$1
  local serial=$2
  local prop=$3
  "$adb" -s "$serial" shell getprop "$prop" < /dev/null 2>/dev/null | tr -d '\r'
}

# Prints device information as JSON
#
# Arguments:
#   $1: adb executable path
#   $2: device list from adb devices
#
# Outputs:
#   Prints JSON object with device information
print_devices() {
  local adb=$1
  local devices=$2

  echo "{"
  echo "  \"success\": true,"

  local devices_json=""
  local first=true
  local device_count=0
  local serial status type model api

  while IFS=$'\t' read -r serial status; do
    [[ -z "$serial" ]] && continue

    if [[ "$serial" == emulator-* ]]; then
      type="emulator"
    else
      type="physical"
    fi

    model=$(get_prop "$adb" "$serial" "ro.product.model") || true
    api=$(get_prop "$adb" "$serial" "ro.build.version.sdk") || true

    model=${model:-""}
    api=${api:-""}

    if [[ "$first" == "true" ]]; then
      first=false
    else
      devices_json+=","
    fi

    devices_json+="
    {
      \"serial\": \"$(json_escape "$serial")\",
      \"type\": \"$(json_escape "$type")\",
      \"model\": \"$(json_escape "$model")\",
      \"api\": \"$(json_escape "$api")\",
      \"status\": \"$(json_escape "$status")\"
    }"

    device_count=$((device_count + 1))
  done <<< "$devices"

  echo "  \"count\": $device_count,"
  echo "  \"devices\": [$devices_json"
  echo "  ]"
  echo "}"
}

main "$@"

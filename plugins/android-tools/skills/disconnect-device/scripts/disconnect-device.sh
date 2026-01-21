#!/usr/bin/env bash
set -euo pipefail

# Disconnects wireless Android devices from ADB.
#
# Usage: ./disconnect-device.sh [all|ip:port]
#
# Arguments:
#   all      - Disconnect all wireless devices
#   ip:port  - Disconnect specific device (e.g., 192.168.1.100:5555)
#   (none)   - Auto-detect: 0 devices -> message, 1 -> auto, 2+ -> select
#
# Outputs:
#   JSON object with disconnect result

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../utils.sh"

# Main entry point
#
# Arguments:
#   $1: (optional) "all" to disconnect all, or "ip:port" for specific device
#
# Outputs:
#   Prints JSON object with disconnect result
#
# Returns:
#   0 on success, 1 on failure
main() {
  local adb
  adb=$(find_adb) || true

  if [[ -z "$adb" ]]; then
    cat <<'EOF'
{
  "success": false,
  "error": "adb not found",
  "hint": "Set ANDROID_HOME or ANDROID_SDK_ROOT environment variable"
}
EOF
    exit 1
  fi

  local arg="${1:-}"

  # Handle "all" argument
  if [[ "$arg" == "all" ]]; then
    "$adb" disconnect &>/dev/null || true
    cat <<'EOF'
{
  "success": true,
  "message": "Disconnected all wireless devices"
}
EOF
    exit 0
  fi

  # Handle specific IP:port argument
  if [[ -n "$arg" ]] && is_wireless_device "$arg"; then
    local result
    result=$("$adb" disconnect "$arg" 2>&1) || true

    if [[ "$result" == *"disconnected"* ]]; then
      cat <<EOF
{
  "success": true,
  "message": "Disconnected from $arg",
  "serial": "$arg"
}
EOF
      exit 0
    else
      cat <<EOF
{
  "success": false,
  "error": "Failed to disconnect from $arg",
  "hint": "Device may already be disconnected"
}
EOF
      exit 1
    fi
  fi

  # No argument or invalid argument - auto-detect wireless devices
  local wireless_devices
  wireless_devices=$(get_wireless_devices "$adb")

  local device_count
  device_count=$(count_wireless_devices "$wireless_devices")

  # No wireless devices
  if [[ "$device_count" -eq 0 ]]; then
    cat <<'EOF'
{
  "success": true,
  "message": "No wireless devices connected"
}
EOF
    exit 0
  fi

  # Single wireless device - auto disconnect
  if [[ "$device_count" -eq 1 ]]; then
    local serial result
    serial=$(get_first_wireless_serial "$wireless_devices")
    result=$("$adb" disconnect "$serial" 2>&1) || true

    if [[ "$result" == *"disconnected"* ]]; then
      cat <<EOF
{
  "success": true,
  "message": "Disconnected from $serial",
  "serial": "$serial"
}
EOF
      exit 0
    else
      cat <<EOF
{
  "success": false,
  "error": "Failed to disconnect from $serial",
  "hint": "Device may already be disconnected"
}
EOF
      exit 1
    fi
  fi

  # Multiple wireless devices - return selection prompt
  cat <<EOF
{
  "success": true,
  "action": "select_device",
  "devices": [$wireless_devices
  ]
}
EOF
}

# Checks if a serial is a wireless device (IP:port format)
#
# Arguments:
#   $1: device serial
#
# Returns:
#   0 if wireless device, 1 otherwise
is_wireless_device() {
  local serial=$1
  [[ "$serial" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]
}

# Gets list of wireless devices with their info
#
# Arguments:
#   $1: adb executable path
#
# Outputs:
#   Prints wireless devices info as JSON array entries
get_wireless_devices() {
  local adb=$1
  local devices
  devices=$("$adb" devices 2>/dev/null | tail -n +2 | grep -v '^$') || true

  if [[ -z "$devices" ]]; then
    return
  fi

  local result=""
  local first=true
  local serial status model api

  while IFS=$'\t' read -r serial status; do
    [[ -z "$serial" ]] && continue
    [[ "$status" != "device" ]] && continue

    if is_wireless_device "$serial"; then
      model=$(adb_get_device_prop "$adb" "$serial" "ro.product.model") || true
      api=$(adb_get_device_prop "$adb" "$serial" "ro.build.version.sdk") || true

      model=${model:-""}
      api=${api:-""}

      if [[ "$first" == "true" ]]; then
        first=false
      else
        result+=","
      fi

      result+="
    { \"serial\": \"$(json_escape "$serial")\", \"model\": \"$(json_escape "$model")\", \"api\": \"$(json_escape "$api")\" }"
    fi
  done <<< "$devices"

  echo "$result"
}

# Counts wireless devices
#
# Arguments:
#   $1: wireless devices JSON (from get_wireless_devices)
#
# Outputs:
#   Prints the number of devices
#
# Returns:
#   0 always
count_wireless_devices() {
  local devices_json=$1
  if [[ -z "$devices_json" ]]; then
    echo 0
  else
    echo "$devices_json" | grep -c '"serial"' || echo 0
  fi
}

# Gets the serial of the first wireless device
#
# Arguments:
#   $1: wireless devices JSON
#
# Outputs:
#   Prints the serial of the first device
#
# Returns:
#   0 always
get_first_wireless_serial() {
  local devices_json=$1
  echo "$devices_json" | grep -o '"serial": "[^"]*"' | head -1 | sed 's/"serial": "//;s/"$//'
}

main "$@"

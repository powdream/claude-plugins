#!/usr/bin/env bash
set -euo pipefail

# Connects to an Android device over ADB wireless (TCP/IP).
#
# Usage: ./connect-device.sh [ip:port]
#        ./connect-device.sh [ip] [port]
#
# Arguments:
#   $1: IP address (or IP:PORT combined)
#   $2: Port number (optional, default: 5555)
#
# Outputs:
#   JSON object with connection result

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../utils.sh"

# Default ADB port
DEFAULT_PORT="5555"

# Mutable state for connection target (set by parse_args)
ip=""
port=""

# Main entry point
#
# Arguments:
#   $@: command line arguments
main() {
  local adb
  adb=$(find_adb) || true

  if [[ -z "$adb" ]]; then
    output_error "adb not found" "Set ANDROID_HOME or ANDROID_SDK_ROOT environment variable"
    exit 1
  fi

  if ! parse_args "$@"; then
    request_input
    exit 0
  fi

  if [[ -z "$ip" ]]; then
    output_error "IP address is required" "Provide IP address as first argument"
    exit 1
  fi

  local target="${ip}:${port}"
  local result
  result=$("$adb" connect "$target" 2>&1) || true

  # Check if connection was successful
  # adb connect returns messages like:
  # - "connected to IP:PORT"
  # - "already connected to IP:PORT"
  # - "failed to connect to IP:PORT"
  # - "cannot connect to IP:PORT: Connection refused"
  if [[ "$result" == *"connected to"* ]] && [[ "$result" != *"failed"* ]]; then
    output_success "$ip" "$port" "Connected to $target"
    exit 0
  else
    output_error "Failed to connect to $target" "Ensure the device is on the same network and ADB over WiFi is enabled"
    exit 1
  fi
}

# Parses IP and port from arguments
#
# Arguments:
#   $@: Command line arguments
#
# Outputs:
#   Sets ip and port global variables
#
# Returns:
#   0 if arguments provided, 1 if no arguments
parse_args() {
  ip=""
  port="$DEFAULT_PORT"

  if [[ $# -eq 0 ]]; then
    return 1
  fi

  if [[ "$1" == *":"* ]]; then
    # Format: IP:PORT
    ip="${1%%:*}"
    port="${1##*:}"
  elif [[ $# -ge 2 ]]; then
    # Format: IP PORT
    ip="$1"
    port="$2"
  else
    # Format: IP only
    ip="$1"
  fi

  return 0
}

# Outputs JSON requesting user input
#
# Outputs:
#   Prints JSON requesting IP and port input
request_input() {
  cat <<'EOF'
{
  "success": true,
  "action": "request_input",
  "message": "Please provide IP address and port"
}
EOF
}

# Outputs success JSON
#
# Arguments:
#   $1: IP address
#   $2: Port number
#   $3: Message
#
# Outputs:
#   Prints JSON success object
output_success() {
  local ip=$1
  local port=$2
  local message=$3

  cat <<EOF
{
  "success": true,
  "message": "$(json_escape "$message")",
  "ip": "$(json_escape "$ip")",
  "port": "$(json_escape "$port")"
}
EOF
}

# Outputs error JSON
#
# Arguments:
#   $1: Error message
#   $2: Hint message
#
# Outputs:
#   Prints JSON error object
output_error() {
  local error=$1
  local hint=$2

  cat <<EOF
{
  "success": false,
  "error": "$(json_escape "$error")",
  "hint": "$(json_escape "$hint")"
}
EOF
}

main "$@"

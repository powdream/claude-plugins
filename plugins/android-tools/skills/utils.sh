#!/usr/bin/env bash

# Common utility functions for Android tools skills

# Finds the adb executable in PATH or SDK locations
#
# Outputs:
#   Prints the path to adb executable
#
# Returns:
#   0 if found, 1 if not found
find_adb() {
  if command -v adb &>/dev/null; then
    echo "adb"
    return 0
  fi

  if [[ -n "${ANDROID_HOME:-}" && -x "${ANDROID_HOME}/platform-tools/adb" ]]; then
    echo "${ANDROID_HOME}/platform-tools/adb"
    return 0
  fi

  if [[ -n "${ANDROID_SDK_ROOT:-}" && -x "${ANDROID_SDK_ROOT}/platform-tools/adb" ]]; then
    echo "${ANDROID_SDK_ROOT}/platform-tools/adb"
    return 0
  fi

  return 1
}

# Finds the emulator executable in PATH or SDK locations
#
# Outputs:
#   Prints the path to emulator executable
#
# Returns:
#   0 if found, 1 if not found
find_emulator() {
  if command -v emulator &>/dev/null; then
    echo "emulator"
    return 0
  fi

  if [[ -n "${ANDROID_HOME:-}" && -x "${ANDROID_HOME}/emulator/emulator" ]]; then
    echo "${ANDROID_HOME}/emulator/emulator"
    return 0
  fi

  if [[ -n "${ANDROID_SDK_ROOT:-}" && -x "${ANDROID_SDK_ROOT}/emulator/emulator" ]]; then
    echo "${ANDROID_SDK_ROOT}/emulator/emulator"
    return 0
  fi

  return 1
}

# Escapes a string for JSON output
#
# Arguments:
#   $1: string to escape
#
# Outputs:
#   Prints the escaped string
json_escape() {
  local str=$1
  str=${str//\\/\\\\}
  str=${str//\"/\\\"}
  str=${str//$'\n'/\\n}
  str=${str//$'\r'/}
  str=${str//$'\t'/\\t}
  echo "$str"
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
adb_get_device_prop() {
  local adb=$1
  local serial=$2
  local prop=$3
  "$adb" -s "$serial" shell getprop "$prop" < /dev/null 2>/dev/null | tr -d '\r'
}

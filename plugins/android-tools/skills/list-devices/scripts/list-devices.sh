#!/bin/bash

# Find adb executable
find_adb() {
    # Check PATH first
    if command -v adb &>/dev/null; then
        echo "adb"
        return 0
    fi

    # Check ANDROID_HOME
    if [[ -n "$ANDROID_HOME" && -x "$ANDROID_HOME/platform-tools/adb" ]]; then
        echo "$ANDROID_HOME/platform-tools/adb"
        return 0
    fi

    # Check ANDROID_SDK_ROOT
    if [[ -n "$ANDROID_SDK_ROOT" && -x "$ANDROID_SDK_ROOT/platform-tools/adb" ]]; then
        echo "$ANDROID_SDK_ROOT/platform-tools/adb"
        return 0
    fi

    return 1
}

# Get device property
get_prop() {
    local adb=$1
    local serial=$2
    local prop=$3
    "$adb" -s "$serial" shell getprop "$prop" 2>/dev/null | tr -d '\r'
}

# Main
ADB=$(find_adb)
if [[ -z "$ADB" ]]; then
    cat <<'EOF'
Error: adb not found

Please do one of the following:
  - Add adb to PATH
  - Set ANDROID_HOME environment variable
  - Set ANDROID_SDK_ROOT environment variable

Example:
  export ANDROID_HOME=~/Android/Sdk
EOF
    exit 1
fi

# Get device list
DEVICES=$("$ADB" devices 2>/dev/null | tail -n +2 | grep -v '^$')

if [[ -z "$DEVICES" ]]; then
    cat <<'EOF'
Connected Devices (0):

No devices connected.

Tips:
  - Start an emulator: emulator -avd <name>
  - Enable USB debugging on your physical device
  - Check USB connection
EOF
    exit 0
fi

# Count devices
DEVICE_COUNT=$(echo "$DEVICES" | wc -l | tr -d ' ')

echo "Connected Devices ($DEVICE_COUNT):"
echo ""
printf "  %-18s %-10s %-18s %-6s %s\n" "SERIAL" "TYPE" "MODEL" "API" "STATUS"
echo "  $(printf '─%.0s' {1..60})"

# Process each device
while IFS=$'\t' read -r serial status; do
    # Skip empty lines
    [[ -z "$serial" ]] && continue

    # Determine device type
    if [[ "$serial" == emulator-* ]]; then
        type="emulator"
    else
        type="physical"
    fi

    # Get device info
    model=$(get_prop "$ADB" "$serial" "ro.product.model")
    api=$(get_prop "$ADB" "$serial" "ro.build.version.sdk")

    # Clean up values
    model=${model:-"unknown"}
    api=${api:-"?"}

    printf "  %-18s %-10s %-18s %-6s %s\n" "$serial" "$type" "$model" "$api" "$status"
done <<< "$DEVICES"

echo ""

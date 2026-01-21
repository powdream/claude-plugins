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

# Escape string for JSON
json_escape() {
    local str=$1
    str=${str//\\/\\\\}
    str=${str//\"/\\\"}
    str=${str//$'\n'/\\n}
    str=${str//$'\r'/}
    str=${str//$'\t'/\\t}
    echo "$str"
}

# Main
ADB=$(find_adb)
if [[ -z "$ADB" ]]; then
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

# Get device list
DEVICES=$("$ADB" devices 2>/dev/null | tail -n +2 | grep -v '^$')

if [[ -z "$DEVICES" ]]; then
    cat <<'EOF'
{
  "success": true,
  "count": 0,
  "devices": []
}
EOF
    exit 0
fi

# Start JSON output
echo "{"
echo "  \"success\": true,"

# Build devices array
devices_json=""
first=true

while IFS=$'\t' read -r serial status; do
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
    model=${model:-""}
    api=${api:-""}

    # Build JSON object
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
done <<< "$DEVICES"

# Count devices
DEVICE_COUNT=$(echo "$DEVICES" | grep -c .)

echo "  \"count\": $DEVICE_COUNT,"
echo "  \"devices\": [$devices_json"
echo "  ]"
echo "}"

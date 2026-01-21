#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils.sh"

# Get value from config.ini
get_config_value() {
    local config_file=$1
    local key=$2
    grep "^${key}=" "$config_file" 2>/dev/null | cut -d'=' -f2-
}

# Extract API level from image.sysdir.1 path
extract_api_level() {
    local sysdir=$1
    echo "$sysdir" | grep -oE 'android-[0-9]+' | grep -oE '[0-9]+' | head -1
}

# Main
EMULATOR=$(find_emulator)
if [[ -z "$EMULATOR" ]]; then
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

# Get AVD list
AVD_LIST=$("$EMULATOR" -list-avds 2>/dev/null)

if [[ -z "$AVD_LIST" ]]; then
    cat <<'EOF'
{
  "success": true,
  "count": 0,
  "emulators": []
}
EOF
    exit 0
fi

# AVD directory
AVD_DIR="$HOME/.android/avd"

# Start JSON output
echo "{"
echo "  \"success\": true,"

# Build emulators array
emulators_json=""
first=true

while IFS= read -r avd_name; do
    [[ -z "$avd_name" ]] && continue

    config_file="$AVD_DIR/${avd_name}.avd/config.ini"

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

    # Build JSON object
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
done <<< "$AVD_LIST"

# Count AVDs
AVD_COUNT=$(echo "$AVD_LIST" | grep -c .)

echo "  \"count\": $AVD_COUNT,"
echo "  \"emulators\": [$emulators_json"
echo "  ]"
echo "}"

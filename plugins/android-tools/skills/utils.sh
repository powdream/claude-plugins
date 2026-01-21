#!/bin/bash

# Common utility functions for Android tools skills

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

# Find emulator executable
find_emulator() {
    # Check PATH first
    if command -v emulator &>/dev/null; then
        echo "emulator"
        return 0
    fi

    # Check ANDROID_HOME
    if [[ -n "$ANDROID_HOME" && -x "$ANDROID_HOME/emulator/emulator" ]]; then
        echo "$ANDROID_HOME/emulator/emulator"
        return 0
    fi

    # Check ANDROID_SDK_ROOT
    if [[ -n "$ANDROID_SDK_ROOT" && -x "$ANDROID_SDK_ROOT/emulator/emulator" ]]; then
        echo "$ANDROID_SDK_ROOT/emulator/emulator"
        return 0
    fi

    return 1
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

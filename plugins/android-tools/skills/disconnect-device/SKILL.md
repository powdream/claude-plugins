---
name: disconnect-device
description: Disconnect a wireless Android device from ADB. Use when you need to disconnect a device connected via WiFi.
---

# Disconnect Device

Disconnect a wireless Android device from ADB.

## Instructions

**Script location**: `scripts/disconnect-device.sh` (relative to this skill's
directory)

Before running, locate this skill's directory (where this SKILL.md is located),
then execute:

```bash
bash <skill-directory>/scripts/disconnect-device.sh [argument]
```

Arguments:

- `all`: Disconnect all wireless devices
- `ip:port` (e.g., `192.168.1.100:5555`): Disconnect specific device
- (none): Auto-detect wireless devices

## JSON Output Schema

### Success - Single Device

```json
{
  "success": true,
  "message": "Disconnected from 192.168.1.100:5555",
  "serial": "192.168.1.100:5555"
}
```

### Success - All Devices

```json
{
  "success": true,
  "message": "Disconnected all wireless devices"
}
```

### No Wireless Devices

```json
{
  "success": true,
  "message": "No wireless devices connected"
}
```

### Select Device (multiple wireless devices)

```json
{
  "success": true,
  "action": "select_device",
  "devices": [
    { "serial": "192.168.1.100:5555", "model": "Pixel 6", "api": "33" },
    { "serial": "192.168.1.101:5555", "model": "Galaxy S21", "api": "31" }
  ]
}
```

### Failure

```json
{
  "success": false,
  "error": "adb not found",
  "hint": "Set ANDROID_HOME or ANDROID_SDK_ROOT environment variable"
}
```

## Claude's Handling

1. If JSON has `action: "select_device"`, use `AskUserQuestion` to let user
   choose:
   - "all" - Disconnect all wireless devices
   - Individual devices (show model and API info)
2. After user selection, run the script again with the selected argument
3. Report disconnect result to user
4. On failure, show the error message and hint to the user

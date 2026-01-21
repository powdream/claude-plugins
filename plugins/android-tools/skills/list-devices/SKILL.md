---
name: list-devices
description: List connected Android devices and emulators. Use when you need to check available devices for deployment or debugging.
---

# List Devices

Display connected Android devices and emulators using adb.

## Instructions

Run the script to list all connected devices:

```bash
bash plugins/android-tools/skills/list-devices/scripts/list-devices.sh
```

The script outputs JSON with device details.

## JSON Output Schema

### Success

```json
{
  "success": true,
  "count": 2,
  "devices": [
    {
      "serial": "emulator-5554",
      "type": "emulator",
      "model": "sdk_gphone64_arm64",
      "api": "33",
      "status": "device"
    },
    {
      "serial": "RF8M33XXXXX",
      "type": "physical",
      "model": "SM-G998N",
      "api": "31",
      "status": "device"
    }
  ]
}
```

### Failure

```json
{
  "success": false,
  "error": "adb not found",
  "hint": "Set ANDROID_HOME or ANDROID_SDK_ROOT environment variable",
  "devices": []
}
```

## Formatting the Output

### Success (`success: true`)

Format the JSON output as a table:

```
Connected Devices (2):

  SERIAL            TYPE       MODEL              API    STATUS
  --------------------------------------------------------------
  emulator-5554     emulator   sdk_gphone64_arm64 33     device
  RF8M33XXXXX       physical   SM-G998N           31     device
```

- Show empty fields as "-"
- If `count` is 0, show "No devices connected."

### Failure (`success: false`)

Show the error message and hint to the user:

```
Error: adb not found
Hint: Set ANDROID_HOME or ANDROID_SDK_ROOT environment variable
```

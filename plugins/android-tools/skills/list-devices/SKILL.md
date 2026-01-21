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

The script will:

1. Find adb in PATH, ANDROID_HOME, or ANDROID_SDK_ROOT
2. Display connected devices with details (serial, type, model, API level,
   status)
3. Show helpful tips if no devices are connected

## Output Format

```
Connected Devices (2):

  SERIAL            TYPE       MODEL              API    STATUS
  ────────────────────────────────────────────────────────────
  emulator-5554     emulator   Pixel_6_API_33     33     device
  RF8M33XXXXX       physical   SM-G998N           31     device
```

## Troubleshooting

If adb is not found, set one of these environment variables:

```bash
export ANDROID_HOME=~/Android/Sdk
# or
export ANDROID_SDK_ROOT=~/Android/Sdk
```

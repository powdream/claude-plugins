---
name: list-emulators
description: List installed Android emulators (AVDs). Use when you need to check available emulators before starting one.
---

# List Emulators

Display installed Android emulators (AVDs) with detailed information.

## Instructions

**Script location**: `scripts/list-emulators.sh` (relative to this skill's
directory)

Before running, locate this skill's directory (where this SKILL.md is located),
then execute:

```bash
bash <skill-directory>/scripts/list-emulators.sh
```

The script outputs JSON with emulator details.

## JSON Output Schema

### Success

```json
{
  "success": true,
  "count": 2,
  "emulators": [
    {
      "name": "Pixel_6_API_33",
      "device": "pixel_6",
      "api": "33",
      "resolution": "1080x2400",
      "image": "google_apis_playstore",
      "playstore": true
    }
  ]
}
```

### Failure

```json
{
  "success": false,
  "error": "emulator not found",
  "hint": "Set ANDROID_HOME or ANDROID_SDK_ROOT environment variable",
  "emulators": []
}
```

## Formatting the Output

### Success (`success: true`)

Format the JSON output as a table:

```
Installed Emulators (2):

  NAME                DEVICE      API    RESOLUTION   IMAGE                  PLAYSTORE
  ------------------------------------------------------------------------------------
  Pixel_6_API_33      pixel_6     33     1080x2400    google_apis_playstore  Yes
  Pixel_4_API_30      pixel_4     30     1080x2280    google_apis            No
```

- Display `playstore: true` as "Yes", `false` as "No"
- Show empty fields as "-"

### Failure (`success: false`)

Show the error message and hint to the user:

```
Error: emulator not found
Hint: Set ANDROID_HOME or ANDROID_SDK_ROOT environment variable
```

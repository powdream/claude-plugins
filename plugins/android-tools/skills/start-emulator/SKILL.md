---
name: start-emulator
description: Start an Android emulator. Use when you need to launch an AVD for testing.
---

# Start Emulator

Start an Android emulator (AVD) with quick boot or cold boot option.

## Instructions

**Script location**: `scripts/start-emulator.sh` (relative to this skill's
directory)

Before running, locate this skill's directory (where this SKILL.md is located),
then execute:

```bash
bash <skill-directory>/scripts/start-emulator.sh [avd_name] [boot_type]
```

Arguments:

- `avd_name` (optional): The name of the AVD to start
- `boot_type` (optional): "quick" (default) or "cold"

## JSON Output Schema

### Success - Launch

```json
{
  "success": true,
  "message": "Emulator started",
  "avd": "Pixel_6_API_33",
  "cold_boot": false
}
```

### Success - Multiple emulators (ask user)

```json
{
  "success": true,
  "action": "select_emulator",
  "emulators": ["Pixel_6_API_33", "Pixel_4_API_30"]
}
```

### Failure

```json
{
  "success": false,
  "error": "no available emulator",
  "hint": "Create an AVD using Android Studio or avdmanager"
}
```

## Claude's Handling

Follow this flow:

1. **Get available emulators**: Run script with no arguments to get the list
2. **Select emulator**: If multiple emulators, use `AskUserQuestion` to let user
   choose. If only one emulator, use that one automatically.
3. **Select boot type**: Use `AskUserQuestion` to ask "Quick boot or cold boot?"
   (recommend quick boot as the first option)
4. **Launch**: Run script with `avd_name` and `boot_type` arguments
5. **Report result**: Inform user the emulator is starting or show error

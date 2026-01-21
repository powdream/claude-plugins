---
name: stop-emulator
description: Stop a running Android emulator. Use when you need to shut down an AVD.
---

# Stop Emulator

Stop a running Android emulator (AVD).

## Instructions

**Script location**: `scripts/stop-emulator.sh` (relative to this skill's
directory)

Before running, locate this skill's directory (where this SKILL.md is located),
then execute:

```bash
bash <skill-directory>/scripts/stop-emulator.sh [avd_name_or_serial]
```

Arguments:

- `avd_name_or_serial` (optional): The name of the AVD (e.g., `Pixel_6_API_33`)
  or serial (e.g., `emulator-5554`) to stop

## JSON Output Schema

### Success

```json
{
  "success": true,
  "message": "Emulator stopped",
  "avd": "Pixel_6_API_33",
  "serial": "emulator-5554"
}
```

### Success - Multiple running (ask user)

```json
{
  "success": true,
  "action": "select_emulator",
  "running": [
    { "avd": "Pixel_6_API_33", "serial": "emulator-5554" },
    { "avd": "Pixel_4_API_30", "serial": "emulator-5556" }
  ]
}
```

### Failure

```json
{
  "success": false,
  "error": "no running emulator",
  "hint": "Start an emulator first using start-emulator skill"
}
```

## Claude's Handling

1. If JSON has `action: "select_emulator"`, use `AskUserQuestion` to let user
   choose which emulator to stop
2. After successful stop, inform user the emulator has been stopped
3. On failure, show the error message and hint to the user

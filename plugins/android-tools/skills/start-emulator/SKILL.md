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

**IMPORTANT**: ALWAYS ask the user about boot type before launching. Never skip
this step.

### Flow

1. **Determine emulator**:
   - If user specified an emulator name → use that name
   - Otherwise → run script with no arguments to get the list, then ask user to
     select if multiple emulators exist

2. **Ask boot type** (REQUIRED - never skip): Use `AskUserQuestion` to ask
   "Quick boot or cold boot?"
   - First option: "Quick boot (Recommended)"
   - Second option: "Cold boot"

3. **Launch**: Run script with `avd_name` and `boot_type` arguments

4. **Report result**: Inform user the emulator is starting or show error

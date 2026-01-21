---
name: connect-device
description: Connect to an Android device over ADB wireless. Use when you need to connect to a device via WiFi.
---

# Connect Device

Connect to an Android device over ADB wireless (TCP/IP).

## Instructions

**Script location**: `scripts/connect-device.sh` (relative to this skill's
directory)

Before running, locate this skill's directory (where this SKILL.md is located),
then execute:

```bash
bash <skill-directory>/scripts/connect-device.sh [ip:port]
# or
bash <skill-directory>/scripts/connect-device.sh [ip] [port]
```

Arguments:

- `ip:port`: IP address and port in format "192.168.1.100:5555"
- Or separate arguments: `ip` and `port` (default port: 5555)

## JSON Output Schema

### Success

```json
{
  "success": true,
  "message": "Connected to 192.168.1.100:5555",
  "ip": "192.168.1.100",
  "port": "5555"
}
```

### Request Input (no arguments)

```json
{
  "success": true,
  "action": "request_input",
  "message": "Please provide IP address and port"
}
```

### Failure

```json
{
  "success": false,
  "error": "Failed to connect to 192.168.1.100:5555",
  "hint": "Ensure the device is on the same network and ADB over WiFi is enabled"
}
```

## Claude's Handling

1. If JSON has `action: "request_input"`, use `AskUserQuestion` to ask for IP
   and port
2. Report connection result to user

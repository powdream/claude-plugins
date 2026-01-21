---
name: bump-version
description: Bump plugin version. Use when you need to increment a plugin's version number.
---

# Bump Version

Increment a plugin's version number (major, minor, or patch).

## Arguments

- `[plugin-name]`: (Optional) Target plugin name

## Instructions

### 1. Determine Target Plugin

If plugin name is provided as argument:

- Use that plugin name

If no argument:

- Infer plugin name from session context (e.g., recently edited files under
  `plugins/<name>/`)
- Ask user to confirm: "Bump version for `<plugin-name>`?"

### 2. Read Current Version

Read `plugins/<plugin-name>/.claude-plugin/plugin.json` and extract current
version.

### 3. Ask Version Type

Use AskUserQuestion tool to ask which version to bump:

- Options: minor (Recommended), patch, major
- minor as first option with "(Recommended)"

### 4. Update Version

- Parse current version (e.g., "0.2.0" -> major=0, minor=2, patch=0)
- Increment selected component, reset lower components to 0
  - major: 1.0.0
  - minor: 0.3.0
  - patch: 0.2.1
- Update plugin.json with new version

### 5. Confirm Result

Output: "Updated <plugin-name> version: 0.2.0 -> 0.3.0"

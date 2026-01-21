# Bash Script Convention

Guidelines for writing bash scripts in this repository.

## Indentation

Use 2 spaces for indentation. Do not use tabs.

```bash
main() {
  local value=$1
  if [[ -n "$value" ]]; then
    echo "$value"
  fi
}
```

## Shebang

Use `#!/usr/bin/env bash` instead of `#!/bin/bash` for better portability.

```bash
#!/usr/bin/env bash
```

## Strict Mode

For executable scripts, enable strict mode at the top:

```bash
set -euo pipefail
```

- `-e`: Exit on error
- `-u`: Error on undefined variables
- `-o pipefail`: Fail on pipe errors

Library scripts (sourced by other scripts) should NOT use `set -euo pipefail`.

## Variable Naming

- **Immutable globals**: `UPPER_SNAKE_CASE`
- **Mutable variables**: `lower_snake_case`
- **Function local variables**: Use `local` keyword

### When to Use UPPER_SNAKE_CASE

Use `UPPER_SNAKE_CASE` for global variables that are conceptually immutable -
values that are set once and should not change during script execution:

- Variables with `readonly` keyword
- Script-level constants (paths, configuration values)
- Variables set once at script initialization (e.g., `SCRIPT_DIR`, `ADB_PATH`)

The `readonly` keyword is optional. Use it when you want to enforce immutability
and catch accidental reassignment. For variables that are simply treated as
constants by convention, `UPPER_SNAKE_CASE` alone is sufficient.

Multiple assignments during initialization are allowed:

```bash
VARIABLE=""
if [[ -f "config.yaml" ]]; then
  VARIABLE="yaml"
elif [[ -f "config.json" ]]; then
  VARIABLE="json"
fi
# No changes after this point - UPPER_SNAKE_CASE is OK
```

### Function Local Variables

Always use `local` keyword for variables inside functions:

```bash
process_file() {
  local file_path=$1
  local result=""
  # ...
}
```

## Conditionals

Use `[[ ]]` instead of `[ ]`:

```bash
# Good
if [[ -n "$value" ]]; then
  echo "has value"
fi

# Avoid
if [ -n "$value" ]; then
  echo "has value"
fi
```

## Environment Variables

Always use fallback syntax `${VAR:-}` when referencing environment variables
that may not be set. This prevents errors when `set -u` is enabled.

```bash
# Good - safe even when ANDROID_HOME is unset
if [[ -n "${ANDROID_HOME:-}" ]]; then
  echo "${ANDROID_HOME}/platform-tools/adb"
fi

# Bad - fails with "unbound variable" error if ANDROID_HOME is unset
if [[ -n "$ANDROID_HOME" ]]; then
  echo "$ANDROID_HOME/platform-tools/adb"
fi
```

Use `${VAR:-default}` to provide a default value:

```bash
LOG_LEVEL="${LOG_LEVEL:-info}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/myapp"
```

## Function Documentation

Document functions with comments describing:

- Description of what the function does
- Arguments (if any)
- Outputs (if any)
- Returns (if any)

```bash
# Finds the adb executable in PATH or SDK locations
#
# Arguments:
#   None
#
# Outputs:
#   Prints the path to adb executable
#
# Returns:
#   0 if found, 1 if not found
find_adb() {
  # ...
}
```

## Function Structure

- Define `main()` function at the top of the file (after global variables)
- Call `main "$@"` at the bottom
- Use blank lines between functions
- Use verb-based function names

## Examples

### Executable Script

```bash
#!/usr/bin/env bash
set -euo pipefail

# This script processes configuration files and runs tasks.
#
# Usage: ./script.sh [config_file]
# Arguments:
#   config_file: Path to config file (default: config.ini)

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../utils.sh"

# Global variables
CONFIG_FILE="config.ini"
OUTPUT_DIR="./output"
mutable_counter=0

# Main entry point
#
# Arguments:
#   $1: config file path (optional)
main() {
  local config_file=${1:-"$CONFIG_FILE"}

  if ! validate_config "$config_file"; then
    exit 1
  fi

  run_task "$config_file"
}

# Validates the configuration file exists
#
# Arguments:
#   $1: config file path
#
# Returns:
#   0 if valid, 1 if invalid
validate_config() {
  local config_file=$1

  if [[ ! -f "$config_file" ]]; then
    echo "Error: Config file not found: $config_file" >&2
    return 1
  fi

  return 0
}

# Runs the main task with the given config
#
# Arguments:
#   $1: config file path
run_task() {
  local config_file=$1
  # Implementation
}

main "$@"
```

### Library Script

Library scripts are sourced by other scripts and should not have
`set -euo pipefail` or a `main()` function.

```bash
#!/usr/bin/env bash

# Finds the adb executable in PATH or SDK locations
#
# Outputs:
#   Prints the path to adb executable
#
# Returns:
#   0 if found, 1 if not found
find_adb() {
  if command -v adb &>/dev/null; then
    echo "adb"
    return 0
  fi

  if [[ -n "${ANDROID_HOME:-}" && -x "${ANDROID_HOME}/platform-tools/adb" ]]; then
    echo "${ANDROID_HOME}/platform-tools/adb"
    return 0
  fi

  return 1
}

# Escapes a string for JSON output
#
# Arguments:
#   $1: string to escape
#
# Outputs:
#   Prints the escaped string
json_escape() {
  local str=$1
  str=${str//\\/\\\\}
  str=${str//\"/\\\"}
  echo "$str"
}
```

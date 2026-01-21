---
name: review-shell-scripts
description: Review all shell scripts against the Bash Script Convention. Use when you need to check script compliance or before committing changes.
---

# Review Shell Scripts

Review all shell scripts in the repository against the Bash Script Convention.

## Instructions

### Step 1: Find All Shell Scripts

Use `find` to locate all `.sh` files:

```bash
find . -name "*.sh" -type f
```

### Step 2: Run Shellcheck

For each script found, spawn a sub-agent to:

1. Run `shellcheck <script-path>`
2. Fix any issues found
3. Repeat shellcheck until no issues remain

### Step 3: Convention Review

Spawn sub-agents in parallel (2-3 scripts per agent) for convention review.

Follow the exact sub-agent prompt structure defined in AGENTS.md under "Bash
Script Review >> 2. Spawn a sub-agent". Fix any violations found.

### Step 4: Library Script Exceptions

Library scripts (like `utils.sh`) have different rules:

- No strict mode (`set -euo pipefail`) required
- No `main()` function required

### Step 5: Report Results

Report the final results summarizing:

- Number of scripts reviewed
- Issues found and fixed
- Any remaining issues that need manual attention

## Notes

- Reference: AGENTS.md "Bash Script Review" section
- The convention document (`doc/bash-script-convention.md`) takes precedence
  over the checklist above

# AGENTS.md

Instructions for AI agents working with this repository.

## Overview

This repository is a Claude Code plugin marketplace containing multiple plugins.
Each plugin provides skills that extend Claude Code's capabilities.

## Guidelines

- **Language**: All documentation must be written in English.
- **Naming**: Use lowercase, hyphen-separated names (e.g., `android-tools`,
  `list-emulators`)
- **Versioning**: Follow semver format (e.g., `0.1.0`)
- **Bash Scripts**: Follow
  [Bash Script Convention](./doc/bash-script-convention.md)

## Project Structure

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json      # Marketplace definition
├── plugins/
│   └── <plugin-name>/
│       ├── .claude-plugin/
│       │   └── plugin.json   # Plugin metadata
│       └── skills/
│           └── <skill-name>/
│               └── SKILL.md  # Skill implementation
└── README.md
```

## Development

### Bash Script Review

When adding or modifying bash scripts, you MUST complete these steps:

1. **Run shellcheck** on all added/modified scripts:
   ```bash
   shellcheck <script-path>
   ```
   Fix any issues before proceeding.

2. **Spawn a sub-agent** for convention review with this exact prompt structure:
   ```
   Review the following bash scripts against the Bash Script Convention.

   IMPORTANT: You MUST first read the convention document at
   `<repo-root>/doc/bash-script-convention.md`, then verify EACH of these
   items for every script:

   Checklist:
   - [ ] Shebang: `#!/usr/bin/env bash`
   - [ ] Strict mode: `set -euo pipefail` (executable scripts only)
   - [ ] Indentation: 2 spaces, no tabs
   - [ ] Function order: `main()` defined first, helper functions after
   - [ ] Variables: UPPER_SNAKE_CASE for immutables, `local` for function vars
   - [ ] Conditionals: `[[ ]]` not `[ ]`
   - [ ] Environment variables: `${VAR:-}` fallback syntax
   - [ ] Function documentation: description, arguments, outputs, returns

   Scripts to review:
   - <list of script paths>

   For each violation found, provide the exact fix.
   ```

**CAUTION**: Do NOT skip or simplify the sub-agent prompt. The checklist must be included.

**Note**: If there is any conflict between the checklist above and
`doc/bash-script-convention.md`, the convention document takes precedence.
Update the checklist in this file to match the convention document.

### Adding a New Plugin

Use the `/add-plugin` skill. See `.claude/skills/add-plugin/SKILL.md` for
details.

### Adding a New Skill

Use the `/add-skill` skill. See `.claude/skills/add-skill/SKILL.md` for details.

### Testing

After making changes, test locally:

```bash
/plugin marketplace add ./
/plugin install <plugin-name>@claude-plugins
```

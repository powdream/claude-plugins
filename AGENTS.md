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

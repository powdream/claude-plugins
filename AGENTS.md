# AGENTS.md

Instructions for AI agents working with this repository.

## Documentation Language

All documentation in this repository must be written in English.

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

## Adding a New Plugin

Refer to `.claude/skills/add-plugin/SKILL.md` for detailed instructions. Actively use the `add-plugin` skill when creating new plugins.

## Adding a New Skill

Refer to `.claude/skills/add-skill/SKILL.md` for detailed instructions. Actively use the `add-skill` skill when adding new skills.

## Naming Conventions

- Plugin names: lowercase, hyphen-separated (e.g., `android-tools`)
- Skill names: lowercase, hyphen-separated (e.g., `list-emulators`)
- Version: semver format (e.g., `0.1.0`)

## Testing

After making changes, test locally:
```bash
/plugin marketplace add ./
/plugin install <plugin-name>@claude-plugins
```

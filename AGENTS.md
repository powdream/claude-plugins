# AGENTS.md

Instructions for AI agents working with this repository.

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

1. Create directory: `plugins/<plugin-name>/`
2. Create `.claude-plugin/plugin.json` with name, description, version
3. Add skills under `skills/<skill-name>/SKILL.md`
4. Register in `.claude-plugin/marketplace.json`

## Adding a New Skill

1. Create `plugins/<plugin-name>/skills/<skill-name>/SKILL.md`
2. SKILL.md should contain the skill prompt/instructions

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

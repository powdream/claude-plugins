---
name: add-plugin
description: Guide for adding a new plugin to this marketplace. Use when creating or scaffolding a new plugin.
---

# Plugin Development Guide

Guide for adding a new plugin to this marketplace.

## Directory Structure

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json      # Required: name, description, version
├── skills/
│   └── <skill-name>/
│       └── SKILL.md     # Skill definition
└── scripts/             # Complex logic as bash scripts
    └── *.sh
```

## plugin.json Required Fields

```json
{
  "name": "plugin-name",
  "description": "Plugin description",
  "version": "0.1.0"
}
```

## SKILL.md Structure

```markdown
---
name: skill-name
description: Skill description
---

# Skill Instructions

Detailed instructions for what the skill should do.
```

## Register in marketplace.json

Add the new plugin to `.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "new-plugin",
      "source": "./plugins/new-plugin",
      "description": "Plugin description"
    }
  ]
}
```

## Testing

```bash
claude --plugin-dir ./plugins/<plugin-name>
```

## Using Complex Scripts

When complex logic is needed:

1. Create bash scripts in `scripts/` directory
2. Reference script execution in SKILL.md
3. Only script output goes to context, making it token-efficient

## Reference

Read the official documentation for more details.

### Official Documentation

- Create plugins: https://code.claude.com/docs/en/plugins
- Agent skills:
  https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview

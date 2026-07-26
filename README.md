# claude-plugins

Claude Code plugins to boost your development workflow.

## Installation

```bash
/plugin marketplace add powdream/claude-plugins
```

## Available Plugins

### android-tools

Android CLI tools: adb, emulator control, and device management.

```bash
/plugin install android-tools@claude-plugins
```

### worktree-tools

Open the current git worktree in a target environment: a cmux split pane, a new
cmux workspace, or VS Code.

```bash
/plugin install worktree-tools@claude-plugins
```

### cmux-tools

cmux workspace helpers:

- **cmux-new-workspace** (skill): opens a new cmux workspace on a project
  directory, launches Claude Code there, and injects `/rename <name>` and `/rc`
  once the TUI is up — so the session lands named and remote-controllable. With
  no path given, it offers the 10 most recently used directories, ranked by
  Claude Code session recency.
- **cmux-slash** (skill): injects a slash command remote control can't open
  (`/context`, `/status`, `/reload-skills`, …) into an already-running pane —
  this session's own, or broadcast to every Claude pane at once.

```bash
/plugin install cmux-tools@claude-plugins
```

### markdown-tools

View or open Markdown files: surface full content over remote control, or open
locally in the macOS default app.

```bash
/plugin install markdown-tools@claude-plugins
```

### pr-tools

GitHub pull request helpers: maintain a stacked-PR series section across a chain
of PRs, and open a PR in Google Chrome.

```bash
/plugin install pr-tools@claude-plugins
```

### session-tools

Session-lifecycle helpers:

- **self-check reminder** (hook): re-injects an independent-verification
  (anti-sycophancy) directive after compaction and every N prompts (default 10,
  override with `SESSION_TOOLS_SELF_CHECK_INTERVAL`), to counter attention decay
  in long sessions.
- **write-handoff-prompt** (skill): when you ask for a handoff / continuation
  prompt (e.g. "컴팩션 후 작업 지시 프롬프트 써줘"), authors one that treats
  documents as intent-only (not ground truth — verify against code), separates
  settled / fact / open / inferred, and keeps the spec·plan agreement gate.

```bash
/plugin install session-tools@claude-plugins
```

## License

MIT

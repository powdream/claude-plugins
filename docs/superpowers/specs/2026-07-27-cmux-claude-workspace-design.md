# cmux-claude-workspace — Design

## Goal

One skill that opens a **new cmux workspace**, `cd`s into a chosen project
directory, launches Claude Code there, and then drives the freshly booted TUI
through `/rename <name>` and `/rc` so the session is named and remote control is
live — without the user typing any of it.

Directory candidates are ranked by **recency of Claude Code use**.

## Placement

- Plugin: `cmux-tools` (already holds `cmux-slash`; this is another cmux
  workspace/pane manipulation skill).
- Path: `plugins/cmux-tools/skills/cmux-claude-workspace/SKILL.md`
- `cmux-tools` version: `0.1.0` → `0.2.0` (new skill, additive).

`worktree-tools` was rejected as a home: its three skills are all scoped to "the
git worktree I am currently working on", while this skill targets an arbitrary
recently used directory.

## Candidate source: why not `~/.claude.json`

Measured on the author's machine (2026-07-27):

| Source                         | Entries              | Usable recency timestamps                  | Worktrees included |
| ------------------------------ | -------------------- | ------------------------------------------ | ------------------ |
| `~/.claude.json` → `projects`  | 11                   | **3** (`lastSessionModified`, rest `null`) | **no**             |
| `~/.claude/projects/*/*.jsonl` | 12 dirs, 8 with logs | 8 (file mtime)                             | yes                |

`~/.claude.json` cannot support a "most recently used" ordering: 8 of 11 project
entries have no timestamp at all, and worktree directories — including the one
this design was written in — never appear.

The session-log directory works because every `*.jsonl` transcript carries a
`cwd` field with the original absolute path. The directory _name_ alone is
useless for this: the encoding collapses `/`, `-`, and `.` all into `-`
(`/Users/h_kang/dev/git/powdream/claude-plugins/.claude/worktrees/bridge-cse_01Ws...`
becomes
`-Users-h-kang-dev-git-powdream-claude-plugins--claude-worktrees-bridge-cse-01Ws...`),
so it cannot be decoded back to a real path.

### Scan algorithm

```
for each directory under ~/.claude/projects/:
    pick the *.jsonl file with the newest mtime
    read lines until one carries a "cwd" field -> absolute path
dedupe by path
drop paths that no longer exist on disk
sort by that mtime, descending
take the first 10
```

The current session's own cwd stays in the list, tagged `(current session)` —
opening a second workspace on the same directory is a legitimate use.

## Flow

### 1. Resolve the target directory

- If the user gave an explicit **path**, use it and skip the scan entirely.
- If the user gave a **project name** rather than a path, run the scan and match
  the name against the candidate paths (basename first, then substring). A
  single match is used directly; zero or multiple matches fall through to the
  picker.
- Otherwise print the 10 candidates as a numbered table (path + last-used
  timestamp) and let the user answer with a number.

Text table, not `AskUserQuestion` — the picker needs more than the 4 options
that tool allows.

### 2. Ask for the session name

Always ask; never infer. The answer is used twice: as the `/rename` argument and
as the cmux workspace `--name`.

### 3. Decide the Claude launch command

- Default: `claude`
- `claude --continue` only when the user explicitly asks to resume ("이어서",
  "resume", "--continue").

### 4. Create the workspace

```bash
cmux new-workspace --name "<session-name>" --cwd "<path>" --command "<claude-cmd>" --focus true
# stdout: OK workspace:18
```

Verified: `--cwd` lands the shell in the target directory, `--command` sends
text+Enter after creation, and stdout is `OK workspace:<n>` (identical with and
without the `--json` global flag).

### 5. Resolve the surface

```bash
cmux --json list-panels --workspace workspace:18
```

Verified output shape:

```json
{
  "surfaces": [{ "ref": "surface:22", "pane_ref": "pane:21", "type": "terminal", ... }],
  "window_ref": "window:1",
  "workspace_ref": "workspace:18"
}
```

Take `surfaces[0].ref` and `window_ref`.

### 6. Wait for Claude to finish booting (poll)

Sending `/rename` before the TUI is up would leak the text into the shell and
run it as a command. Poll instead — 1 s interval, 60 s timeout:

```bash
cmux top --all --processes --flat --format tsv
# columns: cpu_percent, memory_bytes, process_count, kind, ref, parent_ref, title
```

A Claude pane is a row where `kind == "process"`, `parent_ref` equals the target
surface, and `title` matches `^\d+\.\d+\.\d+` (Claude Code reports its version
as the process label).

Verified sample row:

```
0.7	441583152	1	process	4822	surface:1	2.1.219
```

### 7. Inject the slash commands

```bash
cmux send     --window <win> --surface <surf> -- "/rename <name>"
cmux send-key --window <win> --surface <surf> enter
cmux send     --window <win> --surface <surf> -- "/rc"
cmux send-key --window <win> --surface <surf> enter
```

`/rename` takes its argument inline, so one line per command.

`--window` is mandatory alongside a short `surface:<n>` ref. Without it the ref
resolves against `$CMUX_WORKSPACE_ID` — the caller's own workspace — and the
commands land in the wrong pane. This trap is already documented in
`cmux-slash`.

### 8. Report

Echo the resolved path, session name, workspace ref, and surface ref.

## Error handling

Every failure is reported as fact; none is silently swallowed.

| Condition                     | Behavior                                                                                                |
| ----------------------------- | ------------------------------------------------------------------------------------------------------- |
| `cmux` binary missing         | Abort before creating anything                                                                          |
| Chosen path does not exist    | Abort; never substitute another directory                                                               |
| Zero candidates from the scan | Ask the user for a path directly                                                                        |
| Poll times out (60 s)         | Leave the workspace open, state that injection did not happen, tell the user which two commands to type |

## Non-goals

- Splitting the current workspace (that is `worktree-cmux-split`'s job).
- Reading Claude's output back from the new pane — the user views it through
  cmux's pane mirror, same as `cmux-slash`.
- Managing or cleaning up workspaces after creation.

## Implementation notes

- The scan is a Python heredoc inside `SKILL.md`, matching the existing
  `cmux-slash` pattern. No new standalone shell script, so the repo's Bash
  Script Convention review does not apply.
- `cmux` binary path: `/Applications/cmux.app/Contents/Resources/bin/cmux`.

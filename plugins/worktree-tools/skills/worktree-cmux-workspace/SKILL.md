---
name: worktree-cmux-workspace
description: Use when the user wants to open the git worktree they're working on in a NEW cmux workspace (e.g. "이 worktree cmux 새 workspace로 띄워줘", "open the worktree in a new cmux workspace"). For a split pane in the current workspace instead, use worktree-cmux-split.
---

# worktree-cmux-workspace

Open the in-progress git worktree as its own new cmux workspace (a fresh terminal whose cwd is the worktree).

## Resolve the worktree path

In priority order:

1. Explicit argument — a path, or a branch name (resolve via `git worktree list --porcelain`).
2. The task-specific worktree you've been editing this session.
3. If there is no task-specific worktree, open the **primary worktree** (main checkout) of the project the current task targets — the first entry of `git -C <project> worktree list`.

Do NOT fall back to `git -C "$PWD" rev-parse --show-toplevel`: `$PWD` may be an unrelated repo. Resolve the target from `git worktree list` instead — the primary worktree is the project root (main checkout), and task-specific worktrees are the linked worktrees it lists.

## Open

Use the **named** form so the workspace gets a meaningful title. (The bare `cmux "<path>"` form sets the cwd correctly too, but names the workspace generically like "Terminal 7", which clashes with the user's named workspaces.)

```bash
CMUX=/Applications/cmux.app/Contents/Resources/bin/cmux
"$CMUX" new-workspace --cwd "<worktree-path>" --name "<name>" --focus true
```

- `<name>`: the branch for a task-specific worktree (e.g. `feature/my-task`), or the project dir basename for the primary worktree.
- `cmux` binary: `/Applications/cmux.app/Contents/Resources/bin/cmux` (absolute path if not on PATH). It launches the cmux app if it isn't running, and creates the workspace in the caller's window.
- `--cwd` sets the shell cwd to the worktree directly (verified: `pwd` lands in the worktree), so no follow-up `cd` is needed. Unlike `send`, `new-workspace` does not need explicit `--window`/`--surface` context — the caller's *window* ref is correct even though its surface/workspace env is a stale other session.

Echo the resolved path and the workspace name. If the path doesn't exist, say so rather than opening the wrong directory.

## Related

- **worktree-cmux-split** — same worktree, but as a split pane in the current workspace.

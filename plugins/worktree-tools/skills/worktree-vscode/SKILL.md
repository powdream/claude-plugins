---
name: worktree-vscode
description: Use when the user wants to open the git worktree they're currently working on in VS Code (e.g. "이 worktree vscode로 열어줘", "open the worktree in vscode"). Opens the worktree folder with the `code` CLI.
---

# worktree-vscode

Open the in-progress git worktree as a folder in VS Code.

## Resolve the worktree path

In priority order:

1. Explicit argument — a path, or a branch name (resolve via `git worktree list --porcelain`).
2. The task-specific worktree you've been editing this session.
3. If there is no task-specific worktree, open the **primary worktree** (main checkout) of the project the current task targets — the first entry of `git -C <project> worktree list`.

Do NOT fall back to `git -C "$PWD" rev-parse --show-toplevel`: `$PWD` may be an unrelated repo. Resolve the target from `git worktree list` instead — the primary worktree is the project root (main checkout), and task-specific worktrees are the linked worktrees it lists.

## Open

```bash
code "<worktree-path>"
```

Echo the resolved path. If the path doesn't exist or isn't a git worktree, say so instead of guessing.

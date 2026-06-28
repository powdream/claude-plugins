---
name: worktree-cmux-split
description: Use when the user wants to open the git worktree they're working on as a SPLIT PANE in the CURRENT cmux workspace (e.g. "이 worktree cmux 창 분할로 띄워줘", "split the current cmux workspace into the worktree"). Asks split direction (side-by-side vs stacked) via AskUserQuestion. For a separate new workspace instead, use worktree-cmux-workspace.
---

# worktree-cmux-split

Open the in-progress git worktree as a split pane inside the current cmux workspace (next to the pane Claude Code is running in).

## Resolve the worktree path

In priority order:

1. Explicit argument — a path, or a branch name (resolve via `git worktree list --porcelain`).
2. The task-specific worktree you've been editing this session.
3. If there is no task-specific worktree, open the **primary worktree** (main checkout) of the project the current task targets — the first entry of `git -C <project> worktree list`.

Do NOT fall back to `git -C "$PWD" rev-parse --show-toplevel`: `$PWD` may be an unrelated repo. Resolve the target from `git worktree list` instead — the primary worktree is the project root (main checkout), and task-specific worktrees are the linked worktrees it lists.

## Capture the target pane FIRST (before any prompt)

The target is the pane the user is **looking at when they invoke**. Capture it as the very first action — before asking the direction — so the answer prompt can't shift focus away from it:

```bash
CMUX=/Applications/cmux.app/Contents/Resources/bin/cmux
read -r FWIN FW FS < <("$CMUX" identify | python3 -c 'import json,sys;d=json.load(sys.stdin)["focused"];print(d["window_ref"],d["workspace_ref"],d["surface_ref"])')
echo "target: window=$FWIN workspace=$FW surface=$FS  ($("$CMUX" tree | grep "$FS " | grep -oE '\"[^\"]+\"' | head -1))"
```

Capture the **window ref too** (`$FWIN`): every later cmux call must carry full `--window`/`--workspace` context (see "Open the split").

Use `identify.focused` (real-time focus = what the user is looking at). Do **NOT** use `$CMUX_SURFACE_ID` / `$CMUX_WORKSPACE_ID` / `identify.caller`: under Remote Control + multiple sessions the Bash env can point to a *different* session's pane — that mis-targeting is what previously sent a `cd` into another running agent. Capturing `FW`/`FS` up front pins the target, so later focus drift (e.g. while the user answers the direction prompt) doesn't matter.

Echo the captured workspace/surface (with its title) so the user can sanity-check the target.

## Ask the split direction (required)

Use **AskUserQuestion** with these two options (concrete results, so 가로/세로 wording is never ambiguous):

- **좌우 나란히 (오른쪽에 새 pane)** → cmux direction `right`
- **위아래 (아래에 새 pane)** → cmux direction `down`

## Open the split

`new-split` has no `--cwd`, so split the **captured** focused pane (`$FW`/`$FS` from above), then `cd` the **new** pane into the worktree. Every call carries full `--window`/`--workspace` context:

```bash
ref=$("$CMUX" new-split <right|down> --window "$FWIN" --workspace "$FW" --surface "$FS" --focus true | grep -oE 'surface:[0-9]+' | tail -1)
if [ -n "$ref" ]; then
  "$CMUX" send --window "$FWIN" --workspace "$FW" --surface "$ref" "cd '<worktree-path>' && clear\n"   # \n = Enter; goes to the NEW blank split
else
  echo "ABORT: new-split returned no surface ref — not sending cd."
fi
```

**Full context is required**, not optional: the Bash caller env (`$CMUX_*`) belongs to a *different, stale* session, so `cmux send`/`read-screen` with a bare `--surface` short ref — or even a UUID — resolves in the wrong scope and fails with `invalid_params: Surface is not a terminal`. Always pass `--window "$FWIN" --workspace "$FW"` alongside `--surface`.

**Never** fall back to `cmux send` without the captured target (or to `$CMUX_SURFACE_ID`): if the split failed, that would inject the `cd` into the focused pane, which may be a running agent. The `cd` only ever goes to the freshly created split; abort if no new ref.

Echo the targeted workspace/surface, the new surface ref, the worktree path, and the direction. If the worktree path doesn't exist, stop and say so.

## Related

- **worktree-cmux-workspace** — same worktree, but as its own new workspace.

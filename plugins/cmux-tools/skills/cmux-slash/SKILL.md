---
name: cmux-slash
description: Use when on remote control (phone/web) and you need to run a Claude Code slash command that remote control blocks — /context, /status, /cost, /model, /reload-skills, etc. Injects the slash command into a local cmux pane via the cmux CLI so it executes there; you view the result through cmux's pane mirroring. Two modes — this session's own pane (default), or BROADCAST to every running Claude pane at once. Trigger phrases: "리모트에서 /context 실행해줘", "이 세션에 /status 띄워줘", "모든 claude에 /reload-skills 때려줘", "전부 reload-skills", "all claude sessions reload", "run /context in the pane", "inject a slash command locally".
---

# cmux-slash

Run a Claude Code slash command (`/context`, `/status`, `/reload-skills`, …) that remote control can't open, by typing it directly into a local cmux pane via the cmux CLI. The command executes in the real TUI; view the result through cmux pane mirroring (this skill does NOT read output back into the conversation).

CMUX binary: `/Applications/cmux.app/Contents/Resources/bin/cmux`

## Pick a mode

- **Own pane (default → Mode A)** — inject into THIS session's pane. Use for commands about this session: `/context`, `/status`, `/cost`, `/model`, `/compact`.
- **Broadcast (Mode B)** — inject into EVERY running Claude pane at once. Use when the user says "모든 claude", "전부", "all sessions", "every claude" — typically `/reload-skills` after editing a skill.

## What command to send

Passthrough — send whatever slash command the user names, including arguments (`/model opus`, `/config`). Normalize a single leading slash (accept `context` or `/context`; send `/context`).

## Mode A — own pane

The target is **always this session's own pane**, identified by `$CMUX_SURFACE_ID` (cmux auto-sets it as the default `--surface`; it points to the pane this Claude process runs in).

> Note: the `worktree-cmux-*` skills deliberately AVOID `$CMUX_SURFACE_ID` because their goal is the pane the user is *looking at* (`identify.focused`), which differs from Claude's own pane. Here the goal is the opposite — Claude's own pane — so `$CMUX_SURFACE_ID` is exactly right. Do not import that warning.

```bash
CMUX=/Applications/cmux.app/Contents/Resources/bin/cmux

# 1. Guard: must be inside a cmux terminal.
if [ -z "$CMUX_SURFACE_ID" ]; then
  echo "ABORT: \$CMUX_SURFACE_ID is empty — not running inside a cmux pane."
  exit 1
fi

# 2. Transparency: echo the target surface + its title so the user can confirm.
title=$("$CMUX" tree --all 2>/dev/null | grep '◀ here' | grep -oE '"[^"]+"' | head -1)
echo "target surface: $CMUX_SURFACE_ID  ${title:-(title unknown)}"

# 3. Type the command, then commit it with Enter.
CMD="/context"   # <- the normalized command the user asked for
"$CMUX" send     --surface "$CMUX_SURFACE_ID" -- "$CMD"
"$CMUX" send-key --surface "$CMUX_SURFACE_ID" enter

echo "sent: $CMD"
```

`$CMUX_SURFACE_ID` is a UUID, so it resolves without `--window`/`--workspace` context.

## Mode B — broadcast to every Claude pane

Detect every pane running Claude Code and fire the command into each (this pane included).

- **Detection.** A Claude pane is a `cmux top` process row whose parent is a `surface:N` and whose command label is a version string (`2.1.177`).
- **Window context.** Short surface refs (`surface:5`) resolve only within a `--window`; without it they mis-resolve against `$CMUX_WORKSPACE_ID`. Map each surface→window from `cmux --json tree`, then pass `--window` on every `send`/`send-key`.

Set `FIRE=0` to preview the target list, then `FIRE=1` to send. The block below prints the targets before sending either way. For destructive commands (`/clear`, `/compact`, `/logout`, `/exit`), run `FIRE=0` and confirm with the user first — broadcast hits every running agent.

```bash
CMUX=/Applications/cmux.app/Contents/Resources/bin/cmux
CMUX="$CMUX" CMD="/reload-skills" FIRE=1 python3 <<'PY'
import os, re, subprocess, json
CMUX=os.environ["CMUX"]; CMD=os.environ["CMD"]; FIRE=os.environ["FIRE"]=="1"
def run(*a): return subprocess.run([CMUX, *a], capture_output=True, text=True)

# surface -> window / title, from structured tree
tree = json.loads(run("--json", "tree", "--all").stdout)
surf2win, surf2title = {}, {}
for win in tree.get("windows", []):
    for ws in win.get("workspaces", []):
        for pane in ws.get("panes", []):
            for s in pane.get("surfaces", []):
                surf2win[s["ref"]] = win["ref"]
                surf2title[s["ref"]] = s.get("title", "")
own = tree.get("caller", {}).get("surface_ref")

# claude panes: process rows parented to a surface, whose command is a version
VER = re.compile(r'^\d+\.\d+\.\d+')
targets = []
for line in run("top", "--all", "--processes", "--flat", "--format", "tsv").stdout.splitlines():
    f = line.split("\t")
    if len(f) >= 7 and f[3] == "process" and f[5].startswith("surface:") and VER.match(f[6].strip()):
        targets.append((f[5], surf2win.get(f[5], "window:1")))
targets.sort(key=lambda t: int(t[0].split(":")[1]))

print(f"{CMD}  own={own}  claude panes: {len(targets)}")
for ref, win in targets:
    print(f"  {ref:<11} {win:<9} {'[self]' if ref == own else '      '} {surf2title.get(ref, '')}")

if not FIRE:
    print("DRY-RUN: nothing sent.")
    raise SystemExit

print("--- sending ---")
ok = 0
for ref, win in targets:
    a = run("send",     "--window", win, "--surface", ref, "--", CMD)
    b = run("send-key", "--window", win, "--surface", ref, "enter")
    good = a.returncode == 0 and b.returncode == 0
    ok += good
    print(f"  {'OK  ' if good else 'FAIL'} {ref}")
print(f"done: {ok}/{len(targets)} sent")
PY
```

## Behavior: queued, then runs on turn-end

This skill runs *during* an active turn, so the `Enter` does not execute the command immediately — Claude Code **queues** it (the pane shows `❯ /context` above "Press up to edit queued messages"). The queued command runs the instant that pane's turn ends, and the result renders there. That is exactly why the "view via the pane mirror" model works — and why this skill never tries to read the result back. Don't treat the queued state as a failure. (Idle panes in a broadcast execute right away; busy panes queue and run at their own turn-end.)

## Safety

- **Mode A is own pane only.** Targeting is pinned to `$CMUX_SURFACE_ID`; there is no path to fire into another agent.
- **Mode B hits every Claude pane.** Safe and intended for idempotent commands like `/reload-skills`. For destructive ones (`/clear`, `/compact`, `/logout`, `/exit`), preview with `FIRE=0` and confirm before sending.
- **Destructive commands fire as named.** If the user explicitly names `/clear`, `/compact`, etc. for their own pane (Mode A), naming it is the confirmation — send it. Don't add a guard.
- **No read-back.** Results are visible only in the panes; the user views them through cmux's mirror. Don't claim to have read them.

## Related

- **worktree-cmux-split** / **worktree-cmux-workspace** — open a worktree in a cmux pane (those target the *focused* pane, not Claude's own).

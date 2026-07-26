---
name: cmux-new-workspace
description: Use when the user wants a NEW cmux workspace opened on a project directory with Claude Code already running in it — creates the workspace, launches Claude there, waits for the TUI to boot, then injects `/rename <name>` and `/rc` so the session is named and remote control is live. When no path is given, offers the 10 most recently used project directories ranked by Claude Code session recency. Trigger phrases: "cmux 새 워크스페이스 띄워줘", "새 워크스페이스에서 클로드 켜줘", "최근 디렉토리로 세션 하나 열어줘", "리모트 컨트롤까지 켜서 열어줘", "open a new cmux workspace and start claude there", "spin up a named remote-controlled session". For the git worktree you are currently working on, use worktree-cmux-workspace instead; for a split pane inside the current workspace, use worktree-cmux-split.
---

# cmux-new-workspace

Create a new cmux workspace on a chosen project directory, boot Claude Code in
it, and drive the fresh TUI through `/rename <name>` and `/rc` — so the session
lands named and remote-controllable without the user typing anything.

CMUX binary: `/Applications/cmux.app/Contents/Resources/bin/cmux`

For a bare workspace with no agent in it, just run `cmux new-workspace`
directly; this skill is for the full launch sequence.

## Step 1 — Resolve the target directory

In priority order:

1. **Explicit path in the prompt** — use it as-is, skip the scan.
2. **Project name, not a path** — run the scan below, then match the name
   against the candidate paths: basename first, then substring. A single match
   is used directly; zero or several matches fall through to the picker.
3. **Nothing given** — show the picker.

### The scan

Rank by Claude Code session recency, read from `~/.claude/projects`.

Do **not** use `~/.claude.json` for this. Its `projects` map cannot order by
recency: most entries carry no `lastSessionModified` at all, and worktree
directories never appear there. The session logs are the reliable source — each
`*.jsonl` transcript carries a `cwd` field with the original absolute path. The
containing directory's _name_ is useless on its own, because the encoding
collapses `/`, `-`, and `.` all into `-` and cannot be decoded back.

```bash
python3 <<'PY'
import datetime, glob, json, os

base = os.path.expanduser('~/.claude/projects')
here = os.getcwd()
rows = []

for entry in os.listdir(base):
    project = os.path.join(base, entry)
    if not os.path.isdir(project):
        continue
    logs = glob.glob(os.path.join(project, '*.jsonl'))
    if not logs:
        continue
    newest = max(logs, key=os.path.getmtime)
    cwd = None
    with open(newest, errors='replace') as f:
        for line in f:
            try:
                obj = json.loads(line)
            except ValueError:
                continue
            if isinstance(obj, dict) and obj.get('cwd'):
                cwd = obj['cwd']
                break
    if cwd and os.path.isdir(cwd):
        rows.append((os.path.getmtime(newest), cwd))

rows.sort(reverse=True)
seen, out = set(), []
for mtime, cwd in rows:
    if cwd in seen:
        continue
    seen.add(cwd)
    out.append((mtime, cwd))

if not out:
    print('(no candidates)')
for i, (mtime, cwd) in enumerate(out[:10], 1):
    stamp = datetime.datetime.fromtimestamp(mtime).strftime('%Y-%m-%d %H:%M')
    tag = '   <- current session' if cwd == here else ''
    print(f'{i:2}. {stamp}  {cwd}{tag}')
PY
```

Print the table and ask the user to pick a number. The current session's own
directory stays in the list — opening a second workspace on the same directory
is a legitimate thing to do.

If the scan prints `(no candidates)`, ask the user for a path outright.

## Step 2 — Ask for the session name

Always ask; never infer it from the branch or directory. The answer is used
twice: as the `/rename` argument and as the cmux workspace `--name`.

## Step 3 — Pick the launch command

Default is `claude`. Use `claude --continue` **only** when the user explicitly
asked to resume ("이어서", "resume", "--continue"). Do not ask otherwise.

## Step 4 — Create, wait, inject

Fill in the three variables from steps 1-3, then run this as one block.

```bash
CMUX=/Applications/cmux.app/Contents/Resources/bin/cmux

DIR="<resolved path>"
NAME="<session name>"
LAUNCH="claude"          # or "claude --continue"

[ -x "$CMUX" ] || { echo "ABORT: cmux binary not found at $CMUX"; exit 1; }
[ -d "$DIR" ]  || { echo "ABORT: no such directory: $DIR"; exit 1; }

# Create the workspace. stdout is "OK workspace:<n>".
WS=$("$CMUX" new-workspace --name "$NAME" --cwd "$DIR" --command "$LAUNCH" --focus true | awk '{print $2}')
[ -n "$WS" ] || { echo "ABORT: new-workspace produced no workspace ref"; exit 1; }

# Resolve the surface to type into, plus its window.
PANELS=$("$CMUX" --json list-panels --workspace "$WS")
SURF=$(printf '%s' "$PANELS" | python3 -c 'import json,sys; print(json.load(sys.stdin)["surfaces"][0]["ref"])')
WIN=$(printf  '%s' "$PANELS" | python3 -c 'import json,sys; print(json.load(sys.stdin)["window_ref"])')
echo "workspace=$WS surface=$SURF window=$WIN cwd=$DIR"

# Wait until the TUI actually accepts input. Read the screen — do NOT poll for the
# claude process, which appears ~1s in, long before the input box is live and also
# while a blocking prompt is on screen.
READY=0
for _ in $(seq 60); do
  SCREEN=$("$CMUX" read-screen --window "$WIN" --surface "$SURF" 2>/dev/null)
  if printf '%s' "$SCREEN" | grep -q "one you trust"; then
    echo "ABORT: Claude is asking whether $DIR is a folder you trust."
    echo "Answer that prompt in the new workspace yourself, then type:"
    echo "  /rename $NAME"
    echo "  /rc"
    exit 1
  fi
  if printf '%s' "$SCREEN" | grep -qE "shift\+tab to cycle|\? for shortcuts"; then
    READY=1
    break
  fi
  sleep 1
done

if [ "$READY" -ne 1 ]; then
  echo "TIMEOUT: Claude did not reach its input box in $SURF within 60s."
  echo "The workspace is open at $DIR — type these there manually:"
  echo "  /rename $NAME"
  echo "  /rc"
  exit 1
fi

"$CMUX" send     --window "$WIN" --surface "$SURF" -- "/rename $NAME"
"$CMUX" send-key --window "$WIN" --surface "$SURF" enter
sleep 2
"$CMUX" send     --window "$WIN" --surface "$SURF" -- "/rc"
"$CMUX" send-key --window "$WIN" --surface "$SURF" enter
sleep 3

# Verify the rename: Claude labels the input box's top border with the session name.
if "$CMUX" read-screen --window "$WIN" --surface "$SURF" 2>/dev/null | grep -qF "$NAME"; then
  echo "OK: renamed to '$NAME'; /rc sent."
else
  echo "WARN: '$NAME' is not on screen — /rename may not have landed. Check the pane."
fi
```

Notes on the mechanics:

- `--cwd` puts the shell in the target directory directly; no follow-up `cd`.
- `--command` sends text+Enter to the new workspace after it is created.
- `--window` is **required** alongside a short `surface:<n>` ref. Without it the
  ref resolves against `$CMUX_WORKSPACE_ID` — the caller's own workspace — and
  the commands land in the wrong pane.
- `/rename` takes its argument inline, so it is one line, not two.
- **Readiness must come from `read-screen`, not from process presence.** The
  `claude` process shows up in `cmux top` about a second after launch, while the
  screen is still the trust-folder prompt (`❯ 1. Yes, I trust this folder`).
  Typing `/rename …` + Enter there answers that prompt instead. Both footer
  markers grepped above (`shift+tab to cycle`, `? for shortcuts`) are rendered
  by Claude Code itself, so they work on any machine.
- **Do not verify against the status line.** Strings like `session:<name>` or an
  `/rc` indicator come from a user-configured `statusLine` script, not from
  Claude Code — they are absent on a default setup. The input box border label
  is built in, so that is what the check above greps for.
- The trust prompt is left for the user to answer. Silently accepting it would
  be trusting a folder on their behalf.
- `/rc` is sent but not verified — there is no portable on-screen signal for it.
  Report it as sent, not as confirmed.

## Step 5 — Report

Echo the resolved path, the session name, and the workspace/surface refs. Say
plainly whether the injection succeeded; on timeout, say the workspace is open
but the two commands were not sent.

## Failure handling

| Condition                  | Behavior                                                              |
| -------------------------- | --------------------------------------------------------------------- |
| `cmux` binary missing      | Abort before creating anything                                        |
| Chosen path does not exist | Abort; never substitute a different directory                         |
| Scan returns nothing       | Ask the user for a path directly                                      |
| Trust-folder prompt shown  | Stop injecting, leave it for the user, print the two commands to type |
| Readiness poll times out   | Leave the workspace open, report that injection did not happen        |
| Name not on screen after   | Report the warning as-is; do not claim the rename worked              |

Never claim the session was renamed or remote control started without the
commands having actually been sent.

## Related

- **worktree-cmux-workspace** — new workspace for the git worktree in progress,
  no agent launch.
- **worktree-cmux-split** — same, but as a split pane in the current workspace.
- **cmux-slash** — inject a slash command into an already-running Claude pane.

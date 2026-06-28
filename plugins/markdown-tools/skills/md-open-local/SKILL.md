---
name: md-open-local
description: Use when the user wants to open/view a Markdown file LOCALLY on the Mac (e.g. "이 md 로컬에서 열어줘", "open this md locally") — opens it in the macOS default app via the `open` CLI. For viewing over remote control instead, use md-view-remote.
---

# md-open-local

Open a Markdown file in the local Mac's default app so the user can read it on the machine in front of them.

## When to use vs md-view-remote

- **md-open-local** (this): user is at the Mac → `open` the file in its default viewer.
- **md-view-remote**: user is on remote control (phone/web) → surface the full file text into the conversation.

If unsure which, default to this one only when the user explicitly says "local / 로컬"; otherwise ask which.

## Procedure

1. Resolve the target file:
   - Explicit argument if given.
   - Else the Markdown file most recently produced/referenced this session (e.g. a spec you just wrote).
2. Open it:
   ```bash
   open "<file.md>"
   ```
3. Confirm with the path opened. Do not also dump the contents (that's md-view-remote's job).

## Notes

- `open` uses whatever app is registered for `.md` on this Mac. Pass `-a "<App>"` only if the user names a specific app.

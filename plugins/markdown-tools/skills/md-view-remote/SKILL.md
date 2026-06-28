---
name: md-view-remote
description: Use when the user wants to view/surface a Markdown file's content while on REMOTE control (phone/web), e.g. "이 md 띄워줘", "전문 띄워줘", "show me this md". Reads the ENTIRE file into the conversation verbatim (the only way to view a file on remote control) — never summarize. For opening on the local Mac instead, use md-open-local.
---

# md-view-remote

Surface a Markdown file's full content into the conversation so the user can read it over remote control, where opening a local app is not possible.

## Rule

Use the **Read** tool on the file and surface its **full content** — do not summarize, excerpt, or paraphrase. Surfacing the verbatim file is the deliverable; a summary is a failure of this skill. (Matches the standing user preference that "xx 읽어줘 / 전문 띄워줘" means Read the whole file into the chat.)

If the file is very large, Read it in full across multiple calls rather than truncating.

## Procedure

1. Resolve the target file:
   - Explicit argument if given.
   - Else the Markdown file most recently produced/referenced this session.
2. `Read` the file in full.
3. Present it. Add at most a one-line pointer to the path; the content itself is the point.

## When to use vs md-open-local

- **md-view-remote** (this): remote control → full text in chat.
- **md-open-local**: at the Mac → `open` in the default app.

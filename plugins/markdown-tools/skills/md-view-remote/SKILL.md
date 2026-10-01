---
name: md-view-remote
description: Use when the user wants to view/surface a Markdown file's content while on REMOTE control (phone/web), e.g. "이 md 띄워줘", "전문 띄워줘", "show me this md". For opening on the local Mac instead, use md-open-local.
---

# md-view-remote

Send a Markdown file to the user with `SendUserFile` so they can read its full content over remote control, where opening a local app is not possible.

## Rule

Send the **file itself**. The user receives the whole file as written — do not summarize, excerpt, or paraphrase. Delivering the verbatim file is the deliverable; a summary is a failure of this skill. A request like "xx 읽어줘 / 전문 띄워줘" means the user gets the whole file.

Do not `Read` the file or paste it into the chat. The file content never enters your context, so the cost does not grow with file size.

## Procedure

1. Resolve the target file as an absolute path:
   - Explicit argument if given.
   - Else the Markdown file most recently produced/referenced this session.
2. Confirm it exists: `ls <absolute path>`.
3. Call `SendUserFile`. If its schema is not loaded yet (deferred tool), run `ToolSearch` with `select:SendUserFile` first. Several files go in one call.

   ```
   SendUserFile({
     files: ["/abs/path/to/doc.md"],
     display: "attach",
     status: "normal"
   })
   ```

   Use `display: "attach"` (a file card); sending `.md` with `render` has not been tried, so inline rendering is unverified.

4. Add at most a one-line pointer to the path.

## Fallback

If `SendUserFile` is not found by `ToolSearch`, or the call returns `NOT be delivered`, `Read` the file in full (across multiple calls if it is large) and output its full content verbatim in the chat. State the fallback and the error text in one line.

Delivery depends on the session. A session started from the iOS app fails with `this session is not on a project thread`; a session started from the CLI with remote control enabled delivers.

## When to use vs md-open-local

- **md-view-remote** (this): remote control → the file is sent to the user.
- **md-open-local**: at the Mac → `open` in the default app.

---
name: pr-rewrite
description: Write or rewrite a GitHub pull request title and body so it is short, structured, and matched to the repository's own convention — Why / What / How as the default skeleton, extra sections only when they carry information the reader cannot get elsewhere, and never a restatement of the diff. Use when the user asks to write, shorten, tidy, or restructure a PR title or body, or says the PR is too long, too verbose, unstructured, or not following convention. Trigger phrases: "PR 본문 간결하게", "pr 제목 너무 길어", "본문 정리해줘", "구조적으로 작성해", "소설 쓰지 마", "diff 내용 옮기지 마", "repo 관습에 맞춰서", "make the PR body concise", "shorten this PR description".
argument-hint: '[PR number ...]'
---

# PR Rewrite

Rewrites a PR title and body down to the shortest form a reviewer can still
decide from. The failure it exists to prevent: a body that narrates the diff
file-by-file in prose.

## Target

- **No argument** → the current branch's PR:
  `gh pr view --json number,title,body,url`.
- **One or more PR numbers** → each in turn. Rewriting a whole stack in one pass
  is a normal request.
- **No PR yet** → produce the title and body, show them, and ask before running
  `gh pr create`. Never create a PR unprompted.

## 1. Derive the repo's convention

Title language, prefix format, and ticket-ID placement differ per repo. Check in
this order and stop at the first that answers:

1. `.github/pull_request_template.md`
2. `CONTRIBUTING.md`
3. The repo's `CLAUDE.md` / `AGENTS.md`
4. `gh pr list --state merged --limit 15 --json title,body`

State what you derived in **one line** before writing, e.g.
`convention: title ja "<prefix>(<ticket>): <desc>", body ja, no template`.

## 2. Title

- One core change only.
- No decorative tags, qualifiers, or parenthetical filler.
- A trailing `(...)` is reserved for the issue ID.
- Keep the repo's `prefix(scope):` form and its language.

**"Concise" never means dropping the issue ID or the prefix.** Shortening the
description is the job; deleting required structure is not.

## 3. Body — Why / What / How

Three sections, in that order. They are enough for most PRs.

- **Why** — what was broken or missing, stated from the reader's side.
- **What** — the change at the level of behaviour, not files.
- **How** — the approach the reviewer needs in order to read the diff.

**Budget: these three sections total 20 rendered lines or fewer** (headings
excluded), 1–4 bullets each. Bullets, not paragraphs.

## 4. Extra sections

Allowed **only when they carry information the reader cannot get elsewhere**.

- Legitimate: `## スタック（PR シリーズ）`, screenshots or video for UI changes,
  sections the repo's PR template requires, verification steps the reviewer must
  run themselves.
- Never: file-by-file change listings, change-volume tables, diff restatement,
  local-only paths (`docs/superpowers/specs/...` and the like — dead links for
  the reviewer), plan/spec narration, "what I accomplished" summaries.

Test: _"if this section were missing, what would the reviewer get wrong?"_
Screenshots and the stack section do not count toward the 20-line budget.

## 5. Self-check before applying

Run the same test per line: _"if this line were missing, what would the reviewer
get wrong?"_ No concrete answer → delete the line. Then confirm:

- [ ] Why / What / How total 20 lines or fewer
- [ ] Title carries the issue ID and the repo's prefix form
- [ ] No file-by-file listing, no diff restatement
- [ ] No local-only path
- [ ] Every extra section passed the necessity test

## 6. Apply

Write the body to a file first — quoting a multi-line body inline is fragile:

```bash
gh pr edit <N> --title "<title>" --body-file /tmp/pr-body-<N>.md
```

**Preserve `## スタック（PR シリーズ）` verbatim.** `pr-stack` owns that
section: copy it across unchanged rather than regenerating it. Same for pasted
images.

Verify: `gh pr view <N> --json title,body`.

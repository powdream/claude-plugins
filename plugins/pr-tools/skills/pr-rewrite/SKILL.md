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
- **No PR yet** → `gh pr view` exits non-zero. Produce the title and body, write
  the body to `/tmp/pr-body-<branch>.md`, show both, and ask before running
  `gh pr create --title "<title>" --body-file /tmp/pr-body-<branch>.md`. Never
  create a PR unprompted.

**Before touching any existing PR — every one of them, including each number of
a multi-PR run — save its current body:**

```bash
gh pr view <N> --json body -q .body > /tmp/pr-body-<N>.orig.md
```

`gh pr edit --body-file` replaces the whole body, so anything not carried over
from that file is gone. Skipping this step across an open stack destroys the
merged-ancestor history that `pr-stack` reads back out of the bodies.

## 1. Derive the repo's convention

Two conventions, derived separately. `.github/pull_request_template.md` governs
the **body** and says nothing about title format or ticket-ID placement.

- **Body and required sections** — first that answers among
  `.github/pull_request_template.md` → `CONTRIBUTING.md` → the repo's
  `CLAUDE.md` / `AGENTS.md`.
- **Title format, prefix, ticket-ID placement** — those same three sources only
  when one states a title rule outright; otherwise infer it from
  `gh pr list --state merged --limit 15 --json title,body`.

State what you derived in **one line**, naming where each field came from, e.g.
`title "<prefix>(<ticket>): <desc>" ja, from merged PRs; body ja, from CONTRIBUTING.md; no template`.

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

**Budget: these three sections total 20 lines of Markdown source or fewer**
(headings excluded), 1–4 bullets each. Bullets, not paragraphs.

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

- [ ] Why / What / How total 20 lines of Markdown source or fewer
- [ ] Title carries the issue ID and prefix form, if the repo's convention uses
      one
- [ ] No file-by-file listing, no diff restatement
- [ ] No local-only path
- [ ] Every extra section passed the necessity test

## 6. Apply

Build the new body in `/tmp/pr-body-<N>.md` — quoting a multi-line body inline
is fragile. **Copy every preserved block out of `/tmp/pr-body-<N>.orig.md`**
rather than retyping it: `## スタック（PR シリーズ）`, pasted `user-attachments`
image lines, template-required sections. `pr-stack` recovers a stack's merged
ancestors only by parsing the bullets already in the body, so a
retyped-from-memory stack section loses that history for good.

```bash
gh pr edit <N> --title "<title>" --body-file /tmp/pr-body-<N>.md
```

Then assert the stack section survived byte-identical — this must print nothing:

```bash
diff <(sed -n '/^## スタック/,$p' /tmp/pr-body-<N>.orig.md) \
     <(gh pr view <N> --json body -q .body | sed -n '/^## スタック/,$p')
```

If it prints anything, restore the original —
`gh pr edit <N> --body-file /tmp/pr-body-<N>.orig.md` — and redo the copy.

Verify the rest: `gh pr view <N> --json title,body`.

## Examples

Before — tags padding the title, body narrating the diff:

```
[FEAT][BE] Refactor the notification pipeline and add retry support with tests (ABC-123)

## Changes
- `notifier.ts`: extracted `sendWithRetry`, +42 lines
- `notifier.test.ts`: 6 new cases
- `config.ts`: added `maxRetries`

The pipeline is much cleaner now.
```

After — issue ID and `prefix(scope):` kept, everything else cut:

```
feat(notifier): retry failed sends (ABC-123)

## Why
- Transient 5xx from the provider dropped notifications silently.

## What
- Sends retry up to `maxRetries`, then surface as failed.

## How
- Backoff is contained in `sendWithRetry`; callers unchanged.
```

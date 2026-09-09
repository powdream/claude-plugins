---
name: pr-rewrite
description: Write or rewrite a GitHub pull request title and body so it is short, structured, and matched to the repository's own convention — the repository's PR template or merged-PR pattern as the skeleton, Why / What / How only when it has none, extra sections only when they carry information the reader cannot get elsewhere, and never a restatement of the diff. Use when the user asks to write, shorten, tidy, or restructure a PR title or body, or says the PR is too long, too verbose, unstructured, or not following convention. Trigger phrases: "PR 본문 간결하게", "pr 제목 너무 길어", "본문 정리해줘", "구조적으로 작성해", "소설 쓰지 마", "diff 내용 옮기지 마", "repo 관습에 맞춰서", "make the PR body concise", "shorten this PR description", "diff 보면 아는 건 빼", "배경만 남겨", "없는 것부터 쓰지 마", "write only what the diff cannot show", "리포 템플릿 따라서", "기존 PR 패턴대로", "follow the repo's PR template".
argument-hint: '[PR number ...]'
---

# PR Rewrite

Rewrites a PR title and body down to what a reviewer with the diff open still
needs. The two failures it exists to prevent: a body that narrates the diff, and
a body that opens with what was missing before the change.

## Target

- **No argument** → the current branch's PR:
  `gh pr view --json number,title,body,url`.
- **One or more PR numbers** → each in turn. Rewriting a whole stack in one pass
  is a normal request.
- **No PR yet** → `gh pr view` exits non-zero. Produce the title and body, write
  the body to `/tmp/pr-body-new.md`, show both, and ask before running
  `gh pr create --title "<title>" --body-file /tmp/pr-body-new.md`. Never create
  a PR unprompted. Do not derive that filename from the branch — a branch name
  with a `/` in it points at a directory that does not exist.

**Before touching any existing PR — every one of them, including each number of
a multi-PR run — save its current body:**

```bash
gh pr view <N> --json body -q .body > /tmp/pr-body-<N>.orig.md
```

`gh pr edit --body-file` replaces the whole body, so anything not carried over
from that file is gone. Skipping this step across an open stack destroys the
merged-ancestor history that `pr-stack` reads back out of the bodies.

## 1. Derive the repo's convention

The repository's own skeleton wins. Why / What / How is the fallback for a
repository that has none.

Derive these in order, and stop at the first source that answers each:

1. **A repo-supplied PR skill or agent** — `.claude/skills/*pr*/`,
   `.agents/skills/*pr*/`, or a PR-writing rule named in `AGENTS.md` /
   `CLAUDE.md`. When one exists it governs the title and the body: run it, and
   use this skill only for what it leaves open.
2. **Body skeleton** — the section headings and their order, from the first of:
   - a PR template at any location GitHub reads:
     `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE/*.md`,
     `pull_request_template.md` at the root or under `docs/`, then the org
     default in the `<owner>/.github` repository
     (`gh api repos/<owner>/.github/contents/<the same paths>`)
   - a written rule in `CONTRIBUTING.md`, `CLAUDE.md`, or `AGENTS.md`
   - the merged PRs: `gh pr list --state merged --limit 15 --json title,body`.
     The headings that appear in a majority of those bodies, in the order they
     appear, are the skeleton.
3. **Title format** — prefix, scope, ticket-ID placement: a written rule in the
   files above; otherwise the majority form of the merged titles.
4. **Language** — the template's; otherwise the merged PRs'.

An absent `.github/pull_request_template.md` says nothing about the org
template or the merged PRs; both still answer.

State what you derived in **one line**, naming the source of each field, e.g.
`title "[<ticket>] <desc>" ja, from merged PRs; body 背景/変更点/動作確認 ja, from merged PRs (no template, no CONTRIBUTING)`.

## 2. Title

- One core change only.
- No decorative tags, qualifiers, or parenthetical filler.
- The issue ID sits where the repo's form puts it — `[<ticket>]` in front or
  `(<ticket>)` at the end — and a trailing `(...)` holds nothing else.
- Keep the derived form (`prefix(scope):`, `[<ticket>]`, …) and its language.

**"Concise" never means dropping the issue ID or the prefix.** Shortening the
description is the job; deleting required structure is not.

## 3. Body — the derived skeleton, else Why / What / How

The body uses the skeleton from step 1: its headings, in its order, each
section opening with its conclusion. The skeleton's sections hold the material
described below under their own names — `背景` / `変更の背景` / `概要` holds
Why, `変更点` / `変更内容` holds What and never the file list, `動作確認` /
`確認方法` holds the verification steps. Material with no section of its own
goes under the first section. A section the skeleton requires stays even when
it holds one line.

When step 1 derived no skeleton, three sections, in this order:

- **Why** — the requirement the change serves, and what becomes true once it
  lands. The line names what is needed; a triggering bug or ticket is its
  grounds, in parentheses or one nested bullet.
- **What** — the behaviour after the change, as the user or the caller sees it.
- **How** — the background the diff cannot show: a constraint from outside the
  repository, a measured behaviour of a dependency, the reason behind a chosen
  number. How exists only when at least one line survives the test below.

**Each line answers a question the diff leaves open.** Test per line:
_"with the diff open, does the reviewer already know this?"_ Yes → the line
goes. A function name, a call-site count, a file name, a default value, a test
name, a package added to `pubspec.yaml` or `package.json` — the diff shows all
six.

**Each line states what the change does, needs, or makes true.** Read each
line's main verb. しない・ない・not・no・never → rewrite the line as what happens
instead: `以降は端末のキャッシュから表示する`, in place of `再取得しない`. A
rejected alternative lives in the ticket or the ADR. When the change stops short
of something a reviewer would expect it to cover, one line at the end of What
names that boundary, and that line is the one this verb check skips.

**Budget: the body's sections total 20 lines of Markdown source or fewer**
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

- [ ] Every line passed _"with the diff open, does the reviewer already know
      this?"_ — no function name, file name, call-site count, default value,
      test name, or added package the diff shows
- [ ] Every line's main verb is affirmative — no しない・ない・not・never outside
      the one boundary line at the end of What
- [ ] Body headings match the derived skeleton, in its order; Why / What / How
      only when step 1 derived none
- [ ] The convention line names a source for the title and for the body
- [ ] The body's sections total 20 lines of Markdown source or fewer
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
sed -n '/^## スタック/,$p' /tmp/pr-body-<N>.orig.md > /tmp/pr-stack-<N>.before
gh pr view <N> --json body -q .body | sed -n '/^## スタック/,$p' > /tmp/pr-stack-<N>.after
diff /tmp/pr-stack-<N>.before /tmp/pr-stack-<N>.after
```

If it prints anything, restore the original —
`gh pr edit <N> --body-file /tmp/pr-body-<N>.orig.md` — and redo the copy.

Verify the rest: `gh pr view <N> --json title,body`.

## Examples

Before — tag-padded title, file-by-file listing, self-congratulatory closer:

```
[FEAT][BE] Refactor the notification pipeline and add retry support (ABC-123)
## Changes
- `notifier.ts`: extracted `sendWithRetry`, +42 lines
The pipeline is much cleaner now.
```

After — issue ID and `prefix(scope):` kept, every line something the diff
cannot show:

```
feat(notifier): retry failed sends (ABC-123)

## Why
- A notification has to reach the user or be reported as failed (ABC-101, ABC-117).
## What
- A send is retried up to `maxRetries`, then reported as failed.
- A 4xx is reported as failed on the first attempt.
## How
- The provider's 5xx cleared within 2 s in every case over a month, so backoff starts at 1 s.
```

Lines cut from the draft: four the diff already shows (`sendWithRetry` wraps
`provider.send`; three call sites switched; `maxRetries` defaults to 3; four
tests added) and one rejected alternative (the persistent queue), which lives in
the ticket.

---
name: comments-cleanup
description: Remove unnecessary comments from a code change — restated code, tutorial-length rationale, change-history notes, decorative dividers, commented-out code — keeping only comments whose absence would cause a specific wrong change, each rewritten to state what the code does. Asks first whether to clean only the changed lines or every comment in the changed files. Use when the user asks to tidy, prune, or delete unnecessary, verbose, or redundant comments, or says the comments are too many or too verbose. Trigger phrases: "불필요한 주석 정리", "주석 지워", "주석이 너무 verbose", "인라인 주석 정리해줘", "모든 수정에 주석 달지 마", "clean up unnecessary comments", "too many inline comments", "정당화 주석 지워", "Needed 주석 정리", "doc comment 첫 문장 고쳐", "rewrite justification comments".
argument-hint: '[path ...]'
---

# Comments Cleanup

Strips comments that carry no decision-changing information out of a change, and
rewrites the ones that survive into one line that states what the code does.

## 1. Pick the scope — ask first

**An explicit path argument wins.** Use those paths and skip the discovery
below.

Otherwise resolve the base first — `origin/main` may not exist, and a branch
stacked on another PR has to be scoped against its own base, not the ancestor
PR's files:

```bash
gh pr view --json baseRefName -q .baseRefName                   # this PR's base branch
gh repo view --json defaultBranchRef -q .defaultBranchRef.name  # fallback: default branch
git symbolic-ref --short refs/remotes/origin/HEAD               # offline fallback
```

`<base>` is that branch name prefixed with `origin/` (the third command already
prints it that way). If none of them answer, scope from
`git diff --name-only HEAD` alone, or ask.

The changed files are the union of:

```bash
git diff --name-only HEAD            # staged + unstaged
git diff --name-only <base>...HEAD   # committed on this branch
```

Untracked files are **not** in that union. List them separately — the command
also picks up scratch files and un-ignored build output, so they are never
folded in silently:

```bash
git ls-files --others --exclude-standard    # new files, not yet tracked
```

If it prints nothing, say nothing about it.

Then use **AskUserQuestion** to pick one. When the untracked list is non-empty,
name those paths in the question text, so the choice is made with them in view:

- **Changed lines only** — comments on lines this change added or modified.
- **Whole changed files** — every comment in those files.
- **Whole changed files + the untracked paths listed** — offer this option only
  when that list is non-empty.

An untracked file enters the working set only through that third option. Never
widen past what the user picked, and never touch a file the change did not
already modify, unless a path argument named it.

## 2. Apply the survival test

For every comment in scope, answer one question:

> **If this comment were gone, what specific wrong change would somebody make?**

Write the answer down before deciding. No concrete answer → delete the comment.
"It adds context" and "it explains the code" are not answers.

A comment that passes is not finished. It is rewritten into the shape in §4,
and the answer you wrote down is what the rewritten line says: the behaviour
the wrong change would break, stated as what the code does.

A doc comment on a public or exported declaration gets a second question:

> **Beyond its name and signature, what does this thing do?**

That answer is the doc comment's first sentence. Who calls it, when, and why it
exists are not answers; the call sites carry those. The answer is more than the
name when it states the input, the output, or a guarantee: `Exporter renders a
day's ledger rows as a CSV file` names both ends, `Exporter exports` is the
name. When the answer is only the name, the comment goes. When the repository's linter requires a doc comment on
every exported identifier (Go `revive` `exported`, Dart
`public_member_api_docs`), the one-sentence name form stays.

## 3. Delete these

Ordered by how often they show up:

1. **Restates the code**, or restates the line directly next to it.
2. **Tutorial-style rationale** — two sentences or more of explanation.
3. **Justification** — `// Needed: …`, `// No lock: …`, `// We chose X because
   …`. The comment defends a choice. When the code shows the consequence
   (`WithTimeout(ctx, deployTimeout)` sits on the next line), the comment goes.
   When the consequence names something outside this file — a lock held
   elsewhere, a default being overridden, a service's behaviour — the comment
   becomes that consequence, in the shape in §4.
4. **Usage narration** — who calls it, when, from where: `is used by the deploy
   workflow when a merge to main happens`. Call sites show it.
5. **Change-history commentary** — `// removed the old logic`,
   `// changed from X`, `// was: ...`. Git already knows.
6. **Section-divider decoration** — `// ===== helpers =====`.
7. **Obvious type or name annotations**, and commented-out code.
8. **Anything already written** in `README`, `AGENTS.md`, `CLAUDE.md`, or a
   spec.

## 4. Keep these

**Never delete — a tool reads these, not a person.** The survival test does not
apply; deleting them breaks the build:

- Compiler and toolchain directives — `//go:build linux`, `# noqa: E501`,
  `// eslint-disable-next-line`, `# type: ignore`, `@ts-expect-error`, coverage
  pragmas.
- Codegen headers — `// Code generated by protoc-gen-go. DO NOT EDIT.`
- License and SPDX headers.
- Machine-read markers such as `[start]` / `[end]`, and any other comment a tool
  parses.

Run the repo's build or lint after editing. A directive deleted by mistake shows
up there and nowhere else — the counts-only report hides it.

Keep by judgement:

- Temporary code whose **removal condition names a precise trigger**. "Remove
  someday" does not qualify; "remove once the ledger migration in INF-1234
  lands" does.
- The reason for genuinely non-obvious behaviour — **one line**.
- One line of reason per exception, or per `false` entry in a config list.
- Cross-file mapping pointers (jsdoc or inline) a reader cannot infer locally.

### The shape of a surviving comment

A surviving comment is one line that states what the code does or guarantees at
that point. Its subject is the code, and its verb is affirmative.

- An inline comment names the behaviour: what runs, what is returned, what is
  guaranteed, what is skipped and what happens instead.
- A doc comment's first sentence names the declaration and what it does, in the
  language's doc convention (Go: `Deployer registers …`; Dart: `/// Computes
  …`). Constraints the signature does not carry follow, one line each.
- A comment on a setting that overrides a default states what the setting makes
  happen.
- The line is the consequence and nothing after it. A tail that begins with
  `because`, `so that`, `to avoid`, `otherwise`, `would`, or `; the X needs` is
  the justification coming back. Cut the tail; when the code shows what is
  left, the comment goes.

| Before | After |
|---|---|
| `// Deployer is used by the deploy workflow when a merge to main happens, because the workflow needs a single entry point to push a task definition and wait for the service to become stable.` | `// Deployer registers a task definition and waits for the ECS service to stabilize.` |
| `// No lock: taking the deploy lock here would block manual deploys from the console.` | `// UpdateService runs outside the deploy lock; console deploys proceed concurrently.` |
| `// Needed: without the timeout a stuck service blocks the runner forever.` | deleted — `WithTimeout(ctx, deployTimeout)` on the next line shows it |
| `# No lock: locking would block manual applies` | `# Comparison-only plan: output feeds the diff check, never applied.` |
| `/// Used by CheckoutScreen when a coupon is applied to get the new total.` | `/// Computes the discounted total for a cart with a coupon applied.` |
| `# chunked to avoid OOM` | deleted — `chunks(rows, BATCH)` on the same line shows the batching |
| `"""Builds the CSV. We don't stream because the admin button needs the whole file."""` | `"""Builds the CSV for `day` and returns the whole file in memory."""` |

A surviving comment still gets compressed: at two sentences or more, cut it to
one line.

## 5. Language

Match the language of the file's existing comments. Default to English when the
file has no established one. **Never mix languages inside one comment** —
`# 등록に必要な権限` is a defect, not a style choice.

## 6. Report

One line per file: comment-line counts, and the number of comments rewritten:

```
internal/broker/deploy.go       24 → 11  (3 rewritten)
.github/workflows/deploy.yml     7 → 2
```

Do not reprint the deleted comments. That output is the verbosity this skill
exists to remove.

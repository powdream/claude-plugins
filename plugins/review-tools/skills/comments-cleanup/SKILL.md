---
name: comments-cleanup
description: Remove unnecessary comments from a code change — restated code, tutorial-length rationale, change-history notes, decorative dividers, commented-out code — keeping only comments whose absence would cause a specific wrong change. Asks first whether to clean only the changed lines or every comment in the changed files. Use when the user asks to tidy, prune, or delete unnecessary, verbose, or redundant comments, or says the comments are too many or too verbose. Trigger phrases: "불필요한 주석 정리", "주석 지워", "주석이 너무 verbose", "인라인 주석 정리해줘", "모든 수정에 주석 달지 마", "clean up unnecessary comments", "too many inline comments".
argument-hint: '[path ...]'
---

# Comments Cleanup

Strips comments that carry no decision-changing information out of a change, and
compresses the ones that survive.

## 1. Pick the scope — ask first

Collect the changed files:

```bash
git diff --name-only HEAD                  # staged + unstaged
git diff --name-only origin/main...HEAD    # committed on this branch
```

Substitute the repo's actual default branch for `origin/main`. Take the union.
When a path argument is given, use it instead and skip the union.

Then use **AskUserQuestion** to pick one:

- **Changed lines only** — comments on lines this change added or modified.
- **Whole changed files** — every comment in those files.

Never widen beyond the changed files. Never touch a file the change did not
already modify.

## 2. Apply the survival test

For every comment in scope, answer one question:

> **If this comment were gone, what specific wrong change would somebody make?**

Write the answer down before deciding. No concrete answer → delete the comment.
"It adds context" and "it explains the code" are not answers.

## 3. Delete these

Ordered by how often they show up:

1. **Restates the code**, or restates the line directly next to it.
2. **Tutorial-style rationale** — two sentences or more of explanation.
3. **Change-history commentary** — `// removed the old logic`,
   `// changed from X`, `// was: ...`. Git already knows.
4. **Section-divider decoration** — `// ===== helpers =====`.
5. **Obvious type or name annotations**, and commented-out code.
6. **Anything already written** in `README`, `AGENTS.md`, `CLAUDE.md`, or a
   spec.

## 4. Keep these

- Temporary code whose **removal condition names a precise trigger**. "Remove
  someday" does not qualify; "remove once the ledger migration in INF-1234
  lands" does.
- The reason for genuinely non-obvious behaviour — **one line**.
- One line of reason per exception, or per `false` entry in a config list.
- Cross-file mapping pointers (jsdoc or inline) a reader cannot infer locally.
- Machine-read markers such as `[start]` / `[end]`.

A surviving comment still gets compressed: at two sentences or more, cut it to
one line.

## 5. Language

Match the language of the file's existing comments. Default to English when the
file has no established one. **Never mix languages inside one comment** —
`# 등록に必要な権限` is a defect, not a style choice.

## 6. Report

One line per file, comment-line counts only:

```
internal/broker/deploy.go       24 → 11
.github/workflows/deploy.yml     7 → 2
```

Do not reprint the deleted comments. That output is the verbosity this skill
exists to remove.

# pr-rewrite & comments-cleanup — Design

## Goal

Two explicitly-invoked skills that encode instructions the user has had to
repeat roughly 80 times across three projects:

- **`pr-tools:pr-rewrite`** — write or rewrite a PR title and body that is
  short, structured, matched to the repo's own convention, and not a restatement
  of the diff.
- **`review-tools:comments-cleanup`** — remove unnecessary comments from a
  change.

## Why this recurs (measured)

Sweep of `~/.claude/projects/*/*.jsonl` on 2026-08-01, human turns only
(`isSidechain == true` excluded):

| Topic                     | Distinct sessions | Distinct complaint messages |
| ------------------------- | ----------------- | --------------------------- |
| PR title / body           | 12                | ~35                         |
| Unnecessary code comments | 17                | 45–50                       |

Peak: session `e101a8a0` repeated the comment instruction **9 times over 5
days**, with the assistant writing "세 번째 지적입니다" mid-session and then
repeating the mistake again.

Five causes:

1. **No trigger point.** All 12 flagged PR sessions ran raw `gh pr create` /
   `gh pr edit` through Bash. No PR-authoring skill was ever active, so no rule
   had anywhere to attach.
2. **Rules live in project-scoped memory.** `concise-pr-body.md`,
   `feedback_pr_concise.md`, `no-local-file-refs-in-pr-body.md`,
   `feedback_no_unnecessary_comments.md` load only under the `toridori-inc` /
   `toridori-base` project paths. A different repo starts with no rule at all.
3. **The always-on rule covers the title only.** `~/.claude/CLAUDE.md`'s "PR
   작성 규칙" governs the title. PR body, code comments, and "don't restate the
   diff" have no always-on rule anywhere.
4. **The one skill that authors PR bodies pushes the opposite way.**
   `common:create-pr` (`toridori-tools/common@1.1.0`) mandates a 4-section
   template with per-file numbered subsections, plus "抽象的な説明は避ける". It
   has no brevity constraint.
5. **Per-repo conventions diverge with no source of truth.** Japanese titles in
   `toridori-base-backend`, `prefix(scope): desc (INF-xxxx)` in `toridori-inc`.
   Hence the recurring "원본 repo의 관습에 맞춰서" instruction.

These skills fix causes 2–5. **Cause 1 is deliberately left unfixed**: the user
chose manual invocation over a `~/.claude/CLAUDE.md` pointer or a `PreToolUse`
hook, to keep everything inside this marketplace.

## Placement

| Skill              | Plugin         | Path                                                    | Version       |
| ------------------ | -------------- | ------------------------------------------------------- | ------------- |
| `pr-rewrite`       | `pr-tools`     | `plugins/pr-tools/skills/pr-rewrite/SKILL.md`           | 0.2.0 → 0.3.0 |
| `comments-cleanup` | `review-tools` | `plugins/review-tools/skills/comments-cleanup/SKILL.md` | 0.2.0 → 0.3.0 |

- `pr-tools` already holds `pr-chrome` and `pr-stack`; `pr-rewrite` keeps the
  `pr-<verb>` naming and the "operate on a GitHub PR" scope.
- `review-tools`' existing skills both take a code/prose diff as input.
  `comments-cleanup` takes the same input and, like them, judges what should
  survive. It breaks the `cross-` prefix, which marks the two-reviewer technique
  rather than the plugin's scope.
- Both `plugin.json` and `.claude-plugin/marketplace.json` descriptions
  enumerate the plugin's skills, so both need updating for both plugins.
- No new plugin: the user asked for placement in an existing plugin.

## Skill 1: `pr-tools:pr-rewrite`

Target: the PR for the current branch when no argument is given. Accepts
explicit PR numbers, including several at once — reviewing a whole stack in one
pass (`pr-1` … `pr-5`) was a real request. When the branch has no PR yet, the
skill produces the title and body and asks whether to create the PR; it never
runs `gh pr create` unprompted.

### Steps

1. **Derive the repo's convention** — in priority order:
   `.github/pull_request_template.md` → `CONTRIBUTING.md` → the repo's
   `CLAUDE.md` / `AGENTS.md` →
   `gh pr list --state merged --limit 15 --json title,body` to infer title
   format, body language, and section habits. Report the derived convention in
   one line before applying it.
2. **Title** — one core change only. No decorative tags, qualifiers, or
   parenthetical filler. A trailing `(...)` is reserved for the issue ID.
   **"Concise" never means dropping the issue ID or the `prefix(scope):` form**
   — that misreading has already happened.
3. **Body skeleton: Why / What / How.** These three are the default and are
   sufficient for most PRs.
4. **Additional sections are allowed only when they carry information the reader
   cannot get elsewhere.**
   - Allowed in practice: `## スタック（PR シリーズ）` (owned by `pr-stack`),
     screenshots or video for UI changes, sections the repo's PR template
     requires, verification steps the reviewer must run themselves.
   - Still forbidden: file-by-file change listings, change-volume tables, diff
     restatement, local-only paths (`docs/superpowers/specs/...`), plan/spec
     narration, self-congratulation, prose paragraphs.
   - Test: _"if this section were missing, what would the reviewer get wrong?"_
5. **Length** — the Why / What / How sections total **20 rendered lines or
   fewer**, headings excluded, each section 1–4 bullets. Screenshots, the stack
   section, and template-required sections do not count toward the cap.
6. **Self-check before applying** — for every line: _"if this line were missing,
   what would the reviewer get wrong?"_ No concrete answer → delete it.
7. **Apply** via `gh pr edit`. **Preserve the `## スタック（PR シリーズ）`
   section verbatim** — `pr-stack` owns it.

### Draft frontmatter description

> Write or rewrite a GitHub pull request title and body so it is short,
> structured, and matched to the repository's own convention — Why / What / How
> as the default skeleton, extra sections only when they carry information the
> reader cannot get elsewhere, and never a restatement of the diff. Use when the
> user asks to write, shorten, tidy, or restructure a PR title or body, or says
> the PR is too long, too verbose, or not following convention. Trigger phrases:
> "PR 본문 간결하게", "pr 제목 너무 길어", "본문 정리해줘", "구조적으로", "소설
> 쓰지 마", "diff 내용 옮기지 마", "repo 관습에 맞춰서", "make the PR body
> concise", "shorten this PR description".

## Skill 2: `review-tools:comments-cleanup`

### Scope — ask first

On invocation, ask the user which scope applies:

- **Comments inside the change only** — comments on lines this branch added or
  modified.
- **All comments in the changed files** — full sweep of every file the change
  touches.

Never widen beyond the changed files.

### Survival test (single rule)

> **If this comment were gone, what specific wrong change would somebody make?**

If a concrete answer cannot be written, delete the comment.

### Delete (ordered by observed frequency)

1. Restates the code, or restates the line directly next to it.
2. Tutorial-style rationale — two sentences or more of explanation.
3. Change-history commentary (`// removed the old logic`, `// changed from X`).
4. Section-divider decoration.
5. Obvious type/name annotations; commented-out code.
6. Anything already stated in `README`, `AGENTS.md`, or a spec.

### Keep

- Temporary code whose removal condition is stated **with a precise trigger** —
  "someday" does not qualify.
- The reason for genuinely non-obvious behaviour — **one line**.
- A one-line reason per exception or per `false` entry in a config list.
- Cross-file mapping pointers (jsdoc or inline).
- Machine-read markers such as `[start]` / `[end]`.

### Language

Match the language of the file's existing comments; default to English when
there is no established one. Never mix languages inside a comment
(`# 등록に必要な権限` was a real defect).

### Report

Per file, `N → M` comment lines only. Do not reprint the deleted comments — that
output is itself the verbosity being removed.

### Draft frontmatter description

> Remove unnecessary comments from a code change — restated code,
> tutorial-length rationale, change-history notes, decorative dividers,
> commented-out code — keeping only comments whose absence would cause a
> specific wrong change. Asks first whether to clean only the changed lines or
> every comment in the changed files. Use when the user asks to tidy, prune, or
> delete unnecessary, verbose, or redundant comments. Trigger phrases: "불필요한
> 주석 정리", "주석 지워", "주석이 너무 verbose", "인라인 주석 정리해줘", "모든
> 수정에 주석 달지 마", "clean up unnecessary comments", "too many inline
> comments".

## Rejected alternatives

| Alternative                               | Why rejected                                                                                                                     |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| One-line pointer in `~/.claude/CLAUDE.md` | Would fix cause 1, but the user chose manual invocation and wants everything inside this marketplace.                            |
| `PreToolUse` hook on `gh pr create`       | Most deterministic, but adds `settings.json` maintenance outside this repo, and the comment side cannot be hooked sensibly.      |
| One combined skill                        | The two instructions co-occurred only 3 times; comments alone 45–50, PR alone ~35. Combining loads PR rules during comment work. |
| Three skills (title / body / comments)    | Title and body are nearly always corrected in the same breath.                                                                   |
| New plugin for the comment skill          | The user asked for an existing plugin.                                                                                           |
| Enumerated allowlist of body sections     | Rejected during review — stack sections and screenshots are legitimate. Replaced by a necessity test.                            |

## Out of scope

- Commit message rules — `.claude/skills/commit` already covers them.
- Changing `common:create-pr`; it lives in another marketplace.
- Any edit to `~/.claude/CLAUDE.md`, `settings.json`, or project memory files.

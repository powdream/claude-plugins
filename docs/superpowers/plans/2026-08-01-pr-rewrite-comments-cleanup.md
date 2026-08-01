# pr-rewrite & comments-cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two explicitly-invoked skills — `review-tools:comments-cleanup`
and `pr-tools:pr-rewrite` — that encode instructions the user has repeated ~80
times across three projects.

**Architecture:** Each skill is a single `SKILL.md` under an existing plugin. No
scripts, no shared reference files: both skills are short enough to live
entirely in Level 2 content. Each plugin's skill list is enumerated in three
places (`plugin.json`, `.claude-plugin/marketplace.json`, `README.md`), so every
task updates all three for its plugin.

**Tech Stack:** Markdown with YAML frontmatter; `gh` CLI; `git`; `python3` for
validation.

**Spec:**
`docs/superpowers/specs/2026-08-01-pr-rewrite-comments-cleanup-design.md`

## Global Constraints

- SKILL.md prose is **English** (`AGENTS.md`: "All documentation must be written
  in English"). Korean/Japanese appears only in: the frontmatter `description`
  trigger phrases, embedded output templates, and a quoted defect specimen whose
  point depends on the non-English text (`# 등록に必要な権限`, illustrating a
  mixed-language comment). Ruled by the human partner on 2026-08-01.
- Skill `name`: lowercase letters, numbers, hyphens only; max 64 chars; must not
  contain `claude` or `anthropic`.
- Skill `description`: non-empty, max 1024 chars, **one single line** (no YAML
  folding), stating what it does AND when to use it.
- Version bumps are **minor** (new skill, additive): `pr-tools` 0.2.0 → 0.3.0,
  `review-tools` 0.2.0 → 0.3.0.
- Commit messages: conventional-commit prefix, lowercase after the colon,
  English, no co-author trailer, no AI mention.
- **Nothing outside this repository is edited** — not `~/.claude/CLAUDE.md`, not
  `settings.json`, not project memory files.
- Do not modify `pr-stack`, `pr-chrome`, `cross-doc-review`, or
  `cross-code-review`.

---

### Task 1: `review-tools:comments-cleanup`

**Files:**

- Create: `plugins/review-tools/skills/comments-cleanup/SKILL.md`
- Modify: `plugins/review-tools/.claude-plugin/plugin.json` (version +
  description)
- Modify: `.claude-plugin/marketplace.json` (review-tools description)
- Modify: `README.md` (add a `### review-tools` section — currently missing
  entirely)

**Interfaces:**

- Consumes: nothing from other tasks.
- Produces: the skill name `comments-cleanup`, referenced by README and by the
  marketplace/plugin descriptions. Task 3 verifies it loads.

- [ ] **Step 1: Create the skill file**

Create `plugins/review-tools/skills/comments-cleanup/SKILL.md` with exactly this
content:

````markdown
---
name: comments-cleanup
description: Remove unnecessary comments from a code change — restated code, tutorial-length rationale, change-history notes, decorative dividers, commented-out code — keeping only comments whose absence would cause a specific wrong change. Asks first whether to clean only the changed lines or every comment in the changed files. Use when the user asks to tidy, prune, or delete unnecessary, verbose, or redundant comments, or says the comments are too many or too verbose. Trigger phrases: "불필요한 주석 정리", "주석 지워", "주석이 너무 verbose", "인라인 주석 정리해줘", "모든 수정에 주석 달지 마", "clean up unnecessary comments", "too many inline comments".
argument-hint: '[path ...]'
---

# Comments Cleanup

Strips comments that carry no decision-changing information out of a change, and
compresses the ones that survive.

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

Take the union of:

```bash
git diff --name-only HEAD                   # staged + unstaged
git diff --name-only <base>...HEAD          # committed on this branch
git ls-files --others --exclude-standard    # new files, not yet tracked
```

Then use **AskUserQuestion** to pick one:

- **Changed lines only** — comments on lines this change added or modified.
- **Whole changed files** — every comment in those files.

Never widen beyond the changed files. Never touch a file the change did not
already modify, unless a path argument named it.

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
````

- [ ] **Step 2: Validate the frontmatter**

Run:

```bash
python3 - <<'PY'
import re, pathlib, sys
p = pathlib.Path("plugins/review-tools/skills/comments-cleanup/SKILL.md")
t = p.read_text(encoding="utf-8")
m = re.match(r"^---\n(.*?)\n---\n", t, re.S)
assert m, "missing frontmatter"
fm = m.group(1)
name = re.search(r"^name: (.+)$", fm, re.M).group(1).strip()
desc = re.search(r"^description: (.+)$", fm, re.M).group(1).strip()
assert name == "comments-cleanup", name
assert re.fullmatch(r"[a-z0-9-]{1,64}", name), name
assert "claude" not in name and "anthropic" not in name
assert 0 < len(desc) <= 1024, len(desc)
print(f"OK name={name} desc_len={len(desc)}")
PY
```

Expected: `OK name=comments-cleanup desc_len=<n>` with `n` at or under 1024.

- [ ] **Step 3: Bump the plugin version and description**

Edit `plugins/review-tools/.claude-plugin/plugin.json` to exactly:

```json
{
  "name": "review-tools",
  "description": "Review helpers. cross-doc-review and cross-code-review review an artifact with two independent reviewer agents that check each other, adjudicating any single-reviewer finding before it is adopted so no one reviewer's blind spot or overreach slips through. comments-cleanup strips comments that carry no decision-changing information out of a code change.",
  "version": "0.3.0"
}
```

- [ ] **Step 4: Update the marketplace description**

In `.claude-plugin/marketplace.json`, replace the `review-tools` entry's
`description` value with:

```
Review helpers: cross-doc-review and cross-code-review review an artifact with two independent reviewer agents which check each other and adjudicate any single-reviewer finding before it is adopted; comments-cleanup strips comments that carry no decision-changing information out of a code change
```

Leave `name` and `source` untouched.

- [ ] **Step 5: Add the review-tools section to README**

`README.md` currently has no `review-tools` section at all. Insert this block
after the `### pr-tools` block and before `### session-tools`:

````markdown
### review-tools

Review helpers:

- **cross-code-review** (skill): reviews a code change with two independent
  reviewer agents that check each other; a finding only one of them raises must
  survive the other's attempt to refute it before it is reported.
- **cross-doc-review** (skill): the same cross-check for prose artifacts —
  specs, ADRs, PRDs, READMEs, runbooks.
- **comments-cleanup** (skill): removes comments that carry no decision-changing
  information from a change, keeping only those whose absence would let someone
  make a specific wrong change.

```bash
/plugin install review-tools@claude-plugins
```
````

- [ ] **Step 6: Validate JSON and confirm the files line up**

Run:

```bash
python3 - <<'PY'
import json
mk = json.load(open(".claude-plugin/marketplace.json"))
pl = json.load(open("plugins/review-tools/.claude-plugin/plugin.json"))
entry = next(p for p in mk["plugins"] if p["name"] == "review-tools")
assert pl["version"] == "0.3.0", pl["version"]
assert "comments-cleanup" in pl["description"]
assert "comments-cleanup" in entry["description"]
assert entry["source"] == "./plugins/review-tools"
print("OK", pl["version"])
PY
grep -c "review-tools" README.md
```

Expected: `OK 0.3.0`, and the `grep -c` count is at least 2.

- [ ] **Step 7: Commit**

```bash
git add plugins/review-tools/skills/comments-cleanup/SKILL.md \
        plugins/review-tools/.claude-plugin/plugin.json \
        .claude-plugin/marketplace.json README.md
git commit -m "feat(review-tools): add comments-cleanup skill and bump to 0.3.0"
```

---

### Task 2: `pr-tools:pr-rewrite`

**Files:**

- Create: `plugins/pr-tools/skills/pr-rewrite/SKILL.md`
- Modify: `plugins/pr-tools/.claude-plugin/plugin.json` (version + description)
- Modify: `.claude-plugin/marketplace.json` (pr-tools description)
- Modify: `README.md` (expand the `### pr-tools` section into a skill list)

**Interfaces:**

- Consumes: `README.md` and `.claude-plugin/marketplace.json` as edited by Task
  1 — edit different regions of the same files, so rebase on Task 1's commit
  rather than branching from before it.
- Produces: the skill name `pr-rewrite`. Its step 6 must not disturb the
  `## スタック（PR シリーズ）` section owned by `pr-stack`.

- [ ] **Step 1: Create the skill file**

Create `plugins/pr-tools/skills/pr-rewrite/SKILL.md` with exactly this content:

````markdown
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
````

- [ ] **Step 2: Validate the frontmatter**

Run:

```bash
python3 - <<'PY'
import re, pathlib
p = pathlib.Path("plugins/pr-tools/skills/pr-rewrite/SKILL.md")
t = p.read_text(encoding="utf-8")
m = re.match(r"^---\n(.*?)\n---\n", t, re.S)
assert m, "missing frontmatter"
fm = m.group(1)
name = re.search(r"^name: (.+)$", fm, re.M).group(1).strip()
desc = re.search(r"^description: (.+)$", fm, re.M).group(1).strip()
assert name == "pr-rewrite", name
assert re.fullmatch(r"[a-z0-9-]{1,64}", name), name
assert "claude" not in name and "anthropic" not in name
assert 0 < len(desc) <= 1024, len(desc)
print(f"OK name={name} desc_len={len(desc)}")
PY
```

Expected: `OK name=pr-rewrite desc_len=<n>` with `n` at or under 1024.

- [ ] **Step 3: Bump the plugin version and description**

Edit `plugins/pr-tools/.claude-plugin/plugin.json` to exactly:

```json
{
  "name": "pr-tools",
  "description": "GitHub pull request helpers: rewrite a PR title and body into a short, convention-matched Why/What/How, maintain a stacked-PR series section across a chain of PRs, and open a PR in Google Chrome",
  "version": "0.3.0"
}
```

- [ ] **Step 4: Update the marketplace description**

In `.claude-plugin/marketplace.json`, replace the `pr-tools` entry's
`description` value with:

```
GitHub pull request helpers: rewrite a PR title and body into a short, convention-matched Why/What/How, maintain a stacked-PR series section across a chain of PRs, and open a PR in Google Chrome
```

Leave `name` and `source` untouched.

- [ ] **Step 5: Expand the pr-tools README section**

Replace the current `### pr-tools` block in `README.md` (the two prose lines and
the install fence) with:

````markdown
### pr-tools

GitHub pull request helpers:

- **pr-rewrite** (skill): rewrites a PR title and body down to the shortest form
  a reviewer can still decide from — Why / What / How, matched to the repo's own
  title and body convention, with extra sections only when they carry
  information the reader cannot get elsewhere.
- **pr-stack** (skill): maintains the `## スタック（PR シリーズ）` section
  across a chain of stacked PRs, carrying merged ancestors forward and
  preserving the rest of each body.
- **pr-chrome** (skill): opens a PR in Google Chrome.

```bash
/plugin install pr-tools@claude-plugins
```
````

- [ ] **Step 6: Validate JSON and confirm the files line up**

Run:

```bash
python3 - <<'PY'
import json
mk = json.load(open(".claude-plugin/marketplace.json"))
pl = json.load(open("plugins/pr-tools/.claude-plugin/plugin.json"))
entry = next(p for p in mk["plugins"] if p["name"] == "pr-tools")
assert pl["version"] == "0.3.0", pl["version"]
assert pl["description"] == entry["description"], "plugin.json and marketplace.json disagree"
assert "rewrite" in pl["description"]
print("OK", pl["version"])
PY
grep -c "pr-rewrite" README.md
```

Expected: `OK 0.3.0` and a `grep -c` count of 1.

- [ ] **Step 7: Commit**

```bash
git add plugins/pr-tools/skills/pr-rewrite/SKILL.md \
        plugins/pr-tools/.claude-plugin/plugin.json \
        .claude-plugin/marketplace.json README.md
git commit -m "feat(pr-tools): add pr-rewrite skill and bump to 0.3.0"
```

---

### Task 3: Load verification

**Files:**

- Modify: none (verification only; fix-ups land in Tasks 1–2 if something fails)

**Interfaces:**

- Consumes: both skills from Tasks 1 and 2.
- Produces: nothing consumed downstream.

- [ ] **Step 1: Verify every SKILL.md in the repo still parses**

Run:

A plain `^description: (.+)$` would capture `>-` for a folded description and
measure it as 2 characters, so block scalars are joined before measuring:

```bash
python3 - <<'PY'
import re, pathlib

def field(fm, key):
    """Frontmatter scalar, with YAML block scalars (>, >-, |, |-) joined."""
    lines = fm.split("\n")
    for i, line in enumerate(lines):
        m = re.match(rf"^{key}:\s*(.*)$", line)
        if not m:
            continue
        val = m.group(1).strip()
        if not re.fullmatch(r"[>|][+-]?", val):
            return val.strip("\"'")
        sep = " " if val[0] == ">" else "\n"
        cont = []
        for nxt in lines[i + 1:]:
            if nxt.strip() and not nxt.startswith((" ", "\t")):
                break
            cont.append(nxt.strip())
        return sep.join(c for c in cont if c)
    return None

bad = []
for p in sorted(pathlib.Path("plugins").rglob("SKILL.md")):
    t = p.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---\n", t, re.S)
    if not m:
        bad.append((p, "no frontmatter")); continue
    name, desc = field(m.group(1), "name"), field(m.group(1), "description")
    if not name or not desc:
        bad.append((p, "missing name/description")); continue
    if not re.fullmatch(r"[a-z0-9-]{1,64}", name):
        bad.append((p, f"bad name {name!r}"))
    if name != p.parent.name:
        bad.append((p, f"name {name!r} != dir {p.parent.name!r}"))
    if len(desc) > 1024:
        bad.append((p, f"description {len(desc)} chars"))
    print(f"  {name}: description {len(desc)} chars")
print("FAIL" if bad else "OK", *bad, sep="\n")
PY
```

Expected: one `<name>: description <n> chars` line per skill, every `n` at or
under 1024 and none of them 2, then `OK` on its own line.

- [ ] **Step 2: Verify every plugin is registered and versioned**

A marketplace entry's `source` is either a path string (the plugin lives in this
repo and must have a directory under `plugins/`) or an object (the plugin is
fetched from elsewhere and must **not** have one). Check each form against its
own rule:

```bash
python3 - <<'PY'
import json, pathlib
mk = json.load(open(".claude-plugin/marketplace.json"))
listed = {p["name"] for p in mk["plugins"]}
on_disk = {d.name for d in pathlib.Path("plugins").iterdir() if d.is_dir()}
assert on_disk <= listed, f"on disk but unregistered: {on_disk - listed}"
for p in mk["plugins"]:
    src = p["source"]
    if not isinstance(src, str):
        assert p["name"] not in on_disk, f"remote entry has a local dir: {p['name']}"
        print(f"remote: {p['name']} <- {src['source']}:{src['repo']}")
        continue
    assert src == f"./plugins/{p['name']}", src
    assert p["name"] in on_disk, f"path-sourced but no directory: {p['name']}"
    pj = json.load(open(f"plugins/{p['name']}/.claude-plugin/plugin.json"))
    assert pj["name"] == p["name"]
    assert pj["version"].count(".") == 2, pj["version"]
print("OK", len(on_disk), "plugins on disk")
PY
```

Expected: `remote: invoke-agent <- github:powdream/invoke-agent` followed by
`OK 7 plugins on disk`.

`invoke-agent` is sourced from
`{"source": "github", "repo":
"powdream/invoke-agent"}`, so having no directory
under `plugins/` is correct for it, not a defect.

- [ ] **Step 3: Install locally and confirm both skills appear**

In a Claude Code session at the repo root:

```
/plugin marketplace add ./
/plugin install review-tools@claude-plugins
/plugin install pr-tools@claude-plugins
/reload-skills
```

Then confirm `review-tools:comments-cleanup` and `pr-tools:pr-rewrite` are both
listed in the available skills. If either is missing, its frontmatter or its
directory name is wrong — fix in Task 1 or Task 2 and re-run.

- [ ] **Step 4: Smoke-test `comments-cleanup`**

Invoke `/review-tools:comments-cleanup` in a repo with an in-progress change.
Confirm it:

- asks the scope question (changed lines only / whole changed files) **before**
  editing anything,
- edits only files already in the change,
- reports `N → M` per file and does **not** reprint deleted comments.

- [ ] **Step 5: Smoke-test `pr-rewrite`**

Invoke `/pr-tools:pr-rewrite` on a branch with an open PR that has a
`## スタック（PR シリーズ）` section. Confirm it:

- prints the derived convention in one line before writing,
- keeps the issue ID and prefix in the title,
- emits Why / What / How within 20 lines,
- leaves the stack section byte-identical.

Verify the stack section survived:

```bash
gh pr view <N> --json body -q .body | sed -n '/## スタック/,/^$/p'
```

- [ ] **Step 6: Commit any fix-ups**

If Steps 3–5 required changes, commit them:

```bash
git add -A
git commit -m "fix: correct skill metadata found in load verification"
```

If nothing changed, skip this step.

---
name: pr-stack
description: Maintain the "## スタック（PR シリーズ）" section across a stacked PR chain on GitHub. Use when adding a PR to a stack or refreshing the stack list — discovers the open base→tip chain, carries the merged ancestors and their descriptions forward, and patches every open PR body consistently (strikethrough for merged PRs, `(this)` per PR), preserving the rest of each body. Trigger phrases: "PR 스택 시리즈", "스택 본문 업데이트", "add this PR to the stack series".
argument-hint: '[PR番号] [日本語の説明]'
---

# PR Stack Series

Keeps the **`## スタック（PR シリーズ）`** section in sync across a chain of
stacked PRs. The bundled `apply_stack.py` does the deterministic work:
discovering the chain, preserving the rest of each body (no clobbering pasted
images), carrying merged history forward, and placing the `(this)` marker per
PR.

The section it maintains looks like:

```
## スタック（PR シリーズ）

`(this)` が本 PR。左がベース（先にマージ）。

~~#71~~ → ~~#83~~ → #90 (this) → #94

- ~~#71~~ 短い説明 (TICKET-xxxx)
- ~~#83~~ 短い説明 (TICKET-xxxx)
- #90 短い説明 (TICKET-xxxx)
- #94 短い説明 (TICKET-xxxx)
```

`~~#N~~` = merged, plain `#N` = open, `(this)` marks the PR whose body you read.

## How the stack chain is discovered (the foundation)

The chain has two parts, found two different ways. **Always verify both before
writing** — the script prints them.

**1. The open chain — auto-discovered from branch relationships.** Stacked PRs
link by branch: each PR's `base` branch IS the `head` branch of the PR below it.
Among the open PRs:

- Build a `head branch → PR` map.
- From the target PR, walk **down**: while this PR's `base` is some open PR's
  `head`, step to that PR (its parent). Stop when `base` is `master`/`main` (or
  any branch with no open PR) — that is the bottom of the open chain.
- Walk **up**: while some open PR's `base` equals this PR's `head`, step to that
  PR (its child). Stop at the tip.
- Order base → tip.

(Linear stacks resolve cleanly. At a branch point the script takes the first
child — eyeball the printed chain.)

**2. Merged ancestors — carried forward from the existing section.** When a PR
merges, GitHub retargets its children onto `master`, so the merged PR drops out
of the base/head chain and **cannot be auto-discovered**. The script recovers
the merged ancestors (and every PR's description) by parsing the `## スタック`
bullets already in a stack PR's body. The curated list is therefore the source
of truth for history; re-running is idempotent.

**The script prints the split so you can check it:**

```
open chain (base→tip, auto-discovered): #2082 → #2080 → #2085
merged ancestors (carried forward from section): #2071, #2083, #2078
full stack: ~~#2071~~ → ~~#2083~~ → ~~#2078~~ → #2082 → #2080 → #2085
```

If the open chain or merged set is wrong, fix the input (or the existing
section) before applying — do not push a wrong chain.

## Arguments

`/pr-stack [PR番号] [日本語の説明]` — both optional:

- **PR番号** — the PR to anchor on (any open PR in the stack; usually the new
  tip). Omitted ⇒ the current branch's PR
  (`gh pr view --json number -q .number`).
- **日本語の説明** — bullet text for a newly added PR, style
  `<短い説明> (<ISSUE-ID>)`. Omitted ⇒ derive a concise one from the PR
  title / issue (confirm if unsure). Already-listed PRs ignore this; their
  text is carried forward.

Examples: `/pr-stack` · `/pr-stack 機能の概要 (TICKET-123)` ·
`/pr-stack 2085 機能の概要 (TICKET-123)`.

## Steps

1. Run from inside the repo (or pass `--repo owner/name`).
2. Resolve the target PR from the argument, else the current branch's PR
   (`gh pr view --json number -q .number`).
3. For a **new** PR not yet in the section, take the Japanese description from
   the argument (or derive `<短い説明> (<ISSUE-ID>)` from the title/issue) and
   pass it via `--desc`. PRs already in the section need no flag — their
   description and merged/open status are derived automatically.
4. **Dry-run, read the printed chain split + bodies, then apply.**
   `apply_stack.py` sits next to this `SKILL.md`. Resolve this skill's directory
   (the folder containing this `SKILL.md`) and run the script from there:
   ```bash
   python3 <skill-dir>/apply_stack.py \
     --pr <NUMBER> --desc "<NUMBER>=<短い説明> (<ISSUE-ID>)" --dry-run
   # chain + bodies look right ↓
   python3 <skill-dir>/apply_stack.py \
     --pr <NUMBER> --desc "<NUMBER>=<短い説明> (<ISSUE-ID>)"
   ```
5. Verify one PR's chain line: `gh pr view <N> --json body -q .body`.

## Notes

- GitHub body content here is **Japanese** — keep descriptions Japanese.
- Only open PRs are patched; merged ones are left alone (just shown struck).
- **Bootstrapping** (no section yet, ancestors already merged): the walk only
  finds the open chain, so list merged ancestors by hand via `--desc` the first
  time; they persist afterward.
- The script inserts the section before a trailing `---` footer when present,
  else appends it. It replaces only the section, never the rest of the body.
- `--repo` is optional inside the repo; `gh` infers it.

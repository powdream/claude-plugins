---
name: cross-code-review
description: >-
  Cross-review a code change with two independent, strong reviewer agents that
  check each other, and adversarially verify any single-reviewer finding before
  adopting it. The two reviewers are codex (via the codex CLI) and opus (via the
  Agent tool); a finding only one of them raises is sent to the other reviewer,
  which tries to refute it before it counts. Use this whenever the user asks to
  review, cross-review, or get a second / independent opinion on a diff, pull
  request, branch, commit, or set of changed files — for correctness, edge
  cases, security, error handling, tests, or conventions — especially when they
  mention "two agents", "cross review", codex, or want findings verified or
  refuted before they are accepted. Prefer this over a single-agent code review
  whenever review quality matters or a lone reviewer's false positive / false
  negative would be costly.
---

# Cross-code review (two agents, cross-checked)

Review a code change with **two independent strong reviewers** and only accept a
finding after it survives an adversarial cross-check. A single reviewer misses
real bugs (blind spots) and raises confident false positives (overreach). Two
strong reviewers of different provenance cover more, and making each one try to
*refute* the other's solo findings kills plausible-but-wrong claims before they
reach the user.

## Roster (default — models are swappable, the roles are not)

- **Reviewer A — codex**, run through the `codex` CLI. A different vendor/engine,
  strong at reading a repository directly.
- **Reviewer B — opus**, run through the Agent tool with `model: "opus"`.

Both reviewers are strong, so verification is **symmetric**: a codex-only finding
is verified by opus, and an opus-only finding is verified by codex. There is no
lighter third model — with two strong reviewers, the peer is the right judge.
(This differs from `cross-doc-review`, where the weaker reviewer's solo findings
go to a stronger third model. Keep the shape you need: two first-pass reviewers,
and each solo finding adjudicated by an independent reviewer of at least equal
strength.)

## Inputs

1. **Change under review**: a diff scope the reviewers can reconstruct —
   `git diff <base>...<head>`, a PR number, a commit range, or an explicit list
   of changed files. Prefer a diff over "the whole repo" so review stays focused.
2. **Criteria (the review lens)**: default to `references/code-review-criteria.md`.
   If the project has its own review checklist or conventions doc, use it (and
   hand it to both reviewers) — the orchestration below is unchanged.

Confirm the diff scope and criteria if either is ambiguous. Otherwise proceed.

## Workflow

### 1. Run both reviewers in parallel (same turn, same change, same criteria)

Launch A and B in the **same turn** so neither sees the other's output. Give both
the identical diff scope and criteria, and ask for the identical shape: findings
as a list, each with `file:line`, a severity, a concrete failure scenario
(inputs/state → wrong result), and a suggested fix.

**Reviewer A (codex).** codex needs to read the repository and reach its model,
so run it from the repo root with the sandbox disabled (on the Bash tool, set
`dangerouslyDisableSandbox: true`). Have codex **write its result to a file** and
read that file — its stdout carries hook/log noise, so a file it wrote is far
cleaner than scraping stdout. Redirect stdin from `/dev/null` or codex hangs.

```bash
(cd <REPO_ROOT> && codex exec --dangerously-bypass-approvals-and-sandbox \
  "Review the change (<DIFF_SCOPE>, e.g. git diff <base>...<head>) against the
   criteria below. For each finding give file:line, severity, a concrete failure
   scenario (inputs/state -> wrong output/crash), and a fix. You may run git and
   read files. WRITE your final result to <ABS_OUT_PATH> and nothing else to
   stdout.
   Criteria:
   <criteria text>" < /dev/null)
```

Then `Read` `<ABS_OUT_PATH>`.

**Reviewer B (opus).** Spawn an Agent with `model: "opus"`. Give it the diff
scope and criteria, tell it to inspect the change (it can use git / Read / Grep),
return findings in the same shape as its final message, and **not** edit code
(read-only review). Its final message is the result.

### 2. Classify every finding

Match findings by the underlying defect, not by wording, and sort into:

- **both** — raised by codex and opus.
- **codex-only**.
- **opus-only**.

### 3. Adversarially verify the single-reviewer findings

- **both** → confirmed. Adopt.
- **codex-only** → send to **opus** to verify.
- **opus-only** → send to **codex** to verify.

Give the verifier only the solo findings plus the change, and ask it to **try to
refute** each one: does the failure actually reproduce, is the code path
reachable, does the fix change behavior? Return `[confirmed / plausible /
refuted]` with a one- or two-sentence reason. Default to refuted when the
verifier cannot construct the failure — a finding that cannot be made to fail is
not worth the user's time.

Adopt a solo finding only if it comes back confirmed or plausible. Record refuted
findings with the reason — a killed false positive is a result too.

### 4. Consolidate and report

Present a single verdict, most-severe first:

```
Confirmed (both) — adopted:
- <file:line> <defect> — <failure scenario>

Single-reviewer, verified:
| source | finding | verifier verdict | outcome |
|---|---|---|---|
| codex | <file:line> …  | opus: refuted   | not adopted (reason) |
| opus  | <file:line> …  | codex: confirmed| adopted |
```

Then either apply the adopted fixes or hand the list back, per what the user
asked. If you apply fixes, say which findings you rejected and why, so the user
can overrule.

## Notes

- **Cost.** This spends two models (codex, opus) plus your own passes and the
  verification round. Worth it for a change that matters; for a quick glance a
  single reviewer is enough — say so rather than spending the full panel.
- **Independence.** Never show one reviewer the other's output before step 3.
  Their disagreement is the signal; contaminating them collapses it.
- **Adversarial by default.** For code, verification means *trying to break the
  claim*, not re-stating it. A finding that survives a genuine refutation attempt
  is worth acting on; one that does not, is not.
- **The verifier is not an editor.** Verifiers judge; they do not rewrite code.
  You own the edits after adoption.

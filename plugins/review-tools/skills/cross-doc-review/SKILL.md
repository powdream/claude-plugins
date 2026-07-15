---
name: cross-doc-review
description: >-
  Cross-review a document or written artifact for quality using two independent
  reviewer agents that check each other, then adjudicate any single-reviewer
  finding before adopting it. The two reviewers are codex (via the codex CLI)
  and fable (via the Agent tool); findings only one of them raises are
  cross-verified — fable-only by codex, codex-only by a stronger third model
  (opus) rather than by fable. Use this whenever the user asks to review,
  cross-review, or get a second / independent opinion on a doc, spec, ADR, PDD,
  PRD, RFC, README, runbook, or any prose artifact for readability, structure,
  terminology, or duplication — especially when they mention "two agents",
  "cross review", codex, fable, or want single-reviewer findings verified before
  they are accepted. Prefer this over a single-agent review whenever review
  quality or reducing one reviewer's bias matters.
---

# Cross-document review (two agents, cross-checked)

Review a document with **two independent reviewers** and only accept a finding
after it survives cross-checking. One reviewer alone is easy to over-trust: it
has blind spots (misses real problems) and it overreaches (flags non-problems
with confident prose). Two reviewers of different provenance cover more, and
routing each single-reviewer finding to a *different* verifier means a lone
claim is judged by a fresh perspective instead of being rubber-stamped by an
equally fallible peer.

## Roster (default — models are swappable, the roles are not)

- **Reviewer A — codex**, run through the `codex` CLI. A different vendor/engine
  from the Claude side, so its blind spots differ.
- **Reviewer B — fable**, run through the Agent tool with `model: "fable"`.
- **Adjudicator — opus**, run through the Agent tool with `model: "opus"`. Used
  *only* to judge codex's solo findings. It does not do a first-pass review.

The asymmetry is deliberate: codex's solo findings go to opus, **not** to fable.
codex is the outside engine and tends to be the most aggressive reviewer, so its
un-corroborated claims are adjudicated by the strongest independent judge rather
than by the lighter peer. fable's solo findings go to codex (the ordinary mutual
cross-check). If you swap models, keep this shape: two first-pass reviewers, and
a stronger third model that adjudicates the CLI reviewer's solo findings.

## Inputs

1. **Target**: the path to the document to review.
2. **Criteria (the review lens)**: what to check for. Default to
   `references/document-quality-criteria.md` (a reader-perspective checklist for
   prose quality). If the user gives their own criteria, or the artifact is not
   prose (code, config, a design), use theirs instead — the orchestration below
   is unchanged.

Confirm the target and criteria with the user if either is ambiguous. Otherwise
proceed.

## Workflow

### 1. Run both reviewers in parallel (same turn, same criteria)

Launch A and B in the **same turn** so they finish together and neither sees the
other's output. Give both the identical criteria and ask for the identical
output shape: a per-criterion `[pass / issue]` verdict with evidence and a
concrete fix, then a severity-ordered findings list where each finding is tagged
`F1`, `F2`, …

**Reviewer A (codex).** codex needs network/model access, so run it with the
sandbox disabled (on the Bash tool, set `dangerouslyDisableSandbox: true`). Have
codex **write its result to a file** and then read that file — codex's stdout is
full of hook/log noise, so parsing a file it wrote is far cleaner than scraping
stdout. Redirect stdin from `/dev/null` or codex hangs waiting for input.

```bash
codex exec --dangerously-bypass-approvals-and-sandbox \
  "Read the document at <ABS_PATH> and review it from a reader / document-quality
   perspective (NOT correctness of the underlying subject). For each criterion
   below, give [pass/issue] + evidence (section, quote) + a concrete fix.
   End with a severity-ordered list, each item tagged F1, F2, ...
   WRITE your final result to <ABS_OUT_PATH> and nothing else to stdout.
   Criteria:
   <criteria text>" < /dev/null
```

Then `Read` `<ABS_OUT_PATH>`.

**Reviewer B (fable).** Spawn an Agent with `model: "fable"`. Tell it to `Read`
the document, apply the same criteria, return the same shape as its final
message, and **not** edit the file (read-only review). Its final message is the
result.

### 2. Classify every finding

Match findings by the underlying issue, not by wording, and sort into:

- **both** — raised by codex and fable.
- **codex-only**.
- **fable-only**.

### 3. Cross-verify the single-reviewer findings

- **both** → confirmed. Adopt.
- **fable-only** → send to **codex** for an independent verdict.
- **codex-only** → send to **opus** (Agent, `model: "opus"`), **not** to fable.

Give each verifier only the solo findings plus the document, and ask for an
independent `[valid / partial / reject]` per finding with a one- or two-sentence
reason and a concrete fix when valid. Tell it not to take sides. When a verdict
depends on a house rule (e.g. a template's section order), give the verifier
that reference so it can judge against the standard, not its taste.

Adopt a solo finding only if its verifier returns valid or partial. Record
rejects with the verifier's reason — a rejected finding is a result too.

### 4. Consolidate and report

Present a single verdict, most-impactful first:

```
Confirmed (both) — adopted:
- <finding> …

Single-reviewer, cross-verified:
| source | finding | verifier verdict | outcome |
|---|---|---|---|
| fable  | …        | codex: partial   | adopted (…) |
| codex  | …        | opus: reject     | not adopted (reason) |
```

Then either apply the adopted fixes or hand the list back, per what the user
asked for. If you apply fixes, say which findings you rejected and why, so the
user can overrule.

## Notes

- **Cost.** This spends three models (codex, fable, opus) plus your own passes.
  It is worth it for a document that matters; for a quick sanity read, a single
  reviewer is enough — say so rather than spending the full panel.
- **Independence.** Never show one reviewer another's output before step 3. The
  value is in their disagreement; contaminating them collapses it.
- **The verifier is not an editor.** Verifiers judge; they do not rewrite the
  file. You own the edits after adoption.

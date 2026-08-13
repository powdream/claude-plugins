# write-handoff-prompt — goal-first redesign

## Goal

Change `session-tools:write-handoff-prompt` so a handoff transfers **the goal to
reach**, not **the method to reach it** — leaving the next session to do its own
investigation, analysis, ideation, and brainstorming.

## The problem (observed)

Running the skill today produces a handoff that reads like an implementation
plan: the writing session investigates the codebase, reaches conclusions, and
writes those conclusions down as the work to do. The executor then follows the
writer's thinking instead of doing its own.

Four places in the current `SKILL.md` cause this:

1. **No goal section exists.** The output contract is Title → "don't trust what
   is written" → read list → four buckets → gate → next action. The goal is only
   implied by the one-line title, so nothing anchors the handoff to _what must
   be true when done_.
2. **"Fill every pointer with a real path / URL / branch / commit gathered in
   this session — no placeholders"** and **"enumerate every artifact"** push the
   writer to go investigate while writing.
3. **The `확인된 사실` bucket** is an open invitation to dump investigation
   results, interpretation included.
4. **`다음 단 하나의 액션`** ("the single next action") is, in practice, the
   first implementation step — method prescription by another name.

## Constraint that must survive the change

The skill's other reason to exist is that **pointers are unrecoverable after
compaction** — PR URL, branch, worktree path, Linear issue, spec/plan paths. A
naive fix ("stop investigating, write less") would drop those too and break the
skill.

The line this design draws:

| Carry it                                    | Withhold it                              |
| ------------------------------------------- | ---------------------------------------- |
| Pointers — _where to look_                  | Conclusions — _what the code means_      |
| Goal, constraints, settled decisions        | Method — _what to change, in what order_ |
| Observations with evidence (command+output) | Interpretation of those observations     |
| Hazards that waste the executor's time      | Solution direction                       |

## Design

### 1. Second core principle — "Goal over method"

The skill currently has one core principle ("documents are not ground truth"),
which guards against _staleness bias_. It has no ceiling on _how much_ the
writer should put in. Add a second principle of equal standing:

> **Goal over method.** A handoff carries _what must be true when the work is
> done_, not _how to get there_. The method either (a) already exists in an
> agreed plan document — then the handoff only points at it — or (b) does not
> exist yet, and creating it is the executor's job, through its own
> investigation, analysis, and ideation. A method invented by the writer
> pre-empts that.
>
> While writing a handoff, the writer's job is **to record and to point**, not
> **to investigate and to solve**.

### 2. Mode decision — objective, not judgment

The current skill already branches on "agreed spec/plan exists or not", but the
branch only affects which skill to route to. Promote it to a mode that governs
the whole output contract.

- **`resume` mode** — allowed **only** when a plan file exists at a real path
  and the user agreed to it.
- **`goal` mode** — everything else. A plan that exists only in the writer's
  head, agreed verbally in conversation, or a spec without a plan, is **not**
  resume mode.
- When in doubt, `goal` mode.
- State the decision and its evidence (plan file path, or "none") at the top of
  the handoff.

The objective test closes the obvious escape hatch: a writer who wants to
prescribe method cannot simply declare resume mode.

### 3. Writer discipline while writing

**Allowed — pointer collection (mechanical commands only):** `git rev-parse` /
branch / worktree path, `gh pr view --json url`, checking that a path or file
exists.

**Forbidden — analytical investigation:** reading code to find a cause, grepping
to size an impact radius, comparing alternatives, reviewing design.

Record only what this session already established. Anything unknown goes to
`열린 질문` or is explicitly marked as the executor's to investigate.

### 4. Bucket policy

| Current       | Becomes       | Policy change                                                                                           |
| ------------- | ------------- | ------------------------------------------------------------------------------------------------------- |
| `확정`        | `확정`        | unchanged                                                                                               |
| `확인된 사실` | `관측된 사실` | command or source + verbatim output or quote + timestamp only; interpretation and cause forbidden       |
| `열린 질문`   | `열린 질문`   | unchanged                                                                                               |
| `작성자 추정` | `작성자 경고` | hazards only (generated code, known flaky test, do-not-touch); proposing a solution direction forbidden |

Rationale for keeping the last bucket rather than deleting it: a writer's guess
about the _solution_ anchors the executor's ideation, which is exactly what this
change is meant to prevent — but a writer's knowledge of a _hazard_ saves the
executor from stepping on the same mine. Narrow the bucket to hazards instead of
removing it.

### 5. Output contract — `goal` mode

```
Title / mode decision (evidence: no plan file)
## Goal — what must be true when done (+ why)      [new, leads the document]
## 완료 판정 (done = evidence)                      [new]
## 적혀있는 것을 믿지 말 것                          [kept]
## 반드시 읽을 자료 (pointers unrecoverable after compaction)   [refocused]
## 확정 / 관측된 사실 / 열린 질문 / 작성자 경고
## 제약 (what must not be done — not a method)
## 첫 액션: read the listed material → re-verify current state
   → enter brainstorming. No code before user approval.
```

The current `가드레일 / 검증 게이트` section splits into the two new sections:
what counts as done (`완료 판정`, evidence-based) and what the executor must not
do (`제약`, boundaries). Neither states how to do the work.

### 6. Output contract — `resume` mode

```
Title / mode decision (evidence: plan file path)
## Goal
## Plan pointer + how far it has been executed (with evidence)
   + which numbered plan item is next
## 완료 판정
## 적혀있는 것을 믿지 말 것 (the plan's own progress claims are re-verified too)
## 반드시 읽을 자료 / four buckets / 제약
## 첫 액션: read the plan, re-verify the progress point → executing-plans
```

**Even in resume mode, the handoff never invents method.** Steps come from the
plan file; anything not in the plan is an open question, not an instruction.
This is what makes the mode split safe: escaping into resume mode buys the
writer nothing, because the only method available there is the one already
written down and agreed.

### 7. Common mistakes — added entries

- Investigating during writing and filling the handoff with the conclusions →
  pre-empts the executor's investigation and ideation.
- Listing steps with no goal → the executor follows a method without knowing
  what it is for, and cannot tell when it has succeeded.
- Declaring resume mode without an agreed plan file → method prescription
  wearing a disguise.
- Mixing interpretation into an observation ("`3 failed` because the token
  refresh is missing") → the interpretation survives re-verification unnoticed.

(Existing entries stay.)

## Scope

- `plugins/session-tools/skills/write-handoff-prompt/SKILL.md` — rewritten body.
- `plugins/session-tools/.claude-plugin/plugin.json` — `0.2.0` → `0.3.0`
  (behavior change).
- The frontmatter `description` is **not** changed. Trigger conditions are
  unchanged; only the behavior after triggering changes, so editing the trigger
  text carries matching-regression risk with no benefit.

## Non-goals

- Splitting the skill into two skills. One skill, two modes.
- Changing the `session-tools` hooks.
- Any change to how the executor session behaves beyond what the handoff text
  instructs.

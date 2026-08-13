# write-handoff-prompt goal-first Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite `session-tools:write-handoff-prompt` so the handoff it
produces transfers the goal to reach instead of the method to reach it, leaving
the next session to run its own investigation, analysis, and ideation.

**Architecture:** One `SKILL.md` body rewrite adds a second core principle
("Goal over method"), a writer-side investigation rule, an objective two-mode
decision (`goal` / `resume`), and two output contracts with their own templates.
Supporting metadata (version, plugin/marketplace/README descriptions) follows in
a second task. Verification is split: mechanical static checks the executor can
run, plus a live two-mode dry run the human partner performs after reinstalling
the plugin.

**Tech Stack:** Markdown with YAML frontmatter; `git`; `grep`; `python3` for
JSON validation.

**Spec:**
`docs/superpowers/specs/2026-08-13-write-handoff-prompt-goal-first-design.md`

## Global Constraints

- SKILL.md prose is **English** (`AGENTS.md`: "All documentation must be written
  in English"). Korean appears only in: the frontmatter `description` trigger
  phrases, the embedded output templates, and the Korean section names those
  templates use (`## 확정`, `## 관측된 사실`, …), which are part of the emitted
  artifact.
- The frontmatter `description` is **not** edited. Trigger conditions do not
  change; only post-trigger behavior does, so touching the trigger text carries
  matching-regression risk with no benefit.
- Skill `description` must remain non-empty, max 1024 chars, **one single line**
  (no YAML folding).
- Version bump is **minor** (behavior change, no new skill): `session-tools`
  0.2.0 → 0.3.0.
- Commit messages: conventional-commit prefix with `session-tools` scope where a
  plugin file changes, lowercase after the colon, English, no co-author trailer,
  no AI mention.
- **Nothing outside this repository is edited** — not `~/.claude/CLAUDE.md`, not
  `settings.json`, not the installed plugin cache under
  `~/.claude/plugins/cache/`.
- Do not modify the `session-tools` hooks (`hooks/*`), and do not touch other
  plugins.

---

### Task 1: Rewrite the skill body

**Files:**

- Modify: `plugins/session-tools/skills/write-handoff-prompt/SKILL.md` (body
  replaced; frontmatter untouched)

**Interfaces:**

- Consumes: nothing from other tasks.
- Produces: the section names the emitted handoff uses — `## Goal`,
  `## 완료 판정`, `## 적혀있는 것을 믿지 말 것`, `## 반드시 읽을 자료`,
  `## 확정`, `## 관측된 사실`, `## 열린 질문`, `## 작성자 경고`, `## 제약`,
  `## 첫 액션`. Task 2's README bullet and Task 3's dry-run criteria refer to
  these exact names.

- [ ] **Step 1: Record the current failure (red)**

Before changing anything, capture what the current skill does wrong, so the
"fixed" claim later has a baseline to point at. Run:

```bash
grep -n "확인된 사실\|작성자 추정\|다음 단 하나의 액션\|every.*artifact\|gathered in this session" \
  plugins/session-tools/skills/write-handoff-prompt/SKILL.md
```

Expected: 5+ matching lines. These are the four investigation-and-method drivers
named in the spec, plus the missing-goal symptom (no `## Goal` anywhere):

```bash
grep -c "## Goal" plugins/session-tools/skills/write-handoff-prompt/SKILL.md
```

Expected: `0`. (Step 3 re-runs this exact command and expects `3` or more.)

- [ ] **Step 2: Replace the body**

Keep lines 1–4 (the `---` frontmatter block with `name` and `description`)
**byte-identical**. Replace everything from line 5 to the end of file with
exactly this content:

````markdown
# write-handoff-prompt

The prompt you write runs in a session with **zero memory** of this
conversation. Its job is to let a fresh executor resume correctly **without
being biased by your conclusions**.

## Two core principles

**1. Documents are not ground truth.** The spec, plan, Linear, memory, and this
handoff are all _descriptions written at a past moment_. They are canonical for
**intent and agreed decisions only** — never for **current state or fact**.
Current state is defined by **code + what you actually observe** (git state, PR
state via `gh`, test runs, real behavior). Any count/status/behavior a document
asserts ("439 violations", "PR is draft", "X works this way") is trusted only
**after** re-verifying it against code/PR/execution. When a document conflicts
with the code, **the code wins.**

**2. Goal over method.** A handoff carries _what must be true when the work is
done_, not _how to get there_. The method either already exists in an agreed
plan document — then the handoff only points at it — or it does not exist yet,
and creating it is the executor's job, through its own investigation, analysis,
ideation, and brainstorming. A method you invent while writing pre-empts that
work and anchors the executor to your unverified reading. While writing a
handoff, your job is **to record and to point**, not **to investigate and to
solve**.

## While writing: record and point, do not investigate

**Allowed — pointer collection.** Mechanical commands only: current branch,
`git rev-parse HEAD`, worktree path, `gh pr view --json url`, checking that a
path exists. Collect these; after compaction they are unrecoverable, and a
missing pointer costs the executor far more than it costs you.

**Forbidden — analytical investigation.** Reading code to find a cause. Grepping
to size an impact radius. Comparing alternatives. Reviewing design. Deciding
what the fix should be. That work belongs to the executor, who will do it
against the current code instead of your memory of it.

Write down only what this session already established. Anything you do not
already know goes to `열린 질문`, or is named as the executor's to investigate.
"Not established yet" is a useful handoff line. A guess dressed as a finding is
not.

## Mode decision — do this first

**`resume` mode — only when both hold:**

- a plan file exists at a real path (you can print it),
- the user agreed to that plan.

**`goal` mode — everything else.** A plan that lives only in your head, one
agreed verbally in conversation, or a spec with no plan file, is goal mode. When
in doubt, goal mode.

State the mode and its evidence — the plan file path, or `plan 문서 없음` — on
the first line of the handoff, so the reader can check the branch you took.

**Even in resume mode you never invent method.** Steps come from the plan file.
Anything the plan does not cover is an open question, not an instruction. This
is what makes the split safe: choosing resume mode buys you no license to
prescribe, because the only method available there is the one already written
down and agreed.

## Output contract — `goal` mode

Fill every pointer with a **real** path / URL / branch / commit — no
placeholders. A pointer this session did not already establish is omitted, or
named as unknown for the executor to find — do not go looking for it.

1. **Title + mode line** — one line each.
2. **`## Goal`** — what must be true when the work is done, and why it matters.
   This leads the document. Concrete enough to judge success against, silent on
   how to get there.
3. **`## 완료 판정`** — how the executor proves it is done. Evidence, not
   assertion: a command whose output settles it, a state that can be observed.
   When no such command is known, the criterion goes to `열린 질문` rather than
   being invented.
4. **`## 적혀있는 것을 믿지 말 것`** — principle 1, stated to the executor:
   re-verify everything below against current code/PR/execution before any
   implementation action.
5. **`## 반드시 읽을 자료`** — the pointers that are unrecoverable after
   compaction: spec path, code paths, PR/Linear URLs, memory files,
   branch/commit/worktree. Mark spec as the 정본 of intent, code as the 정본 of
   current state. Point at where to look; do not summarize what is there.
6. **Four labeled buckets** — never blend status, fact, and assumption into one
   narrative:
   - `## 확정 (User 결정 — 재론 금지)` — settled by the user; don't relitigate.
   - `## 관측된 사실 (명령어/출처+출력/인용+시점 — 재검증 대상)` — what was
     observed, with the command or source and its verbatim output or quote and
     when. **No interpretation.**
   - `## 열린 질문 (User 결정 대기 — 임의 결정 금지)` — open; the executor must
     not decide alone.
   - `## 작성자 경고 (함정 — 시간 낭비 방지용)` — hazards that would waste the
     executor's time. **Never a solution direction.**
7. **`## 제약`** — what must not be done, and the boundaries to respect. A
   constraint rules options out; it does not pick one.
8. **`## 첫 액션`** — read the listed material, re-verify current state, then
   enter `brainstorming` → `writing-plans`. No code before user approval.

## Output contract — `resume` mode

Same as goal mode, with four differences:

- After `## Goal`, add **`## Plan 진행 지점`** — the plan file path, how far it
  has been executed with the evidence for that claim, and which numbered plan
  item is next. Zero items executed is a valid claim — the plan may be agreed
  but unstarted — but it still needs evidence, and the next item is then the
  first one in the plan. Progress claims are re-verification targets like any
  other.
- **`## 적혀있는 것을 믿지 말 것`** carries one more bullet: the plan's own
  progress claims are also re-verification targets, not just its steps.
- **`## 반드시 읽을 자료`** carries one more pointer: the plan file, marked as
  the 정본 of the agreed method.
- `## 첫 액션` is: read the plan, re-verify the progress point, then
  `executing-plans`.

## Observation vs interpretation

The line the `관측된 사실` bucket turns on:

| Write this                               | Not this                                    |
| ---------------------------------------- | ------------------------------------------- |
| `` `flutter test` → 3 failed (14:02) ``  | "3 tests fail because of the token refresh" |
| verbatim output: `expected 200, got 401` | "auth is broken"                            |
| `gh pr view` → `isDraft: true` (14:05)   | "the PR isn't ready"                        |

The first column survives re-verification honestly: the executor re-runs it and
either matches or finds it stale. The second column reads as established fact
while being an unverified inference, and quietly becomes the executor's starting
hypothesis.

## Reference standing conventions by name — don't re-teach them

worktree-first, branch/env preconditions, PR rules,
`verification-before-completion`, amend rules, etc. are already supplied by the
executor's CLAUDE.md / memory. Name the ones the task touches in one line; don't
bloat the handoff re-explaining them. The handoff's unique value is the **goal +
the four buckets + the read list + the mode**.

## Output

Print the finished prompt inline as a copy-pasteable code block. The prompt body
itself is **Korean** (it's the user's handoff) — the templates below are
verbatim output. Offer to also save it as an `.md` file if the user wants.

## Template — `goal` 모드

```
# 작업 지시: <한 줄 요약>
모드: goal (근거: plan 문서 없음)

## Goal — 완료 시 무엇이 참이어야 하는가
- <달성 상태>. 왜 필요한가: <이유>
- 방법은 여기 없음. 조사·분석·대안 검토는 실행자가 직접 수행할 것.

## 완료 판정 (완료 = 증거)
- <이 명령의 출력이 이렇게 되면 완료> / <관측 가능한 상태>

## 적혀있는 것을 믿지 말 것 — 코드·팩트가 정본
- Spec/Linear/memory/이 프롬프트는 과거 시점 서술. 현재 코드와 어긋날 수 있음.
- 문서 = 의도·결정의 정본.  코드 + 관측된 팩트 = 현재 상태·사실의 정본.
- 아래 자료를 전부 읽고 현재 코드/PR/실행으로 재검증한 뒤에만 착수.

## 반드시 읽을 자료 (전부 읽기 전 착수 금지)
- Spec (의도·결정의 정본): <path>
- 코드 (현재 상태의 정본): <paths>
- PR / Linear: <urls>   - memory: [[...]]
- 브랜치 / commit / worktree: <...>

## 확정 (User 결정 — 재론 금지)
- ...
## 관측된 사실 (명령어/출처+출력/인용+시점 — 재검증 대상)
- `<command 또는 출처>` → <출력 원문 또는 인용> (<시점>)   ※ 해석·원인 서술 금지
## 열린 질문 (User 결정 대기 — 임의 결정 금지)
- ...  (작성자가 모르는 것은 여기. 추측으로 메우지 말 것)
## 작성자 경고 (함정 — 시간 낭비 방지용)
- ...  (해법 방향 제시 아님)

## 제약 (해서는 안 되는 것)
- ...  (경계 조건일 뿐, 방법 지시가 아님)

## 첫 액션
위 자료를 전부 읽고 현재 코드로 재검증한 뒤, brainstorming → writing-plans로 진입.
코드 착수 전 User 승인 필수.
```

## Template — `resume` 모드

```
# 작업 지시: <한 줄 요약>
모드: resume (근거: 합의된 plan 파일 <path>)

## Goal — 완료 시 무엇이 참이어야 하는가
- <달성 상태>. 왜 필요한가: <이유>

## Plan 진행 지점
- Plan (합의된 방법의 정본): <path>
- 어디까지 실행됨: <항목, 없으면 "없음(미착수)"> — 근거: `<command>` → <출력> (<시점>)
- 다음 항목: plan의 <N번>
- plan에 없는 방법은 지시하지 않음. 없으면 열린 질문으로 둘 것.

## 완료 판정 (완료 = 증거)
- ...

## 적혀있는 것을 믿지 말 것 — 코드·팩트가 정본
- Spec/Linear/memory/이 프롬프트는 과거 시점 서술. 현재 코드와 어긋날 수 있음.
- 문서 = 의도·결정의 정본.  코드 + 관측된 팩트 = 현재 상태·사실의 정본.
- 아래 자료를 전부 읽고 현재 코드/PR/실행으로 재검증한 뒤에만 착수.
- plan의 진행 상태 서술도 재검증 대상. 충돌 시 코드가 정본.

## 반드시 읽을 자료 (전부 읽기 전 착수 금지)
- Plan (합의된 방법의 정본): <path>
- Spec (의도·결정의 정본): <path>
- 코드 (현재 상태의 정본): <paths>
- PR / Linear: <urls>   - memory: [[...]]
- 브랜치 / commit / worktree: <...>

## 확정 (User 결정 — 재론 금지)
- ...
## 관측된 사실 (명령어/출처+출력/인용+시점 — 재검증 대상)
- `<command 또는 출처>` → <출력 원문 또는 인용> (<시점>)   ※ 해석·원인 서술 금지
## 열린 질문 (User 결정 대기 — 임의 결정 금지)
- ...
## 작성자 경고 (함정 — 시간 낭비 방지용)
- ...

## 제약 (해서는 안 되는 것)
- ...

## 첫 액션
plan을 읽고 진행 지점을 현재 코드로 재검증한 뒤, executing-plans로 진입.
```

## Common mistakes

- **Investigating while writing, then filling the handoff with the
  conclusions.** The result reads like an implementation plan and pre-empts the
  executor's own investigation and ideation. Collect pointers; leave the
  analysis.
- **Listing steps with no goal.** The executor follows a method without knowing
  what it is for, and cannot tell when it has succeeded — or that the method is
  wrong.
- **Declaring resume mode without an agreed plan file.** Method prescription
  wearing a disguise. No file at a real path → goal mode.
- **Mixing interpretation into an observation.** "3 failed _because the token
  refresh is missing_" survives re-verification unnoticed: the executor re-runs
  the test, sees 3 failures, and inherits the cause you guessed.
- **Calling the spec/plan "정본/SSoT" for everything** (or worse, "prefer the
  document on conflict"). It is canonical for _intent_ only; counts, statuses,
  and behavior are re-verified against code.
- **Blending status, fact, and assumption into one narrative** → the executor
  can't tell what to challenge. Use the four buckets.
- **Omitting an artifact the executor needs** (path/URL/branch) → unreachable
  after compaction.
````

- [ ] **Step 3: Static verification (green)**

Run the same checks as Step 1 and confirm they flipped:

```bash
grep -c "## Goal" plugins/session-tools/skills/write-handoff-prompt/SKILL.md
grep -n "확인된 사실\|작성자 추정\|다음 단 하나의 액션" \
  plugins/session-tools/skills/write-handoff-prompt/SKILL.md
```

Expected: the first prints `3` or more (the contract entry plus one heading per
template — Step 1 printed `0`); the second prints **nothing** (exit 1) — the
renamed buckets and the removed method-prescription section leave no trace.

Then confirm every required element is present:

Use `python3`, not a shell loop — the interactive shell here is fish, and
`for … do … done` is bash-only syntax:

```bash
python3 -c "
t = open('plugins/session-tools/skills/write-handoff-prompt/SKILL.md').read()
need = ['Goal over method', 'record and point, do not investigate',
        'Mode decision', '관측된 사실', '작성자 경고', '## 제약', '## 첫 액션']
miss = [s for s in need if s not in t]
n = t.count('Template —')
print('MISS:', miss) if miss else print('ok — all', len(need), 'present')
print('templates:', n, '(expected 2)')
"
```

Expected: `ok — all 7 present` and `templates: 2 (expected 2)`. No backticks in
that command on purpose — fish does not treat them the way bash does.

Confirm the frontmatter was not touched:

```bash
git diff -U0 plugins/session-tools/skills/write-handoff-prompt/SKILL.md | \
  grep -E "^[-+](name:|description:|---)"
```

Expected: **no output**. Any hit means the frontmatter changed — revert those
lines before continuing.

- [ ] **Step 4: Commit**

```bash
git add plugins/session-tools/skills/write-handoff-prompt/SKILL.md
git commit -m "feat(session-tools): make write-handoff-prompt goal-first with goal/resume modes"
```

---

### Task 2: Version bump and description accuracy

**Files:**

- Modify: `plugins/session-tools/.claude-plugin/plugin.json` (version +
  description)
- Modify: `.claude-plugin/marketplace.json` (session-tools description)
- Modify: `README.md:96-101` (the write-handoff-prompt bullet)

**Interfaces:**

- Consumes: the section names produced by Task 1 — the README bullet describes
  `## Goal` / `관측된 사실` / `작성자 경고`, so Task 1 must land first.
- Produces: version `0.3.0`, which Task 3's reinstall step checks for.

**Note on scope:** the spec's Scope section lists only `SKILL.md` and the
version. The three description strings are added here because Task 1 makes them
factually wrong — they currently advertise "separates settled / fact / open /
inferred", and `inferred` (`작성자 추정`) no longer exists. Leaving them would
ship a description that does not match the skill.

- [ ] **Step 1: Bump the version and update the plugin description**

In `plugins/session-tools/.claude-plugin/plugin.json`, set `"version"` to
`"0.3.0"` and replace `"description"` with:

```
Session-lifecycle helpers. Includes a self-check reminder that re-injects an independent-verification (anti-sycophancy) directive after compaction and periodically in long sessions, and a write-handoff-prompt skill for authoring goal-first continuation prompts that hand over the goal to reach rather than the method, leaving the next session to do its own investigation.
```

- [ ] **Step 2: Update the marketplace description**

In `.claude-plugin/marketplace.json`, replace the `session-tools` entry's
`description` with:

```
Session-lifecycle helpers: a self-check reminder that re-injects an independent-verification directive after compaction and periodically in long sessions, plus a write-handoff-prompt skill for authoring goal-first continuation prompts that hand over the goal rather than the method
```

- [ ] **Step 3: Update the README bullet**

In `README.md`, replace the `write-handoff-prompt` bullet under
`### session-tools` with:

```markdown
- **write-handoff-prompt** (skill): when you ask for a handoff / continuation
  prompt (e.g. "컴팩션 후 작업 지시 프롬프트 써줘"), authors one that leads with
  the goal to reach and withholds the method, so the next session runs its own
  investigation and brainstorming. Treats documents as intent-only (not ground
  truth — verify against code) and separates 확정 / 관측된 사실 / 열린 질문 /
  작성자 경고. Picks `resume` mode only when an agreed plan file actually
  exists; otherwise `goal` mode.
```

- [ ] **Step 4: Verify both JSON files parse and the version landed**

```bash
python3 -c "
import json
p = json.load(open('plugins/session-tools/.claude-plugin/plugin.json'))
m = json.load(open('.claude-plugin/marketplace.json'))
assert p['version'] == '0.3.0', p['version']
e = [x for x in m['plugins'] if x['name'] == 'session-tools'][0]
assert 'goal-first' in p['description'] and 'goal-first' in e['description']
print('ok', p['version'])
"
```

Expected: `ok 0.3.0`.

- [ ] **Step 5: Confirm no stale bucket name survives anywhere in the repo**

```bash
grep -rn "작성자 추정\|확인된 사실" --include='*.md' --include='*.json' . \
  | grep -v '^./docs/superpowers/'
```

Expected: **no output**. (Hits under `docs/superpowers/` are the spec and this
plan quoting the old names on purpose — those stay.)

- [ ] **Step 6: Commit**

```bash
git add plugins/session-tools/.claude-plugin/plugin.json \
        .claude-plugin/marketplace.json README.md
git commit -m "chore(session-tools): bump to 0.3.0 and align descriptions"
```

---

### Task 3: Live two-mode verification gate

**Files:** none — this task produces evidence, not edits.

**Interfaces:**

- Consumes: version `0.3.0` from Task 2 and the section names from Task 1.
- Produces: a pass/fail record for the behavior the whole change exists to fix.

This is the only check that exercises the skill as a skill. The static greps in
Task 1 prove the text changed; they cannot prove the emitted handoff stopped
prescribing method. **Do not report the work as done without this task.**

- [ ] **Step 1: Reinstall the plugin so the running skill is the edited one**

The session that ran the old skill loaded it from
`~/.claude/plugins/cache/powdream-plugins/session-tools/0.2.0/`, not from this
repo. Ask the human partner to run, from the repo root:

```
/plugin marketplace add ./
/plugin install session-tools@claude-plugins
```

Then confirm the loaded version is 0.3.0 before running anything else. If it
still reports 0.2.0, stop — every result below would describe the old skill.

- [ ] **Step 2: Goal-mode dry run**

In a **fresh session**, with no plan file agreed, invoke
`/session-tools:write-handoff-prompt` on any in-progress task. Check the emitted
handoff against these criteria:

- [ ] First line states `모드: goal` with its evidence.
- [ ] `## Goal` is the first content section and says what must be true when
      done — not what to change.
- [ ] No section tells the executor which file to edit, in what order, or what
      the fix is.
- [ ] `## 관측된 사실` entries are command + output + timestamp, with no
      "because …" / cause attribution.
- [ ] `## 작성자 경고` (if present) names hazards only, no solution direction.
- [ ] `## 첫 액션` routes to `brainstorming`, not to code.
- [ ] While writing it, the session ran only pointer commands (branch, commit,
      worktree, `gh pr view`) — no code reading to find causes, no impact-radius
      grepping.

Any unchecked box is a failure. Record which one, and fix the corresponding
section of `SKILL.md` before continuing.

- [ ] **Step 3: Resume-mode dry run**

In a **fresh session** where an agreed plan file exists at a real path and part
of it has been executed, invoke the skill again. Check:

- [ ] First line states `모드: resume` **and prints the plan file path**.
- [ ] `## Plan 진행 지점` cites evidence for how far execution got, not a bare
      claim.
- [ ] Every step mentioned traces back to a numbered item in the plan file —
      nothing invented.
- [ ] `## 첫 액션` routes to `executing-plans`.

- [ ] **Step 4: Negative check — the escape hatch is closed**

In a session where a plan was agreed **only in conversation** (no file), invoke
the skill.

- [ ] It picks `goal` mode, not `resume`, and says `plan 문서 없음`.

If it picks resume mode, the mode decision is not objective enough — tighten the
three-condition wording in `SKILL.md` and re-run.

- [ ] **Step 5: Record the result**

Report each dry run's outcome with the actual emitted handoff as the evidence.
"It looks better" is not a result; a checked list with the handoff text is.

---

## Self-Review

**Spec coverage:**

| Spec section                    | Task                              |
| ------------------------------- | --------------------------------- |
| 1. "Goal over method" principle | Task 1.2                          |
| 2. Mode decision (objective)    | Task 1.2, verified Task 3.4       |
| 3. Writer discipline            | Task 1.2, verified Task 3.2       |
| 4. Bucket policy                | Task 1.2, verified Task 1.3 + 2.5 |
| 5. `goal` output contract       | Task 1.2, verified Task 3.2       |
| 6. `resume` output contract     | Task 1.2, verified Task 3.3       |
| 7. Common mistakes entries      | Task 1.2                          |
| Scope: version bump             | Task 2.1                          |
| Scope: description untouched    | Task 1.3 (frontmatter diff check) |

The spec's Scope omitted the marketplace/README description strings; Task 2
covers them and states why. No spec requirement is left without a task.

**Placeholder scan:** no TBD/TODO; every step carries the literal text or
command to run; the full replacement body is embedded verbatim in Task 1 Step 2.

**Name consistency:** the section names produced in Task 1 (`## Goal`,
`## 완료 판정`, `## 관측된 사실`, `## 작성자 경고`, `## 제약`, `## 첫 액션`,
`## Plan 진행 지점`) are the same strings used by Task 1's grep assertions, Task
2's README bullet, and Task 3's criteria.

---
name: write-handoff-prompt
description: Use when the user asks you to write a work-instruction, handoff, or continuation prompt for a future/next session to resume in-progress work after context compaction or in a fresh session — triggers like "컴팩션 후/이후 작업 지시 프롬프트 써줘", "이어서 할 작업 프롬프트 만들어줘", "다음 세션 지시문", "핸드오프 프롬프트", "continuation/handoff prompt", or preserving work across a summary boundary.
---

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

## Before writing: sweep project memories

This sweep keeps `type: project` memories current before the handoff points at
them. Read every file with `type: project` in the memory directory the system
prompt names. Judge each file only from facts this session has already
established, or from one mechanical check (PR state, file existence, merge
status). Reading code and root-cause analysis are outside this sweep.

| Verdict | Action |
| --- | --- |
| Still true | Keep the file |
| Partly changed | Rewrite it with the current values |
| No longer true, or the work is finished | Delete the file |
| No evidence to judge | Leave the file as it is |

After a rewrite or a delete, fix the matching line of the memory index.

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
   compaction: spec path, code paths, PR/Linear URLs, branch/commit/worktree,
   and the memory files whose body the first action must read (the memory index
   loads automatically every session). Mark spec as the 정본 of intent, code as
   the 정본 of current state. Point at where to look; do not summarize what is
   there.
6. **Four labeled buckets** — never blend status, fact, and assumption into one
   narrative:
   - `## 확정 (User 결정 — 재론 금지)` — settled by the user; don't relitigate.
     When a decision record exists (spec decision table, ledger, ADR), this
     section holds that record's location (path + section/row or grep pattern)
     and the decisions made in this session (number + location). When no
     decision record exists, write the decisions here directly.
   - `## 재검증할 상태 (다음 세션의 첫 액션이 기대는 상태 — 명령으로 다시 잰다)`
     — a table `무엇 | 확인 명령 | 마지막 값 (시각)`. 마지막 값 is the verbatim
     output of the command and carries no interpretation. Grounds of decisions
     already made, and state the first action does not rely on, live in the
     decision record.
   - `## 열린 질문 (해소 조건 포함)` — open; the executor must not decide alone.
     Before writing, sort each candidate question (carried-over ones from an
     earlier handoff included) into one of these:
     1. The user can answer → ask in this conversation, then move the answer
        to `## 확정` (or the decision record).
     2. The executor's investigation resolves it → move it to an investigation
        step in `## 첫 액션` and name where to look.
     3. It remains → one line: `<질문> — 정해지려면: <무엇> · 언제: <시점·계기>`.
   - `## 작성자 경고 (함정 — 시간 낭비 방지용)` — hazards that would waste the
     executor's time. **Never a solution direction.**
7. **`## 작업 방식 (상황 → 방법)`** — how the executor handles the situations it
   will meet in this work. One line per situation the executor actually meets:
   `<실행자가 맞닥뜨릴 상황>에서는 <방법>. (근거: <결정 위치>)`. An entry that
   blocks an option is written as "X 대신 Y 로 한다". This section holds
   procedure about environment, tools, approvals, and repositories; the method
   that achieves the Goal (design, solution) belongs to the plan or the
   executor (principle 2). Standing conventions already in the executor's
   CLAUDE.md or memory get one line by name (see "Reference standing
   conventions by name"). An entry that already stood in the previous handoff
   and is still needed as is goes up into the standing rules document the
   executor reads (CLAUDE.md, the project rules file), not into the handoff.
8. **`## 첫 액션`** — read the listed material, re-verify current state with the
   commands in `## 재검증할 상태`, carry out the investigation steps moved from
   `열린 질문` (written only when there are any), then enter `brainstorming` →
   `writing-plans`. No code before user approval.

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

The line the `재검증할 상태` bucket turns on:

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
- PR / Linear: <urls>   - memory: [[...]]   ※ memory 는 첫 액션이 본문을 읽어야 하는 것만 (색인은 매 세션 자동 로드)
- 브랜치 / commit / worktree: <...>

## 확정 (User 결정 — 재론 금지)
- 결정 기록: <경로> — <절/행 또는 grep 패턴>   ※ 결정 기록 문서(spec 결정 표 · 원장 · ADR)가 있을 때
- 이번 세션의 새 결정: <번호> — <결정 기록 안의 위치>   ※ 결정 기록 문서가 있을 때
- <결정 내용>   ※ 결정 기록 문서가 없을 때 이 자리에 직접 적는다
## 재검증할 상태 (다음 세션의 첫 액션이 기대는 상태 — 명령으로 다시 잰다)
| 무엇 | 확인 명령 | 마지막 값 (시각) |
|---|---|---|
| <상태> | `<command 또는 출처>` | <출력 원문 또는 인용> (<시각>) |
※ 마지막 값에는 출력 원문(또는 인용)만 쓴다
## 열린 질문 (해소 조건 포함)
- <질문> — 정해지려면: <무엇> · 언제: <시점·계기>   (작성자가 모르는 것은 여기. 추측으로 메우지 말 것)
## 작성자 경고 (함정 — 시간 낭비 방지용)
- ...  (해법 방향 제시 아님)

## 작업 방식 (상황 → 방법)
- <실행자가 맞닥뜨릴 상황>에서는 <방법>. (근거: <결정 위치>)   ※ 환경·도구·승인·리포를 다루는 절차만. Goal 을 이루는 방법(설계·해법)은 plan 이나 실행자의 몫

## 첫 액션
위 자료를 전부 읽고 현재 코드로 재검증하고, `## 재검증할 상태` 표의 명령으로 현재 상태를 다시 잰 뒤, brainstorming → writing-plans로 진입.
조사 단계(열린 질문에서 옮긴 것): <질문> → 볼 곳: <…>   ※ 있을 때만 쓴다
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
- PR / Linear: <urls>   - memory: [[...]]   ※ memory 는 첫 액션이 본문을 읽어야 하는 것만 (색인은 매 세션 자동 로드)
- 브랜치 / commit / worktree: <...>

## 확정 (User 결정 — 재론 금지)
- 결정 기록: <경로> — <절/행 또는 grep 패턴>   ※ 결정 기록 문서(spec 결정 표 · 원장 · ADR)가 있을 때
- 이번 세션의 새 결정: <번호> — <결정 기록 안의 위치>   ※ 결정 기록 문서가 있을 때
- <결정 내용>   ※ 결정 기록 문서가 없을 때 이 자리에 직접 적는다
## 재검증할 상태 (다음 세션의 첫 액션이 기대는 상태 — 명령으로 다시 잰다)
| 무엇 | 확인 명령 | 마지막 값 (시각) |
|---|---|---|
| <상태> | `<command 또는 출처>` | <출력 원문 또는 인용> (<시각>) |
※ 마지막 값에는 출력 원문(또는 인용)만 쓴다
## 열린 질문 (해소 조건 포함)
- <질문> — 정해지려면: <무엇> · 언제: <시점·계기>
## 작성자 경고 (함정 — 시간 낭비 방지용)
- ...

## 작업 방식 (상황 → 방법)
- <실행자가 맞닥뜨릴 상황>에서는 <방법>. (근거: <결정 위치>)

## 첫 액션
plan을 읽고 진행 지점을 현재 코드로 재검증하고, `## 재검증할 상태` 표의 명령으로 현재 상태를 다시 잰 뒤, executing-plans로 진입.
조사 단계(열린 질문에서 옮긴 것): <질문> → 볼 곳: <…>   ※ 있을 때만 쓴다
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
- **Carrying open questions over from the previous handoff unchanged.** The
  list grows without sorting, and questions the user or the executor could
  resolve stay open. Sort each one as item 6 describes first.
- **Carrying `작업 방식` entries over from the previous handoff unchanged.** The
  same entry is copied into every handoff. An entry still needed as is moves up
  into the standing rules document (CLAUDE.md, the project rules file).

---
name: write-handoff-prompt
description: Use when the user asks you to write a work-instruction, handoff, or continuation prompt for a future/next session to resume in-progress work after context compaction or in a fresh session — triggers like "컴팩션 후/이후 작업 지시 프롬프트 써줘", "이어서 할 작업 프롬프트 만들어줘", "다음 세션 지시문", "핸드오프 프롬프트", "continuation/handoff prompt", or preserving work across a summary boundary.
---

# write-handoff-prompt

The prompt you write runs in a session with **zero memory** of this conversation. Its job is to let a fresh executor resume correctly **without being biased by your conclusions**.

**Core principle — documents are not ground truth.** The spec, plan, Linear, memory, and this handoff are all *descriptions written at a past moment*. They are canonical for **intent and agreed decisions only** — never for **current state or fact**. Current state is defined by **code + what you actually observe** (git state, PR state via `gh`, test runs, real behavior). Any count/status/behavior a document asserts ("439 violations", "PR is draft", "X works this way") is trusted only **after** re-verifying it against code/PR/execution. When a document conflicts with the code, **the code wins.**

## Output contract (these sections, in this order)

The handoff contains **all** of the following. Fill every pointer with a **real** path / URL / branch / commit gathered in this session — no placeholders.

1. **Title** — one line.
2. **"적혀있는 것을 믿지 말 것"** — state the core principle to the executor: read everything below and re-verify it against current code/PR/execution **before** any implementation action.
3. **"반드시 읽을 자료"** — enumerate **every** artifact the executor must read to do the task: spec/plan paths, code paths, PR/Linear URLs, memory files, branch/commit/worktree. Anything not listed is unreachable after compaction = lost. Mark spec/plan as the "정본 of intent/decisions", code as the "정본 of current state".
4. **Four labeled buckets** (the anti-bias core — never blend status, fact, and assumption into one narrative):
   - `## 확정 (User 결정 — 재론 금지)` — settled by the user; don't relitigate.
   - `## 확인된 사실 (근거+시점 — 재검증 대상)` — facts with evidence + timestamp; still re-verify.
   - `## 열린 질문 (User 결정 대기 — 임의 결정 금지)` — open; the executor must not decide alone.
   - `## 작성자 추정 (검증·반박 대상)` — your opinion goes **here only**, so the executor can overturn it.
5. **spec·plan agreement gate** (conditional):
   - If an agreed spec/plan **exists** → point to it as canonical, confirm understanding, then `executing-plans`. No arbitrary changes.
   - If it **doesn't** → route through `brainstorming` (agree the spec) → `writing-plans` (agree the plan). **User approval required before touching code. Do not skip the gate.**
6. **Guardrails / verification gates** (when relevant) — done = evidence, not assertion.
7. **The single next action** — the first thing to do, unambiguous.

## Reference standing conventions by name — don't re-teach them

worktree-first, branch/env preconditions, PR rules, `verification-before-completion`, amend rules, etc. are already supplied by the executor's CLAUDE.md / memory. Name the ones the task touches in one line; don't bloat the handoff re-explaining them. The handoff's unique value is the **task-specific delta + the four buckets + the read list + the gate**.

## Output

Print the finished prompt inline as a copy-pasteable code block. The prompt body itself is **Korean** (it's the user's handoff) — the template below is verbatim output. Offer to also save it as an `.md` file if the user wants.

## Template

```
# 작업 지시: <한 줄 요약>

## 적혀있는 것을 믿지 말 것 — 코드·팩트가 정본
- Spec/Plan/Linear/memory/이 프롬프트는 과거 시점 서술. 현재 코드와 어긋날 수 있음.
- 문서 = 의도·결정의 정본.  코드 + 관측된 팩트 = 현재 상태·사실의 정본.  충돌 시 코드가 정본.
- 아래 자료를 전부 읽고 현재 코드/PR/실행으로 재검증한 뒤에만 착수. 재검증 전 구현 액션 금지.

## 반드시 읽을 자료 (전부 읽기 전 착수 금지)
- Spec (의도·결정의 정본): <path>
- Plan: <path>          - 코드 (현재 상태의 정본): <paths>
- PR / Linear: <urls>   - memory: [[...]]
- 브랜치 / commit / worktree: <...>

## 확정 (User 결정 — 재론 금지)
- ...
## 확인된 사실 (근거+시점 — 재검증 대상)
- ...  (수치·상태에 시점/근거 명시)
## 열린 질문 (User 결정 대기 — 임의 결정 금지)
- ...
## 작성자 추정 (검증·반박 대상)
- ...  (내 의견일 뿐 — 실행자는 독립 검증하고 틀리면 뒤집을 것)

## spec·plan 합의 게이트
- [있음] 위 정본 읽고 이해 확인 → executing-plans. 임의 변경 금지.
- [없음] brainstorming → writing-plans. 코드 착수 전 User 승인 필수. 게이트 생략 금지.

## 가드레일 / 검증 게이트 (완료 = 증거)
- ...

## 다음 단 하나의 액션
<가장 먼저 할 일>
```

## Common mistakes (what a naive handoff does)

- Calls the spec/plan "정본/SSoT" and tells the executor to **trust and read** it (or worse, "prefer the document on conflict"). → The document is canonical for *intent* only; its counts/statuses/behavior must be re-verified against code.
- Blends status, fact, and assumption into one narrative → the executor can't tell what to challenge. **Use the four buckets.**
- States a leaning as if decided → label it `작성자 추정` or `열린 질문`.
- Omits an artifact the executor needs (path/URL/branch) → unreachable after compaction.
- Sends the executor straight to code when no agreed spec/plan exists → route through the gate.

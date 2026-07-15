# Code-review criteria

The default review lens for `cross-code-review`. Pass the whole list to both
reviewers, or replace it with the project's own review checklist. Reviewers
should raise a finding only when they can name a concrete failure — inputs or
state that lead to a wrong result — not a matter of taste.

1. **Correctness.** Logic errors, wrong conditions, off-by-one, inverted checks,
   incorrect API/library usage, wrong types or units.
2. **Edge cases.** Null / empty / boundary inputs, unexpected ordering,
   concurrency and races, partial failure, retries, idempotency.
3. **Error handling.** Swallowed or misclassified errors, missing rollback,
   leaked resources (files, connections, locks), unhandled rejections.
4. **Security.** Injection, missing authz/authn, secret exposure, unsafe
   deserialization, SSRF, path traversal, unvalidated input crossing a trust
   boundary. Scope to what the change actually touches.
5. **Tests.** Does the change come with tests that would fail without it? Are the
   assertions meaningful (not asserting on mocks / always-green)? Are the
   important paths and edge cases covered?
6. **Simplicity & maintainability.** Dead code, needless duplication, avoidable
   complexity, leaky abstractions, a file or function doing too much.
7. **Conventions.** Matches surrounding style, naming, and the project's stated
   rules; no ad-hoc deviations that a maintainer would have to undo.
8. **Performance.** Obvious inefficiencies that matter at real scale — N+1
   queries, unbounded loops/allocations, work repeated in a hot path. Skip
   speculative micro-optimizations.
9. **API & contract.** Breaking changes to a public interface, backward-
   compatibility, consistency with sibling endpoints/functions, migration safety.
10. **Comments & docs.** Non-obvious *why* is captured; no comments that merely
    restate the code or narrate the change (those become noise after merge).

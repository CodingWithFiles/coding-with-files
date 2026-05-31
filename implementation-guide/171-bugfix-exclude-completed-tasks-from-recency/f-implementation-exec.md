# exclude-completed-tasks-from-recency - Implementation Execution
**Task**: 171 (bugfix)

## Task Reference
- **Task ID**: internal-171
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/171-exclude-completed-tasks-from-recency
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [ ] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [ ] Verify all prerequisites met
- [ ] Execute implementation steps sequentially
- [ ] Update "Actual Results" for each step
- [ ] Document any deviations from plan
- [ ] Update status to "Implemented" when complete

## Implementation Steps (from d-implementation-plan.md)

Single-edit guard added to `_get_recency_signal`; same-commit hash refresh. See d-implementation-plan.md for the full spec.

## Actual Results

### Step 1: Setup / pre-refresh verification
- **Planned**: Confirm branch; `git log 6df7b70..HEAD -- TaskContextInference.pm` shows no drift before refreshing.
- **Actual**: On `bugfix/171-...`. `git log` range empty → no unrecorded drift since the last hash-set commit (`6df7b70`, Task 170). Verified clean before editing.
- **Deviations**: None.

### Step 2: Core implementation (the guard)
- **Planned**: Add `next if CWF::TaskState::state_done($task->{full_path}) >= 100;` in the mtime-collection loop (`:392-396`), fully-qualified, no import edit.
- **Actual**: Added the four-line comment + guard exactly as specified at `.cwf/lib/CWF/TaskContextInference.pm:392-397`. Import line (`:11`) untouched; call is fully-qualified, matching the existing `state_achievable` precedent at `:519`. No other signal or the D3 logic touched.
- **Deviations**: None.

### Step 3: Testing (regression check only — new TC-9/TC-10 land in g-testing-exec)
- **Planned**: Confirm existing suite green post-edit.
- **Actual**: `prove t/taskcontextinference.t` → all 19 tests pass (TC-1..TC-8b green; version-mismatch warnings are pre-existing fixture noise). Full suite `prove -r t/` → 634 tests pass. TC-9/TC-10 authored in e-testing-plan.md are added in the testing-exec phase.
- **Deviations**: None.

### Step 4: Documentation
- **Planned**: Inline comment only.
- **Actual**: Four-line explanatory comment on the guard; no API/user docs (internal helper, no interface change).
- **Deviations**: None.

### Step 5: Validation / hash refresh
- **Planned**: `sha256sum` → update manifest entry; `cwf-manage validate` clean.
- **Actual**: New digest `fc51db57…d7d7b` written to `script-hashes.json` (`.pm` → digest-only, no permissions key). `.cwf/scripts/cwf-manage validate` → `[CWF] validate: OK`.
- **Deviations**: None.

## Blockers Encountered

None.

## Security Review

**State**: no findings

I have what I need. Let me reason through the threat categories.

## Security review — implementation phase

The changeset is a single five-line addition inside `_get_recency_signal` in `/home/matt/repo/coding-with-files/.cwf/lib/CWF/TaskContextInference.pm` (lines 394–398): a comment plus one guard `next if CWF::TaskState::state_done($task->{full_path}) >= 100;` that skips completed tasks when computing the recency signal.

I checked each threat category:

**(a) Bash injection / unsafe command construction.** The added line invokes no shell. It is a pure Perl function call into an already-loaded library. No `system`, no backticks, no string-interpolated command. `state_done` itself (`/home/matt/repo/coding-with-files/.cwf/lib/CWF/TaskState.pm:99`) operates on status files via `_get_all_statuses` and does arithmetic; nothing in the call path the diff introduces reaches a shell. Not applicable.

**(b) Perl helpers consuming git/user output without `-z` / input validation.** The diff adds no git invocation and no newline-splitting. `$task->{full_path}` is not parsed or split by the new line — it is passed opaquely to `state_done`, which is the same handling already used at line 524 (`state_achievable($task_dir)`) on the same data structure. No new untrusted-input parsing surface. Not applicable.

**(c) Prompt injection via user-supplied strings.** The added code performs a numeric comparison (`>= 100`) on the integer returned by `state_done` and uses it only to control whether a task is included in an internal mtime hash. No string flows into LLM context as a result of this change; the value gating behaviour is a digits-only completion percentage. This actually aligns with the doc's stated mitigation philosophy (helper scripts compute validated, structured signals rather than passing free text through). Not applicable.

**(d) Unsafe environment-variable handling.** No env var is read or introduced. Not applicable.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere).** The one pattern worth naming: the guard trusts `state_done(...) >= 100` to mean "completed, exclude from recency." `state_done` returns `0` when a task has no readable status files (`return 0 unless @statuses;` at TaskState.pm:103/106). So a task whose status files are missing or unparseable is treated as *not done* and therefore *retained* in the recency pool — it can still win recency. That is the fail-safe direction for this callsite (a task with no readable state is more plausibly live than finished, and including it only affects an inference heuristic, never a destructive action), so it is **safe here because the consequence of misclassification is at most a wrong recency ranking in a best-effort inference signal; audit future uses where `state_done`'s 0-on-missing-status default is reused as a security or correctness gate (e.g. to authorise deletion, skip integrity checks, or drive an irreversible action), where treating "unreadable" as "incomplete" could be the wrong, exploitable default.** No change required in this diff — this is forward-looking signal per the category (e) carve-out, not an actionable defect.

The call is consistent with existing conventions in the same file: `CWF::TaskState` is already imported (line 11), the fully-qualified call form matches the sibling `state_achievable` usage (line 524), and the operand is the same `$task->{full_path}` already in scope. No new imports, no new I/O, no shell, no env, no untrusted-string-to-LLM flow.

Conclusion: the diff is clean. The only category-(e) observation is explicitly framed as safe-here with a future-audit pointer and requires no change.

```cwf-review
state: no findings
summary: One-line Perl guard (state_done gate) in recency signal; no shell/git/env/prompt surface introduced; (e) note on state_done's 0-on-missing default is safe at this inference-only callsite.
```

## Deferral Check
Before marking status=Finished, verify:
- [ ] All steps from d-implementation-plan.md executed
- [ ] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements-plan.md addressed (if applicable)
- [ ] All design guidance in c-design-plan.md followed (if applicable)
- [ ] No planned work deferred without user approval
- [ ] If work deferred: Follow-up task created and linked

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See the per-step "Actual Results" above. Single guard line landed, hash refreshed
in-commit, `validate: OK`, security review: no findings.

## Lessons Learned
Matching the module's existing fully-qualified `TaskState` call precedent kept the
production diff to exactly one line with no second unused import.

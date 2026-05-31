# exclude-completed-tasks-from-recency - Testing Execution
**Task**: 171 (bugfix)

## Task Reference
- **Task ID**: internal-171
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/171-exclude-completed-tasks-from-recency
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [ ] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [ ] Verify test environment ready
- [ ] Execute test cases sequentially
- [ ] Record pass/fail for each test
- [ ] Document failures with reproduction steps
- [ ] Update status to "Testing" when in progress, "Finished" when all pass

## Test Results

### Functional Tests

Two new subtests added to `t/taskcontextinference.t` (plus a `_write_status`
fixture helper that emits real `## Status` / `**Status**:` markers, so
`state_done` reflects true completion rather than the `0` that bare `"x"`
files yield).

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-9 | Completed task (`41-feature-done`, Finished → state_done 100) is the newest-touched dir; active task (`40-feature-active`, In Progress → 25) older | `recency->{top}` = `'40'` | `'40'` | PASS | Load-bearing: **fails pre-fix** (returns `'41'`), passes post-fix |
| TC-10 | Fresh task (`50-feature-fresh`, To-Do → state_done 0) newest; other live task (`51`, In Progress) older | `recency->{top}` = `'50'` | `'50'` | PASS | Boundary: live/fresh task retained (no over-filter toward rejected `state_achievable == 0`) |
| TC-1..TC-8b | Pre-existing inference suite | green | green | PASS | No regression; 19 prior tests unchanged |

**Pre-fix failure verification (TC-9 load-bearing proof)**: temporarily
removed the guard line from `_get_recency_signal`, re-ran the suite →
TC-9 `not ok` (recency top = `'41'`, the completed task), TC-10 still
`ok`. Restored the module (`sha256 fc51db57…d7d7b`, matching the committed
digest) and re-ran → all green. This confirms TC-9 genuinely reproduces the
defect and is not a fixture that would pass regardless.

### Non-Functional Tests
- **Performance**: negligible — one extra `state_done` call per task dir,
  the same per-dir cost the adjacent `progress` signal already pays. No
  benchmark warranted (e-testing-plan.md §Non-Functional).
- **Reliability (fail-open)**: covered by `state_done`'s own contract
  (returns 0 on unparseable/missing status → task retained); owned by
  `taskstate.t`, not re-tested here.
- **Security**: no new attack surface (see Security Review below).

## Test Failures

None. (TC-9's deliberate pre-fix `not ok` was an intentional verification
step, not a suite failure — the committed module passes all cases.)

## Coverage Report

- `prove t/taskcontextinference.t` → 21 subtests PASS (was 19; +TC-9, +TC-10).
- `prove -r t/` → 636 tests PASS across 53 files (was 634).
- Critical path (the new completed-task guard) exercised by TC-9 with a
  proven pre-fix failure → post-fix pass.

## Security Review

**State**: no findings

I have enough to complete the review. Let me work through the threat categories.

## Security Review — testing phase

**Scope confirmation.** Two files in the changeset:
- `.cwf/lib/CWF/TaskContextInference.pm` — CWF-internal (`.cwf/lib/`), unconditional include. In scope.
- `t/taskcontextinference.t` — outside CWF-internal trees but carries `#!/usr/bin/env perl`, so it qualifies via the shebang sniff. In scope.

This is a testing-phase changeset: a one-line production guard plus its regression coverage (a helper and two subtests).

**(a) Bash injection / unsafe command construction.** No new `system`, `exec`, `qx{}`, or backtick calls in either hunk. The production change adds a single pure-Perl call: `CWF::TaskState::state_done($task->{full_path}) >= 100`. No shell is invoked anywhere in the diff. Nothing here.

**(b) Perl helpers consuming git/user output without `-z`.** The production guard consumes no git output — `$task->{full_path}` originates from `_enumerate_all_tasks()` (pre-existing, unchanged) and is passed to `state_done`, which reads on-disk status markers via `_get_all_statuses`. No newline-splitting of porcelain is introduced. The test helper `_write_status` does `open my $fh, '>', $rel` with a three-argument `open` and list-form mode/path — safe. `$rel` and `$status` are hardcoded literals from the test bodies, not external input. No `-z` concern arises because no path-emitting git command is added.

**(c) Prompt injection via user-supplied strings.** No `{arguments}` substitution, no markdown skill/rule/agent instruction text, and no new flow of untrusted strings into LLM context. The production change actually *tightens* a structural inference signal (recency) by gating it on completion state — it does not widen any string-to-LLM path. The test fixtures write only literal status strings into temp files that never reach a model. Nothing here.

**(d) Unsafe environment-variable handling.** No `$ENV{...}` reads introduced. The test uses `File::Temp::tempdir(CLEANUP => 1)` and `Cwd::getcwd()` with a `chdir $saved` restore — standard, no env-var-driven path into `chmod`/`rm`/`open`. The `chdir $tmp` targets a freshly created `File::Temp` dir (mode 0700 by default), not an attacker-influenced path. Nothing here.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere).** One pattern worth flagging for future-reuse framing, not as a defect:

The test helper `_write_status` opens `$rel` for writing with no validation. **Safe here because** every call site passes a hardcoded literal path under a freshly minted `File::Temp::tempdir`, and the test runs in a controlled CI/dev context — there is no untrusted input. **Audit future uses where** `$rel` could become derived from a task slug, directory name, or any partly-controlled string: the bare two-element `open '>', $rel` would then be a path-traversal / arbitrary-write surface (no `..` rejection, no `rel2abs` canonicalisation). This mirrors the (d) "do instead" guidance. No action required for this diff; the note is for anyone copying the helper into a fixture that writes to a computed path.

I also confirmed the guard's invariant is sound for its own purposes: `state_done` returns `0` when no parsable status markers exist, so the gate `>= 100` cannot accidentally exclude a task that merely lacks status files — it only excludes genuinely-completed tasks. The test helper's comment correctly documents that the bare `"x"` fixture files from TC-8a yield `state_done == 0` (not filtered), while the new `## Status`/`**Status**:` files drive a real percentage. This is correctness-relevant but not a security concern, and TC-10 guards against over-filtering live tasks.

No actionable security concerns in this changeset.

```cwf-review
state: no findings
summary: One-line state-gated recency guard plus regression tests; no shell, no untrusted-string-to-LLM flow, no env-var or path-traversal surface introduced.
```

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See "Test Results" above. 21 subtests in the inference file, 636 in the full
suite, all green. TC-9 verified to fail pre-fix. Security review: no findings.

## Lessons Learned
A regression fixture must drive the *actual* gating value: TC-8a's bare `"x"`
files yield `state_done == 0`, so a copy-paste fixture would have passed without
the fix. The `_write_status` helper writing real `**Status**:` markers is what
makes TC-9 load-bearing.

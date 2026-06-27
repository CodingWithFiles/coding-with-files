# TC-VALIDATE in-flight false-failure - Testing Execution
**Task**: 211 (bugfix)

## Task Reference
- **Task ID**: internal-211
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/211-tc-validate-in-flight-false-failure
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready (live repo; task 211 in-flight = mid-flight condition)
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Finished" when all pass

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-A | Both edited subtests run mid-flight (task 211 in-flight) | Green; no aggregate `is($rc,0)` false-fail | `prove t/security-review-changeset.t t/exec-changeset-reviewers.t` → 60 tests, all OK | PASS | Pre-fix the `is($rc,0)` would have gone red on in-flight state |
| TC-B | Genuine integrity regression on a named file still caught | Retained `unlike` fails; liveness `like` still passes | Perturbed helper to 0700 → `validate` named it → `not ok - no integrity violation names the changed helper`, `ok - ran to a verdict`, `ok - migrated agent` | PASS | Restored via `fix-security` (1 file repaired, validate OK, perms 500) |
| TC-C | Liveness guards vacuous pass | `like` rejects empty/banner-less output, accepts both banners | Standalone 4-assertion test → all OK | PASS | empty→fail, field-text-only→fail, `validate: OK`→pass, `N violation(s) found`→pass |
| TC-D | Full-suite regression | No new failures vs phase-d baseline | `prove t/` → 73 files, 882 tests, all successful | PASS | Includes `cwf-manage-fix-security.t` (green after the f-phase 0444 perm restore) |

### Non-Functional Tests
- **Reliability**: the `or die` fork guard is preserved in both subtests (verified by
  inspection; fork-failure path still aborts loudly). TC-B confirmed the liveness `like`
  passes on a real `N violation(s) found` verdict — environment-independent as designed.
- **Integrity**: `cwf-manage validate` itself is unchanged; TC-B demonstrated it still
  emits and names a genuine violation, and `fix-security` cleanly restored the perturbed
  file. No tampering signal smoothed.

## Test Failures
None. (TC-B's `not ok` is the *expected* failure of a deliberately-perturbed run,
demonstrating regression coverage; the tree was restored to `validate: OK` afterward.)

## Coverage Report
The change is test-only; coverage is the assertions themselves. The two edited subtests
retain their file-scoped `unlike` checks (TC-B proves these still bite) and gain a
liveness `like` (TC-C proves it guards the vacuous-pass hole the dropped `is($rc,0)`
previously, incidentally, covered). No production code paths added or removed.

## Changeset Reviews (Step 8 — two-reviewer MAP, launched in parallel)
Branch `bugfix/211-...` (not main); security changeset 879 lines / 9 files / 0 production;
best-practice-resolve returned 2 matches → both reviewers launched. Verbatim outputs in
the task scratch dir; tokens are the shared `security-review-classify` verdicts.

### Security Review
**State**: no findings

Test-only Perl edits use shell-free list-form `open '-|'` over trusted `cwf-manage validate`
producer output (no injection, no env-var handling, no prompt surface, no path-splitting).
The dropped `is($rc,0)` does not weaken the integrity gate — `cwf-manage validate` is
untouched and remains the SHA256/permission authority; the retained file-scoped `unlike`
checks still catch tampering naming the changed helper/agent. Phase-doc markdown has no
executable surface.

### Best-Practice Review
**State**: no findings

Resolved Go/Postgres sources do not bind a Perl-test + CWF-markdown change. The one
cross-language testing principle — avoid environment-coupled flaky tests; assert behaviour
not implementation; fail loudly — is upheld, not violated: the change removes the whole-repo
coupling that caused the flakiness, retains file-scoped regression coverage (TC-B proves it
still bites), and adds a liveness guard against vacuous pass. Known tag-resolution mismatch
already tracked in the backlog.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
The full-suite run surfaced an *unrelated* environmental failure (the perm dual-semantics
above), validating this task's own thesis: file-scoped assertions localise blame, aggregate
ones don't. See j-retrospective.md.

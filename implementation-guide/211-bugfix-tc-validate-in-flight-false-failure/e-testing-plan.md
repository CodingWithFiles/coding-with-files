# TC-VALIDATE in-flight false-failure - Testing Plan
**Task**: 211 (bugfix)

## Task Reference
- **Task ID**: internal-211
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/211-tc-validate-in-flight-false-failure
- **Template Version**: 2.1

## Goal
Verify the two edited subtests (TC-VALIDATE, TC-10) no longer false-fail mid-flight,
still catch genuine integrity regressions on their named files, and cannot pass
vacuously — without touching production code.

## Test Strategy
This is a test-only change, so verification is itself the suite. No new test files;
we run the two affected files plus the full suite, and use temporary, reverted
perturbations to confirm the retained assertions still bite.

### Test Levels
- **Suite execution**: run `t/security-review-changeset.t` and
  `t/exec-changeset-reviewers.t` directly, then `prove t/` for regressions.
- **Mutation checks**: temporary, reverted perturbations to confirm the liveness and
  `unlike` assertions fail when they should (guards against silent/vacuous passes).

### Test Coverage Targets
- Both edited subtests: green when run mid-flight (task 211 in-flight, non-terminal
  phase Statuses present).
- Retained `unlike` regression coverage: demonstrably still failing on a named-file
  perturbation.
- Liveness assertion: demonstrably failing on empty validate output.
- Full suite: no new failures vs the phase-d baseline.

## Test Cases
### Functional Test Cases
- **TC-A — mid-flight no longer false-fails (the bug)**
  - **Given**: task 211 is in-flight; an unrelated in-flight condition that flips the
    aggregate validate exit code is present (e.g. a placeholder phase `Status`, or a
    transient perm bump on an unrelated hashed file).
  - **When**: `prove t/security-review-changeset.t` and `prove t/exec-changeset-reviewers.t`.
  - **Then**: TC-VALIDATE and TC-10 pass (pre-fix, the `is($rc,0)` would have failed).
  - **Cleanup**: revert the perturbation; re-run `cwf-manage validate` clean.

- **TC-B — genuine regression on a named file still caught**
  - **Given**: temporarily perturb a file named by the retained `unlike` checks
    (the `security-review-changeset` helper hash, or a lens agent), so validate emits
    a violation naming it.
  - **When**: run the owning subtest.
  - **Then**: the relevant `unlike` fails (regression coverage intact).
  - **Cleanup**: `cwf-manage fix-security` / restore; validate clean.

- **TC-C — liveness guards vacuous pass**
  - **Given**: validate produces no output reaching `$output` (simulate by pointing the
    fork at a stub that exits without printing, or reason from the `like` regex).
  - **When**: the subtest runs.
  - **Then**: the liveness `like(qr/validate: OK|\d+ violation\(s\) found/)` fails,
    so the subtest cannot pass with empty output.

- **TC-D — full-suite regression**
  - **Given**: the two edits applied.
  - **When**: `prove t/`.
  - **Then**: no new failures vs the phase-d baseline (allowing for known,
    independent in-flight noise unrelated to these two files).

### Non-Functional Test Cases
- **Reliability**: the `or die` on the fork is preserved (fork-failure path still
  aborts loudly).
- **Integrity**: `cwf-manage validate` itself is unchanged and remains the SHA256/
  permission gate; the change does not smooth any genuine tampering signal.

## Test Environment
### Setup Requirements
- The live repo (these subtests run `cwf-manage validate` against the resolved git
  root; they cannot be pointed at a temp dir).
- Any perturbations (TC-B) must be made on the live tree and **reverted** in the same
  step; restore with `cwf-manage fix-security` and confirm `validate: OK`.

### Automation
- `prove t/...`; no CI changes.

## Validation Criteria
- [ ] TC-A: both subtests green mid-flight with unrelated drift present.
- [ ] TC-B: `unlike` checks still fail on a named-file perturbation, then restored.
- [ ] TC-C: liveness `like` fails on empty output.
- [ ] TC-D: full `prove t/` shows no new failures attributable to this change.
- [ ] Working tree restored; `cwf-manage validate` clean post-verification.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
TC-B (perturb-and-restore on a named hashed file) was the decisive check — it proved the
retained `unlike` still bites while the liveness `like` passes. A test-only change still
warrants a deliberate regression-coverage demonstration. See j-retrospective.md.

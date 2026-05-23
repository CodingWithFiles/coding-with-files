# Converge cwf-manage update onto install.bash - Testing Execution
**Task**: 155 (feature)

## Task Reference
- **Task ID**: internal-155
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/155-converge-cwf-manage-update-onto-install-bash
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status

## Test Results

### Functional Tests
Run: `prove -l t/cwf-manage-update-end-to-end.t` (FR test cases) — 5 subtests, all PASS.

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-FR9  | Malformed refs (`--foo`, `;rm`, `$(touch pwned)`, `../escape`) | rejected pre-side-effect, "Invalid ref" | rejected, no `pwned` file | PASS | lexical validation before clone |
| TC-FR2/FR3/FR5 | Cross-version-gap subtree update v0.0.1→v0.0.3 | success, no conflict, target marker, validate OK | E2E-MARKER=v0.0.3, validate OK | PASS | target laydown ran; no squash conflict |
| TC-FR6a | Manifest-SHA pin survives second update | pin present; 2nd update no false-positive | pin written; 2nd update clean | PASS | commit between updates (real usage) |
| TC-FR6b | Downgrade v0.0.3→v0.0.1 | success, marker downgraded | E2E-MARKER=v0.0.1 | PASS | converged path supports rollback |
| TC-FR10 | Unrelated staged work isolation | not swept into remove commit; never lost | UNRELATED.txt absent from remove commit, present in tree | PASS | pathspec change verified |
| TC-FR5 (perms) | exact-perms least-privilege | `validate` passes post-update | validate OK | PASS | exact-set mode strips excess bits |

### Regression
Full suite `prove -l t/`: **46 files, 505 tests, all PASS**. Notably `cwf-manage-fix-security.t` (8) green after the `_read_hashes_data`/`_apply_recorded_perms` extraction; `cwf-manage-update.t`, `cwf-manage-check-clean-tree.t`, `cwf-manage-resolve-source.t` green. `cwf-manage validate`: OK.

### Non-Functional Tests
- **Security**: TC-FR9 (injection rejected), TC-FR10 (staged-work isolation), exec-phase changeset review → no findings (recorded in f-implementation-exec.md). Existing `copy_tree`/`_escapes_src` subtests remain green (copy path unchanged).
- **Reliability**: delegation distinguishes spawn-failure/signal/non-zero-exit, each aborting before the manifest pin (code-reviewed; exact-perms fatal-on-mismatch path covered by reasoning — a forced corrupt laydown is not separately fixtured).
- **Performance (NFR1)**: end-to-end suite completes in ~5s wall — within the per-test budget; no multi-minute hang.

## Test Failures
None. (During bring-up, two fixture-shaped issues were resolved — see f-implementation-exec.md Blockers: committing the install + gitignoring the lock; `CWF_UPGRADE_RESOLVE=new` for non-TTY apply-artefacts. Neither is a product defect.)

## Coverage Report
FR1 (subtree path), FR2, FR3, FR5, FR6, FR9, FR10 covered by end-to-end cases above. FR4 (accreted steps) covered indirectly: updates that pass run lock/settings/manifest/apply-artefacts/settings-merge in order and validate cleanly. FR7 (docs) verified by inspection of INSTALL.md. FR8 (harness) is the delivered test file. FR1 copy-path and the manifest-schema-bump scenario are deferred (see e-testing-plan / BACKLOG).

## Status
**Status**: Finished
**Next Action**: /cwf-rollout 155
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See test results table above. 5/5 end-to-end subtests pass; full suite 46 files / 505 tests green; `cwf-manage validate` clean.

## Security Review

**State**: error

error: changeset exceeds 500-line review cap; split the change or perform manual review

**Context (manual review performed)**: the testing-phase changeset (649 lines, 3 files) re-includes the full `cwf-manage` + `install.bash` implementation diff — already reviewed in f-implementation-exec.md with **no findings** — plus the only net-new file for this phase, `t/cwf-manage-update-end-to-end.t` (shebang-sniffed in). Manual read of the test file: it spawns `install.bash`/`cwf-manage` via list-form `system`/`open '-|'` (no shell), sets `GIT_*`/`CWF_*` env explicitly, operates only within `File::Temp` tempdirs, and consumes no untrusted input (fixture content is seeded from the repo). No injection, path-escape, or env-handling concerns. Test-only code; not shipped to consumers.

## Lessons Learned
The 500-line exec-phase security-review cap was tripped purely because the testing-phase changeset re-includes the already-reviewed implementation diff plus one test file. Manual review of the small net-new test-only delta was the right fallback; the cap is coarse for phases whose net content is small. See j-retrospective.md.

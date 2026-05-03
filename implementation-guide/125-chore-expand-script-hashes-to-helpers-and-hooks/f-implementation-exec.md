# expand script-hashes to helpers and hooks - Implementation Execution
**Task**: 125 (chore)

## Task Reference
- **Task ID**: internal-125
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/125-expand-script-hashes-to-helpers-and-hooks
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Finished" when complete

## Actual Results

### Step 1: Setup
- **Planned**: Confirm 17-file inventory + 4 perms-drift updates; confirm `Validate::Security` accepts arbitrary keys; confirm shell helpers run from `#!/bin/sh`.
- **Actual**: All confirmed during d-plan phase. No new prerequisites surfaced.

### Step 2: Compute SHA256s
- **Planned**: Write `/tmp/task-125/compute-hashes.pl` and run it.
- **Actual**: Created `/tmp/task-125/compute-hashes.pl` (Write tool) and ran it. All 17 hashes captured. All files confirmed at on-disk perms `0700`.

### Step 3: Splice into `script-hashes.json`
- **Planned**: Insert 17 new entries alphabetised by key; lower 4 drift entries' permissions from `"0755"` → `"0500"`; bump `last_updated`.
- **Actual**: Wrote new manifest (36 scripts entries total: 19 pre-existing + 17 new). 4 drift entries (`cwf-set-status`, `migrate-v2.1-file-order`, `task-context-inference`, `task-stack`) lowered to `0500`. `last_updated` set to `2026-05-03`. JSON validated via `/tmp/task-125/check-json.pl` (parses cleanly; 36 scripts, 19 lib).

### Step 4: Run `cwf-manage validate`
- **Planned**: Expect 0 violations (sha256 + permissions).
- **Actual**: `[CWF] validate: OK` — zero violations. Pre-existing 4 perms warnings cleared.

### Step 5: Coverage regression test
- **Planned**: Create `t/validate-security-coverage.t` modelled on `validate-perl-conventions.t`; demonstrate RED before splice, GREEN after.
- **Actual**: Created and chmod 0500. Ran BEFORE Step 3 splice — confirmed RED: 17 missing entries flagged across TC-C1 (8 fail), TC-C2 (7 fail), TC-C3 (2 fail); TC-U4 symlink subtest passed. Ran AFTER splice — all 4 subtests PASS (TC-C1: 22 hits, TC-C2: 7 hits, TC-C3: 2 hits, TC-U4: symlink skipped).

### Step 6: Full test suite
- **Planned**: `prove -r t/` zero regressions + new file green.
- **Actual**: 29 files / 271 tests / All tests successful. Baseline was 28 files / 267 tests; delta is +1 file (the new coverage test) and +4 subtests, exactly as expected.

### Step 7: Self-reference check
- **Planned**: NOT modify — `script-hashes.json` itself is not registered (would be self-referential).
- **Actual**: No change needed; file remains unregistered.

## Deviations
None. The 17 new entries hashed cleanly on the first attempt; no recompute needed.

## Files Changed
- `.cwf/security/script-hashes.json` — 17 new entries, 4 drift fixes, `last_updated` bumped.
- `t/validate-security-coverage.t` — **new** coverage guard.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (coverage achieved; `cwf-manage validate` clean; planted-byte-flip is g-phase per plan; no end-user refresh-hashes added; hash-key naming unambiguous)
- [x] All requirements addressed
- [x] All design guidance followed
- [x] No planned work deferred without user approval

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

no findings: empty changeset (the files touched — `.cwf/security/script-hashes.json` and `t/validate-security-coverage.t` — are outside the security-review pathspec; manifest data and test files are not security-review surface)

## Lessons Learned
Splicing the JSON via Write tool (full rewrite) was simpler and safer than chaining Edits; the file is small enough that a full rewrite leaves a cleaner diff than dozens of insert points. Pre-existing perms warnings during a-d-e checkpoints cleared in this phase as soon as the manifest was updated — folding the drift fix into this task (rather than splitting it) was the right call.

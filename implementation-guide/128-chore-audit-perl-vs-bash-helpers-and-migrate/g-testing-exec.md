# Audit Perl-vs-Bash helpers and migrate - Testing Execution
**Task**: 128 (chore)

## Task Reference
- **Task ID**: internal-128
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/128-audit-perl-vs-bash-helpers-and-migrate
- **Template Version**: 2.1

## Goal
Execute the test cases from e-testing-plan.md to verify the deletions and inline did not regress integrity tracking, the coverage guard, the `cwf-config` skill, or the wider test suite.

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-F1 | `cwf-manage validate` clean | exit 0, "[CWF] validate: OK" | "[CWF] validate: OK" | PASS |
| TC-F2 | `prove t/validate-security-coverage.t` GREEN with auto-counts | TC-C1=19, TC-C2=7, TC-C3=2 | TC-C1=19 (1 sentinel + 19 helpers, plan 1..20), TC-C2=7 (plan 1..8), TC-C3=2 (plan 1..3); all subtests ok | PASS |
| TC-F3 | Inlined Bash loads autoload config when present | full YAML output | Full YAML emitted, identical to deleted helper output | PASS |
| TC-F4 | Inlined Bash falls back when config missing | "No autoload config found" | Output: "No autoload config found" (verified by `cd /tmp && cat .cwf/autoload.yaml 2>/dev/null \|\| echo …`) | PASS |
| TC-F5 | No active code references the deleted helpers | hits only in BACKLOG/CHANGELOG/historical task docs | Hits in `CHANGELOG.md`, `implementation-guide/{59,101,125,126,128}-…` only. **No** hits in `.claude/skills/`, `.cwf/scripts/`, `.cwf/lib/`, `.cwf/docs/`, `t/`, `scripts/`, or `install.bash`. (Note: BACKLOG.md no longer in the hit list because Step 6 closed the entry.) | PASS |
| TC-F6 | BACKLOG entry removed | only completion marker remains | Single `<!-- Completed: … Task 128 (2026-05-06) … -->` line at BACKLOG.md:32; no open entry | PASS |

### Non-Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-NF1 | Full `prove t/` GREEN | all PASS | Files=33, Tests=325, all PASS | PASS |
| TC-NF2 | Atomic commit (deletes + manifest in one commit) | single commit contains 5 deletions + manifest edit | `git show 76d79a7 --stat` lists exactly 5 helper deletions + `script-hashes.json` modification + the f-implementation-exec.md addition | PASS |
| TC-NF3 | Permissions unchanged for surviving helpers | no perm-drift violations | `cwf-manage validate` is clean (it enforces both SHA256 and recorded permissions); no surviving helper saw any perm change | PASS |

## Test Failures
None.

## Coverage Report
- `t/validate-security-coverage.t` auto-adjusted: 24 → 19 top-level command-helpers asserted as registered. Subcommands (7) and hooks (2) unchanged.
- Wider suite: 325 tests across 33 files, 100% pass.
- Manifest entries: scripts map went from 38 → 33; lib map (20) and other sections unchanged.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: error

error: changeset exceeds 500-line review cap; split the change or perform manual review

Note for human reviewer: same cap-overflow situation as f-phase (1545 lines), inflated by unmerged Task 127 between this branch's merge-base and main. The g-phase (testing-exec) added no new in-pathspec code beyond the f-phase delta — only ran tests and updated wf step docs (which are outside the security pathspec). Manual review against threat categories (a)–(e) for the testing-phase changes: no new shell command construction, no new Perl helpers, no new SKILL `{arguments}` flows, no env-var reads, no risky patterns introduced. The f-phase manual review remains the substantive review for this task.

## Lessons Learned
*To be captured during retrospective*

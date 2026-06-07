# Replace git-subtree with read-tree laydown - Testing Execution
**Task**: 185 (feature)

## Task Reference
- **Task ID**: internal-185
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/185-replace-git-subtree-with-read-tree-laydown
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready (`prove`, core-Perl, throwaway git repos)
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Full `t/` suite green

## Test Results

Whole suite: **`prove t/` → 61 files, 706 tests, all pass** (was 58 files; +3 new files).

### New test files (TC-1..TC-13)

| TC | AC | Where | Status | Notes |
|----|----|-------|--------|-------|
| TC-1 | AC1 | `t/install-bash-read-tree.t` | PASS | merge-free (1 parent, 0 merges); 3 non-`.cwf` prefixes tree-exact vs mapped source; `.cwf` fidelity via sentinel blob (see deviation); exec mode `100755` preserved; laydown staged not committed |
| TC-2 | AC3 | `t/install-bash-read-tree.t` | PASS | `CWF_METHOD=subtree` exits non-zero, names read-tree/copy, nothing laid down |
| TC-3 | AC2 | `t/install-bash-read-tree.t` | PASS | copy installs, records `cwf_method=copy` |
| TC-4 | AC9 | `t/install-bash-read-tree.t` | PASS | forced reinstall: stale file gone, `.cwf-skills` tree byte-identical to clean install, no merge |
| TC-5 | AC8 | `t/install-bash-read-tree.t` | PASS | escaping source symlink refused fail-closed, nothing materialised |
| TC-6 | AC4+ | `t/cwf-manage-update-migrate.t` | PASS | subtree install migrates → `read-tree`, no new merge, warning emitted, validate clean |
| TC-7 | AC4− | `t/cwf-manage-update-migrate.t` | PASS | failed laydown leaves `cwf_method=subtree` (fail-closed) |
| TC-8 | AC5 | `t/cwf-detect-merges.t` | PASS | total=4 / CWF=2 / elsewhere=2; ambiguous "Add CWF" decoy under-claimed |
| TC-9 | AC6 | `t/cwf-detect-merges.t` | PASS | read-only (HEAD unchanged), counts-only (no raw subject echoed), names re-linearisation+maintainer, exit 0 |
| TC-10 | AC7 | `t/cwf-manage-update-migrate.t` | PASS | `check-merges` read-only (HEAD + `status --porcelain` unchanged) |
| TC-11 | extra-a | `t/install-bash-read-tree.t` | PASS | second forced reinstall idempotent (`.cwf-skills` unchanged) |
| TC-12 | extra-b | `t/cwf-manage-update-migrate.t` | PASS | detector forced non-zero (hash-consistent stub) → migration still completes |
| TC-13 | AC10 | `t/validate-*` + INSTALL grep | PASS (manual) | default flipped + INSTALL.md read-tree/copy/subtree-deprecated, no "first-class" (verified in f-exec) |

### Migrated existing files (regression)
- `t/install-bash-reinstall.t`: removed the three "item 1" subtests (they exercised
  `install_subtree`'s force-removal *commit*, deleted in Task 185); switched the item-2
  settings-merge subtests and the cross-method TC-6 to `read-tree`; copy symlink-guard
  subtests unchanged. **PASS.**
- `t/version-records-commit-sha.t`, `t/cwf-manage-update-end-to-end.t`: default install
  method switched `subtree`→`copy` (their assertions are method-agnostic; read-tree and
  migration are covered by the new files). Stale "subtree" labels corrected. **PASS.**

### Non-Functional Tests
- **Security (NFR4)**: TC-5 (symlink-escape fail-closed) + TC-9 (counts-only, read-only)
  pass; exec-phase `security-review-changeset` returned **no findings** (recorded in
  f-implementation-exec.md). list-form spawn / NUL-safe reads confirmed by review.
- **Reliability (NFR5)**: TC-7 (fail-closed migration), TC-11 (idempotent re-run), TC-12
  (detection-failure-tolerant) all pass.
- **Performance (NFR1)**: `cwf-detect-merges` is single-pass and sub-second on the fixtures.

## Test Failures

None outstanding. Two failures encountered and resolved during authoring (both test-harness
issues, not product defects): (1) a backtick `run` helper shell-split a commit message with
a space — fixed to list-form capture; (2) cross-install `.cwf` tree comparisons were
confounded by `post_install`'s `.cwf/version` timestamp — switched determinism checks to the
mutation-free `.cwf-skills` prefix and a sentinel blob for `.cwf`.

## Coverage Report

Every AC1–AC10 has ≥1 automated test (table above), plus the two plan-review failure modes
(TC-11 idempotent re-run, TC-12 detection-failure-tolerant). The fresh-install perms-ceiling
matter surfaced in f-exec is **not** newly asserted here: per the established contract
(`install-bash-reinstall.t` asserts no fresh-install validate; `cwf-manage-update-end-to-end.t`
asserts validate post-update), validate-clean is asserted on the migration/update path
(TC-6), where `apply_exact_perms_or_die` runs — matching the existing copy behaviour.

## Security Review

**State**: no findings

Testing-exec adds three new test files and migrates three existing ones; the security-relevant production code was already reviewed clean at implementation-exec and is unchanged here.

(a) Bash injection: `install_read_tree` git plumbing is argv-form with `CWF_PAIRS` literals, hex `$tree`, `--` option terminators, `set -euo pipefail`; test harnesses use list-form `system`/`run(cmd=>[...])`. (b) Perl/git: `cwf-detect-merges` reads NUL-separated, list-form fork/exec, `POSIX::_exit` child; the only test `split /\s+/` is over hex `rev-list --parents` output. (c) Prompt injection: TC-9 actively asserts the counts-only invariant (`unlike $out, qr/Squashed '/`) — a crafted subject shifts a count by at most one and never reaches stdout. (d) Env vars: tests set `CWF_*` via `local $ENV` with literals/test paths; TC-12 patches a stub's recorded sha256 to stay integrity-consistent and confirms `run_detect_merges` ignores a failing detector (defence-in-depth verified). (e) Advisory only: hex-only `\s+` split; regex-over-self-authored-JSON confined to the TC-12 fixture.

Mechanism note surfaced by the reviewer: the three new test files are untracked, so `git diff <baseline>..worktree` (the auto-built changeset) did not include them; the reviewer read them from disk and found them clean. They are staged for the g checkpoint commit, so they enter version control here.

```cwf-review
state: no findings
summary: testing-exec adds/updates tests for the read-tree laydown; production code unchanged and clean (list-form spawn, NUL-safe reads, counts-only detector). Two advisory pattern notes (hex-only \s+ split; regex-over-self-authored-JSON in a fixture). Note: 3 new untracked test files were absent from the auto-built changeset and were reviewed directly from disk.
```

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*

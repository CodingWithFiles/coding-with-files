# fix hook sandbox tmpdir scratch path - Testing Execution
**Task**: 215 (bugfix)

## Task Reference
- **Task ID**: internal-215
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/215-fix-hook-sandbox-tmpdir-scratch-path
- **Template Version**: 2.1

## Goal
Execute the tests in e-testing-plan.md (TC-9..TC-14 probe branch + TC-1..TC-8
regression) and verify the Approach A implementation.

## Test Environment
- `prove -lr t/` from repo root; `PERL5OPT=-CDSLA`.
- Real sandbox active: `TMPDIR=/tmp/claude-1000`, EUID 1000 (so TC-12 ran, not skipped).
- Probe branch exercised hermetically via `local $CWF::Common::SANDBOX_TMP_PROBE`.

## Test Results

### Functional Tests (t/scratch.t — `prove -lv`, all 14 subtests PASS)

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-9  | `$TMPDIR` set vs present probe | base = `$TMPDIR` (probe ignored) | as expected | PASS |
| TC-10 | `$TMPDIR` unset, writable probe | base = probe dir | as expected | PASS |
| TC-11 | `$TMPDIR` unset, absent probe | base = `/tmp` | as expected | PASS |
| TC-12 | `$TMPDIR` unset, probe `chmod 0500` | base = `/tmp` (`-w` fails) | as expected (ran, EUID 1000) | PASS |
| TC-13 | `$TMPDIR` unset, symlinked probe | base = `/tmp` (`!-l` reject) | as expected (symlink supported) | PASS |
| TC-14 | `$TMPDIR` unset, empty probe var | base = `/tmp` (`length` guard) | as expected | PASS |
| TC-1..TC-8 | regression (env branch, worktree, not_a_repo, bad_num, leaf 0700, symlink-parent, idempotent) | unchanged | unchanged | PASS |

### Non-Functional Tests
- **Reliability**: every probe branch resolves to a usable base; no `undef`/die
  outside the pre-existing `not_a_repo` (TC-3 unchanged). Confirmed by TC-11..TC-14.
- **Security**: TC-13 confirms a symlinked probe is rejected (defence-in-depth,
  parity with `scratch_dir`'s leaf guard). The changeset security reviewer
  returned **no findings** (recorded in f-implementation-exec.md).
- **Performance**: env branch (in-sandbox hot path) stays disk-free; probe branch
  costs one `lstat`. No assertion (negligible); noted.

### Live acceptance (recorded in f, repeated here for the testing record)
With `$TMPDIR` deleted (mimicking the unsandboxed hook), `scratch_parent`
resolved to `/tmp/claude-1000/cwf-home-matt-repo-coding-with-files`
(`err = undef`) — the in-sandbox **writable** base, not the stale read-only
`/tmp/cwf-…`. This is the bug's success criterion met end-to-end.

## Test Failures
None. The only failure surfaced during execution was the pre-existing
`t/backlog-bootstrap-changelog.t` hardcoded-`/tmp` defect (same bug class), fixed
in f-implementation-exec; it now passes.

## Coverage Report
Full suite: **937 tests, all PASS** (74 files). New branch coverage: 100% — every
arm of the three-way resolver (env / probe-adopted / four `/tmp` fall-throughs)
has a dedicated case. `cwf-manage validate`: OK.

## Changeset Reviews

Testing-exec MAP (security + best-practice). Changeset 1104 lines, 12 files,
anchor `ba88c17`. Classifier verdicts (`security-review-classify`): both
**no findings**.

### Security Review
**State**: no findings

Narrow self-validating resolver branch: no new shell construction, no
untrusted-string flow into LLM context, no new env-var trust boundary (probe
derives from numeric `$>`). The two category-(e) patterns (stat-buffer reuse
gated by `!-l`; adopting a writable probe dir) are parity with the existing
`/tmp` fallback and bounded by the documented single-user trust model; the
multi-user pre-creation case is explicitly out of model, same as today's `/tmp`.
TOCTOU window unchanged and backstopped by `scratch_dir`'s leaf guard. Hash
refresh internally consistent (validate's job).

### Best-Practice Review
**State**: no findings

Resolved `golang`/`postgres` corpora read OK but inapplicable — changeset is
Perl/Markdown/JSON with no Go or SQL. Language-agnostic asides (return-early,
Rule of Three, document exported decls, test-every-branch) are independently
honoured (idiom reuse, both export and doc-comment updated, TC-9..TC-14 cover
every arm).

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Live end-to-end acceptance (deleting `$TMPDIR` to mimic the unsandboxed hook) proved the
fix against the real environment, not just the unit seam. Self-verifying preconditions
kept TC-12/TC-13 from silently skipping. See j-retrospective.md.

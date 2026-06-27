# TC-VALIDATE in-flight false-failure - Implementation Execution
**Task**: 211 (bugfix)

## Task Reference
- **Task ID**: internal-211
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/211-tc-validate-in-flight-false-failure
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

### Step 1: TC-VALIDATE (`t/security-review-changeset.t:1297`)
- **Planned**: Drop `my $pid`/`my $rc`/`is($rc,0)`; add liveness `like` + WHY comment;
  keep both `unlike` checks and the `or die` fork guard; tighten the subtest title.
- **Actual**: Done exactly as planned. Subtest now asserts three things — the liveness
  `like($output, qr/validate: OK|\d+ violation\(s\) found/)`, then the two file-scoped
  `unlike` checks. Title changed to "TC-VALIDATE: no integrity violation for the changed
  script + agent".
- **Deviations**: None.

### Step 2: TC-10 (`t/exec-changeset-reviewers.t:210`)
- **Planned**: Identical treatment above the `for my $lens (@LENSES)` `unlike` loop.
- **Actual**: Done. Dropped `my $pid`/`my $rc`/`is($rc,0)`; added the same liveness `like`
  and WHY comment; the per-lens `unlike` loop and `or die` are unchanged.
- **Deviations**: None.

### Step 3: Verify (per e-testing-plan.md)
- **TC-A (mid-flight no false-fail)**: both edited subtests run green with task 211 in-flight
  (non-terminal phase Statuses present). Pre-fix the `is($rc,0)` would have gone red.
- **TC-C (liveness)**: the `like` regex matches `cmd_validate`'s always-printed verdict
  banner (`validate: OK` / `N violation(s) found`, `cwf-manage:619,632`); empty `$output`
  would fail it — the `unlike` checks can no longer pass vacuously.
- **TC-D (full suite)**: `prove t/` → 73 files, 882 tests, all successful.
- **TC-B (named-file regression)**: deferred to g-testing-exec (requires a reverted
  perturbation of a named hashed file); the retained `unlike` checks are unchanged so
  coverage is structurally intact.

## Blockers Encountered

The first full `prove t/` showed one unrelated failure: `t/cwf-manage-fix-security.t`
TC-8 flagged the three Task-210 lens-reviewer agent files at on-disk `0400` against
their recorded floor `0444`. Root cause: a `cwf-manage fix-security` run earlier this
session clamped them `0600 → 0400` (`0600 & 0444 = 0400`); `validate` accepts that
(recorded perms are a ceiling) but TC-8 treats the recorded value as a provisioning
floor. Fixed on-sight per the standing permission-drift rule by restoring the recorded
`0444`. This is non-exec-bit drift on tracked files, so it is invisible to git and does
**not** enter this task's commit. After the fix, `validate: OK` and the full suite is green.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (the kept `unlike` checks satisfy the
      "still catches a genuine violation" criterion; "fixture clean-repo assertion" was
      explicitly rejected at design in favour of dropping the aggregate assertion)
- [x] N/A — no b-requirements-plan.md (bugfix)
- [x] All design guidance in c-design-plan.md followed (both subtests; `or die` preserved)
- [x] No planned work deferred without user approval (TC-B is a g-phase verification step,
      not implementation work)

## Changeset Reviews (Step 8 — five-reviewer MAP, all launched in parallel)
Branch `bugfix/211-...` (not main); security changeset 821 lines / 9 files / 0 production;
best-practice-resolve returned 2 matches → all five reviewers launched. Each verbatim
output is in the task scratch dir; tokens below are the shared `security-review-classify`
verdicts.

### Security Review
**State**: no findings

Test-only change to two Perl `.t` files. Edits fork `cwf-manage validate` via shell-free
list-form `open(..., '-|', $mgr, 'validate')` (no metacharacter surface; paths are
FindBin-derived, not user input). No new `system`/backtick, no env-var handling, no
prompt-injection vector, no NUL-split path handling. The change drops only a fragile
whole-repo exit-code coupling; `cwf-manage validate` — the actual SHA256/permission gate —
is untouched, so no tampering signal is smoothed. No actionable security findings.

### Best-Practice Review
**State**: no findings

Resolved sources are Go/Postgres-specific; the changeset is Perl test + CWF markdown, so
none applies. The one transferable testing principle (avoid brittle tests coupled to
environmental state) is upheld — the change removes exactly that coupling. The tag
mismatch is a known input-resolution concern already flagged in the design/impl plans
(existing backlog item to narrow best-practice active-tags for CWF-internal Perl/Markdown).

### Improvements Review
**State**: no findings

Minimal in-place edits (delete `$pid`/`$rc`/`is($rc,0)`, add one `like`). Correctly
declines new fixture machinery (Option (a) rejected at design, Rule of Three). The
two-file duplication is below the abstraction threshold and matches repo convention; a
shared helper would add net-new coupling (neither file uses `CWFTest::Fixtures`). No
production code, hashes, or docs touched.

### Robustness Review
**State**: no findings

Verified the load-bearing claim against `cwf-manage:41,619,632` — both verdict banners
(`validate: OK` / `N violation(s) found.`) reach stdout, so the liveness `like` is
environment-independent. The vacuous-pass edge (empty/banner-less output) now fails
loudly. Confirmed `cmd_validate` violation output cannot inject the changed-file names
into `$output`, so the retained `unlike` regression coverage is preserved. Sound.

### Misalignment Review
**State**: no findings

Reuses existing Test::More idioms (`like`/`unlike`, 86 uses) and the verified
`cwf-manage validate` stdout contract. Grep of `t/` for the `open('-|',$mgr,'validate')`
pattern found precisely the two treated sites — no untreated twin; the per-binary
`is($rc,0)` helper-exit checks (a different legitimate pattern) are correctly untouched.
Phase docs follow the standard CWF template.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
`fix-security` can leave a hashed file *below* its recorded perms (`0600 & 0444 = 0400`),
which `validate` accepts (ceiling) but `fix-security.t` TC-8 rejects (floor). Restore to
the exact recorded value. See j-retrospective.md Key Learnings.

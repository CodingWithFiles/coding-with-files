# TC-VALIDATE in-flight false-failure - Implementation Plan
**Task**: 211 (bugfix)

## Task Reference
- **Task ID**: internal-211
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/211-tc-validate-in-flight-false-failure
- **Template Version**: 2.1

## Goal
Remove the fragile whole-repo `is($rc, 0)` aggregate assertion from both
changeset-reviewer integrity subtests, leaving the file-scoped `unlike` checks.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `t/security-review-changeset.t` — TC-VALIDATE subtest (`:1297`): remove the
  `my $rc = $? >> 8;` line and the `is($rc, 0, ...)` assertion; add a comment
  explaining why no aggregate exit-code assertion belongs here.
- `t/exec-changeset-reviewers.t` — TC-10 subtest (`:210`): identical change
  (remove `my $rc`, remove `is($rc, 0, ...)`, add the same explanatory comment).

### Supporting Changes
- None. No production code, no hashes, no docs change. (`security-review-changeset`,
  `cwf-manage`, and the agent files are untouched, so `script-hashes.json` is
  unaffected.)

## Implementation Steps
### Step 1: TC-VALIDATE (`t/security-review-changeset.t`)
- [ ] Delete `my $rc = $? >> 8;` (dead once the assertion is gone).
- [ ] Delete `is($rc, 0, 'cwf-manage validate exits 0 (fully clean)') or diag($output);`.
- [ ] Drop the now doubly-unused `my $pid =` — make it a bare
      `open(my $fh, '-|', $mgr, 'validate') or die "fork cwf-manage: $!";`
      (3 reviewers flagged `$pid` dead; we are editing this line regardless).
- [ ] Add a liveness assertion so the `unlike` checks cannot pass vacuously when
      validate runs-but-dies-early (empty `$output`):
      `like($output, qr/validate: OK|\d+ violation\(s\) found/, 'validate ran to a verdict');`
      — `cmd_validate` always ends on stdout with one of these two banners
      (`cwf-manage:619,632`), so this is outcome- and environment-independent.
- [ ] Add the WHY comment (see Code Changes) above the retained checks.
- [ ] Keep `do { local $/; <$fh> }`, `close $fh`, `$output //= ''`, and both `unlike`
      checks unchanged.
- [ ] Tighten the subtest description string from "is clean" to reflect the
      file-scoped intent ("has no integrity violation for the changed script + agent").

### Step 2: TC-10 (`t/exec-changeset-reviewers.t`)
- [ ] Same edits: drop `my $rc`/`is($rc, 0)`; drop `my $pid =`; add the same liveness
      `like` and WHY comment above the retained per-lens `unlike` loop; keep the loop.

### Step 3: Verify (detail in e-testing-plan.md)
- [ ] Run both files mid-flight (task 211 in-flight) — previously-red subtests now green.
- [ ] False-failure regression pin: with deliberate *unrelated* in-flight drift present
      (e.g. a placeholder phase Status, or a transient perm bump on an unrelated file),
      confirm both subtests stay green — this is the actual bug being fixed.
- [ ] Vacuous-pass guard: confirm the liveness `like` fails if validate emits nothing.
- [ ] Positive coverage pin: confirm the `unlike` checks still fail when a *named*
      hashed file is perturbed, then restore.
- [ ] Run full suite (`prove t/`) — no regressions.

## Code Changes
### Before (TC-VALIDATE, `t/security-review-changeset.t:1297`)
```perl
    my $pid = open(my $fh, '-|', $mgr, 'validate') or die "fork cwf-manage: $!";
    my $output = do { local $/; <$fh> };
    close $fh;
    my $rc = $? >> 8;
    $output //= '';
    unlike($output, qr{security-review-changeset},
           'no integrity violation names the changed helper');
    unlike($output, qr{cwf-security-reviewer-changeset},
           'no integrity violation names the migrated agent');
    is($rc, 0, 'cwf-manage validate exits 0 (fully clean)')
        or diag($output);
```
### After
```perl
    open(my $fh, '-|', $mgr, 'validate') or die "fork cwf-manage: $!";
    my $output = do { local $/; <$fh> };
    close $fh;
    $output //= '';
    # No `is($rc, 0)` whole-repo assertion: cwf-manage validate aggregates every
    # sub-validator over the live repo, so its exit code flips on unrelated
    # in-flight state (placeholder phase Statuses, transient perm/hash drift) —
    # environmental noise, not a property of this change. The file-scoped unlike
    # checks below are the actual AC8 assertion. The liveness check guards against
    # a validate that runs-but-dies-early passing the unlike checks vacuously;
    # the `or die` above guards a failed fork. (Task 211)
    like($output, qr/validate: OK|\d+ violation\(s\) found/,
         'cwf-manage validate ran to a verdict');
    unlike($output, qr{security-review-changeset},
           'no integrity violation names the changed helper');
    unlike($output, qr{cwf-security-reviewer-changeset},
           'no integrity violation names the migrated agent');
```
TC-10 (`t/exec-changeset-reviewers.t:210`) gets the identical treatment: drop
`my $pid`/`my $rc`/`is($rc,0)`, add the same liveness `like` and comment above its
`for my $lens (@LENSES)` `unlike` loop.

## Plan Review Notes
- **Robustness (load-bearing, applied)**: `or die` guards only fork failure, not a
  validate that runs-but-dies-early — `unlike` would pass vacuously. Added an
  environment-independent liveness `like` on the always-present verdict banner and
  corrected the comment. Verified `cmd_validate` always prints one of the two
  banners to stdout (`cwf-manage:618-633`).
- **Misalignment (applied)**: removal is correctly scoped to the two *aggregate*
  `cwf-manage validate` assertions; the ~35 `is($rc,0,'helper exits 0')` checks of the
  `security-review-changeset` binary are untouched (legitimate single-binary checks).
- **Dead `$pid` (applied)**: dropped on the lines we edit.
- **Hash impact (confirmed nil)**: test files are not in `script-hashes.json`.
- **Best-practice**: resolved tags (golang/postgres) do not bind this Perl change;
  the one transferable testing principle (determinism/focus) supports the fix.

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
The liveness `like` was the load-bearing addition; verifying its banners always reach
stdout (`cwf-manage:41,619,632`) before relying on it was essential and was re-checked
independently by two exec reviewers. See j-retrospective.md.

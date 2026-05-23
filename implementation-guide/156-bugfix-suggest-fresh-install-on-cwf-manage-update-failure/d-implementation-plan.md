# suggest fresh install on cwf-manage update failure - Implementation Plan
**Task**: 156 (bugfix)

## Task Reference
- **Task ID**: internal-156
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/156-suggest-fresh-install-on-cwf-manage-update-failure
- **Template Version**: 2.1

## Goal
Implement suggest fresh install on cwf-manage update failure following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/scripts/cwf-manage` — three edits (see Implementation Steps):
  1. declare `my $update_in_progress = 0;` immediately before `sub die_msg` (line 45)
  2. extend `die_msg` to print the fresh-install suggestion to STDERR when the flag is set
  3. set `$update_in_progress = 1;` in `cmd_update` immediately before the laydown dispatch (`if ($method eq 'subtree')`, currently line 406)

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh the `sha256` for the `cwf-manage` entry (line 207) in the **same commit** as the edit above (hash-updates convention; current digest `1311378e…0777`, validate currently clean = no pre-existing drift).
- `t/cwf-manage-update-end-to-end.t` — add hint presence/absence subtests. (Authoring detail lives in e-testing-plan.md; listed here as the touched file.)

## Implementation Steps
### Step 1: Source edits to `cwf-manage`
- [ ] Add `my $update_in_progress = 0;` with the never-reset invariant comment, directly above `sub die_msg` (line 45) — declared first so `die_msg` and `cmd_update` both close over it.
- [ ] In `die_msg`, after the existing `print STDERR "[CWF] ERROR: @_\n";`, add `if ($update_in_progress) { print STDERR …5 lines… }` per the design code sketch. Keep the bootstrap line's `<tag>`/`<source-url>` **literal** (guardrail — do not interpolate live `$source`/`$resolved`).
- [ ] In `cmd_update`, insert `$update_in_progress = 1;` on its own line immediately before `if ($method eq 'subtree') {` (after checkout at line 404, before the laydown branch).

### Step 2: Hash refresh (same commit)
- [ ] `sha256sum .cwf/scripts/cwf-manage` to compute the new digest.
- [ ] Replace the `sha256` value at `.cwf/security/script-hashes.json:207` with the new digest.
- [ ] `.cwf/scripts/cwf-manage validate` → expect `validate: OK`.

### Step 3: Regression check
- [ ] Run `prove t/cwf-manage-update.t t/cwf-manage-update-end-to-end.t t/validate-security.t` to confirm no regressions before the testing phase adds new assertions.

## Code Changes
See c-design-plan.md "Code Sketch" — the exact `die_msg` body and flag-set line are specified there; not duplicated here.

## Test Coverage
**See e-testing-plan.md for complete test plan** — positive (laydown failure → hint) and negative (pre-flight guard + clone/checkout failure → no hint) assertions in `t/cwf-manage-update-end-to-end.t`.

## Validation Criteria
- `cwf-manage validate` clean after the hash refresh.
- Existing `cwf-manage` update/security tests pass unchanged.
- **See e-testing-plan.md for the new-assertion test plan.**

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

**Decomposition check**: No signals triggered — three small edits to one script + one hash-line refresh.

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Three edits + same-commit hash refresh applied exactly as planned; no deviations. See f-implementation-exec.md.

## Lessons Learned
See j-retrospective.md.

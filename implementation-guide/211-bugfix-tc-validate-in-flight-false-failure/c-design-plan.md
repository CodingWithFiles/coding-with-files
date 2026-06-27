# TC-VALIDATE in-flight false-failure - Design
**Task**: 211 (bugfix)

## Task Reference
- **Task ID**: internal-211
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/211-tc-validate-in-flight-false-failure
- **Template Version**: 2.1

## Goal
Decide how the changeset-reviewer integrity subtests should assert the changed
helper/agents are integrity-clean without coupling to whole-live-repo validate state.

## Scope (two instances of one defect-class)
Plan review surfaced that this is a defect *class* with two live instances, both
matching the same shape (fork `cwf-manage validate`, then a broad `is($rc, 0)`
aggregate assertion alongside correctly-scoped `unlike` checks):
- `t/security-review-changeset.t` TC-VALIDATE (`:1297`) — the originally-reported one.
- `t/exec-changeset-reviewers.t` TC-10 (`:210`, added in Task 210) — its twin.
Both are fixed identically. Fixing one and leaving the other would re-plant the same
mid-flight landmine, so both are in scope.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Investigation Findings (measure twice)
- TC-VALIDATE (`t/security-review-changeset.t:1297`) makes three assertions:
  1. `unlike($output, qr{security-review-changeset})` — no violation names the helper;
  2. `unlike($output, qr{cwf-security-reviewer-changeset})` — none names the agent;
  3. `is($rc, 0, 'cwf-manage validate exits 0 (fully clean)')` — **whole repo** clean.
  Only #3 is fragile mid-flight.
- `cwf-manage validate` aggregates nine sub-validators (`cwf-manage:603-615`),
  including `CWF::Validate::Workflow` (flags any phase-file `Status` not in
  `cwf-project.json`, e.g. "Planning") and `CWF::Validate::Security` (flags perm/
  hash drift). Any of these can fail for reasons unrelated to the change under test
  — confirmed live this task: Task-210 agent files were 0600-vs-recorded-0444.
- `cwf-manage validate` resolves its target via `find_git_root()` and validates the
  **main worktree** (`cwf-manage:94`); it cannot be aimed at a temp dir
  (MEMORY: end-to-end validate tests must use the real repo).
- `make_synthetic_repo` (`t/security-review-changeset.t:56`) builds a *minimal* git
  repo: README seed + one `implementation-guide/<task>/a-task-plan.md`. It has no
  `.cwf/`, no `script-hashes.json`, no agents. It is not a CWF install.

## Key Decisions
### Architecture Choice
- **Decision**: **Option (b)** — remove the broad `is($rc, 0)` whole-repo assertion;
  retain the two file-scoped `unlike` checks as TC-VALIDATE's complete assertion set.
  Add a comment documenting *why* the exit-code assertion is deliberately absent, so
  a future reader does not "helpfully" re-add it.
- **Rationale**:
  - AC8's actual intent is "the same-commit hash refresh is consistent **for the
    changed helper + agent**." That is exactly what the two `unlike` checks verify:
    if validate finds a violation naming either file, the check fails (regression
    caught); if validate is clean, or fails only on *unrelated* files, neither name
    appears and the checks pass (no false failure).
  - The `is($rc, 0)` assertion adds no scoped coverage — it only additionally demands
    the entire repo validate clean, which is environmental state, not a property of
    this change. That coupling is the defect.
  - Whole-repo "validate exits 0 on a clean tree" is environmental state, not a
    property of this change; these file-scoped subtests need not (and structurally
    cannot, mid-flight) re-assert it. (No claim is made that another test re-asserts
    the aggregate exit code: `t/validate-workflow.t` only unit-tests the
    `CWF::Validate::Workflow` module, not the `cwf-manage validate` aggregate. The
    deletion is justified by the property being out-of-scope, not by redundancy.)
- **Trade-offs**:
  - (+) Minimal, test-only, robust to mid-flight runs; no new fixture machinery.
  - (+) Preserves real regression coverage on the changed files.
  - (−) Loses a live "repo is fully clean" signal from these subtests — accepted,
    because that signal is environmental noise here, not a property of the change.
  - (−) Also loses the incidental "validate actually executed" guard the `is($rc,0)`
    gave: the `unlike` checks pass vacuously if validate emits no output. Mitigated —
    the existing `open('-|', ...) or die "fork cwf-manage"` aborts the subtest on a
    fork failure, so a non-running validate fails loudly rather than passing green.
    Implementation MUST preserve that `or die`.

### Rejected: Option (a) — fixture-scoped exit-0 assertion
`cwf-manage validate` validates the resolved git root, not a passed path, and
`make_synthetic_repo` produces no CWF install to validate. Making (a) work would mean
standing up a full `.cwf/` tree (hashes, agents, perms) inside a fixture purely to
re-assert a property `t/validate-workflow.t` already covers — disproportionate, and a
new abstraction with no second caller (fails Rule of Three).

### Rejected: tolerant exit-code assertion
"`rc == 0` OR (violations present but none name our files)" reintroduces the exact
classify-the-noise fragility we are removing: distinguishing acceptable in-flight
noise from a real unrelated problem is unbounded and not these subtests' job.

## System Design
### Component Overview
- **TC-VALIDATE** (`t/security-review-changeset.t`): asserts the changed helper and
  migrated agent carry no integrity violation in live `cwf-manage validate` output.
- **TC-10** (`t/exec-changeset-reviewers.t`): asserts the three new lens agents carry
  no integrity violation in live `cwf-manage validate` output (per-lens `unlike`).
Both: drop the broad `is($rc, 0)`; keep the file-scoped `unlike` checks; keep the
`or die` on the fork; add a comment so the assertion is not re-added.

### Data Flow (both subtests)
1. Subtest forks `cwf-manage validate` (`open('-|', ...) or die`), captures stdout.
2. Asserts no changed-file name appears in the violation output (`unlike` checks).
3. (Removed) no longer asserts the aggregate exit code.

## Interface Design
No interface changes. Test-internal only; `security-review-changeset`,
`cwf-manage`, and the agent files are untouched.

## Constraints
- Test-only change; no production code touched.
- Reuse existing scaffolding; add no new fixture machinery.
- Preserve the `or die` fork guard in both subtests (vacuous-pass safeguard).

## Decomposition Check
- [x] No signals triggered — two identical one-line edits to the same defect-class
  across two test files (see a-task-plan.md). Same change, no isolation needed.

## Plan Review Notes
- Misalignment reviewer found the TC-10 twin and the inaccurate `t/validate-workflow.t`
  cross-reference — both folded in above (scope widened; claim corrected).
- Improvements/robustness reviewers flagged the vacuous-pass edge — `or die` guard
  retention added to trade-offs and constraints.
- Best-practice reviewer's resolved tags (golang/postgres) do not match this Perl
  test change — no plan content affected; relates to existing backlog item "Narrow
  best-practice active-tags for CWF internal Perl/Markdown tasks".

## Validation
- [x] Design review completed (plan-review subagents, Step 8)
- [x] Architecture choice documented with rationale and rejected alternatives
- [x] Integration points verified — no production interfaces touched

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
Rejecting Option (a) on Rule-of-Three held up: no second caller ever materialised, so the
fixture machinery would have been dead weight. The deletion's real risk was its incidental
coverage (vacuous pass), addressed at impl review. See j-retrospective.md.

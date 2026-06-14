# report whether parent branch is direct ancestor - Rollout
**Task**: 202 (feature)

## Task Reference
- **Task ID**: internal-202
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/202-report-whether-parent-branch-is-direct-ancestor
- **Template Version**: 2.1

## Goal
Define how the tri-state parent-branch-ancestry signal reaches CWF users and how it is
backed out if it misbehaves.

## Deployment Strategy
### Release Type
- **Strategy**: Standard CWF release. The change lands on `main` (squashed), is tagged
  `v1.1.202` by the maintainer, and reaches existing installs via `cwf-manage update`.
  New installs receive it through `INSTALL.md` / the installer. There is no server,
  no fleet, and no per-user cohorting — every install gets the same files.
- **Rationale**: CWF is a file-based system distributed by git; the unit of rollout is
  the release tag. The change is **purely additive** — `context-manager hierarchy` gains
  one JSON field (`parent_branch_is_ancestor`) and one conditional markdown line; no
  existing field, exit code, or output line changes. Nothing in the codebase yet *reads*
  the new field, so shipping it to 100% of installs at once carries no behavioural change.
  The signal is informational: it tells an agent whether a subtask's parent branch is a
  direct ancestor of HEAD (strict-linear history) or has diverged.
- **Rollback Plan**: Backed out by reverting the task commit (removes the `run_quiet`
  hoist, `parent_branch_ancestry`, the hierarchy output lines, the `delete` refactor, and
  the four integrity entries) and cutting a follow-up tag; `cwf-manage rollback` restores
  the prior installed release for an individual user. No state migration — the signal is
  recomputed from git on every `hierarchy` call.

### Pre-Deployment Checklist
- [x] Code review completed — exec-phase security review: no findings (see f-implementation-exec.md)
- [x] All tests passing — TC-1…TC-9 + regression suite (67 files, 807 tests) green (see g-testing-exec.md)
- [x] Security scan — `cwf-manage validate` → OK (four refreshed hashes match; scripts `0500`)
- [x] Performance validated — two extra `git` calls (`rev-parse`, `merge-base`) per
      `hierarchy` invocation on a *parented* task only; negligible, gated behind the
      existing `parent_path` resolution
- [x] Documentation updated — additive field self-documents via the markdown line; the
      tri-state contract is recorded in c-design-plan.md
- [x] Registration configured — no new file; edits are to already-tracked, hash-managed
      scripts/libs (`Common.pm`, `TaskPath.pm`, `hierarchy`, `delete`)
- [x] Rollback verified — additive-only change; revert restores byte-identical prior output

## Rollout Plan
### Phase 1: Ship the signal
- **Scope**: All installs that take the release. `context-manager hierarchy` emits the
  new field/line on every parented-task invocation; top-level tasks are unaffected
  (no parent → no line, `null` in JSON).
- **Duration**: Immediate and permanent — no opt-in gate.
- **Success Metrics**: Pre-existing `hierarchy` JSON fields and exit code unchanged
  (TC-8); downstream consumers (`statusaggregator`, `contextinheritance`) stay green.

### Phase 2: Consumers adopt the signal (out of this task's scope)
- **Scope**: Future work may surface the divergence signal in workflow guidance (e.g.
  warn when a subtask's parent branch has diverged from HEAD, undermining the
  archaeological-main strict-linear assumption).
- **Mechanism**: Read `parent_branch_is_ancestor` from the `hierarchy --format=json`
  output. The tri-state (`true`/`false`/`null`) lets a consumer distinguish *diverged*
  from *undecidable* (no parent, missing branch, unborn HEAD).
- **Success Metrics**: Consumers treat `null` as "no assertion", never as "diverged".

## Monitoring
### Key Metrics
- **Behaviour**: `hierarchy` continues to function; no change to existing fields/lines.
- **Integrity**: `cwf-manage validate` reports the four refreshed hashes matching.
- **Errors**: The ancestry probe is fail-soft — any git error (unborn HEAD, missing
  branch) yields `undef` → `null`/`unknown`, never a crash or wrong assertion.

### Alerting
- No automated alerting (file-based local tool). The operator's signal is
  `cwf-manage validate` and the test suite.

## Rollback Plan
### Triggers
- `hierarchy` emits a wrong ancestry verdict (e.g. asserts `true` where branches diverged).
- `cwf-manage validate` reports a hash mismatch on any of the four edited files
  (integrity signal — surface, never smooth).
- A regression in `delete` traced to the shared-`run_quiet` refactor.

### Procedure
1. **Operator-level**: `cwf-manage rollback` to the prior release.
2. **Project-level**: Revert the Task 202 commit (drops the function, the hierarchy
   output, the delete refactor, the integrity entries) and cut a follow-up release tag.
3. **Communication**: Note in the release/CHANGELOG that the signal was withdrawn.
4. **Analysis**: Root-cause via the retrospective.

## Success Criteria
- [x] Purely additive — no existing field/line/exit-code changes
- [x] Fail-soft — git errors degrade to `null`/`unknown`, never a wrong verdict
- [x] Integrity verified — `cwf-manage validate` OK after the hash refresh
- [x] Tri-state contract documented (distinguishes diverged from undecidable)
- [x] Rollback path is a plain commit revert + tag; no state migration

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout plan recorded. The artefact is ready to ship in the next CWF release; it is a
purely additive signal that no consumer yet reads, and fail-soft so it cannot produce a
wrong verdict. Tagging and release are human-only actions and are not performed here.

## Lessons Learned
*Consolidated in j-retrospective.md.*

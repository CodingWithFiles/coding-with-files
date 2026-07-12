# unresolved-decisions gate for a-task-plan - Rollout
**Task**: 228 (feature)

## Task Reference
- **Task ID**: internal-228
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/228-unresolved-decisions-gate-a-task-plan
- **Template Version**: 2.1

## Goal
Define deployment strategy and rollout plan for the unresolved-decisions gate for a-task-plan.

## Deployment Strategy
### Release Type
- **Strategy**: Single-step ship via the normal CwF release path — squash the task branch,
  fast-forward `main`, then a human tags `v1.1.228` and cuts the release. End users receive
  the change on their next `cwf-manage update`. No phased/canary rollout applies: this is a
  guidance-only edit to three documentation/template/skill files, not a runtime service.
- **Rationale**: The changeset is Markdown only (`planning.md`, `a-task-plan.md.template`,
  `cwf-task-plan/SKILL.md`). There is no binary to deploy, no migration, no user-data path, and
  no runtime code to fail. The blast radius is "the next `a-task-plan` a user generates gains an
  `## Open Decisions` section and an outcome-shaped-criteria note" — additive and inert until
  authored against. All three files are untracked by `script-hashes.json`, so consumers see no
  hash/permission drift on update.
- **Rollback Plan**: `git revert` the squash commit (or `cwf-manage rollback` on an installed
  copy) restores the prior template/skill/doc verbatim. Because the change is additive and
  content-keyed structural readers ignore the new section (TC-3), revert is clean and
  side-effect-free — no data to migrate back, no generated artefacts to purge.

### Pre-Deployment Checklist
- [x] Code review completed and approved — 7 changeset-reviewer runs across f/g (security,
      best-practice, improvements, robustness, misalignment); all clean bar one misalignment
      finding (backtick convention) fixed in-phase before the f checkpoint.
- [x] All tests passing — TC-1..TC-6 all PASS (g-testing-exec.md); additivity proven by
      structural-reader regression, not asserted.
- [x] Security scan completed with no critical issues — no executable/Perl/shell/env-var or new
      prompt-injection surface across FR4(a–e); `cwf-manage validate` → `[CWF] validate: OK`.
- [x] Performance testing — N/A: no runtime cost (guidance-only, no check shipped per design D1).
- [x] Documentation updated — the change *is* documentation; `planning.md` is the single source
      of truth, template and skill reference it rather than restating (no duplication).
- [x] Monitoring and alerting configured — N/A: no runtime metrics to emit.
- [x] Rollback plan tested — trivially reversible single-commit `git revert` (see above).

## Rollout Plan
### Phase 1: Limited Release
- **Scope**: This repo (dogfood). The gate is live for CwF's own `/cwf-task-plan` runs the moment
  the branch merges to `main` — CwF develops CwF, so the maintainer is the first user.
- **Duration**: Continuous — exercised by the next in-repo task's planning phase.
- **Success Metrics**: The next `a-task-plan` generated in this repo carries `## Open Decisions`
  and the criteria note; the skill's two new `## Success Criteria` items are checked.

### Phase 2: Gradual Rollout
- **Scope**: N/A as a distinct phase. External users pull the change atomically on their next
  `cwf-manage update`; there is no server-side percentage dial to turn.

### Phase 3: Full Release
- **Scope**: All CwF installations, on `cwf-manage update` after the `v1.1.228` tag is published.
- **Monitoring**: None runtime. Effectiveness is observed qualitatively — whether future
  `a-task-plan` files name their open decisions and keep criteria outcome-shaped.

## Monitoring
### Key Metrics
- **Performance**: N/A — no runtime code path.
- **Errors**: N/A — no executable surface; the only failure mode (structural-reader break from
  the inserted H2) was verified impossible in TC-3 (marker-based, not positional).
- **Adoption**: Qualitative — presence of a populated `## Open Decisions` section and
  outcome-shaped success criteria in subsequently generated plans.

### Alerting
- N/A — no runtime signals. Divergence surfaces at author time via the skill checklist gate, not
  via alerts.

## Rollback Plan
### Triggers
- The `## Open Decisions` prompt or criteria note proves confusing or noise-generating in practice.
- A structural reader is found to mis-parse the new section (not observed; TC-3 refutes it).

### Procedure
1. **Immediate**: `git revert` the `v1.1.228` squash commit on a task branch (no hotfix path
   needed — nothing is broken at runtime).
2. **Rollback**: Ship the revert through the normal release path; users pick it up on
   `cwf-manage update`.
3. **Communication**: Note the reversal in `CHANGELOG.md` / release notes.
4. **Analysis**: Fold the confusion signal back into a follow-up refinement of `planning.md`.

## Success Criteria
- [x] Deployment path defined (squash → ff main → human tag → `cwf-manage update`).
- [x] Pre-deployment checklist completed (all items closed or justified N/A).
- [x] Rollback plan documented and confirmed trivially reversible.
- [x] Rollout phasing described honestly for a guidance-only docs change (no runtime phasing).
- [x] Next steps suggested.

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout is a documentation-distribution step: no runtime deployment, monitoring, or alerting
applies. The change ships atomically via the standard squash-to-main + human-tagged release,
reaches users on `cwf-manage update`, and is trivially reversible by a single-commit `git revert`.
All pre-deployment checks pass or are justified N/A.

## Lessons Learned
For a guidance-only docs change the rollout is a single squash-to-main + human tag; the
phased/monitoring scaffold is honestly marked N/A rather than fabricated.

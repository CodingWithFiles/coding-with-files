# Anti-fragile concept in robustness reviewer - Rollout
**Task**: 217 (hotfix)

## Task Reference
- **Task ID**: internal-217
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/217-anti-fragile-concept-in-robustness-reviewer
- **Template Version**: 2.1

## Goal
Define deployment strategy and rollout plan for Anti-fragile concept in robustness reviewer.

## Deployment Strategy
### Release Type
- **Strategy**: Merge the task branch to `main` (human action), then the change
  reaches CWF-using projects on their next `cwf-manage update`. No runtime
  service, no phased user rollout — the "artefact" is two reviewer-agent
  definition files + their refreshed `sha256` entries.
- **Rationale**: Standard CWF self-development flow. The edit is inert prose until
  a reviewer subagent next runs; there is nothing to stage or canary.
- **Effect on consumers**: the robustness reviewers gain the anti-fragile clause.
  Agent definitions are session-cached, so a running session picks up the new
  wording only on next session start (per [[feedback_agent_def_session_cache]]).

### Pre-Deployment Checklist
- [x] Changeset reviews completed (5 at f-exec, 2 at g-exec) — all no findings
- [x] All test cases pass (g-testing-exec.md: TC-1..TC-7 + regression)
- [x] Security review: no findings across FR4(a-e)
- [x] `cwf-manage validate` clean (sha256 + permissions)
- [x] Docs updated (the change IS the docs; CHANGELOG entry at retrospective)
- [ ] Merge to `main` — **human action** (suggested command in retrospective)

## Rollout Plan
Single step: fast-forward `main` to the task tip, then tag `v1.1.217` (both human
actions). No staged percentage rollout applies to a doc edit.

## Rollback Plan
### Triggers
- A reviewer clause is found to mislead (e.g. produces false-positive verdicts in
  practice) or the hash refresh is later shown wrong.

### Procedure
1. `git revert` the task's squashed commit (or drop it before the FF if not yet
   merged) — restores the prior reviewer prose and sha256 entries together.
2. `cwf-manage validate` to confirm the manifest matches the reverted files.
3. No consumer coordination needed — next `cwf-manage update` distributes the
   revert.

## Success Criteria
- [x] All gates green (reviews, tests, validate)
- [ ] Merge + tag performed by the human maintainer
- [ ] No revert required

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All pre-deployment gates green. Merge + tag pending human action.

## Lessons Learned
Rollback for a hashed-doc edit is a single `git revert` — it restores the reviewer
prose and its sha256 entry together, keeping `validate` consistent.

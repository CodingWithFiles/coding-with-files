# Sync README command reference - Plan
**Task**: 169 (chore)

## Task Reference
- **Task ID**: internal-169
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/169-sync-readme-command-reference
- **Baseline Commit**: 7c676c8bc1d9de833454a1040def80e9217f3a6e
- **Template Version**: 2.1

## Goal
Bring `README.md`'s command/skill reference back into agreement with what the
repo actually ships, after 62 tasks of drift since it was last touched (Task 106).

## Success Criteria
- [ ] README's skill list matches `.claude/skills/cwf-*` exactly — zero missing, zero phantom (verified by diff)
- [ ] Each documented command's argument form matches its `SKILL.md` usage line (no stale signatures)
- [ ] `cwf-manage` subcommands named in README match the helper's actual subcommand set
- [ ] An output-level grep of README finds no renamed/removed command names
- [ ] `cwf-manage validate` clean (incl. the Task 165 template-ref linter)

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None — README and the skill/helper sources are all in-tree

## Major Milestones
1. **Audit**: enumerate shipped skills, helper subcommands, and changed signatures; diff against README to produce a concrete add/change/remove gap list (the "properly identify" step)
2. **Update**: edit README to close the gap list, nothing wider
3. **Verify**: re-run the diff and `cwf-manage validate`; grep README for stale names

## Risk Assessment
### High Priority Risks
- **Scope creep**: README also carries architecture, install, and config prose that may have drifted too.
  - **Mitigation**: scope this task strictly to the command/skill reference and command signatures. Log any non-command prose drift as a separate backlog item rather than fixing it here.

### Medium Priority Risks
- **Over-documenting internals**: not every helper/subcommand is meant to be user-facing.
  - **Mitigation**: document only user-invocable skills (the `/cwf-*` set) and the publicly-referenced `cwf-manage` subcommands; exclude dev-only internals.
- **Re-drift**: README falls out of sync again after future skill changes.
  - **Mitigation**: out of scope to fix here; note in retrospective whether a mechanical skill-list check is worth a backlog item.

## Dependencies
- None external. All inputs (`README.md`, `.claude/skills/`, `.cwf/scripts/`) are in the working tree.

## Constraints
- Documentation-only change; no behavioural code touched.
- British spelling in prose; existing product/command names unchanged.

## Decomposition Check
- [ ] **Time**: <1 week — no
- [ ] **People**: single contributor — no
- [ ] **Complexity**: one concern (doc sync) — no
- [ ] **Risk**: no high-risk components — no
- [ ] **Independence**: not meaningfully separable — no

No signals triggered → no subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 169
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met. README synced to the shipped command surface; four
audited gaps closed (3 skills, discovery type, stale signatures, cwf-manage); validate clean.

## Lessons Learned
Scope-discipline risk (deferring non-command prose drift to BACKLOG) held — no scope creep
beyond one in-scope signature fix. See j-retrospective.md for the full write-up.

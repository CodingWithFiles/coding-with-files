# Remove obsolete Implemented status value - Plan
**Task**: 69 (bugfix)

## Task Reference
- **Task ID**: internal-69
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/69-remove-obsolete-implemented-status-value
- **Template Version**: 2.1

## Goal
Remove the `Implemented` status value, which became obsolete when v2.1 split implementation and testing into separate workflow files (`f-implementation-exec.md` and `g-testing-exec.md`), making the intermediate "code done, not yet tested" state meaningless.

## Background
`Implemented` (50%) was introduced in Task 4 for the v2.0 workflow, where a single file tracked both implementation completion and testing. In v2.1 (Task 25), these phases were split: `f-implementation-exec.md` tracks implementation (should be `Finished` when done), `g-testing-exec.md` tracks testing (separate file). There is no longer any workflow state where a file should sit at `Implemented` — it causes agents to leave `f-implementation-exec.md` at 50% indefinitely, breaking the 100% check before retrospective.

## Success Criteria
- [ ] `Implemented` removed from `cwf-project.json` status-values
- [ ] `Implemented` removed from `TaskState.pm` (DEFAULT_STATUS_MAP, `_is_active_work`, comments)
- [ ] `Implemented` removed from `workflow-steps.md` Status Values documentation
- [ ] `cwf-manage validate` exits 0 (script-hashes.json updated)
- [ ] No existing workflow files broken (confirmed: zero files currently use `Implemented`)

## Original Estimate
**Effort**: Trivial (<1 session)
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. Remove from config and library
2. Update docs and hashes
3. Retire BACKLOG workaround item ("Add Status Field Review to Pre-Retrospective Checklist")

## Risk Assessment
### Low Priority Risks
- **Existing files using Implemented**: Pre-checked — zero files in `implementation-guide/` currently have `**Status**: Implemented`
  - **Mitigation**: Grep confirms clean; validate will catch any missed during testing
- **TaskState.pm hash mismatch**: Editing TaskState.pm invalidates script-hashes.json
  - **Mitigation**: Regenerate hash as final step before validate

## Dependencies
- None

## Constraints
- No workflow files currently use `Implemented` — no migration needed
- `Implemented` must be removed from ALL locations consistently (config + library + docs + hashes)

## Decomposition Check
- [ ] **Time**: >1 week? — No
- [ ] **People**: >2 people? — No
- [ ] **Complexity**: 3+ distinct concerns? — No (all one coherent removal)
- [ ] **Risk**: High-risk components? — No
- [ ] **Independence**: Parts separable? — No

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 69
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*

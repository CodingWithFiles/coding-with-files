# cwf-init runs security check - Plan
**Task**: 120 (bugfix)

## Task Reference
- **Task ID**: internal-120
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/120-cwf-init-runs-security-check
- **Template Version**: 2.1

## Goal
`/cwf-init` verifies and repairs script permissions before completing, so a freshly initialised project can immediately run CWF skills without permission errors.

## Success Criteria
- [ ] `/cwf-init` runs `cwf-manage validate` (or equivalent permission/integrity check) after directory setup and before the init commit
- [ ] If any script under `.cwf/scripts/` lacks `u+rx`, `/cwf-init` fixes it (chmod) and reports the fix
- [ ] If `cwf-manage validate` reports SHA256 or other integrity violations, `/cwf-init` surfaces them as a clear failure rather than silently continuing
- [ ] An end-to-end test demonstrates: copy CWF into a fresh repo with permissions stripped → run `/cwf-init` flow → all scripts executable, validate passes
- [ ] Behaviour is idempotent: re-running `/cwf-init` on an already-initialised project does not regress permissions or duplicate fixes

## Original Estimate
**Effort**: 0.5 day
**Complexity**: Low
**Dependencies**: `cwf-manage validate` (already exists), `.cwf/security/script-hashes.json`

## Major Milestones
1. **Design**: Decide whether `/cwf-init` calls `cwf-manage validate` directly, gains a new sub-mode, or invokes `/cwf-security-check` — and where in the init sequence the check runs (before commit, after directory setup)
2. **Implement**: Wire the check into `cwf-init` SKILL.md (and any helper) with chmod-fix behaviour for missing exec bits
3. **Test**: Add a regression test that simulates the file-copy install scenario (permissions stripped) and asserts post-init state

## Risk Assessment
### Medium Priority Risks
- **Risk**: Auto-chmod could mask a real tampering signal (e.g. an attacker stripped exec bits as part of a larger change)
  - **Mitigation**: Only fix permissions when the file's SHA256 still matches `script-hashes.json`; otherwise fail loudly and refuse to chmod
- **Risk**: SHA256 verification may fail in a fresh install because `script-hashes.json` is a moving target between releases
  - **Mitigation**: Confirm during design that `cwf-manage validate` is stable for an installed release; otherwise scope this task to permissions only and treat hash verification as advisory

### Low Priority Risks
- **Risk**: Init commit may include unintended changes if the chmod step modifies the working tree right before `git add`
  - **Mitigation**: Run the check before `git add` and ensure only `.cwf/` permission changes are staged; document in design

## Dependencies
- `cwf-manage validate` semantics and exit codes
- `.cwf/security/script-hashes.json` being present and accurate at install time

## Constraints
- Bugfix workflow — no new user-visible features beyond the init flow
- Must not require new external tooling (chmod and existing helpers only)
- Keep `/cwf-init` advisory-friendly: clear messages on what was fixed vs what failed

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — half-day scope
- [ ] **People**: Does this need >2 people working on different parts? No
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — single skill change plus test
- [ ] **Risk**: Are there high-risk components that need isolation? No
- [ ] **Independence**: Can parts be worked on separately? No

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 120
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

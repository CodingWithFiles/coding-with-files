# Path-prefix retrospective-extras helper calls - Plan
**Task**: 216 (bugfix)

## Task Reference
- **Task ID**: internal-216
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/216-path-prefix-retrospective-extras-helper-calls
- **Baseline Commit**: f3f5eda924679215aef16f5f5c9e3faa0a2283f8
- **Template Version**: 2.1

## Goal
Give every helper invocation in `.cwf/docs/skills/retrospective-extras.md` the full `.cwf/scripts/command-helpers/` path prefix so the retrospective agent runs them directly instead of guessing then searching.

## Success Criteria
- [ ] All 3 `checkpoints-branch-manager` calls (Step 10) carry the `.cwf/scripts/command-helpers/` prefix
- [ ] Both `context-manager hierarchy` calls (Step 12) carry the prefix
- [ ] No bare command-helper invocation remains in `retrospective-extras.md` (grep-verifiable)
- [ ] Non-executed name references (Steps 9/11 pointing at SKILL.md) left unchanged

## Original Estimate
**Effort**: <0.5 day
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Fix**: Add path prefix to the 5 bare invocations in `retrospective-extras.md`
2. **Verify**: grep confirms no bare helper call remains; SKILL.md-pointer references untouched

## Risk Assessment
### Medium Priority Risks
- **Risk**: Over-reach — prefixing name-only references (Steps 9/11 `cwf-version-bump`/`cwf-version-tag`) that intentionally defer to SKILL.md, or touching unrelated docs.
  - **Mitigation**: Scope strictly to executed invocations inside fenced/inline commands; leave "see SKILL.md" pointers as prose names.

## Dependencies
- None (self-contained documentation fix)

## Constraints
- Single file changed: `.cwf/docs/skills/retrospective-extras.md`
- Not a hashed script — no `script-hashes.json` refresh needed

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — under half a day
- [ ] **People**: Does this need >2 people working on different parts? No
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — one doc, one concern
- [ ] **Risk**: Are there high-risk components that need isolation? No
- [ ] **Independence**: Can parts be worked on separately? No — single edit

No signals triggered — no decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 4 success criteria met. The 5 invocations (3 `checkpoints-branch-manager`, 2 `context-manager hierarchy`) were prefixed; the grep gate confirms no bare in-scope invocation remains; SKILL.md-pointer prose (86/118) left unchanged. Effort matched the <0.5 day estimate; no decomposition needed.

## Lessons Learned
The over-reach risk flagged here (prefixing Step 9/11 prose pointers) was the correct thing to guard — the plan review confirmed the line-scoped approach and the boundary held through exec.

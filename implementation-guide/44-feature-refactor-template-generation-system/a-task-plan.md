# refactor template generation system - Plan

## Task Reference
- **Task ID**: internal-44
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/44-refactor-template-generation-system
- **Template Version**: 2.1

## Goal
Enhance CIG templates to leverage Task 32's inference system, improve task-type visibility, fix broken cross-references, and add git workflow automation (checkpoint commits, auto-branch creation, squash-on-retrospective)

## Success Criteria
- [ ] All 10 templates have task type identifier in headers (line 2)
- [ ] All Next Action fields use task inference (no `<task>` parameters)
- [ ] Cross-references fixed: `e-testing.md` → `e-testing-plan.md`, `b-requirements.md` → `b-requirements-plan.md`, `c-design.md` → `c-design-plan.md`
- [ ] Decomposition checks present in a, b, c templates only (planning phases)
- [ ] Template copier infers phase sequences from symlink structure (not hardcoded)
- [ ] All workflow step docs instruct checkpoint git commits after completing each phase
- [ ] `/cig-new-task` auto-creates and checks out task branch (not just suggests it)
- [ ] `/cig-retrospective` creates `-checkpoints` branch and squashes task to one commit with "why"-focused message

## Original Estimate
**Effort**: 6-9 hours (1-2 days)
**Complexity**: Medium-High
**Dependencies**: Task 32 (inference system - completed), existing template pool structure, template-copier-v2.1 script, cig-new-task skill, cig-retrospective skill

## Major Milestones
1. **Template Content Updates**: All 10 pool templates updated with headers, cross-references, decomposition, and inference-ready next actions
2. **Template Copier Enhancement**: Script enhanced to infer sequences from symlinks and compute task-type-aware next actions
3. **Git Workflow Automation**: Checkpoint commits in templates, auto-branch creation in cig-new-task, squash-on-retrospective in cig-retrospective
4. **Verification Complete**: New templates tested with all 5 task types, git workflow tested, backward compatibility confirmed

## Risk Assessment
### High Priority Risks
- **Breaking Existing Workflow Commands**: Changes to template variables could break workflow command compatibility
  - **Mitigation**: Commands already support inference, `<task>` parameter ignored if present. Test all commands with new format before merge.

### Medium Priority Risks
- **Incorrect Next-Action Computation**: Dynamic computation could point to wrong next phase for task type
  - **Mitigation**: Infer phase sequences from actual symlink structure (single source of truth), not hardcoded maps
- **Broken Cross-References**: Filename changes could break inter-file references
  - **Mitigation**: Fix all references to use v2.1 naming (`e-testing-plan.md`), verify links resolve

## Dependencies
- Task 32 inference system (completed) - provides automatic task detection from context
- Template pool structure (`.cig/templates/pool/`) - single source of truth
- Task-type symlink directories (feature/bugfix/hotfix/chore/discovery) - define phase sequences
- template-copier-v2.1 script - handles template instantiation and variable substitution
- cig-new-task skill (`.claude/commands/cig-new-task.md`) - needs branch auto-creation
- cig-retrospective skill (`.claude/commands/cig-retrospective.md`) - needs checkpoint/squash logic
- Workflow step documentation (`.cig/docs/workflow/workflow-steps.md`) - needs checkpoint commit guidance

## Constraints
- Must maintain backward compatibility with existing tasks (1-43) using old format
- Cannot break symlink-based template selection (task types share pool files)
- Must preserve DRY principle (single source of truth in pool directory)
- Templates are filled once at creation, then edited manually (not dynamic documents)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated 6-9 hours (1-2 days)
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer task
- [x] **Complexity**: Does this involve 3+ distinct concerns? **Yes** - templates (10 files), copier logic, cross-references, git workflow (3 skills), but all related to workflow improvement
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - risks mitigated through testing
- [ ] **Independence**: Can parts be worked on separately? **Partially** - git workflow changes are independent of template changes, but doing together is efficient

**Decomposition Decision**: Not needed. While complexity increased with git workflow additions, total effort still < 1 week. Changes are all workflow improvements and benefit from being done together (we're already modifying templates and workflow docs).

## Status
**Status**: Finished
**Next Action**: Move to requirements phase → `/cig-requirements-plan 44`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

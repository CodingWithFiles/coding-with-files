# Research Claude Code best practices for CWF quality improvements - Plan
**Task**: 97 (discovery)

## Task Reference
- **Task ID**: internal-97
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/97-research-claude-code-best-practices-for-cwf-qual
- **Template Version**: 2.1

## Goal
Analyse Claude Code best practices documentation and identify actionable improvements for CWF's quality, context management, and agent process adherence.

## Success Criteria
- [x] Best practices documentation fully reviewed and compared against CWF current state
- [x] Gap analysis completed identifying where CWF diverges from recommended patterns
- [x] Actionable backlog items created for each viable improvement
- [x] User feedback captured on each suggestion (accepted, rejected, modified)
- [x] Discussion of agent enforcement limitations documented (process vs outcome validation)

## Original Estimate
**Effort**: 1 session
**Complexity**: Medium
**Dependencies**: Access to ../analysis/claude-code-best-practice repository

## Major Milestones
1. **Best practices review**: Read and synthesise all documents from the analysis repo
2. **Gap analysis**: Compare 10 suggestion areas against CWF current implementation
3. **Backlog population**: Create prioritised backlog items for accepted suggestions

## Risk Assessment
### High Priority Risks
- None — discovery task with no code changes

### Medium Priority Risks
- **Suggestions may not fit CWF's architecture**: Some best practices assume standard projects, not a meta-tool installed into other repos
  - **Mitigation**: Evaluate each suggestion against CWF's unique constraint (installed into third-party repos)

## Dependencies
- Claude Code best practices analysis repo at `../analysis/claude-code-best-practice`
- Understanding of CWF's current skill, hook, and rules architecture

## Constraints
- CWF is installed into other people's repos — suggestions must be portable
- No code changes in this task — discovery only, backlog items for implementation

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — single session
- [ ] **People**: Does this need >2 people working on different parts? No
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — research and catalogue
- [ ] **Risk**: Are there high-risk components that need isolation? No
- [ ] **Independence**: Can parts be worked on separately? No

0/5 signals triggered — no decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 97
**Blockers**: None

## Actual Results
Reviewed full best practices corpus (40+ files across 10 topic areas). Produced 10 suggestions, user accepted 6 as backlog items (2 high, 2 high discovery, 1 medium discovery, 1 medium chore), rejected 2 (context:fork, disable-model-invocation), deferred 1 (@import — current progressive disclosure approach is better for caching), elided 1 (notification hooks — not portable). Also sparked significant discussion on agent process enforcement limitations and Deming-inspired post-training approaches.

## Lessons Learned
- Path-scoped rules (`.claude/rules/`) are the closest thing to enforcement for skill usage — advisory but injected at the point of action
- Progressive disclosure via Read tool is better than @import for prompt cache stability
- Agent enforcement is fundamentally impossible with full system access — only outcome validation or model training can address it
- User has very strong preference for skill auto-triggering; never suggest disabling it

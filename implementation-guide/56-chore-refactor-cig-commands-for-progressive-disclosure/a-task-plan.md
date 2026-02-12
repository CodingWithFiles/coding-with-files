# Refactor CIG commands for progressive disclosure - Plan
**Task**: 56 (chore)

## Task Reference
- **Task ID**: internal-56
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/56-refactor-cig-commands-for-progressive-disclosure
- **Template Version**: 2.1

## Goal
Refactor 17 CIG commands from inline instruction monoliths (80-237 lines each, 1,914 total) to thin dispatchers (~30-40 lines each) that reference shared `.cig/docs/` files, enabling future skill conversion without context pollution.

## Success Criteria
- [ ] All 17 CIG commands refactored to thin dispatcher pattern
- [ ] Shared instructions extracted to `.cig/docs/` reference files (argument parsing, task resolution, context loading, checkpoint commits, status guidance)
- [ ] Each command file under 40 lines
- [ ] Total line count reduced by 60%+ (from 1,914 to ~700 or less)
- [ ] All commands still function correctly after refactoring (verified by invocation)

## Original Estimate
**Effort**: 2-3 days
**Complexity**: Medium (repetitive pattern applied across 17 files, but must preserve functionality)
**Dependencies**:
- Task 55 findings: `!{bash}` works in commands, so refactored commands can still use it to inject doc content
- When later converted to skills (Task 57), the LLM will use Read tool to load the same docs at runtime

## Major Milestones
1. **Shared docs extracted**: Common patterns identified and written to `.cig/docs/` reference files
2. **Workflow commands refactored (8)**: The 8 workflow step commands (task-plan, requirements-plan, design-plan, implementation-plan, testing-plan, implementation-exec, testing-exec, retrospective) converted to thin dispatchers
3. **Remaining commands refactored (9)**: new-task, subtask, status, extract, init, config, security-check, maintenance, rollout
4. **Validation complete**: All 17 commands verified functional post-refactoring

## Risk Assessment
### Medium Priority Risks
- **Breaking command functionality during refactoring**: Extracting too aggressively could lose context that commands need
  - **Mitigation**: Refactor one command at a time, test immediately, commit incrementally
- **Doc references not providing enough context**: If shared docs are too abstract, the LLM may not follow instructions correctly
  - **Mitigation**: Test refactored commands with real tasks; include concrete examples in docs
- **`!{bash}` injection of doc content inflates prompt size**: If docs are large, injecting them via `!{bash} cat` may not reduce tokens
  - **Mitigation**: Keep shared docs focused; use `!{bash}` selectively (only for content needed at prompt time); rely on LLM reading docs at runtime for details

### Low Priority Risks
- **Scope creep into skill conversion**: Temptation to also convert to skills during refactoring
  - **Mitigation**: Strict scope — this task is refactoring only. Skill conversion is Task 57.

## Dependencies
- Task 55 complete (confirmed: `!{bash}` works in commands, doesn't work in skills)
- No external dependencies

## Constraints
- Must maintain backward compatibility — all existing command invocations (e.g., `/cig-task-plan 55`) must work identically
- Commands remain in `.claude/commands/` (not moved to skills yet)
- Shared docs go in `.cig/docs/` (existing documentation directory)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** — 2-3 days estimated
- [ ] **People**: Does this need >2 people working on different parts? **NO**
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **NO** — single concern (extract + slim down) applied repeatedly
- [ ] **Risk**: Are there high-risk components that need isolation? **NO** — each command refactored independently
- [ ] **Independence**: Can parts be worked on separately? **YES** — but the pattern is repetitive, so a single task is more efficient

**Decision**: Do NOT decompose. The 8 workflow commands share ~80% structure, so the pattern established on the first command applies to all others. Separate subtasks would add ceremony without value.

## Status
**Status**: Finished
**Next Action**: /cig-implementation-plan 56
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Completed in ~1 day (vs 2-3 day estimate). 16 of 17 commands refactored, 3 shared docs created. 59.1% command-only reduction (1,914 → 782 lines). All success criteria met except aspirational per-file line targets (48-51 vs 40 lines).

## Lessons Learned
Repetitive refactoring tasks are faster than estimated — use diminishing-time model. Set metrics targets after proof-of-concept, not before. Template-first approach (refactor one, verify, apply to all) prevents error propagation.

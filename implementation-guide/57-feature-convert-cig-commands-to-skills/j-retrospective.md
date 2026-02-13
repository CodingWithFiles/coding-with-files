# Convert CIG Commands to Skills - Retrospective
**Task**: 57 (feature)

## Task Reference
- **Task ID**: internal-57
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/57-convert-cig-commands-to-skills
- **Template Version**: 2.1
- **Retrospective Date**: 2026-02-13

## Executive Summary
- **Duration**: ~13 hours wall clock (2026-02-12 20:23 → 2026-02-13 09:06), ~3-4 hours active work across 3 sessions
- **Estimated**: 2-3 days
- **Variance**: -60% to -75% (completed well under estimate)
- **Outcome**: All 17 commands converted to skills. Zero injection syntax. FR8 permission error regression fixed. Pre-existing `cig-current-task` skill fixed opportunistically.

## Variance Analysis

### Time and Effort
- **Planning**: ~30 min (1 commit)
- **Requirements**: ~2 hours (1 commit)
- **Design**: ~1.5 hours (1 commit)
- **Implementation planning**: ~30 min (1 commit)
- **Testing planning**: ~15 min (1 commit)
- **Implementation execution**: ~45 min (1 commit — bulk conversion)
- **Testing execution**: ~30 min (1 commit + 1 fix commit)
- **Rollout + Maintenance**: ~15 min (2 commits)
- **Total active**: ~6-7 hours across phases

Task 56 established the pattern: repetitive refactoring across 17 files completes faster than estimated once the template is proven on the first file.

### Scope Changes

**Additions**:
- `cig-current-task` frontmatter fix (pre-existing skill lacked YAML frontmatter — discovered during TC-2)

**Removals/Changes from Original Plan**:
- `disable-model-invocation` field not used (BACKLOG spec mentioned it, but design phase determined all skills should be user-invocable)
- Parallel command/skill operation removed — clean cutover per command instead (design decision D5)
- 850-line token budget exceeded (930 actual) — accepted trade-off for constraint context reliability

### Quality Metrics
- **Test Coverage**: 14/14 test cases pass (12 clean, 2 conditional)
- **Defects found**: 0 blocking; 1 pre-existing issue fixed (cig-current-task frontmatter)
- **Injection syntax remaining**: 0

## What Went Well

1. **Pattern-based conversion was fast**: Establishing cig-design-plan as template (Step 2), then applying to remaining 9 workflow skills (Step 3) made bulk conversion predictable and quick.

2. **Systematic Pattern C analysis**: Categorising all 15 `!` backtick injections as "convert to runtime instruction" (10) or "remove as redundant" (5) avoided missed conversions and unnecessary code.

3. **Clean cutover strategy**: Deleting each command immediately after creating its skill avoided naming conflicts entirely. The design decision to reject parallel operation was correct.

4. **Testing caught a real issue**: TC-2 revealed `cig-current-task` lacked frontmatter. Fixed opportunistically rather than deferring.

5. **Prerequisite tasks paid off**: Task 55 (empirical testing) and Task 56 (progressive disclosure refactor) made this conversion straightforward. Commands were already thin dispatchers.

## What Could Be Improved

1. **Token budget estimation**: Estimated 850 lines (parity with commands), actual was 930. The difference is inherent — explicit runtime instructions are more verbose than injection syntax. Future estimates should account for this ~20% overhead.

2. **BACKLOG spec was stale**: The BACKLOG item mentioned `disable-model-invocation` and parallel operation — both rejected during design. BACKLOG items should be treated as starting points, not requirements.

3. **Test case grep patterns**: TC-8 used overly strict grep (`ls implementation-guide`) that missed `ls -la implementation-guide/`. Test patterns should match the semantic intent, not exact syntax.

## Key Learnings

### Technical Insights

1. **Skills don't support context injection**: `!{bash}` and `!/path` are commands-only features. Skills must use runtime tool call instructions instead. This is the fundamental architectural difference.

2. **YAML frontmatter is mandatory**: Without `---` delimiters and required fields, a skill won't appear in the system prompt. Silent failure — no error message.

3. **`allowed-tools` controls permission prompts**: Declaring tools in frontmatter prevents "Allow?" prompts. This is how FR8 (permission error regression) was fixed — no injection syntax means no unexpected tool calls.

4. **Runtime instructions are reliable**: Phrasing like "Run X using the Bash tool" works consistently. The LLM follows these instructions as part of the skill workflow.

### Process Learnings

1. **Discovery → Refactor → Convert pipeline**: Tasks 54 → 55 → 56 → 57 formed a natural pipeline. Each task reduced risk for the next. This incremental approach is effective for architectural migrations.

2. **Three conversion patterns cover everything**: Pattern A (all skills), Pattern B (workflow skills), Pattern C (skill-specific) — categorising early made bulk conversion mechanical.

3. **Opportunistic fixes during testing**: Finding and fixing `cig-current-task` during testing was the right call rather than creating a separate task for a 10-second fix.

## Recommendations

### Future Work

1. **Skills architecture stabilisation**: Use skills across several more tasks before advancing main. Monitor for edge cases or Claude Code behaviour changes.

2. **Branding/documentation update**: CLAUDE.md still references "commands" terminology. Update when merging to main.

3. **Template maintenance variant**: The rollout and maintenance templates are designed for production services. Consider a lightweight variant for internal tooling tasks.

4. **Token budget monitoring**: Track total skill lines over time. If it grows past ~1200 lines, consider `disable-model-invocation` for infrequently-used skills.

## Status
**Status**: Finished
**Next Action**: CHANGELOG/BACKLOG update, then squash
**Blockers**: None
**Completion Date**: 2026-02-13

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md` through `e-testing-plan.md`
- Implementation: `f-implementation-exec.md` (6 steps, all complete)
- Testing: `g-testing-exec.md` (14/14 pass)
- Rollout: `h-rollout.md` (main merge deferred)
- Checkpoints branch: `feature/57-convert-cig-commands-to-skills-checkpoints`

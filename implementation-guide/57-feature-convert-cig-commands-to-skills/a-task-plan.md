# Convert CIG Commands to Skills - Plan
**Task**: 57 (feature)

## Task Reference
- **Task ID**: internal-57
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/57-convert-cig-commands-to-skills
- **Template Version**: 2.1

## Goal
Convert 17 CIG commands from `.claude/commands/cig-*.md` to `.claude/skills/cig-*/SKILL.md` format, replacing prompt-time context injection (`!{bash}`, `!/path`) with runtime tool call instructions, to adopt the skills system while maintaining full functionality.

## Success Criteria
- [ ] All 17 CIG commands converted to skills in `.claude/skills/`
- [ ] Each skill has correct SKILL.md frontmatter (name, description, user-invocable, allowed-tools)
- [ ] Context injection syntax replaced with runtime tool call instructions (Read/Bash)
- [ ] All skills functional and tested (sample invocations pass)
- [ ] Command files removed (clean cutover, no parallel operation — see Constraints)
- [ ] Token consumption measured (total skill content auto-loaded into context)

## Original Estimate
**Effort**: 2-3 days
**Complexity**: Medium (repetitive conversion pattern, but context injection replacement requires careful translation)
**Dependencies**:
- Task 55: Confirmed `!{bash}` and `!/path` don't work in skills — must use runtime tool calls
- Task 56: Commands are now thin dispatchers (34-53 lines each), making conversion straightforward
- Existing skills: `cig-current-task` and `test-cig-skill` provide format reference

## Major Milestones
1. **Conversion pattern established**: Convert one command (cig-design-plan) as reference template, verify it works
2. **Workflow commands converted (10)**: All workflow step commands (task-plan through retrospective) converted
3. **Remaining commands converted (7)**: new-task, subtask, status, extract, init, config, security-check
4. **Validation complete**: All 17 skills tested, command files removed, token consumption measured

## Risk Assessment

### High Priority Risks
- **Context injection replacement breaks functionality**: Commands rely on `!{bash}` for runtime context (git root, task stack) and `!/current-task-wf` for current task detection. Skills must reproduce this via explicit tool call instructions.
  - **Mitigation**: Convert one command first, test thoroughly, then apply pattern. Task 55 identified 4 alternative approaches — use "allowed-tools with Bash + thin skill + doc reference" strategy.
- **Skills auto-loading bloats context**: All skills auto-load into conversation context. 17 skills at ~50 lines each = ~850 lines = ~14k tokens loaded before conversation starts.
  - **Mitigation**: Skills are already thin dispatchers (Task 56). Measure actual token consumption. If excessive, use `disable-model-invocation: true` on infrequently-used skills. Consider whether all 17 need to be user-invocable.

### Medium Priority Risks
- **Naming conflicts during migration**: If both command and skill exist with the same name, behaviour is undefined.
  - **Mitigation**: Remove command file immediately when creating corresponding skill. No parallel operation period.
- **Skill frontmatter syntax errors**: YAML frontmatter in SKILL.md has different fields than commands. Incorrect frontmatter silently breaks skills.
  - **Mitigation**: Use existing `cig-current-task` and `test-cig-skill` as reference. Test each skill individually.

### Low Priority Risks
- **Shared doc references still work**: Skills reference `.cig/docs/commands/*.md` via Read instructions. Path resolution must work from skill context.
  - **Mitigation**: Test with one skill first. Paths are relative to git root, which skills can resolve.

## Dependencies
- Task 55 complete: Context injection limitation confirmed and alternatives identified
- Task 56 complete: Commands refactored to thin dispatchers (prerequisite for manageable conversion)
- No external dependencies

## Constraints
- **No parallel operation**: Commands and skills with same names could conflict. Clean cutover per command.
- **Skills-only mode**: Use `.claude/skills/` directory format, not plugin mode (avoids Bug #17688 with hooks in plugins)
- **No hooks initially**: Convert command instructions only. Hooks can be added later if needed.
- **Preserve `allowed-tools`**: Each skill must declare its tool permissions in frontmatter
- **Skill content must be self-contained**: No `!{bash}` or `!/path` injection — all context must come from runtime tool calls

## Decomposition Check
- [ ] **Time**: Will this take >1 week? **NO** — 2-3 days, same as Task 56 which completed in 1 day
- [ ] **People**: Does this need >2 people? **NO**
- [x] **Complexity**: 3+ distinct concerns? **MARGINAL** — format conversion + context injection replacement, but both are repetitive
- [ ] **Risk**: High-risk components? **NO** — each command converts independently, failures isolated
- [x] **Independence**: Can parts be worked on separately? **YES** — each command is independent

**Decision**: Do NOT decompose. Task 56 demonstrated that repetitive refactoring across 17 files completes faster than estimated when pattern is established on first file. Same applies here.

## Status
**Status**: Finished
**Next Action**: /cig-requirements-plan 57
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

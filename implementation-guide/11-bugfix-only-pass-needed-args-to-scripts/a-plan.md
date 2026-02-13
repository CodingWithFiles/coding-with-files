# Only pass needed args to scripts - Plan

## Task Reference
- **Task ID**: internal-11
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/11-only-pass-needed-args-to-scripts
- **Template Version**: 2.0

## Goal
Ensure CIG command Context sections pass only required arguments to helper scripts, separating script invocation from LLM context.

## Success Criteria
- [ ] All Context section script calls extract only needed args from $ARGUMENTS
- [ ] Scripts receive clean arguments without explanatory text
- [ ] Context sections still provide helpful LLM context
- [ ] All 13 CIG commands updated consistently
- [ ] Scripts execute successfully with new argument passing

## Original Estimate
**Effort**: 2-3 hours
**Complexity**: Medium
**Dependencies**: Understanding of bash parameter expansion and CIG command structure

## Major Milestones
1. **Identify pattern**: Analyze current Context section script invocations
2. **Fix script calls**: Update all Context sections to pass only needed args
3. **Verify**: Test all CIG commands work with updated argument passing

## Risk Assessment
### Medium Priority Risks
- **Breaking existing commands**: Incorrect arg extraction could break all CIG commands
  - **Mitigation**: Test each command after modification, use consistent pattern

- **Script compatibility**: Scripts might expect different arg formats
  - **Mitigation**: Review script usage patterns before modifying calls

## Dependencies
- Helper scripts: hierarchy-resolver.pl, context-inheritance.pl, format-detector.pl, status-aggregator.pl
- All 13 CIG command files

## Constraints
- Must maintain backward compatibility with existing script interfaces
- Context section output must remain helpful for LLM understanding
- Changes must be consistent across all commands

## Decomposition Check
- [x] **Time**: 2-3 hours - No decomposition needed
- [x] **People**: Single developer - No decomposition needed
- [x] **Complexity**: Script calls in 13 files - Repetitive but manageable
- [x] **Risk**: Medium risk but mitigated by testing - No decomposition needed
- [x] **Independence**: All changes in command files - No decomposition needed

**Decision**: Keep as single task. Repetitive updates across 13 files, but all follow same pattern.

## Files to Modify
### CIG Command Files (13 total)
All in `.claude/commands/`:
- cig-design.md
- cig-extract.md
- cig-implementation.md
- cig-maintenance.md
- cig-new-task.md
- cig-plan.md
- cig-requirements.md
- cig-retrospective.md
- cig-rollout.md
- cig-status.md
- cig-subtask.md
- cig-testing.md

### Context Section Pattern (Current)
```markdown
- Task resolution: !`.cig/scripts/command-helpers/hierarchy-resolver.pl $ARGUMENTS 2>/dev/null || echo "Task path required"`
```

### Problem
`$ARGUMENTS` may contain extra text beyond what script expects, causing script failures.

### Solution Pattern
Extract only the first argument (task path) for scripts:
```bash
${ARGUMENTS%% *}  # Extract first word before space
```

## Status
**Status**: Cancelled
**Cancellation Reason**: Superseded by Task 57 — commands converted to skills, bypassing the $ARGUMENTS parsing bug entirely
**Next Action**: None
**Blockers**: None

## Actual Results
### Discovery Phase
- **Problem identified**: Commands fail when users pass extra text after task number (e.g., `/cig-design 11 update the UI`)
- **Initial approach**: Attempted to use `${ARGUMENTS%% *}` bash parameter expansion to extract first word
- **Failure**: Bash parameter expansion doesn't work because `$ARGUMENTS` is only available to Claude, not to inline bash execution
- **Research findings**: GitHub issues #4370 and #5520 confirmed that only `$ARGUMENTS` exists in Claude Code; `$1`, `$2`, `$3` do NOT exist despite documentation

### Solution Evolution
1. **Iteration 1 - Claude Parses Arguments**: Remove inline bash execution (`!`), have Claude extract first word from `$ARGUMENTS` text
2. **Iteration 2 - Clarity Enhancement**: Update instructions to clarify that extra words provide context to Claude (not ignored!)
3. **Iteration 3 - Security Enhancement**: Add LLM-level format validation to prevent command injection before bash invocation (defense in depth)

### Final Implementation
- All 8 workflow commands updated with secure argument parsing pattern
- LLM validates task path format (hierarchical numbers only) before invoking bash
- Defense in depth: LLM validation + script validation
- Handles arbitrary user input safely (quotes, backticks, shell metacharacters)

## Lessons Learned
- **Documentation can be incorrect**: Official docs showed `$1`/`$2`/`$3` that don't exist. Always verify with GitHub issues and source code.
- **After 3 failures, stop and research**: Tried multiple approaches based on docs before researching GitHub issues revealed ground truth.
- **Dogfooding catches issues early**: Testing cig-design.md first validated pattern before applying to all 8 files.
- **Security requires defense in depth**: Single-layer validation (scripts only) insufficient. LLM must validate BEFORE bash invocation.
- **Estimation was 5x off**: 2-3 hours estimated, ~1 day actual. Tasks involving "research unknown behaviour" need larger contingency.

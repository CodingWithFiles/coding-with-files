# Add PreToolUse hook for rule re-injection - Plan
**Task**: 99 (feature)

## Task Reference
- **Task ID**: internal-99
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/99-add-pretooluse-hook-for-rule-re-injection
- **Template Version**: 2.1

## Goal
Add a Claude Code PreToolUse hook on UserPromptSubmit that re-injects critical CWF rules on every user message, ensuring they survive context compaction.

## Success Criteria
- [ ] Rules injection file created (`.cwf/rules-inject.txt` or similar) containing the 3-4 most critical CWF rules
- [ ] PreToolUse hook configured in project-level `.claude/settings.json` that fires on UserPromptSubmit
- [ ] Hook outputs rules text so it appears as a system reminder in the agent's context
- [ ] `/cwf-init` updated to install the hook configuration and rules file
- [ ] `install.bash` updated to include the rules injection file
- [ ] Rules survive compaction (verified by inspection — rules re-injected on next user message after compaction)

## Original Estimate
**Effort**: 1 session
**Complexity**: Low
**Dependencies**: Claude Code hooks mechanism (PreToolUse event, UserPromptSubmit matcher)

## Major Milestones
1. **Rules file authored**: Identify and write the 3-4 most critical rules that must survive compaction
2. **Hook configured**: PreToolUse hook wired up in settings.json
3. **Install pipeline updated**: cwf-init and install.bash install the hook and rules file

## Risk Assessment
### High Priority Risks
- **Context token cost**: Hook output appears as a system reminder on every user message, consuming tokens each turn
  - **Mitigation**: Keep rules file extremely terse (target under 10 lines). Every word costs tokens across every turn of every session.

### Medium Priority Risks
- **Hook mechanism may not support UserPromptSubmit**: Documentation says it does, but we haven't used hooks in CWF before
  - **Mitigation**: Test with a minimal hook first before building the full feature
- **settings.json merge conflict**: `/cwf-init` already writes to `.claude/settings.json` for skill permissions; adding hooks to the same file needs careful JSON merging
  - **Mitigation**: Read existing settings, merge hooks key, write back — same pattern as skill permissions

## Dependencies
- Claude Code PreToolUse hook mechanism with UserPromptSubmit matcher
- Project-level `.claude/settings.json` (already managed by `/cwf-init`)
- Rules content informed by MEMORY.md "Recurring Process Errors" section

## Constraints
- Rules file must be portable — installed into third-party repos
- Token cost is the primary constraint — every line costs tokens on every turn
- Hook runs outside the reasoning loop — no token cost for execution, but output becomes a system reminder that does consume tokens
- Must not conflict with existing settings.json content (skill permissions)

## Decomposition Check
- [ ] **Time**: Will this take >1 week? No — single session
- [ ] **People**: Does this need >2 people working on different parts? No
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — rules file + hook config + install
- [ ] **Risk**: Are there high-risk components that need isolation? No
- [ ] **Independence**: Can parts be worked on separately? No

0/5 signals triggered — no decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 99
**Blockers**: None

## Actual Results
Delivered as planned in 1 session. Rules injection file, hook configuration in cwf-init, glossary updates, and install pipeline all implemented. 8/8 tests pass. Install.bash simplified during /simplify review.

## Lessons Learned
- `/simplify` review is a valuable quality gate — caught duplication and a bash syntax error
- Dynamic test operators in bash require `test` command, not `[[ ]]`

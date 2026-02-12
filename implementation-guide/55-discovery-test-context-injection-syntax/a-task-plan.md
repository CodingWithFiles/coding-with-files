# Test context injection syntax - Plan
**Task**: 55 (discovery)

## Task Reference
- **Task ID**: internal-55
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/55-test-context-injection-syntax
- **Template Version**: 2.1

## Goal
Verify whether CIG's context injection syntax (`!{bash}` blocks and `` ! ` `` backtick syntax) works in SKILL.md format, unblocking the decision on command-to-skill conversion.

## Success Criteria
- [ ] `!{bash}` syntax tested in a SKILL.md file with documented result (works / doesn't work / partially works)
- [ ] `` ! ` `` backtick syntax tested in a SKILL.md file with documented result
- [ ] If either syntax fails, alternative approaches identified and documented
- [ ] Results recorded with evidence (transcript excerpts or observed behaviour)

## Original Estimate
**Effort**: < 1 hour
**Complexity**: Low (create test skills, invoke them, observe behaviour)
**Dependencies**:
- Claude Code v2.1.x with skills support (already available)
- Understanding of SKILL.md frontmatter format (documented in Task 16 and Task 54)

## Major Milestones
1. **Test skill created**: SKILL.md with `!{bash}` context injection in `.claude/skills/`
2. **Syntax tested**: Both injection syntaxes invoked and results observed
3. **Results documented**: Pass/fail for each syntax with evidence

## Risk Assessment
### Low Priority Risks
- **Syntax works differently than expected**: Context injection may work but with subtle differences (e.g., timing, escaping)
  - **Mitigation**: Test with the actual patterns CIG uses (context-manager calls, file path references), not just trivial examples
- **Test skill interferes with existing commands**: A test skill with the same name as an existing command could cause conflict
  - **Mitigation**: Use a unique name (e.g., `cig-test-injection`) that doesn't clash with existing CIG commands

## Dependencies
- Claude Code skills system operational (confirmed — CIG already has a `test-cig-skill` skill)
- Git working directory clean enough to create test files

## Constraints
- Test only — do not modify existing CIG commands or skills
- Clean up test skills after experiment (don't leave test artefacts)
- Time-boxed to 1 hour maximum

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** — < 1 hour
- [ ] **People**: Does this need >2 people working on different parts? **NO**
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **NO** — single experiment
- [ ] **Risk**: Are there high-risk components that need isolation? **NO** — read-only test
- [ ] **Independence**: Can parts be worked on separately? **NO** — single task

**Decision**: Do NOT decompose. This is a focused experiment with a single deliverable.

## Status
**Status**: Finished
**Next Action**: /cig-requirements-plan 55
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Both context injection syntaxes (`!{bash}` and `!` path shorthand) confirmed as commands-only features — they do not work in SKILL.md format. All success criteria met: both syntaxes tested with documented FAIL results, alternative approaches identified, results recorded with evidence. Completed in ~30 minutes (within <1 hour estimate).

## Lessons Learned
- Empirical testing of platform behaviour is more reliable than documentation or inference
- Focused discovery tasks with clear PASS/FAIL criteria complete faster than open-ended research

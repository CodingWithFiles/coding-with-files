# Add path-scoped rules for wf file protection - Plan
**Task**: 98 (feature)

## Task Reference
- **Task ID**: internal-98
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/98-add-path-scoped-rules-for-wf-file-protection
- **Template Version**: 2.1

## Goal
Add `.claude/rules/` with path-scoped rule files that auto-load when the agent operates on wf step files, instructing it to use the corresponding CWF skill instead of editing directly.

## Success Criteria
- [ ] `.claude/rules/` directory created with at least one path-scoped rule file
- [ ] Rule file uses glob frontmatter to match wf step files (`implementation-guide/**/{a,b,c,d,e,f,g,h,i,j}-*.md`)
- [ ] Rule text maps each step prefix to the correct `/cwf-{step}` skill name
- [ ] `/cwf-init` updated to create `.claude/rules/` and copy rule files into target projects
- [ ] `install.bash` updated to include `.claude/rules/` in the installed file set
- [ ] Rule loads automatically when agent touches a matching file (verified by inspection)

## Original Estimate
**Effort**: 1 session
**Complexity**: Low
**Dependencies**: Understanding of Claude Code `.claude/rules/` mechanism (path-scoped YAML frontmatter with `globs` field)

## Major Milestones
1. **Rule file authored**: `.claude/rules/workflow-files.md` with correct glob pattern and skill mapping
2. **Install pipeline updated**: `/cwf-init` and `install.bash` copy rules into target projects
3. **Verified**: Rule loads when agent edits a wf step file in a test scenario

## Risk Assessment
### High Priority Risks
- None — low-complexity additive feature

### Medium Priority Risks
- **Glob pattern may not match all wf step file locations**: Nested subtask directories may require `**/` glob depth
  - **Mitigation**: Test with both top-level and nested task directories
- **Rule text too long burns context tokens**: Rules load automatically and consume context on every matching operation
  - **Mitigation**: Keep rule text concise — skill name mapping only, no explanatory prose

## Dependencies
- Claude Code rules mechanism must support `globs` frontmatter for path scoping (documented in best practices)
- `/cwf-init` skill must be updated (existing skill, straightforward addition)

## Constraints
- Rule files must be portable — installed into third-party repos via `/cwf-init`
- Rule text must be concise to minimise context cost
- Advisory only — cannot enforce, only guide (as established in Task 97 discovery)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — single session
- [ ] **People**: Does this need >2 people working on different parts? No
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — rule file + install integration
- [ ] **Risk**: Are there high-risk components that need isolation? No
- [ ] **Independence**: Can parts be worked on separately? No

0/5 signals triggered — no decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 98
**Blockers**: None

## Actual Results
Path-scoped rule file created with glob targeting `implementation-guide/**/{a,b,c,d,e,f,g,h,i,j}-*.md`. Install script updated with `create_rule_symlinks()` and third subtree split. Closing phases delayed by Task 99 interleaving.

## Lessons Learned
Namespace prefix (`cwf-`) matters for rule files to avoid collisions with other tools. Close tasks before starting new ones to avoid interleaving delays.

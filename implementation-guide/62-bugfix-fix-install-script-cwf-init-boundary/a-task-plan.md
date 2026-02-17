# Fix install script / cwf-init boundary and post-install UX - Plan
**Task**: 62 (bugfix)

## Task Reference
- **Task ID**: internal-62
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/62-fix-install-script-cwf-init-boundary
- **Template Version**: 2.1

## Goal
Fix the overlapping responsibilities between `scripts/install.bash` and `/cwf-init`, add PERL5OPT detection, and ensure `/cwf-init` commits its output.

## Success Criteria
- [ ] Install script only handles CWF plumbing (`.cwf/`, `.cwf-skills/`, symlinks, `.cwf/version`) — no `implementation-guide/` or `.gitignore`
- [ ] `/cwf-init` detects existing PERL5OPT config and skips the suggestion if already present
- [ ] `/cwf-init` offers to commit its output (staged files) at the end
- [ ] INSTALL.md documents that a Claude Code restart is needed after install for skills to register
- [ ] cwf-manage uses core Perl idioms (`File::Find`, `File::Copy`, `File::Path`) instead of `system()` calls for file operations
- [ ] External test: install + restart + `/cwf-init` produces a clean, committed project setup

## Original Estimate
**Effort**: 1 session
**Complexity**: Low
**Dependencies**: Task 61 (install script exists on parent branch)

## Major Milestones
1. **Install script cleanup**: Remove `implementation-guide/` and `.gitignore` from `post_install()`
2. **cwf-init improvements**: PERL5OPT detection, post-init commit offer
3. **cwf-manage idioms**: Replace `system()` file ops with core Perl equivalents
4. **Documentation**: INSTALL.md restart note

## Risk Assessment
### Low Priority Risks
- **Existing installs**: Users who already installed via Task 61's script have `implementation-guide/` created by the install script. No impact — `/cwf-init` already handles the "directory exists" case.

## Dependencies
- Task 61 branch (install script and cwf-init skill both present)

## Constraints
- `/cwf-init` is a SKILL.md file (instructions for Claude Code), not executable code — changes are to the skill's workflow instructions
- PERL5OPT detection must work across platforms (check `~/.claude/settings.json`)

## Decomposition Check
- [x] **Time**: No — estimated 1 session
- [x] **People**: No — single author
- [x] **Complexity**: No — three small, related fixes
- [x] **Risk**: No — low risk changes
- [x] **Independence**: No — all three parts are tightly coupled around the install→init workflow

Zero signals triggered. No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 62
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 6 success criteria met. Install script cleaned of project setup responsibilities. cwf-manage uses core Perl for all file operations (File::Find, File::Copy, File::Path). cwf-init SKILL.md updated with PERL5OPT detection and post-init commit. INSTALL.md documents restart requirement. 15/15 tests pass, zero bugs.

## Lessons Learned
- Scope expanded mid-design to include Perl idiom cleanup — good call, addressed code quality alongside the boundary fix without adding significant effort.

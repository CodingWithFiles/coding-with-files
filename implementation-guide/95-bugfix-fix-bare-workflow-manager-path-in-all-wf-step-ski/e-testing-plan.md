# Fix bare workflow-manager path in all wf step skills — Testing Plan
**Task**: 95 (bugfix)

## Task Reference
- **Task ID**: internal-95
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/95-fix-bare-workflow-manager-path-in-wf-step-skills
- **Template Version**: 2.1

## Test Strategy
Static grep verification. No unit tests required — the change is a documentation string replacement with no logic.

## Test Cases

### TC-1: No bare references remain
- **Given**: All 10 SKILL.md files have been edited
- **When**: `grep -r "workflow-manager control" .claude/skills/`
- **Then**: Every match is prefixed with `.cwf/scripts/command-helpers/` — zero bare occurrences

### TC-2: Correct count of updated references
- **Given**: All 10 SKILL.md files have been edited
- **When**: `grep -r ".cwf/scripts/command-helpers/workflow-manager control" .claude/skills/`
- **Then**: Exactly 10 matches (one per skill)

### TC-3: Script resolves at the stated path
- **Given**: Repo checkout with CWF installed
- **When**: `.cwf/scripts/command-helpers/workflow-manager control --current-step=a-task-plan --task-path=95`
- **Then**: Exits without "command not found" — returns usage or a valid response

### TC-4: No other command-helper paths inadvertently changed
- **Given**: All 10 SKILL.md files have been edited
- **When**: `git diff .claude/skills/` reviewed
- **Then**: Only the `workflow-manager control` lines changed; all other content identical

## Validation Criteria
- [ ] TC-1 passes — 0 bare `workflow-manager control` in `.claude/skills/`
- [ ] TC-2 passes — exactly 10 full-path references
- [ ] TC-3 passes — script found and responds
- [ ] TC-4 passes — diff shows only targeted lines changed

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 95
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

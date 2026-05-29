# Sync README command reference - Testing Plan
**Task**: 169 (chore)

## Task Reference
- **Task ID**: internal-169
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/169-sync-readme-command-reference
- **Template Version**: 2.1

## Goal
Verify the post-edit README documents exactly the shipped command surface — no
missing, no phantom — with correct signatures and task types.

## Test Strategy
### Test Levels
This is a documentation change. There is no runtime behaviour to unit/integration
test. Verification is **diff-based**: compare what README documents against the
authoritative in-tree sources, plus the standing integrity gate.

- **Source-of-truth diffs**: README's documented set vs the real shipped set
- **Lint/integrity gate**: `cwf-manage validate` (incl. Task 165 template-ref linter)

### Coverage Target
- 100% of the four audited gaps closed; zero new discrepancies introduced.

## Test Cases
### Functional Test Cases
- **TC-1 — Skills: no missing, no phantom**
  - **Given**: edited README
  - **When**: compare `grep -oE '/cwf-[a-z-]+' README.md | sort -u` (strip leading `/`) against `ls .claude/skills/ | grep '^cwf-'`
  - **Then**: sets are equal. `cwf-project` is excluded as a known `cwf-project.json` false positive; `test-cwf-skill` is not matched by either pattern.

- **TC-2 — Three previously-missing skills now present**
  - **Given**: edited README
  - **When**: grep README for `cwf-delete-task`, `cwf-current-task`, `cwf-backlog-manager`
  - **Then**: each appears exactly once in the Commands section with its `SKILL.md`-derived one-liner.

- **TC-3 — Task types match supported-task-types**
  - **Given**: edited README `## Task Types`
  - **When**: compare documented types against `cwf-project.json:supported-task-types`
  - **Then**: equal to {feature, bugfix, hotfix, chore, discovery}; `discovery` documented as 8 phases (a,b,c,d,e,f,g,j). NOT compared against `.cwf/templates/` dirs (which include the non-type `install/`).

- **TC-4 — Signatures match skills**
  - **Given**: edited README:109/110
  - **When**: inspect `/cwf-new-task` and `/cwf-new-subtask` signature lines
  - **Then**: both show `[<type>]` (optional), matching each `SKILL.md` parse line.

- **TC-5 — cwf-manage subcommands complete and correctly framed**
  - **Given**: edited README
  - **When**: compare documented `cwf-manage` subcommands against `cwf-manage help`
  - **Then**: all 7 present (status, list-releases, update, rollback, validate, fix-security, help); `fix-security` framed as the narrow integrity-repair carve-out, not a warning-silencer.

### Non-Functional Test Cases
- **Integrity**: `cwf-manage validate` exits clean after the edit.
- **No stale strings**: grep README for removed/renamed command names (none expected) → empty.
- **Prose untouched**: `git diff` shows changes confined to the Commands and Task Types sections (scope discipline).

## Test Environment
### Setup Requirements
- Working tree on branch `chore/169-sync-readme-command-reference`; no external deps.

### Automation
- Manual diff + grep checks run during g-testing-exec; `cwf-manage validate` already
  runs automatically via the checkpoint-commit hook.

## Validation Criteria
- [ ] TC-1 — skill sets equal
- [ ] TC-2 — three skills present
- [ ] TC-3 — task types == supported-task-types
- [ ] TC-4 — signatures show `[<type>]`
- [ ] TC-5 — cwf-manage subcommands complete + fix-security framed correctly
- [ ] `cwf-manage validate` clean; diff confined to intended sections

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 169
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All TC-1..TC-5 executed and passed in g-testing-exec.md; diff-based oracles gave
unambiguous results.

## Lessons Learned
Diff-against-authoritative-source is the right verification shape for doc-sync chores —
no manual judgement, catches both missing and phantom entries. See j-retrospective.md.

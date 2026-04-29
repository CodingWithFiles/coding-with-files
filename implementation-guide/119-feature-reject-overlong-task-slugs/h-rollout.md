# Reject overlong task slugs - Rollout
**Task**: 119 (feature)

## Task Reference
- **Task ID**: internal-119
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/119-reject-overlong-task-slugs
- **Template Version**: 2.1

## Deployment Strategy

**Strategy**: Immediate — single-developer internal tool, no phased rollout needed. Mirrors the standard CWF self-development rollout (e.g. Tasks 113, 116).

**Deployment**:
- The script change (`.cwf/scripts/command-helpers/template-copier-v2.1`), the matching hash bump in `.cwf/security/script-hashes.json`, the SKILL.md updates for `cwf-new-task` and `cwf-new-subtask`, and the new test file `t/template-copier-slug-validation.t` are all on the task branch and will be deployed by the human-driven fast-forward of `main` after the retrospective squash.
- Existing tasks on disk are unaffected (FR5 / AC5.2 — validation only fires in `parse_parameters` at task-creation time).

**Rollback**: Single-commit revert. The change is one logical unit (script + hash + SKILL.md + test); reverting the squashed `Task 119:` commit on `main` restores the prior silent-truncation behaviour. No external state to undo.

**Breaking change**: Yes — descriptions whose slug exceeds 50 chars now error where they previously succeeded with a truncated slug. Captured in the CHANGELOG entry written during the retrospective.

## Pre-Deployment Checklist
- [x] All 17 test cases pass (TC-1..17 in g-testing-exec.md)
- [x] `prove t/` clean: 246 / 246 passing (was 238 baseline; +8 new)
- [x] `cwf-manage validate` clean
- [x] Script permissions verified (mode 0700; matches the existing hash-record entry)
- [x] FR3 (single source of truth) verified by grep — `SLUG_MAX_LEN` declared in exactly one file
- [x] FR4 verified by grep — no remaining "truncate 50 chars" instructions in either SKILL.md
- [x] /simplify pass applied (commit 78a16a5): `$limit` local removed, redundant `generate_slug` call eliminated
- [x] CHANGELOG and BACKLOG updates pending in retrospective phase

## Monitoring
- Next live invocation of `/cwf-new-task` or `/cwf-new-subtask` exercises the rejection path. Any regression (false positive on short descriptions, missing error, partial directory creation) becomes visible at first use.
- No separate monitoring infrastructure needed — this is a CLI script.

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance 119
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

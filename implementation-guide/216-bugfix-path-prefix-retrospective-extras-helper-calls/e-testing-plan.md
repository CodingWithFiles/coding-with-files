# Path-prefix retrospective-extras helper calls - Testing Plan
**Task**: 216 (bugfix)

## Task Reference
- **Task ID**: internal-216
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/216-path-prefix-retrospective-extras-helper-calls
- **Template Version**: 2.1

## Goal
Verify the 5 invocations are prefixed, nothing else changed, and system integrity holds.

## Test Strategy
Prose-doc change: verification is deterministic grep assertions plus `cwf-manage validate`.
No unit/integration/performance testing applies — there is no code or runtime behaviour.
All checks run manually in g-testing-exec.

## Test Cases

### TC-1: No bare in-scope invocation remains (positive fix)
- **Given**: the edited `.cwf/docs/skills/retrospective-extras.md`
- **When**: `grep -nE '(checkpoints-branch-manager|context-manager)' .cwf/docs/skills/retrospective-extras.md | grep -v 'command-helpers/'`
- **Then**: no output (all 5 executed invocations carry the `.cwf/scripts/command-helpers/` prefix, fenced and inline alike)

### TC-2: All 5 target lines carry the prefix (count check)
- **Given**: the edited file
- **When**: `grep -c 'command-helpers/checkpoints-branch-manager' …` and `grep -c 'command-helpers/context-manager' …`
- **Then**: 3 and 2 respectively

### TC-3: Prose pointers left untouched (no over-reach)
- **Given**: the edited file
- **When**: inspect lines 86 and 118
- **Then**: `cwf-version-bump` / `cwf-version-tag` still bare (they defer to SKILL.md)

### TC-4: Already-pathed lines not double-prefixed
- **Given**: the edited file
- **When**: `grep -n 'command-helpers/command-helpers' …` and inspect lines 21/45
- **Then**: no double prefix; `workflow-manager` (21) and `cwf-manage` (45) unchanged

### TC-5: System integrity
- **Given**: the committed change
- **When**: `.cwf/scripts/cwf-manage validate`
- **Then**: clean (file is not in `script-hashes.json`; no hash/permission drift)

## Test Environment
Repo working tree at the task branch tip. No test data, mocks, or CI hooks required.

## Validation Criteria
- [ ] TC-1 through TC-5 all pass

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 5 test cases (TC-1…TC-5) executed in g-testing-exec; 5/5 PASS. See g-testing-exec.md for the results table.

## Lessons Learned
Deterministic grep + `cwf-manage validate` was sufficient coverage for a prose-doc change — no unit/integration layer applies.

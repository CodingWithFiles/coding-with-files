# Rebrand CIG to CWF (Coding with Files) - Testing Plan
**Task**: 59 (feature)

## Task Reference
- **Task ID**: internal-59
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/59-rebrand-cig-to-cwf-coding-with-files
- **Template Version**: 2.1

## Goal
Validate that the CIG→CWF rebrand is complete, consistent, and functional with zero regressions.

## Test Strategy

### Test Levels
- **Structural**: Verify all renames landed correctly (no orphaned old names)
- **Compilation**: `perl -c` on all Perl scripts and modules
- **Functional**: Key scripts produce correct output after rename
- **Regression**: Historical docs untouched, CHANGELOG untouched, permissions preserved

### Test Coverage Targets
- **Grep sweeps**: 100% — every file outside exclusions must be free of old brand references
- **Perl compilation**: 100% — all 15 helper scripts must pass `perl -c`
- **Functional smoke tests**: Core scripts (context-manager, status-aggregator, task-context-inference) must execute
- **Exclusion verification**: 100% — zero changes to protected files

## Test Cases

### Structural Tests (Phase 1 validation)

- **TC-1**: No old directories exist
  - **When**: `ls -d .cig 2>/dev/null; ls -d .claude/skills/cig-* 2>/dev/null`
  - **Then**: Both commands return empty / exit non-zero

- **TC-2**: New directories exist
  - **When**: `ls -d .cwf .cwf/lib/CWF .cwf/scripts/command-helpers .cwf/templates .cwf/docs .cwf/security`
  - **Then**: All directories exist

- **TC-3**: Namespace modules in correct location
  - **When**: `ls .cwf/lib/CWF/TaskState.pm .cwf/lib/CWF/TaskContextInference.pm`
  - **Then**: Both files exist (moved from lib root into CWF/)

- **TC-4**: No old-named files outside exclusions
  - **When**: `find . -name '*cig*' -not -path './implementation-guide/*' -not -name 'CHANGELOG.md' -not -path './.git/*'`
  - **Then**: Zero results

- **TC-5**: Config file renamed
  - **When**: `ls implementation-guide/cwf-project.json`
  - **Then**: File exists. `ls implementation-guide/cig-project.json` returns not found.

### Perl Compilation Tests (Phase 2 validation)

- **TC-6**: All helper scripts compile
  - **When**: Run `perl -c` on each of the 15 scripts in `.cwf/scripts/command-helpers/` (including dispatched scripts in `.d/` subdirs)
  - **Then**: All 15 return "syntax OK"

- **TC-7**: All Perl modules compile
  - **When**: `perl -I.cwf/lib -e 'use CWF::Common; use CWF::TaskState; use CWF::TaskContextInference; use CWF::WorkflowFiles; use CWF::StatusAggregator::Core; print "OK\n"'`
  - **Then**: Prints "OK" with no errors

### Content Sweep Tests (Phase 3 validation)

- **TC-8**: No `CIG::` namespace references outside exclusions
  - **When**: `grep -r 'CIG::' .cwf/ .claude/skills/`
  - **Then**: Zero matches

- **TC-9**: No `.cig/` path references outside exclusions
  - **When**: `grep -r '\.cig/' --include='*.md' --include='*.pm' --include='*.yaml' --include='*.json' --include='*.sh' . | grep -v 'implementation-guide/' | grep -v 'CHANGELOG.md' | grep -v '.git/'`
  - **Then**: Zero matches

- **TC-10**: No `cig-project.json` references outside exclusions
  - **When**: `grep -r 'cig-project\.json' --include='*.md' --include='*.pm' --include='*.yaml' --include='*.json' --include='*.sh' . | grep -v 'implementation-guide/' | grep -v 'CHANGELOG.md' | grep -v '.git/'`
  - **Then**: Zero matches

- **TC-11**: No `/cig-` skill invocation references outside exclusions
  - **When**: `grep -r '/cig-' --include='*.md' . | grep -v 'implementation-guide/' | grep -v 'CHANGELOG.md'`
  - **Then**: Zero matches

- **TC-12**: No "Code Implementation Guide" prose outside exclusions
  - **When**: `grep -r 'Code Implementation Guide' --include='*.md' --include='*.pm' --include='*.yaml' --include='*.json' . | grep -v 'implementation-guide/' | grep -v 'CHANGELOG.md'`
  - **Then**: Zero matches

- **TC-13**: README contains "swiff" pronunciation
  - **When**: `grep -i 'swiff' README.md`
  - **Then**: At least 1 match containing pronunciation guidance

### Functional Smoke Tests

- **TC-14**: context-manager location works
  - **When**: `.cwf/scripts/command-helpers/context-manager location`
  - **Then**: Outputs git root path without errors

- **TC-15**: task-context-inference runs
  - **When**: `.cwf/scripts/command-helpers/task-context-inference`
  - **Then**: Produces output (may be "inconclusive" but must not crash)

- **TC-16**: status-aggregator works
  - **When**: `.cwf/scripts/command-helpers/status-aggregator-v2.1 implementation-guide/59-feature-rebrand-cig-to-cwf-coding-with-files`
  - **Then**: Produces percentage output without errors or warnings

### Regression Tests

- **TC-R1**: Historical docs unchanged
  - **When**: `git diff --name-only HEAD -- 'implementation-guide/*/'`
  - **Then**: Zero files listed (no changes to task subdirectories)

- **TC-R2**: CHANGELOG unchanged
  - **When**: `git diff --name-only HEAD -- CHANGELOG.md`
  - **Then**: Zero files listed

- **TC-R3**: File permissions preserved
  - **When**: `find .cwf/scripts -type f ! -perm -u+rx`
  - **Then**: Zero results (all scripts have u+rx)

- **TC-R4**: Security check passes
  - **When**: Run `/cwf-security-check verify` (or the underlying script)
  - **Then**: Passes with no integrity violations

## Test Environment
- **Prerequisites**: On branch `feature/59-rebrand-cig-to-cwf-coding-with-files`, all implementation steps complete
- **Tools**: bash, perl, grep, find, git
- **No external dependencies**

## Validation Criteria
- [ ] TC-1 through TC-5: Structural tests pass
- [ ] TC-6 through TC-7: Perl compilation passes
- [ ] TC-8 through TC-13: Content sweep clean
- [ ] TC-14 through TC-16: Functional smoke tests pass
- [ ] TC-R1 through TC-R4: Regression tests pass
- [ ] Total: 20/20 tests pass

## Status
**Status**: Finished
**Next Action**: /cig-implementation-exec 59
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

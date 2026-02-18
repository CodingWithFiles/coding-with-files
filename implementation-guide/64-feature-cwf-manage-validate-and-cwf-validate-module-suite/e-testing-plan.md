# cwf-manage validate and CWF::Validate module suite - Testing Plan
**Task**: 64 (feature)

## Task Reference
- **Task ID**: internal-64
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/64-cwf-manage-validate-and-cwf-validate-module-suite
- **Template Version**: 2.1

## Goal
Validate that all four `CWF::Validate::*` modules and `cwf-manage validate` behave correctly, that error messages are actionable, and that integration points (checkpoint-commit.md, security-check skill) work as expected.

## Test Strategy

### Test Levels
- **Static**: Perl syntax check and perlcritic --stern on all new/modified files
- **Unit**: Each module tested in isolation with crafted inputs (temp files/dirs)
- **Integration**: `cwf-manage validate` end-to-end against known-good and known-bad repos
- **Regression**: Existing functionality (`cwf-security-check`, status aggregator) unaffected

### Coverage Targets
- All violation types: each check has at least one FAIL test and one PASS test
- All four modules exercised independently
- `cwf-manage validate` exit codes: 0 (clean) and 1 (violations)

## Test Cases

### Static Analysis

- **TC-1**: `perl -c` on all four new modules
  - **Then**: All exit 0 with "syntax OK"

- **TC-2**: `perlcritic --stern` on all four new modules and updated `cwf-manage`
  - **Then**: All exit 0 with "source OK"

### CWF::Validate::Config

- **TC-3**: Valid config passes
  - **Given**: `cwf-project.json` with `supported-task-types` (array), `source-management.branch-naming-convention` (string)
  - **When**: `CWF::Validate::Config::validate($root)` called
  - **Then**: Returns empty list (no violations)

- **TC-4**: Missing `supported-task-types`
  - **Given**: Config without `supported-task-types` key
  - **When**: `validate($root)` called
  - **Then**: Returns violation with `field => 'supported-task-types'`, message includes suggested fix

- **TC-5**: `supported-task-types` wrong type (string instead of array)
  - **Given**: Config with `"supported-task-types": "feature"`
  - **When**: `validate($root)` called
  - **Then**: Returns violation noting expected arrayref

- **TC-6**: Missing `source-management.branch-naming-convention`
  - **Given**: Config without `source-management` key
  - **When**: `validate($root)` called
  - **Then**: Returns violation with actionable fix message

- **TC-7**: No config file (pre-init state)
  - **Given**: No `implementation-guide/cwf-project.json` exists
  - **When**: `validate($root)` called
  - **Then**: Returns empty list (not an error — pre-init is valid)

- **TC-8**: `validate_config_hash($hashref, $path)` works independently
  - **Given**: A hashref with missing keys, an arbitrary path string
  - **When**: `validate_config_hash` called directly
  - **Then**: Returns same violations as `validate()` would for same config

### CWF::Validate::Workflow

- **TC-9**: Valid status values pass
  - **Given**: Workflow file with `**Status**: Finished`
  - **When**: `CWF::Validate::Workflow::validate($root)` called
  - **Then**: No violation for that file

- **TC-10**: Invalid status value flagged
  - **Given**: Workflow file with `**Status**: In-Progress` (hyphenated — invalid)
  - **When**: `validate($root)` called
  - **Then**: Violation includes file path, field, actual value, allowed values list

- **TC-11**: Missing `## Status` section flagged
  - **Given**: Workflow file with no `## Status` section
  - **When**: `validate($root)` called
  - **Then**: Violation includes file path and suggested fix

- **TC-12**: v1.0 format file not rejected
  - **Given**: Old `plan.md` with valid status
  - **When**: `validate($root)` called
  - **Then**: No violation for that file

### CWF::Validate::Consistency

- **TC-13**: Matching task number passes
  - **Given**: Directory `63-bugfix-foo/`, file with `**Task**: 63`
  - **When**: `CWF::Validate::Consistency::validate($root)` called
  - **Then**: No violation

- **TC-14**: Mismatched task number flagged
  - **Given**: Directory `63-bugfix-foo/`, file with `**Task**: 99`
  - **When**: `validate($root)` called
  - **Then**: Violation includes directory name, field, actual value, expected value

- **TC-15**: Branch mismatch flagged for active task
  - **Given**: Task with `**Branch**: feature/old-branch`, current git branch is `feature/new-branch`, task has an In Progress file
  - **When**: `validate($root)` called
  - **Then**: Violation reported

- **TC-16**: Branch mismatch not flagged for finished task
  - **Given**: Task where all files are Finished, `**Branch**:` doesn't match current branch
  - **When**: `validate($root)` called
  - **Then**: No violation (completed task legitimately has non-current branch)

### CWF::Validate::Security

- **TC-17**: Matching hash passes
  - **Given**: Script file whose SHA256 matches `script-hashes.json`
  - **When**: `CWF::Validate::Security::validate($root)` called
  - **Then**: No violation for that script

- **TC-18**: Hash mismatch flagged
  - **Given**: Script file whose contents differ from recorded hash
  - **When**: `validate($root)` called
  - **Then**: Violation includes file path, actual hash, expected hash, fix suggestion

- **TC-19**: Missing file flagged
  - **Given**: Entry in `script-hashes.json` for a file that doesn't exist
  - **When**: `validate($root)` called
  - **Then**: Violation includes file path and fix suggestion

- **TC-20**: Wrong permissions flagged
  - **Given**: Script file with permissions `0644` (not executable)
  - **When**: `validate($root)` called
  - **Then**: Violation includes file path, actual permissions, expected minimum

### cwf-manage validate (integration)

- **TC-21**: Clean repo exits 0
  - **Given**: This repo in its current state (all hashes correct, valid config)
  - **When**: `.cwf/scripts/cwf-manage validate` run
  - **Then**: Exit 0, output contains "OK"

- **TC-22**: All violations reported before exit
  - **Given**: Temp repo with one Config violation and one Workflow violation
  - **When**: `cwf-manage validate` run
  - **Then**: Both violations printed, exits 1

- **TC-23**: `cwf-manage help` lists `validate`
  - **When**: `.cwf/scripts/cwf-manage help` run
  - **Then**: Output contains `validate`

### Regression

- **TC-24**: `/cwf-security-check` skill still works
  - **Given**: Updated skill delegating to `CWF::Validate::Security`
  - **When**: Skill invoked
  - **Then**: Produces equivalent output to previous behaviour, no errors

- **TC-25**: `status-aggregator-v2.1` unaffected
  - **When**: `.cwf/scripts/command-helpers/status-aggregator-v2.1 64 --workflow` run
  - **Then**: Correct output, no errors

## Validation Criteria
- [ ] TC-1 through TC-25 all PASS
- [ ] No regressions in existing CWF functionality
- [ ] All violation messages include file, field, actual, expected, fix
- [ ] `cwf-manage validate` exits 0 on this repo post-implementation

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 64
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned deliverables met. See j-retrospective.md for full variance analysis.

## Lessons Learned
See j-retrospective.md Key Learnings section.

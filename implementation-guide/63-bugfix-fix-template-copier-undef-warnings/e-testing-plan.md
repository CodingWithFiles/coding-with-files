# Fix template-copier undef warnings for unresolved variables - Testing Plan
**Task**: 63 (bugfix)

## Task Reference
- **Task ID**: internal-63
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/63-fix-template-copier-undef-warnings
- **Template Version**: 2.1

## Goal
Validate the two defined-or guards in template-copier-v2.1 and the sparse-checkout bootstrap documentation.

## Test Strategy
### Test Levels
- **Unit**: Perl syntax and static analysis on template-copier-v2.1
- **Integration**: End-to-end template creation via `task-workflow create`
- **Documentation**: Verify bootstrap commands in README.md and INSTALL.md

## Test Cases
### Functional Test Cases

- **TC-1**: Perl syntax check
  - **Given**: Modified template-copier-v2.1
  - **When**: `perl -c .cwf/scripts/command-helpers/template-copier-v2.1`
  - **Then**: Exits 0 with "syntax OK"

- **TC-2**: Perlcritic stern
  - **Given**: Modified template-copier-v2.1
  - **When**: `perlcritic --stern .cwf/scripts/command-helpers/template-copier-v2.1`
  - **Then**: Exits 0, no violations

- **TC-3**: Guard on $pattern (line 352)
  - **Given**: template-copier-v2.1 source
  - **When**: Inspect `compute_variables()` for `$config->{'branch-naming-convention'} // ''`
  - **Then**: Defined-or guard present

- **TC-4**: Guard on $value (line 384)
  - **Given**: template-copier-v2.1 source
  - **When**: Inspect `substitute_variables()` for `$vars->{$key} // ''`
  - **Then**: Defined-or guard present

- **TC-5**: Template creation with all params
  - **Given**: Valid cwf-project.json with branch-naming-convention set
  - **When**: `task-workflow create --task-type=feature --destination=/tmp/tc5 --task-num=99 --description="test"`
  - **Then**: Zero warnings, files created with correct substitutions

- **TC-6**: Template creation with missing branch config
  - **Given**: cwf-project.json without branch-naming-convention
  - **When**: `task-workflow create --task-type=bugfix --destination=/tmp/tc6 --task-num=99 --description="test"`
  - **Then**: Zero warnings, branch field is empty string

- **TC-7**: Security hash matches
  - **Given**: Modified template-copier-v2.1
  - **When**: Compare SHA256 of file against `.cwf/security/script-hashes.json`
  - **Then**: Hash matches

- **TC-8**: README.md bootstrap sequence
  - **Given**: Updated README.md
  - **When**: Inspect for sparse-checkout commands
  - **Then**: Contains `git clone --depth 1 --filter=blob:none --sparse`, `sparse-checkout set scripts`, `CWF_SOURCE=`, cleanup

- **TC-9**: INSTALL.md bootstrap sequence
  - **Given**: Updated INSTALL.md
  - **When**: Inspect for sparse-checkout commands
  - **Then**: Contains matching bootstrap sequence

## Validation Criteria
- [ ] TC-1 through TC-9 all PASS
- [ ] Zero undef warnings during template creation
- [ ] Documentation contains correct bootstrap commands

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 63
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
10/10 test cases passed. Testing plan was updated mid-session to reflect D4 scope expansion. External testing added TC-10 (array deref guard).

## Lessons Learned
Write the testing plan after design is finalised to avoid mid-session updates.

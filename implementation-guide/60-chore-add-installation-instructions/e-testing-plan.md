# Add installation instructions - Testing Plan
**Task**: 60 (chore)

## Task Reference
- **Task ID**: internal-60
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/60-add-installation-instructions
- **Template Version**: 2.1

## Goal
Validate that INSTALL.md is accurate, complete, and that README.md references it correctly.

## Test Strategy
### Test Levels
- **Content accuracy**: All file paths and commands in INSTALL.md match the actual repo
- **Completeness**: Both installation methods documented with prerequisites and verification
- **Regression**: README.md still renders correctly with updated Installation section

## Test Cases

### File Existence and Structure

- **TC-1**: INSTALL.md exists at repo root
  - **When**: `ls INSTALL.md`
  - **Then**: File exists

- **TC-2**: INSTALL.md contains both installation methods
  - **When**: Grep for "subtree" and "copy" section headers
  - **Then**: Both present

- **TC-3**: INSTALL.md contains prerequisites section
  - **When**: Grep for "Prerequisites" header
  - **Then**: Present, mentions Perl, git, Claude Code

### Path Accuracy

- **TC-4**: All `.cwf/` paths in INSTALL.md exist in repo
  - **When**: Extract `.cwf/` paths from INSTALL.md and verify each exists
  - **Then**: Zero missing paths

- **TC-5**: All `.claude/skills/cwf-*` references match actual skill dirs
  - **When**: Extract skill dir references and compare to `ls .claude/skills/cwf-*`
  - **Then**: All referenced dirs exist

- **TC-6**: No stale `.cig/` references in INSTALL.md
  - **When**: `grep -c '\.cig/' INSTALL.md`
  - **Then**: Zero matches

### Command Validity

- **TC-7**: Git subtree add command uses valid syntax
  - **When**: Inspect the `git subtree add` command in INSTALL.md
  - **Then**: Has `--prefix`, remote URL placeholder, and branch reference

- **TC-8**: Copy commands reference correct source paths
  - **When**: Inspect `cp` or `rsync` commands
  - **Then**: Source paths match actual repo layout

### README Integration

- **TC-9**: README Installation section references INSTALL.md
  - **When**: Read README.md Installation section
  - **Then**: Contains link or reference to INSTALL.md

- **TC-10**: README Installation section is concise (not duplicating INSTALL.md)
  - **When**: Count lines in README Installation section
  - **Then**: Shorter than before (was 12 lines) or comparable; not duplicating full instructions

### Post-Install Verification

- **TC-11**: Verification steps in INSTALL.md are actionable
  - **When**: Read the verification/checklist section
  - **Then**: Contains concrete commands the user can run to confirm installation

## Test Environment
- Current repo state on branch `chore/60-add-installation-instructions`
- All tests are manual inspection / grep-based — no external environment needed

## Validation Criteria
- [ ] All 11 test cases passing
- [ ] Zero stale `.cig/` references in new files
- [ ] All documented paths verified against actual repo

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 60
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

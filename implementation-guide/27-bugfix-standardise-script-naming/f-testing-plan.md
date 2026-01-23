# Standardise Script Naming - Testing

## Task Reference
- **Task ID**: internal-27
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/27-standardise-script-naming
- **Template Version**: 2.0

## Goal
Define test strategy and validation approach for Standardise Script Naming.

## Test Strategy

### Test Approach
**Manual validation with phase-level checkpoints** - no automated test harness exists for CIG system yet.

### Test Levels
- **System Tests**: End-to-end functionality validation (primary focus)
  - Script execution tests (verify renamed scripts work)
  - Command execution tests (verify CIG commands still work)
  - Unicode handling tests (verify PERL5OPT active)
- **Integration Tests**: Component interaction testing
  - Reference integrity (verify all references updated)
  - Git history preservation (verify `git mv` worked correctly)
- **Acceptance Tests**: Success criteria validation from a-task-plan.md
  - All 6 scripts renamed without extensions
  - PERL5OPT configured and active
  - All shebangs portable
  - All active references updated (historic excluded)

### Test Coverage Targets
- **Phase Validation**: 100% - every phase must have validation checkpoint
- **Success Criteria**: 100% - all 7 criteria from planning must pass
- **Script Execution**: 100% - all 6 renamed scripts must execute
- **Reference Updates**: 100% - zero grep hits for old extensions in active files
- **Regression**: All existing CIG commands must work after refactoring

## Test Cases

### Functional Test Cases

#### Phase 1: Environment Configuration

- **TC-F1**: PERL5OPT environment variable configured
  - **Given**: `.claude/settings.json` has been updated with PERL5OPT
  - **When**: Execute `perl -V | grep PERL5OPT`
  - **Then**: Output shows `PERL5OPT="-CDSL"`

- **TC-F2**: Unicode handling works with PERL5OPT
  - **Given**: PERL5OPT is configured
  - **When**: Execute `echo "Testing: 日本語 中文 한글" | perl -ne 'print'`
  - **Then**: UTF-8 characters display correctly without errors

#### Phase 2: Script Renaming

- **TC-F3**: All 6 scripts renamed successfully
  - **Given**: Implementation has executed git mv commands
  - **When**: Execute `ls -1 .cig/scripts/command-helpers/ | grep -E "^(hierarchy-resolver|context-inheritance|template-copier|format-detector|status-aggregator|template-version-parser)$" | wc -l`
  - **Then**: Output shows 6 (or more if versioned status-aggregators counted)

- **TC-F4**: Old script names no longer exist
  - **Given**: Scripts have been renamed
  - **When**: Execute `ls .cig/scripts/command-helpers/*.{pl,sh} 2>&1`
  - **Then**: Output shows "No such file or directory" or no `.pl`/`.sh` files

- **TC-F5**: Git history preserved through rename
  - **Given**: Scripts renamed with git mv
  - **When**: Execute `git log --follow .cig/scripts/command-helpers/hierarchy-resolver | head -20`
  - **Then**: History shows commits from before rename

#### Phase 3: Shebang Updates

- **TC-F6**: Perl scripts have portable shebangs
  - **Given**: Shebangs have been updated
  - **When**: Execute `head -1 .cig/scripts/command-helpers/hierarchy-resolver`
  - **Then**: Output is `#!/usr/bin/env perl` (no -CDSL flags)

- **TC-F7**: Shell scripts have portable shebangs
  - **Given**: Shebangs have been updated
  - **When**: Execute `head -1 .cig/scripts/command-helpers/template-version-parser`
  - **Then**: Output is `#!/usr/bin/env bash`

- **TC-F8**: All scripts execute without shebang errors
  - **Given**: Shebangs updated and PERL5OPT configured
  - **When**: Execute each script with `--help` flag (6 scripts)
  - **Then**: All scripts run without "bad interpreter" or similar errors

#### Phase 4: Reference Updates

- **TC-F9**: Command files updated
  - **Given**: References in `.claude/commands/*.md` have been updated
  - **When**: Execute `grep -r "\.pl\|\.sh" .claude/commands/ | grep -E "(hierarchy-resolver|context-inheritance|template-copier|format-detector|status-aggregator|template-version-parser)"`
  - **Then**: Output is empty (zero matches)

- **TC-F10**: Documentation files updated
  - **Given**: References in README.md, CLAUDE.md, COMMANDS.md have been updated
  - **When**: Execute `grep -E "hierarchy-resolver\.pl|context-inheritance\.pl|template-copier\.pl|format-detector\.pl|status-aggregator\.pl|template-version-parser\.sh" README.md CLAUDE.md COMMANDS.md`
  - **Then**: Output is empty (zero matches)

- **TC-F11**: Workflow documentation updated
  - **Given**: References in `.cig/docs/**/*.md` have been updated
  - **When**: Execute `grep -r "\.pl\|\.sh" .cig/docs/ | grep -E "(hierarchy-resolver|context-inheritance|template-copier|format-detector|status-aggregator|template-version-parser)"`
  - **Then**: Output is empty (zero matches)

- **TC-F12**: BACKLOG.md updated
  - **Given**: Task 27 entry in BACKLOG.md has been updated
  - **When**: Execute `grep -E "\.pl|\.sh" BACKLOG.md | grep -i "task 27\|standardis"`
  - **Then**: Output is empty (zero matches in Task 27 context)

- **TC-F13**: Historic tasks unchanged
  - **Given**: Historic task directories should NOT be updated
  - **When**: Execute `grep -r "hierarchy-resolver\.pl" implementation-guide/26-feature-update-cig-status-to-use-workflow-flag/`
  - **Then**: Output shows historic references exist (proving they weren't touched)

#### Phase 5: Final Validation

- **TC-F14**: End-to-end command execution
  - **Given**: All changes implemented
  - **When**: Execute `/cig-status`, `/cig-status 27`, `/cig-extract 27 goal`
  - **Then**: All commands execute successfully, return expected output

- **TC-F15**: Script permissions correct
  - **Given**: Scripts have been renamed
  - **When**: Execute `ls -la .cig/scripts/command-helpers/ | grep -E "^-r.x"`
  - **Then**: All 6 renamed scripts have at least u+rx permissions (0500+)

- **TC-F16**: Comprehensive reference check
  - **Given**: All references should be updated
  - **When**: Execute comprehensive grep excluding historic tasks and .git
  - **Then**: Zero results for old script extensions in active files

### Non-Functional Test Cases

#### Security

- **TC-NF1**: Script permissions maintain security model
  - **Given**: All scripts should have u+rx minimum (0500)
  - **When**: Check permissions after rename
  - **Then**: No script has write permissions for group/other, all have execute for owner

- **TC-NF2**: No command injection through extensionless names
  - **Given**: Scripts now invoked without extensions
  - **When**: Test with edge case task paths and arguments
  - **Then**: No shell interpretation of script names as commands

#### Usability

- **TC-NF3**: Error messages remain clear
  - **Given**: Scripts renamed, error paths should still work
  - **When**: Trigger error conditions (invalid arguments, missing files)
  - **Then**: Error messages reference correct script names (without extensions)

- **TC-NF4**: Documentation clarity
  - **Given**: All references updated
  - **When**: User reads documentation
  - **Then**: No confusion from mixed naming (extensions vs extensionless)

#### Reliability

- **TC-NF5**: No regression in existing functionality
  - **Given**: Refactoring should not break existing behavior
  - **When**: Run typical CIG workflow commands
  - **Then**: All commands work identically to before refactoring

- **TC-NF6**: Git history integrity
  - **Given**: Git mv preserves history
  - **When**: Use `git blame`, `git log --follow` on renamed scripts
  - **Then**: Full history accessible, blame annotations correct

#### Portability

- **TC-NF7**: Portable shebangs work across systems
  - **Given**: `/usr/bin/env` finds interpreters in PATH
  - **When**: Scripts executed on Unix/Linux/macOS
  - **Then**: Scripts work regardless of perl/bash installation path

## Test Environment

### Setup Requirements

**Environment**: Linux system with working git repository

**Prerequisites**:
- Git working tree (Task 27 branch: `bugfix/27-standardise-script-naming`)
- Perl installation accessible via PATH (for `#!/usr/bin/env perl`)
- Bash installation accessible via PATH (for `#!/usr/bin/env bash`)
- `.claude/settings.json` with PERL5OPT configured
- Existing CIG system operational (to test regression)

**Test Data**:
- Task 27 implementation guide directory
- Task 26 historic directory (for TC-F13 historic task verification)
- Multiple active markdown files with script references
- BACKLOG.md with Task 27 entry

**No Mock Services Required**: Testing real script execution and file system operations

### Automation

**Current State**: No automated test harness exists for CIG system

**Manual Execution**: All tests executed manually via bash commands provided in test cases

**Future Automation Opportunity** (BACKLOG):
- Create automated test suite for CIG system
- Integrate with CI/CD for pre-commit validation
- Add regression test suite for refactoring tasks

**CI/CD Integration**: Not applicable for this task (manual validation only)

**Test Execution Schedule**:
- Executed once during testing execution phase (g-testing-exec.md)
- Re-run if defects found and fixed
- No ongoing scheduled execution

## Validation Criteria

### Testing Phase Complete When:

**Functional Tests**:
- [ ] All 16 functional test cases pass (TC-F1 through TC-F16)
- [ ] Phase 1: Environment configuration validated (TC-F1, TC-F2)
- [ ] Phase 2: Script renaming validated (TC-F3, TC-F4, TC-F5)
- [ ] Phase 3: Shebang updates validated (TC-F6, TC-F7, TC-F8)
- [ ] Phase 4: Reference updates validated (TC-F9, TC-F10, TC-F11, TC-F12, TC-F13)
- [ ] Phase 5: Final validation complete (TC-F14, TC-F15, TC-F16)

**Non-Functional Tests**:
- [ ] All 7 non-functional test cases pass (TC-NF1 through TC-NF7)
- [ ] Security validation complete (TC-NF1, TC-NF2)
- [ ] Usability validation complete (TC-NF3, TC-NF4)
- [ ] Reliability validation complete (TC-NF5, TC-NF6)
- [ ] Portability validation complete (TC-NF7)

**Coverage Targets**:
- [ ] Phase validation: 100% (all 5 phases validated)
- [ ] Success criteria: 100% (all 7 criteria from planning pass)
- [ ] Script execution: 100% (all 6 scripts execute)
- [ ] Reference updates: 100% (zero grep hits for old extensions in active files)
- [ ] Regression: All existing CIG commands work

**Success Criteria from a-task-plan.md**:
- [ ] All 6 helper scripts renamed without extensions (5 `.pl` + 1 `.sh`)
- [ ] PERL5OPT configured in `.claude/settings.json` for Unicode handling
- [ ] All Perl shebangs updated to `#!/usr/bin/env perl` (portable)
- [ ] Shell shebang updated to `#!/usr/bin/env bash` (portable)
- [ ] All references fixed throughout repo (excluding historic task documents)
- [ ] Unicode test passes (Perl scripts handle UTF-8 correctly)
- [ ] No grep hits for old extensions in active references (excluding historic)

## Status
**Status**: Finished
**Next Action**: Proceed to implementation execution → `/cig-implementation-exec 27`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results

### Testing Plan Completed

**Test Strategy**: Manual validation with phase-level checkpoints aligned to 5-phase implementation strategy

**Test Coverage**:
- **16 functional test cases** (TC-F1 through TC-F16) covering all 5 phases
- **7 non-functional test cases** (TC-NF1 through TC-NF7) covering security, usability, reliability, portability
- **Total: 23 test cases** with Given/When/Then format

**Test Case Distribution by Phase**:
- Phase 1 (Environment): 2 tests
- Phase 2 (Renaming): 3 tests
- Phase 3 (Shebangs): 3 tests
- Phase 4 (References): 5 tests
- Phase 5 (Validation): 3 tests
- Non-functional: 7 tests

**Key Testing Decisions**:

1. **Phase-aligned test structure**: Tests mirror 5-phase implementation for traceability
   - Each phase has dedicated functional tests
   - Enables incremental validation during implementation

2. **Manual validation approach**: No automated test harness (BACKLOG opportunity)
   - Executable bash commands provided in each test case
   - Copy-paste verification during testing execution phase

3. **100% coverage targets**: Every aspect validated
   - All 6 scripts must execute
   - All active references must be updated
   - Zero grep hits for old extensions required

4. **Historic task validation**: TC-F13 verifies historic tasks NOT updated
   - Proves exclusion pattern worked correctly
   - Validates intentional design decision

5. **Non-functional emphasis on reliability and portability**:
   - Git history integrity (TC-NF6)
   - Portable shebangs across systems (TC-NF7)
   - No regression (TC-NF5)

**Test Environment**: Real CIG system on Linux, no mocks required

**Automation Status**: Manual execution only (automated test suite is BACKLOG opportunity)

### Testing Readiness

**Ready for execution**:
- ✅ All test cases defined with executable commands
- ✅ Success criteria aligned to planning phase
- ✅ Coverage targets specified (100% for critical paths)
- ✅ Test environment requirements documented
- ✅ Validation criteria comprehensive

**Next phase**: Implementation execution (`/cig-implementation-exec 27`) will execute the 26-step plan, then testing execution (`/cig-testing-exec 27`) will run these 23 test cases.

## Lessons Learned
*To be captured during testing execution and retrospective*

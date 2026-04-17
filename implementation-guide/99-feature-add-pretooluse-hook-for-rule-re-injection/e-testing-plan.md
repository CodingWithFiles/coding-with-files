# Add PreToolUse hook for rule re-injection - Testing Plan
**Task**: 99 (feature)

## Task Reference
- **Task ID**: internal-99
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/99-add-pretooluse-hook-for-rule-re-injection
- **Template Version**: 2.1

## Goal
Verify rules file content, hook configuration, cwf-init integration, silent failure, and regression.

## Test Strategy
### Test Levels
- **File validation**: Rules file exists, correct content, correct line count
- **Hook validation**: Hook outputs rules content when run
- **Init integration**: cwf-init skill includes hook configuration step
- **Edge cases**: Missing file, existing hooks in settings.json
- **Regression**: cwf-manage validate still passes

## Test Cases

### Rules File Validation
- **TC-1**: Rules file exists with correct content
  - **Given**: `.cwf/rules-inject.txt` created
  - **When**: Read file
  - **Then**: Contains header line plus 4 numbered rules

- **TC-2**: Rules file under 10 lines (NFR1)
  - **Given**: `.cwf/rules-inject.txt`
  - **When**: Count lines
  - **Then**: Under 10 lines (target: 5)

- **TC-3**: All 4 critical rules present
  - **Given**: Rules file content
  - **When**: Grep for each rule keyword
  - **Then**: "skills" (rule 1), "Checkpoint" (rule 2), "merge to main" (rule 3), "git status" (rule 4) all present

### Hook Behaviour
- **TC-4**: Hook command outputs rules content
  - **Given**: `.cwf/rules-inject.txt` exists
  - **When**: Run `cat .cwf/rules-inject.txt 2>/dev/null || true`
  - **Then**: Output matches file content exactly

- **TC-5**: Hook command silent on missing file
  - **Given**: `.cwf/rules-inject.txt` does not exist (temporarily renamed)
  - **When**: Run `cat .cwf/rules-inject.txt 2>/dev/null || true`
  - **Then**: No output, exit code 0

### Init Integration
- **TC-6**: cwf-init skill includes hook configuration step
  - **Given**: Updated `.claude/skills/cwf-init/SKILL.md`
  - **When**: Read skill file
  - **Then**: Contains step 6c with PreToolUse hook configuration, UserPromptSubmit matcher, and cat command

- **TC-7**: cwf-init skill handles idempotent hook addition
  - **Given**: cwf-init step 6c instructions
  - **When**: Read instructions
  - **Then**: Contains check for existing UserPromptSubmit matcher to avoid duplicates

### Regression
- **TC-8**: cwf-manage validate still passes
  - **Given**: All changes applied
  - **When**: Run `perl -I.cwf/lib .cwf/scripts/cwf-manage validate`
  - **Then**: Exit 0, "OK"

## Validation Criteria
- [ ] TC-1 through TC-3: Rules file valid and concise
- [ ] TC-4 through TC-5: Hook command works correctly
- [ ] TC-6 through TC-7: cwf-init updated with idempotent hook step
- [ ] TC-8: No regressions

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 99
**Blockers**: None

## Actual Results
8/8 test cases passed. Test plan was sufficient — no additional tests needed.

## Lessons Learned
- Temporarily renaming a file to test missing-file behaviour is a clean approach for silent-failure tests

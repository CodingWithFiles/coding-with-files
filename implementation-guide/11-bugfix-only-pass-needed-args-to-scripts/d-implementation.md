# Only pass needed args to scripts - Implementation

## Task Reference
- **Task ID**: internal-11
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/11-only-pass-needed-args-to-scripts
- **Template Version**: 2.0

## Goal
Update Context sections in CIG command files to safely handle arbitrary user input by:
1. Removing inline bash execution
2. Having Claude parse and validate `$ARGUMENTS` text
3. Adding format validation for task paths (hierarchical numbers only)
4. Preventing command injection at LLM level before scripts are invoked

## Workflow
Remove `!` notation → Add argument parsing instructions → Add format validation → Claude validates & invokes → Test with special chars and injection attempts

## Files to Modify
### Primary Changes (8 CIG command files)
All in `.claude/commands/`:

1. `cig-design.md` - ✓ Already updated (dogfood test - working!)
2. `cig-implementation.md` - Remove `!` notation, add argument parsing instructions
3. `cig-maintenance.md` - Remove `!` notation, add argument parsing instructions
4. `cig-plan.md` - Remove `!` notation, add argument parsing instructions
5. `cig-requirements.md` - Remove `!` notation, add argument parsing instructions
6. `cig-retrospective.md` - Remove `!` notation, add argument parsing instructions
7. `cig-rollout.md` - Remove `!` notation, add argument parsing instructions
8. `cig-testing.md` - Remove `!` notation, add argument parsing instructions

### Changes Required
- Remove lines with inline bash execution (`!` notation)
- Add `**Task arguments**: $ARGUMENTS` to Context section
- Add **CRITICAL - Argument Parsing** instructions
- Add **CRITICAL - Task Path Validation** instructions (NEW - security layer)
- Update workflow steps to validate format before invoking scripts

### Optional Changes
9. `cig-subtask.md` - May need similar update (uses bash expansion, same vulnerability)

## Implementation Steps
### Step 1: Dogfood Test & Validation
- [x] Updated cig-design.md with new pattern
- [x] Tested with `/cig-design 11 extra text with special chars`
- [x] Confirmed Claude successfully parsed arguments and invoked scripts
- [x] Documented pattern in c-design.md

### Step 2: Update Remaining 7 Core Workflow Commands (Initial Pattern)
- [x] Update cig-implementation.md (with initial pattern)
- [x] Update cig-maintenance.md (with initial pattern)
- [x] Update cig-plan.md (with initial pattern)
- [x] Update cig-requirements.md (with initial pattern)
- [x] Update cig-retrospective.md (with initial pattern)
- [x] Update cig-rollout.md (with initial pattern)
- [x] Update cig-testing.md (with initial pattern)

### Step 2b: Update All 8 Commands with Clearer Instructions
- [x] Update cig-design.md with clearer wording
- [x] Update cig-implementation.md with clearer wording
- [x] Update cig-maintenance.md with clearer wording
- [x] Update cig-plan.md with clearer wording
- [x] Update cig-requirements.md with clearer wording
- [x] Update cig-retrospective.md with clearer wording
- [x] Update cig-rollout.md with clearer wording
- [x] Update cig-testing.md with clearer wording

### Step 2c: Add Format Validation to All 8 Commands (Security Enhancement)
- [x] Update cig-design.md with validation requirement
- [x] Update cig-implementation.md with validation requirement
- [x] Update cig-maintenance.md with validation requirement
- [x] Update cig-plan.md with validation requirement
- [x] Update cig-requirements.md with validation requirement
- [x] Update cig-retrospective.md with validation requirement
- [x] Update cig-rollout.md with validation requirement
- [x] Update cig-testing.md with validation requirement

### Step 3: Validation
- [ ] Test each command with extra text: `/cig-X 11 with extra text`
- [ ] Test with special characters: `/cig-X 11 she said "hello`
- [ ] Verify all commands successfully invoke scripts
- [ ] Confirm no bash parsing errors

### Step 4: Optional - Update Other Commands
- [ ] Check cig-subtask.md for similar issues
- [ ] Update if needed

## Code Changes
### Before (Broken - Using `$1` with inline bash)
```markdown
## Context
- Task resolution: !`.cig/scripts/command-helpers/hierarchy-resolver.pl $1 2>/dev/null...`
- Parent context: !`.cig/scripts/command-helpers/context-inheritance.pl $1 2>/dev/null...`

## Your task
Guide the user through the X phase for task: **$1**
**Additional context**: $ARGUMENTS
```

**Problems**:
- `$1` does NOT exist in Claude Code (only `$ARGUMENTS`)
- Inline bash execution (`!`) fails on special characters (quotes, backticks, etc.)
- Cannot safely handle arbitrary user input

### After (Secure - Claude Validates & Parses Text)
```markdown
## Context
**Task arguments**: $ARGUMENTS

## Your task
Guide the user through the X phase.

**CRITICAL - Argument Parsing**:
- Extract the FIRST space-separated word from the task arguments above as the task path
- Any additional words after the first provide user context about their intent
- Use the extra words to understand what the user wants, but do NOT pass them to script calls
- Example: "11 update the design" → task path is "11", extra text explains what to do

**CRITICAL - Task Path Validation**:
- Task paths MUST match hierarchical number format: digits separated by dots
- Valid formats: "11", "1.2", "12.2.3", "1.1.1.1"
- Invalid formats: "some text", "`date`", "11; rm -rf", "text.text"
- If first word does NOT match valid format, inform user and do not invoke scripts
- This prevents command injection and ensures only valid task identifiers reach scripts

Follow the 8-step workflow structure:

1. **Resolve Task Directory**:
   - Extract first word from task arguments
   - Validate it matches hierarchical number format (digits and dots only)
   - If valid: call `.cig/scripts/command-helpers/hierarchy-resolver.pl <task-path>` using the Bash tool
   - If invalid: inform user the task path format is invalid, do not invoke script

2. **Load Parent Context**:
   - Use the validated task path from step 1
   - Call `.cig/scripts/command-helpers/context-inheritance.pl <task-path>` using the Bash tool
```

**Fix**:
- No inline bash execution - removes bash parsing vulnerabilities
- Claude reads `$ARGUMENTS` as text, extracts first word
- **Claude validates format before invoking bash** (NEW - defense in depth)
- Only hierarchical numbers (e.g., 11, 1.2.3) allowed - rejects injection attempts
- Claude constructs Bash command with literal value (safe for any input)
- Handles quotes, special chars, backticks safely

## Test Coverage
- **Manual Testing**: Test each command with extra text: `/cig-X 11 with extra text`
- **Special Characters**: Test with quotes, backticks: `/cig-X 11 she said "hello`
- **Regression**: Verify existing task path only usage works: `/cig-X 11`
- **Edge Cases**: Test with task paths containing dots (e.g., 1.1, 1.2.3)
- **Validation Testing** (NEW): Test format validation rejects invalid inputs:
  - Command injection: `/cig-X \`date\` test` - should reject before invoking bash
  - Arbitrary text: `/cig-X some-text test` - should reject
  - Shell metacharacters: `/cig-X "11; rm -rf" test` - should reject

## Validation Criteria
- [x] Researched and confirmed `$1` does NOT exist (GitHub issues #4370, #5520)
- [x] Documented Claude-parses-text pattern in c-design.md
- [x] Dogfood tested cig-design.md successfully
- [x] All 7 remaining command files updated with new pattern
- [x] Updated design with format validation requirement
- [x] All 8 command files updated with validation requirement
- [ ] All commands tested with extra text and special characters
- [ ] Format validation tested (rejection of invalid inputs)
- [ ] No bash parsing errors occur

## Status
**Status**: Cancelled
**Cancellation Reason**: Superseded by Task 57 — commands converted to skills, bypassing the $ARGUMENTS parsing bug entirely
**Next Action**: None
**Blockers**: None

## Actual Results
### Discovery & Design Process
1. **Problem identified**: Commands fail when extra text passed after task number
2. **First attempt**: Used `$ARG1` - not recognized by Claude Code
3. **Second attempt**: Used `$1` based on documentation - still failed
4. **Root cause discovery**:
   - Only `$ARGUMENTS` exists (GitHub issues #4370, #5520)
   - `$1`, `$2`, `$3` do NOT exist
   - Inline bash execution unsafe for arbitrary input
5. **Solution designed**: Remove `!` notation, have Claude parse `$ARGUMENTS` text
6. **Dogfood test**: Updated cig-design.md, tested successfully with extra text
7. **Design documented**: c-design.md updated with working pattern

### Current State
All 8 command files updated with new pattern:
- ✓ cig-design.md updated and tested (working!)
- ✓ cig-implementation.md updated
- ✓ cig-maintenance.md updated
- ✓ cig-plan.md updated
- ✓ cig-requirements.md updated
- ✓ cig-retrospective.md updated
- ✓ cig-rollout.md updated
- ✓ cig-testing.md updated

### Implementation Complete
All files now use the Claude-validates-and-parses pattern with security enhancements:
- No inline bash execution (`!` notation removed)
- Claude parses `$ARGUMENTS` text to extract task path
- **Claude validates format before invoking bash** (NEW - defense in depth)
- Extra words provide user context about intent (not ignored!)
- Claude uses extra words to understand what user wants
- Only hierarchical numbers allowed (11, 1.2.3) - rejects invalid formats
- Scripts invoked via Bash tool with validated literal values
- Safe for arbitrary user input (quotes, special chars, backticks, injection attempts)

### Instruction Wording Evolution
**Initial pattern (ambiguous)**:
- "Any additional words after the first are extra context, ignore them for script calls"
- Could be misinterpreted as "ignore the context entirely"

**Updated pattern (clear)**:
- "Any additional words after the first provide user context about their intent"
- "Use the extra words to understand what the user wants, but do NOT pass them to script calls"
- Example: "11 update the design" → task path is "11", extra text explains what to do

**Security enhancement (validation added)**:
- Added format validation requirement to prevent command injection
- LLM validates task path matches hierarchical number format before invoking bash
- Defense in depth: validation at LLM level + script level
- Valid formats: digits separated by dots (11, 1.2, 12.2.3)
- Invalid formats rejected with clear error message

## Lessons Learned
- Documentation can be outdated/incorrect - verify with GitHub issues and real usage
- Test with edge cases (special characters) early in the process
- Dogfooding changes incrementally catches issues before full rollout
- Bash parsing is fundamentally unsafe for untrusted user input
- LLM text parsing is more robust than bash variable expansion
- After 3 failures, stop and research the actual implementation (GitHub, source code)
- **Defense in depth is critical**: Testing revealed LLM passed backticks to bash before scripts could reject them - need validation at LLM level, not just script level
- **Be explicit about security requirements**: LLM needs clear instructions on what formats are valid, not just how to extract arguments

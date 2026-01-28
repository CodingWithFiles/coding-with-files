# Only pass needed args to scripts - Testing

## Task Reference
- **Task ID**: internal-11
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/11-only-pass-needed-args-to-scripts
- **Template Version**: 2.0

## Goal
Validate that all 8 CIG workflow commands safely handle arbitrary user input (including special characters) when passing arguments to helper scripts.

## Test Strategy
### Test Levels
- **Manual Integration Tests**: Test each command with various argument patterns to verify safe script invocation
- **Regression Tests**: Verify existing functionality (task path only) still works
- **Edge Case Tests**: Test special characters, quotes, backticks that previously caused bash parsing failures

### Test Coverage Targets
- **Overall Coverage**: 100% of 8 workflow commands tested
- **Critical Paths**: All commands with extra text and special characters
- **Edge Cases**: Unmatched quotes, backticks, multiple spaces, empty extra text
- **Regression**: All commands with task path only (existing usage pattern)

## Test Cases
### Functional Test Cases

- **TC-1**: Command handles task path with extra text
  - **Given**: All 8 CIG workflow commands updated with new argument parsing pattern
  - **When**: User invokes command with `/cig-X 11 with some extra text`
  - **Then**: Claude extracts "11" as task path, successfully invokes helper scripts, ignores extra text

- **TC-2**: Command handles unmatched single quote
  - **Given**: All 8 CIG workflow commands updated with new argument parsing pattern
  - **When**: User invokes command with `/cig-X 11 and i'm passing text with one single quote`
  - **Then**: Claude extracts "11" as task path, successfully invokes helper scripts without bash parsing error

- **TC-3**: Command handles unmatched double quote
  - **Given**: All 8 CIG workflow commands updated with new argument parsing pattern
  - **When**: User invokes command with `/cig-X 11 she said "hello`
  - **Then**: Claude extracts "11" as task path, successfully invokes helper scripts without bash parsing error

- **TC-4**: Command handles backticks
  - **Given**: All 8 CIG workflow commands updated with new argument parsing pattern
  - **When**: User invokes command with `/cig-X 11 code snippet: `somefunction()`
  - **Then**: Claude extracts "11" as task path, successfully invokes helper scripts without command injection

- **TC-5**: Regression - Command handles task path only (existing usage)
  - **Given**: All 8 CIG workflow commands updated with new argument parsing pattern
  - **When**: User invokes command with `/cig-X 11` (no extra text)
  - **Then**: Claude extracts "11" as task path, works identically to previous version

- **TC-6**: Command handles subtask paths with dots
  - **Given**: All 8 CIG workflow commands updated with new argument parsing pattern
  - **When**: User invokes command with `/cig-X 1.1 extra text`
  - **Then**: Claude extracts "1.1" as task path, successfully invokes helper scripts

- **TC-7**: Command handles multiple spaces in extra text
  - **Given**: All 8 CIG workflow commands updated with new argument parsing pattern
  - **When**: User invokes command with `/cig-X 11    multiple   spaces   here`
  - **Then**: Claude extracts "11" as task path, successfully invokes helper scripts

- **TC-8**: All 8 commands tested
  - **Given**: All workflow commands updated (cig-plan, cig-requirements, cig-design, cig-implementation, cig-testing, cig-rollout, cig-maintenance, cig-retrospective)
  - **When**: Each command invoked with extra text pattern
  - **Then**: All 8 commands successfully parse arguments and invoke scripts

### Non-Functional Test Cases
- **Security Tests**: Verify no bash command injection possible through user input (TC-4 validates this)
- **Usability Tests**: Extra text provides context to user without breaking functionality
- **Reliability Tests**: Commands handle malformed input gracefully without crashing

## Test Environment
### Setup Requirements
- CIG system installed and initialized (`.cig/` directory structure present)
- Task 11 exists at `implementation-guide/11-bugfix-only-pass-needed-args-to-scripts/`
- All 8 command files updated with new argument parsing pattern
- Helper scripts operational (hierarchy-resolver.pl, context-inheritance.pl)

### Automation
- **Manual testing required**: This is a CLI interaction bugfix that requires human validation
- **Test approach**: Systematically invoke each of the 8 commands with test case patterns
- **No CI/CD integration**: Manual validation of user-facing command behavior

## Validation Criteria
- [x] TC-1: Extra text pattern tested on at least one command (✓ cig-design.md dogfood test passed)
- [x] TC-2: Single quote handling verified (✓ cig-testing invocation passed)
- [x] TC-3: Double quote handling verified (✓ cig-testing invocation with unbalanced `"` passed)
- [x] TC-4: Backtick handling verified (✓ command injection prevented - backticks passed as literal string)
- [x] TC-4b: LLM validation layer verified (✓ format validation prevents invalid task paths from reaching bash)
- [x] TC-4c: Invalid task path rejection verified (✓ LLM rejects backticks as task path)
- [x] TC-5: Regression test - task path only still works (✓ `/cig-testing 11` passed)
- [x] TC-6: Subtask paths (with dots) work correctly (✓ `/cig-testing 11.1` format accepted)
- [x] TC-7: Multiple spaces handled correctly (✓ `/cig-testing    11  with lots more spaces` passed)
- [ ] TC-8: All 8 commands tested with at least one special character pattern
- [x] No bash parsing errors occur in any test case (✓ all TCs passed)
- [x] Helper scripts successfully invoked with correct task path in all cases (✓ all valid tests)
- [x] Command injection prevented at LLM level (✓ TC-4b, TC-4c validated)
- [x] Defense in depth working (✓ LLM validation + script validation)
- [x] Backwards compatibility maintained (✓ TC-5 regression test passed)
- [x] Hierarchical number format with dots accepted (✓ TC-6 passed)
- [x] Multiple/leading spaces handled robustly (✓ TC-7 passed)

## Status
**Status**: Blocked
**Next Action**: Waiting on Task 32 (inference-based context) - architectural shift away from argument passing
**Blockers**: Implementation blocked; testing cannot complete until implementation unblocked

## Actual Results
### Tests Completed
- ✓ TC-1: Verified with `/cig-design 11 extra text` dogfood test - Claude successfully extracted "11" and used extra text as context
- ✓ TC-2: Verified with `/cig-testing 11 and i'm passing text with one single quote` - No bash parsing error, scripts invoked successfully
- ✓ TC-3: Verified with `/cig-testing 11 now check that the rest of the input is treated as context and also make sure that unbalanced characters, like `"`, which are interpreted by bash no longer cause problems` - Unbalanced double quote handled successfully, no bash parsing error, Claude understood user intent from extra context

### Test Analysis for TC-3
This invocation demonstrates both key requirements:
1. **Extra input treated as context**: Claude read the full argument string and understood the user wanted to verify context handling and bash character safety
2. **Unbalanced bash characters handled**: The literal `"` character in the argument string would have caused bash parsing failure in the old implementation using inline `!` notation, but works perfectly with the new Claude-parses approach

- ✓ TC-4: Verified with `/cig-testing `date` make sure that we can't inject commands into scripts` - Command injection prevented, backticks passed as literal string to script

### Test Analysis for TC-4 (Security Critical - Initial Test)
This invocation demonstrates command injection prevention at script level:
1. **User provided**: Argument string starting with backticks: `` `date` make sure... ``
2. **Claude extracted**: First word `` `date` `` as literal string (not executed)
3. **Script received**: Literal string `\`date\`` passed to hierarchy-resolver.pl
4. **Result**: Script rejected invalid task path format (expected), but **no command execution occurred**
5. **Security gap identified**: LLM passed backticks to bash - script rejected them, but bash still parsed the command

**Security gap**: Claude passed invalid format to bash tool before scripts could validate. Need LLM-level validation.

- ✓ TC-4b: Verified with `/cig-testing 11 `echo command test`` - **LLM validation prevents bash invocation**

### Test Analysis for TC-4b (Security Critical - Validation Layer)
This invocation demonstrates command injection prevention at LLM level (NEW - after validation enhancement):
1. **User provided**: `` 11 `echo command test` `` - valid task path "11" with backticks in extra context
2. **Claude extracted**: First word "11"
3. **Claude validated**: "11" matches hierarchical number format ✓
4. **Scripts invoked**: Only validated "11" passed to scripts
5. **Security validation**: Backticks `` `echo command test` `` remained in extra context, never passed to bash
6. **Defense in depth**: LLM validation layer prevents invalid formats from reaching bash entirely

**Old implementation vulnerability**: Using inline bash execution, backticks would be interpreted immediately

**New implementation security with validation**:
- Layer 1 (LLM): Validates format, rejects invalid task paths BEFORE bash invocation
- Layer 2 (Script): Scripts validate as fallback if LLM validation bypassed
- Result: Defense in depth prevents command injection at multiple levels

- ✓ TC-4c: Verified with `/cig-testing \`date\`` - **LLM validation rejects invalid task path**

### Test Analysis for TC-4c (Security Critical - Invalid Task Path Rejection)
This invocation demonstrates LLM validation rejecting invalid task paths:
1. **User provided**: `` `date` `` - backticks as task path (command injection attempt)
2. **Claude extracted**: First word `` `date` ``
3. **Claude validated**: `` `date` `` does NOT match hierarchical number format ✗
4. **Result**: Validation rejected, scripts NOT invoked, user informed of invalid format
5. **Security validation**: Complete prevention - bash never invoked, no command execution possible

**Defense in depth validation**: LLM blocks invalid formats before any bash interaction.

- ✓ TC-5: Verified with `/cig-testing 11` - **Regression test passed**

### Test Analysis for TC-5 (Regression Test)
This invocation demonstrates backwards compatibility:
1. **User provided**: "11" (task path only, no extra text - original usage pattern)
2. **Claude extracted**: First word "11"
3. **Claude validated**: "11" matches hierarchical number format ✓
4. **Scripts invoked**: Successfully resolved task 11
5. **Regression validation**: Existing usage pattern works identically to before

**Backwards compatibility**: Users can continue using commands without extra text.

- ✓ TC-6: Verified with `/cig-testing 11.1` - **Subtask path format accepted**

### Test Analysis for TC-6 (Subtask Path Validation)
This invocation demonstrates hierarchical number format with dots:
1. **User provided**: "11.1" (subtask path with dot notation)
2. **Claude extracted**: First word "11.1"
3. **Claude validated**: "11.1" matches hierarchical number format (^\d+(\.\d+)*$) ✓
4. **Scripts invoked**: hierarchy-resolver.pl received "11.1"
5. **Script result**: Task not found (expected - 11.1 doesn't exist in repository)
6. **Format validation success**: "11.1" accepted by LLM, passed to script correctly

**Validation layer correctness**: LLM validates format (digits and dots), scripts validate existence. This is the correct separation of concerns.

- ✓ TC-7: Verified with `/cig-testing    11  with lots more spaces` - **Multiple spaces handled correctly**

### Test Analysis for TC-7 (Multiple Spaces Handling)
This invocation demonstrates robust argument parsing with multiple spaces:
1. **User provided**: "   11  with lots more spaces" (leading spaces, multiple spaces between words)
2. **Claude extracted**: First word "11" (correctly parsed despite extra spaces)
3. **Claude validated**: "11" matches hierarchical number format ✓
4. **Scripts invoked**: hierarchy-resolver.pl successfully received "11"
5. **Extra context preserved**: "with lots more spaces" - Claude understood test intent
6. **Parsing robustness**: Multiple/leading spaces don't break argument extraction

**Whitespace handling**: Space-separated word extraction works correctly regardless of spacing.

### Tests Remaining
- TC-8: All 8 commands tested

## Lessons Learned
- Dogfooding the fix incrementally (testing cig-design.md first) validated the approach before full rollout
- The current invocation (`/cig-testing 11 and i'm...`) successfully demonstrates the fix is working - the single quote in "i'm" would have caused bash parsing failure in the old implementation

# fix inconclusive inference output format - Testing

## Task Reference
- **Task ID**: internal-37
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/37-fix-inconclusive-inference-output-format
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for fix inconclusive inference output format.

## Test Strategy
### Test Levels
- **Unit Tests**: Test `format_output()` function with mocked context hashes
- **Integration Tests**: Test full inference pipeline (signals → correlation → output)
- **System Tests**: Test command-line wrapper script with real task directories
- **Regression Tests**: Verify existing Task 32 tests still pass

### Test Coverage Targets
- **Overall Coverage**: 100% of output format code paths
- **Critical Paths**: All three scenarios (conclusive, inconclusive, no_signals) - 100% coverage required
- **Edge Cases**: Empty arrays, missing fields, unusual task numbers/slugs
- **Regression**: All 22 existing Task 32 tests must continue passing

## Test Cases
### Functional Test Cases

#### TC-1: Conclusive Output Format (Regression)
- **Given**: Context hash with `current: conclusive` and singular fields populated
- **When**: `format_output($context)` is called
- **Then**: Output includes:
  - `current: conclusive`
  - `confidence: correlated`
  - `task_num: 37` (singular)
  - `task_slug: fix-inconclusive-inference-output-format` (singular)
  - `workflow_step: e-testing-plan` (singular)
  - Exit code: 0
  - Format is parseable with `/^(\w+): (.+)$/` regex

#### TC-2: Inconclusive Output Format - Uncorrelated Signals
- **Given**: Context hash with `current: inconclusive`, `confidence: uncorrelated`, and plural arrays populated
- **When**: `format_output($context)` is called
- **Then**: Output includes:
  - `current: inconclusive`
  - `confidence: uncorrelated`
  - `task_nums: 14,32,37` (plural, comma-separated)
  - `task_slugs: retro-suggest-updating,task-tracking-inference,fix-inconclusive-output` (plural)
  - `workflow_steps: j-retrospective,j-retrospective,e-testing-plan` (plural)
  - `candidates: 3`
  - `reasons: branch_signal,recency_signal,progress_signal` (which signals contributed)
  - Exit code: 1
  - Format is parseable, values can be split on comma

#### TC-3: Inconclusive Output Format - No Signals
- **Given**: Context hash with `current: inconclusive`, `confidence: no_signals`
- **When**: `format_output($context)` is called
- **Then**: Output includes:
  - `current: inconclusive`
  - `confidence: no_signals`
  - `task_nums: unknown`
  - `task_slugs: unknown`
  - `workflow_steps: unknown`
  - `candidates: 0`
  - `reasons: none`
  - Exit code: 3
  - Format is parseable

#### TC-4: Parseability - Simple Regex Extraction
- **Given**: Any output format (conclusive or inconclusive)
- **When**: Output is parsed with regex `/^(\w+): (.+)$/m` for each line
- **Then**:
  - All fields are extracted successfully
  - Field names match specification (current, confidence, task_num(s), etc.)
  - No nested structures or JSON required

#### TC-5: Parseability - Comma-Separated Values
- **Given**: Inconclusive output with plural fields
- **When**: Field values are split on comma: `split(/,/, $value)`
- **Then**:
  - `task_nums` splits into individual task numbers
  - `task_slugs` splits into individual slugs
  - `workflow_steps` splits into individual steps
  - `reasons` splits into individual signal names

#### TC-6: Backward Compatibility Detection
- **Given**: Command/skill needs to detect format version
- **When**: Output is checked for `current` field
- **Then**:
  - If `current:` line exists → v2 format (structured)
  - If `current:` line missing → v1 format (conclusive only)
  - Commands can adapt parsing logic based on version

#### TC-7: Edge Case - Empty Candidates
- **Given**: Context hash with empty arrays for plural fields
- **When**: `format_output($context)` is called
- **Then**:
  - Plural fields default to "unknown"
  - `candidates: 0`
  - No crashes or undefined behavior

#### TC-8: Edge Case - Single Candidate in Plural Format
- **Given**: Context hash with inconclusive status but only 1 candidate
- **When**: `format_output($context)` is called
- **Then**:
  - Plural fields contain single value (no trailing comma)
  - `task_nums: 37` (not "37,")
  - Format remains consistent

### Non-Functional Test Cases

#### Performance Tests
- **TC-P1**: Output Generation Performance
  - **Given**: Context hash with 100 candidate tasks (stress test)
  - **When**: `format_output($context)` is called
  - **Then**: Completes in <10ms (string concatenation is O(n))
  - **Rationale**: Ensure comma-joining large arrays doesn't cause performance issues

#### Security Tests
- **TC-S1**: Field Injection Prevention
  - **Given**: Task slug contains special characters: `task-with-"quotes"-and-\nnewlines`
  - **When**: Slug is included in output
  - **Then**: Special characters are sanitized or escaped, no format corruption

- **TC-S2**: Command Injection via Task Numbers
  - **Given**: Malicious task number: `37; rm -rf /`
  - **When**: Task number is validated and included in output
  - **Then**: Validation rejects non-numeric task numbers, no code execution

#### Usability Tests
- **TC-U1**: Output Readability
  - **Given**: Inconclusive output with 3 candidates
  - **When**: Human user reads output
  - **Then**: Field names are self-documenting (plural indicates multiple values)
  - **Then**: `reasons` field clearly shows which signals contributed

- **TC-U2**: Command/Skill Parsing Ease
  - **Given**: Command needs to extract task numbers from output
  - **When**: Command uses simple regex or split operations
  - **Then**: Extraction succeeds without JSON parser or complex parsing logic

#### Reliability Tests
- **TC-R1**: Missing Field Handling
  - **Given**: Context hash missing optional fields (e.g., no `reasons` array)
  - **When**: `format_output($context)` is called
  - **Then**: Uses safe defaults ("none", "unknown"), no crashes

- **TC-R2**: Exit Code Consistency
  - **Given**: Various output scenarios (conclusive, uncorrelated, no_signals)
  - **When**: Wrapper script processes output
  - **Then**: Exit codes remain unchanged from Task 32 (0, 1, 3)

## Test Environment
### Setup Requirements
- **Test Repository**: Use CIG repository itself as test environment (has real tasks)
- **Test Tasks**: Tasks 32, 34, 35, 36, 37 available for signal testing
- **Perl Environment**: Perl 5.10+ with core modules only (no external dependencies)
- **Mock Data**: Context hash fixtures for unit tests (conclusive, inconclusive, no_signals)
- **Git State**: Control branch, recency, and progress signals by manipulating test tasks

### Test Execution Methods

#### Unit Tests (Manual)
- Create test script: `t/test-output-format.pl`
- Mock context hashes for each scenario
- Call `format_output()` directly
- Assert output matches specification using regex matching

#### Integration Tests (Manual)
- Run `task-context-inference` wrapper script
- Verify full pipeline: signal gathering → correlation → formatted output
- Check exit codes (0, 1, 3) match output format

#### Regression Tests (Automated)
- Rerun existing Task 32 test suite
- All 22 tests must continue passing
- Verify conclusive output still works correctly

### Automation
- **Test Framework**: Perl Test::Simple or manual assertions
- **CI/CD Integration**: Not applicable (internal CIG tool, no CI/CD pipeline)
- **Test Execution**: Manual execution via `perl t/test-output-format.pl`
- **Validation**: Grep/diff verification for batch validation

## Validation Criteria
- [ ] **TC-1 through TC-8**: All functional test cases passing
- [ ] **TC-P1**: Performance test passing (<10ms for 100 candidates)
- [ ] **TC-S1, TC-S2**: Security tests passing (no injection vulnerabilities)
- [ ] **TC-U1, TC-U2**: Usability tests passing (parseable, self-documenting)
- [ ] **TC-R1, TC-R2**: Reliability tests passing (safe defaults, consistent exit codes)
- [ ] **Regression**: All 22 existing Task 32 tests continue passing
- [ ] **Coverage**: 100% of output format code paths tested
- [ ] **Parseability**: Output can be parsed with simple regex and string split operations
- [ ] **Exit Codes**: Verified unchanged (0=conclusive, 1=uncorrelated, 3=no_signals)
- [ ] **Documentation**: state-tracking.md updated with format specification and examples

## Decomposition Check
Review these signals to determine if testing should be broken into subtasks:
- [ ] **Time**: Will testing take >1 week? **No** - Estimated 1-2 hours for test execution
- [ ] **People**: Does testing need >2 people? **No** - Single tester can execute all tests
- [ ] **Complexity**: Does testing involve 3+ distinct concerns? **No** - 2 concerns (unit tests, regression)
- [ ] **Risk**: Are there high-risk tests needing isolation? **No** - Medium risk, deterministic output format
- [ ] **Independence**: Can test groups run separately? **No** - Regression depends on implementation completion

**Analysis**: 0/5 signals triggered. Testing is appropriately scoped as single phase with 16 test cases.

## Status
**Status**: Finished
**Next Action**: Move to implementation execution → `/cig-implementation-exec 37`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

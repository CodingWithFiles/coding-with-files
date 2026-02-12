# Test context injection syntax - Testing Plan
**Task**: 55 (discovery)

## Task Reference
- **Task ID**: internal-55
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/55-test-context-injection-syntax
- **Template Version**: 2.1

## Goal
Define validation criteria for the context injection syntax experiment, ensuring results are unambiguous and actionable.

## Test Strategy

**Note**: Discovery task — tests validate experiment results, not software functionality.

### Test Levels
- **Per-syntax validation**: Each injection syntax tested independently with clear PASS/FAIL
- **Real-world validation**: If basic syntax works, confirm it works with actual CIG helper scripts
- **Cleanup validation**: Test skills removed after experiment

### Coverage Targets
- **Syntax coverage**: 100% of identified injection patterns (2 patterns)
- **Evidence quality**: Each test produces observable, documentable evidence

## Test Cases

### Functional Test Cases

- **TC-1**: `!{bash}` block with simple echo
  - **Given**: Test skill `cig-test-bash-block` created with `!{bash}\necho "INJECTION_TEST_MARKER_1234"`
  - **When**: User invokes `/cig-test-bash-block`
  - **Then**: Expanded prompt contains "INJECTION_TEST_MARKER_1234" (not the raw `!{bash}` syntax)

- **TC-2**: `!{bash}` block with CIG helper script
  - **Given**: Test skill `cig-test-bash-block` created with `!{bash}\n.cig/scripts/command-helpers/context-manager location`
  - **When**: User invokes `/cig-test-bash-block`
  - **Then**: Expanded prompt contains "Git repo root:" output (not the raw script path)

- **TC-3**: `!` path shorthand
  - **Given**: Test skill `cig-test-inline-inject` created with `!/current-task-wf`
  - **When**: User invokes `/cig-test-inline-inject`
  - **Then**: Expanded prompt contains task context output (not the raw `!/current-task-wf` literal)

- **TC-4**: `!` path shorthand inline with surrounding text
  - **Given**: Test skill `cig-test-inline-inject` created with `Before: !/current-task-wf :After`
  - **When**: User invokes `/cig-test-inline-inject`
  - **Then**: Expanded prompt contains "Before:" followed by task context followed by ":After"

### Non-Functional Test Cases

- **TC-5**: Test skill cleanup
  - **Given**: Both test skills exist in `.claude/skills/`
  - **When**: `rm -rf .claude/skills/cig-test-bash-block .claude/skills/cig-test-inline-inject`
  - **Then**: `ls .claude/skills/cig-test-*` returns error; no test artefacts remain

- **TC-6**: Test skill isolation
  - **Given**: Both test skills created
  - **When**: User invokes existing CIG commands (e.g., `/cig-status`)
  - **Then**: Existing commands work normally; test skills don't interfere

## Test Environment
### Setup Requirements
- Claude Code with skills support (current version)
- `.claude/skills/` directory exists and is writable
- CIG helper scripts accessible (for TC-2)

### Automation
- Manual execution — context injection is observed in the LLM's expanded prompt, not programmatically testable
- Results recorded by the LLM observing its own input

## Validation Criteria
- [ ] TC-1 and TC-2 executed with PASS/FAIL result for `!{bash}` syntax
- [ ] TC-3 and TC-4 executed with PASS/FAIL result for `!` path syntax
- [ ] TC-5 confirms cleanup (no test artefacts)
- [ ] TC-6 confirms no interference with existing commands
- [ ] If any test fails, FR3 (alternative approaches) documented

## Status
**Status**: Finished
**Next Action**: /cig-implementation-exec 55
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
6/6 test cases executed: 4 FAIL (TC-1 to TC-4, both injection syntaxes), 2 PASS (TC-5 cleanup, TC-6 isolation). All validation criteria met. FR3 alternatives documented.

## Lessons Learned
- Test cases with clear binary outcomes (literal text visible vs expanded content) make PASS/FAIL judgement unambiguous
- Non-functional tests (cleanup, isolation) are worth including even for small experiments

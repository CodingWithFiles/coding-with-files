# Test context injection syntax - Testing Execution
**Task**: 55 (discovery)

## Task Reference
- **Task ID**: internal-55
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/55-test-context-injection-syntax
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Finished" — all tests executed with clear verdicts

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-1 | `!{bash}` block with simple echo | Expanded prompt contains "INJECTION_TEST_MARKER_1234" | Raw literal `!{bash}\necho "INJECTION_TEST_MARKER_1234"` visible as plain text in skill prompt | **FAIL** | Syntax not processed by skills loader |
| TC-2 | `!{bash}` block with CIG helper script | Expanded prompt contains "Git repo root:" output | Raw literal `!{bash}\n.cig/scripts/command-helpers/context-manager location` visible as plain text | **FAIL** | Same root cause as TC-1 |
| TC-3 | `!` path shorthand (standalone) | Expanded prompt contains task context output | Raw literal `!/current-task-wf` visible as plain text | **FAIL** | Path shorthand not processed by skills loader |
| TC-4 | `!` path shorthand (inline) | "Before:" + task context + ":After" | Raw literal `Before: !/current-task-wf :After` visible as plain text | **FAIL** | Same root cause as TC-3 |

### Non-Functional Tests

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-5 | Test skill cleanup | `ls .claude/skills/cig-test-*` returns error; no test artefacts remain | `ls: cannot access '.claude/skills/cig-test-*': No such file or directory` | **PASS** | Both test skill directories removed cleanly |
| TC-6 | Test skill isolation | Existing CIG commands work normally; test skills don't interfere | CIG commands (`/cig-status`, `/cig-implementation-exec`, etc.) worked throughout; test skills appeared/disappeared from skills list without affecting other skills | **PASS** | No interference observed |

### Summary

| Category | PASS | FAIL | Total |
|----------|------|------|-------|
| Functional (TC-1 to TC-4) | 0 | 4 | 4 |
| Non-Functional (TC-5 to TC-6) | 2 | 0 | 2 |
| **Total** | **2** | **4** | **6** |

## Test Failures

### TC-1 and TC-2: `!{bash}` Block Syntax

**Root cause**: The `!{bash}` context injection syntax is a feature of the `.claude/commands/` loader. The `.claude/skills/` loader delivers the SKILL.md body as static text without processing any injection directives.

**Reproduction**:
1. Create `.claude/skills/cig-test-bash-block/SKILL.md` with `!{bash}\necho "MARKER"` in the body
2. Invoke `/cig-test-bash-block`
3. Observe the expanded skill prompt — raw `!{bash}` syntax appears literally

**Impact**: Skills cannot use `!{bash}` to pre-inject dynamic context. Alternative: use `allowed-tools: [Bash]` and instruct the LLM to run commands at runtime via tool calls.

### TC-3 and TC-4: `!` Path Shorthand

**Root cause**: Same as TC-1/TC-2. The `!` path shorthand is also a commands-loader feature, not processed by the skills loader.

**Reproduction**:
1. Create `.claude/skills/cig-test-inline-inject/SKILL.md` with `!/current-task-wf` in the body
2. Invoke `/cig-test-inline-inject`
3. Observe the expanded skill prompt — raw `!/current-task-wf` appears literally

**Impact**: Skills cannot use `!` shorthand for inline context injection. Alternative: instruct the LLM to use Read tool to load context files at runtime.

### Common Observations

1. **No error or warning**: Both syntaxes silently pass through as literal text. No indication of failure.
2. **Skills ARE detected and delivered**: SKILL.md frontmatter is parsed correctly, skill body is delivered as the prompt. The failure is specifically in context injection processing.
3. **Key architectural difference**: Commands pre-inject context (before LLM sees prompt). Skills deliver static text and the LLM must load dynamic context via tool calls (1-2 extra round trips).

## Coverage Report

| Metric | Value |
|--------|-------|
| Syntax patterns tested | 2/2 (100%) — `!{bash}` block and `!` path shorthand |
| Test cases executed | 6/6 (100%) |
| Evidence quality | High — each test produced observable, documentable PASS/FAIL |
| Alternative approaches | 4 documented in f-implementation-exec.md (FR3) |

## Validation Criteria

- [x] TC-1 and TC-2 executed with PASS/FAIL result for `!{bash}` syntax — **FAIL**
- [x] TC-3 and TC-4 executed with PASS/FAIL result for `!` path syntax — **FAIL**
- [x] TC-5 confirms cleanup (no test artefacts) — **PASS**
- [x] TC-6 confirms no interference with existing commands — **PASS**
- [x] All tests failed → FR3 (alternative approaches) documented in f-implementation-exec.md

## Status
**Status**: Finished
**Next Action**: /cig-retrospective 55
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 6 test cases executed with unambiguous results. Both context injection syntaxes (`!{bash}` and `!` path shorthand) confirmed as commands-only features — they do not work in SKILL.md format. Cleanup and isolation tests passed. Alternative approaches documented.

## Lessons Learned
- Context injection is a commands-loader feature, not a general markdown processing feature — this is not documented anywhere
- The failure mode is silent (no error, no warning), making it easy to miss without explicit testing
- Skills deliver their body as static text; dynamic content requires LLM tool calls at runtime
- Testing with minimal, isolated skills is an effective way to verify platform behaviour empirically

# Testing Execution

> Part of the [Workflow Steps](../workflow-steps.md) reference.

**File**: `g-testing-exec.md` (v2.1 only)

**Purpose**: Execute the test plan, record test results, and document failures with reproduction steps.

**Focus on**:
- Executing test cases from testing plan file (e-testing-plan.md for v2.1, e-testing.md for v2.0) sequentially
- Setting up test environment as specified
- Recording PASS/FAIL status for each test case
- Documenting test failures with reproduction steps
- Measuring and recording test coverage
- Executing non-functional tests (performance, security, etc.)

**Avoid**:
- Changing the test plan (update testing plan file if needed)
- Skipping test cases without documentation
- Marking tests as passing when they fail
- Moving to rollout before all tests pass

**Key Questions**:
- What tests from the plan have been executed?
- What were the actual test results (PASS/FAIL)?
- Were any test failures encountered? What are the reproduction steps?
- What is the test coverage achieved?
- What remains to be tested?

**Structure**: Defined in workflow file template (`.cwf/templates/pool/`).

**Checkpoint Commit**: See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `g-testing-exec.md`

**Transition Triggers**:
- **Primary → Rollout**: All tests pass, coverage targets met
- **Alternative → Implementation Execution**: Test failures require bug fixes
- **Alternative → Testing Planning**: Test plan proves insufficient
- **Alternative → Design**: Tests reveal fundamental design flaws
- **Blocked**: Test environment issues prevent execution

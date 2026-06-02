# Testing Planning

> Part of the [Workflow Steps](../workflow-steps.md) reference.

**File**: `e-testing-plan.md` (v2.1) OR `e-testing.md` (v2.0)

**Purpose**: Define test strategy and validate both functional and non-functional requirements through comprehensive test coverage.

**Focus on**:
- Test strategy with test levels (unit, integration, system, acceptance)
- Test coverage targets (overall, critical paths, edge cases, regression)
- Functional test cases in Given/When/Then format
- Non-functional test cases (performance, security, usability, reliability)
- Test environment requirements
- Automation approach and CI/CD integration
- Success criteria for testing phase

**Avoid**:
- Implementation details (covered in implementation)
- Design rationale (covered in design)
- Deployment procedures (covered in rollout)
- Future test scenarios not needed now

**Key Questions**:
- What test levels are needed? (unit, integration, system, acceptance)
- What are coverage targets for each level?
- What critical test cases verify functionality?
- What non-functional tests are needed? (performance, security, usability, reliability)
- What test environment setup is required?
- How will tests be automated and integrated into CI/CD?
- What are success criteria for testing phase?

**Structure**: Defined in workflow file template (`.cwf/templates/pool/`).

**Checkpoint Commit**: See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `e-testing-plan.md`

**Transition Triggers**:
- **Primary → Testing Execution** (v2.1): Test plan complete, ready to execute `/cwf-testing-exec`
- **Primary → Rollout** (v2.0): All tests passing, coverage targets met
- **Alternative → Implementation**: Planning reveals implementation gaps
- **Alternative → Requirements**: Test plan reveals missing acceptance criteria

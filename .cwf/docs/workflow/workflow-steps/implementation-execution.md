# Implementation Execution

> Part of the [Workflow Steps](../workflow-steps.md) reference.

**File**: `f-implementation-exec.md` (v2.1 only)

**Purpose**: Execute the implementation following the approved plan, recording actual results and deviations.

**Focus on**:
- Executing steps from d-implementation-plan.md sequentially
- Making code changes according to the design
- Testing changes locally to verify they work
- Recording actual results for each step
- Documenting deviations from plan with rationale
- Noting blockers encountered during execution

**Avoid**:
- Changing the plan (update d-implementation-plan.md if needed)
- Skipping steps without documentation
- Implementing features not in the plan
- Moving to testing before all implementation steps complete

**Key Questions**:
- What steps from the plan have been executed?
- What were the actual results for each step?
- Did any steps deviate from the plan? Why?
- Were any blockers encountered?
- What remains to be done?

**Structure**: Defined in workflow file template (`.cwf/templates/pool/`).

**Checkpoint Commit**: See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `f-implementation-exec.md`

**Transition Triggers**:
- **Primary → Testing Planning**: Execution complete, all implementation steps done
- **Alternative → Implementation Planning**: Execution reveals plan is insufficient
- **Alternative → Design**: Execution reveals design flaws
- **Blocked**: Critical blocker prevents progress

# Implementation Planning

> Part of the [Workflow Steps](../workflow-steps.md) reference.

**File**: `d-implementation-plan.md` (v2.0 and v2.1)

**Purpose**: Plan the implementation approach following approved design, defining steps, files to modify, and validation criteria.

**Focus on**:
- Files to modify (primary and supporting changes)
- Implementation steps as numbered, actionable checklist
- Code changes illustrated with before/after examples
- Test coverage (unit, integration, regression)
- Validation criteria before marking complete
- Workflow: Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

**Avoid**:
- Design rationale (covered in design phase)
- Business requirements (covered in requirements)
- Deployment strategies (covered in rollout)
- Performance optimization not required by NFRs
- Gold-plating or scope creep

**Key Questions**:
- What files need creation or modification?
- What is step-by-step implementation approach?
- What tests verify functionality?
- How do we validate requirements are met?
- What are validation criteria before completion?
- Are we following patterns from existing codebase?

**Structure**: Defined in workflow file template (`.cwf/templates/pool/`).

**Checkpoint Commit**: See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `d-implementation-plan.md`

**Transition Triggers**:
- **Primary → Implementation Execution** (v2.1): Plan complete, ready to execute `/cwf-implementation-exec`
- **Primary → Testing** (v2.0): Implementation complete, all tests passing
- **Alternative → Design**: Planning reveals design gaps
- **Alternative → Decomposition**: Planning shows task too complex, create subtasks

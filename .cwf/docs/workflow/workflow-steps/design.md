# Design

> Part of the [Workflow Steps](../workflow-steps.md) reference.

**Purpose**: Document architecture decisions, component design, and interface contracts that satisfy requirements while following design priorities.

**Focus on**:
- Architecture choice with rationale and trade-offs
- Component overview with clear responsibilities
- Data flow showing component interactions
- Interface design (API endpoints, data models)
- Design priorities: Testability → Readability → Consistency → Simplicity → Reversibility
- Architecture preferences: Composition over inheritance, interfaces over singletons, explicit over implicit
- Technical constraints influencing design

**Avoid**:
- Detailed implementation code
- Specific test cases
- Deployment procedures
- Business requirements justification (covered in requirements)
- Step-by-step implementation instructions

**Key Questions**:
- What architecture pattern best fits requirements?
- What are key components and their responsibilities?
- How do components interact? (Data flow)
- What are critical interfaces? (APIs, data models)
- What constraints influenced design?
- What are trade-offs of this approach?
- Does design satisfy requirements?
- Is design validated and approved?

**Structure**: Defined in workflow file template (`.cwf/templates/pool/`).

**Checkpoint Commit**: See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `c-design-plan.md`

**Transition Triggers**:
- **Primary → Implementation**: Design approved and validated
- **Alternative → Requirements**: Design reveals missing requirements
- **Alternative → Spike**: Design uncertainty high, create investigation task

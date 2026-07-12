# Requirements

> Part of the [Workflow Steps](../workflow-steps.md) reference.

**Purpose**: Define what the system must do (functional) and how well it must do it (non-functional) with clear acceptance criteria.

**Focus on**:
- Functional requirements (FR1-FRn) with specific acceptance criteria
- Non-functional requirements across 5 dimensions:
  - NFR1: Performance (response time, throughput, resource usage)
  - NFR2: Usability (learning curve, error recovery, consistency)
  - NFR3: Maintainability (code clarity, modularity, testability)
  - NFR4: Security (authentication, authorization, data protection)
  - NFR5: Reliability (availability, error handling, data integrity)
- User stories capturing user perspective
- Acceptance criteria as testable checkpoints
- Constraints (technical, integration, resource)
- **Simplicity — challenge every requirement**: this is where "the best part is no part" and "reduce, reuse, recycle" apply. Test whether each requirement is *actually* needed rather than inheriting the conventional/default set — LLMs default to "the way it's always been done"; counter that. A cut that touches the task's **goal** or a user-named deliverable is not yours to make: surface it to the owner as a decision (see the goals phase), never apply it silently.

**Avoid**:
- Implementation approaches or "how" details
- Code structure or architecture decisions
- Deployment strategies
- Specific technology choices
- Design patterns

**Key Questions**:
- What must the system do? (Functional requirements)
- How well must it perform? (Performance NFRs)
- How usable must it be? (Usability NFRs)
- How maintainable must it be? (Maintainability NFRs)
- What security requirements exist? (Security NFRs)
- How reliable must it be? (Reliability NFRs)
- How do we verify each requirement? (Acceptance criteria)
- What are the hard constraints?

**Structure**: Defined in workflow file template (`.cwf/templates/pool/`).

**Checkpoint Commit**: See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `b-requirements-plan.md`

**Transition Triggers**:
- **Primary → Design**: Requirements clear and approved
- **Alternative → Planning**: Requirements reveal scope issues, return to planning
- **Alternative → Decomposition**: Requirements too complex, create focused subtasks

# Planning

> Part of the [Workflow Steps](../workflow-steps.md) reference.

**Purpose**: Establish clear objectives, success criteria, and high-level approach before diving into details.

**Simplicity Principles**:

Keeping the system simple is a core goal. Sometimes this means "don't add new features/code for the sake of adding" and can also sometimes mean "we don't need that (anymore), remove it".

- **"The best part is no part"**: The simplest, most reliable solution often involves removing unnecessary code or not adding it in the first place
- **"Reduce, reuse, recycle"**: Minimise new code, leverage existing solutions, extract common patterns only when proven necessary

When planning, explicitly consider:
- What can be removed or simplified?
- What existing code/files/artifacts does this make obsolete?
- What's the minimal solution that satisfies requirements?

**Focus on**:
- Single-sentence objective that captures the "why"
- 3-5 measurable success criteria that define "done"
- Major milestones showing progression
- Top 3-5 risks with mitigation strategies
- Dependencies (external, team, technical)
- Constraints (technical, resource, timeline)
- Decomposition signals check

**Avoid**:
- Implementation details or code specifics
- Detailed design decisions
- Specific technology choices (save for design phase)
- Test case details
- Deployment procedures

**Key Questions**:
- What problem are we solving and why does it matter?
- How will we know when we're successful?
- What are the major milestones from start to finish?
- What could go wrong and how do we mitigate it?
- What do we depend on and what depends on this?
- What constraints limit our approach?
- Is this task too large (check decomposition signals)?

**Structure**: Defined in workflow file template (`.cwf/templates/pool/`).

**Checkpoint Commit**: See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `a-task-plan.md`

**Transition Triggers**:
- **Primary → Requirements**: Planning complete, objectives clear
- **Alternative → Decomposition**: 2+ decomposition signals triggered, create subtasks
- **Alternative → Clarification**: Objectives unclear, request user input

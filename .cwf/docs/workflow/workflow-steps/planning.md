# Planning

> Part of the [Workflow Steps](../workflow-steps.md) reference.

**Purpose**: Establish clear objectives, success criteria, and high-level approach before diving into details.

**Goal vs means**:

"The best part is no part" and "reduce, reuse, recycle" are first-class engineering ideals — but they apply to the **means** of achieving the goal, never to the goal itself or the deliverables the user named. In this phase you capture the goal; you do not cut it. Challenge and simplify *requirements* (the means) in the requirements and implementation phases, not here. "You can't cut your way to success" — descoping the goal is not simplification.

**Goal ownership**:

A task's goal is owner-owned and near-inviolable. Do **not** unilaterally narrow **or** expand it. If the user's explicit request is in tension with the stated "why", or a scope change (in **either** direction) looks beneficial, **loudly surface it to the owner as a decision** — never resolve it silently by editing the goal yourself.

**Focus on**:
- Objective capturing **both** the "why" (intent) **and** the user's explicit request — every deliverable the user named, preserved verbatim in intent; "none stated" if the request is a genuine one-liner with no named deliverables. No paraphrase that drops a named deliverable.
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

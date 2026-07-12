# Planning

> Part of the [Workflow Steps](../workflow-steps.md) reference.

**Purpose**: Establish clear objectives, success criteria, and high-level approach before diving into details.

**Goal vs means**:

"The best part is no part" and "reduce, reuse, recycle" are first-class engineering ideals — but they apply to the **means** of achieving the goal, never to the goal itself or the deliverables the user named. In this phase you capture the goal; you do not cut it. Challenge and simplify *requirements* (the means) in the requirements and implementation phases, not here. "You can't cut your way to success" — descoping the goal is not simplification.

**Goal ownership**:

A task's goal is owner-owned and near-inviolable. Do **not** unilaterally narrow **or** expand it. If the user's explicit request is in tension with the stated "why", or a scope change (in **either** direction) looks beneficial, **loudly surface it to the owner as a decision** — never resolve it silently by editing the goal yourself.

**Focus on**:
- Objective capturing **both** the "why" (intent) **and** the user's explicit request — every deliverable the user named, preserved verbatim in intent; "none stated" if the request is a genuine one-liner with no named deliverables. No paraphrase that drops a named deliverable.
- Every open surface/mechanism/constraint decision, named at plan time (transport, storage, layout, licensing-class, …) as a question to resolve later — see "Open-decisions gate" below
- 3-5 measurable success criteria that define "done"
- Major milestones showing progression
- Top 3-5 risks with mitigation strategies
- Dependencies (external, team, technical)
- Constraints (technical, resource, timeline)
- Decomposition signals check

**Avoid**:
- Implementation details or code specifics
- Detailed design decisions — *resolving* them is the design phase's job; but **naming** an unresolved design/mechanism decision as an open question is required here, not avoided (see "Open-decisions gate" below)
- Specific technology choices — save *choosing* for the design phase; naming the still-open choice now (as a question) is not the same as choosing it
- Test case details
- Deployment procedures

**Key Questions**:
- What problem are we solving and why does it matter?
- How will we know when we're successful?
- What are the major milestones from start to finish?
- What could go wrong and how do we mitigate it?
- What do we depend on and what depends on this?
- What constraints limit our approach?
- What surface/mechanism/constraint decisions are still open?
- Is any success criterion named after a not-yet-chosen mechanism?
- Is this task too large (check decomposition signals)?

**Open-decisions gate & outcome-shaped criteria**:

Name every open surface/mechanism/constraint decision at plan time (transport, storage,
layout, licensing-class, …), each as a question to resolve in requirements/design. If
genuinely none are open, say so with a one-line justification ("None open — <why>"); a bare
"None" is not conformant. Naming an open decision is required here; *resolving* it is not
(that waits for design).

A success criterion is **mechanism-named** if its statement of "done" is worded around a
specific chosen means — a named tool, library, data structure, transport, file format,
algorithm, flag, or component — rather than the observable end. **Litmus test**: if a
legitimate change of mechanism that still achieves the goal would force the criterion to be
reworded, it is mechanism-named. An **outcome-shaped** criterion states an observable result
and survives that change.

- ✗ mechanism-named: "Ranks results with a Redis sorted-set." (names Redis + sorted-set)
- ✓ outcome-shaped: "Returns results in rank order." (survives a storage swap)
- ✗ mechanism-named: "Adds a `--json` CLI flag." (names the flag mechanism)
- ✓ outcome-shaped: "A caller can obtain the report as machine-readable output."

**Structure**: Defined in workflow file template (`.cwf/templates/pool/`).

**Checkpoint Commit**: See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `a-task-plan.md`

**Transition Triggers**:
- **Primary → Requirements**: Planning complete, objectives clear
- **Alternative → Decomposition**: 2+ decomposition signals triggered, create subtasks
- **Alternative → Clarification**: Objectives unclear, request user input

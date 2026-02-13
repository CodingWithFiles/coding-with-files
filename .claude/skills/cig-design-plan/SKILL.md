---
name: cig-design-plan
description: Guide user through design phase
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

## Scope & Boundaries

**This step**: Complete c-design-plan.md with architecture decisions, component design, and interface specifications.
**Not this step**: Implementation, testing, or deployment.
**If blocked or finished**: Call `workflow-manager control --current-step=c-design-plan --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cig/scripts/command-helpers/task-context-inference` using the Bash tool.

**First**: Run `.cig/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Steps 1-4 (Preamble)**: Read `.cig/docs/skills/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `.cig/docs/workflow/workflow-steps.md#design` for detailed design phase guidance.

**Step 6 (Execute)**:
- Open c-design-plan.md (v2.1) or c-design.md (v2.0) or design.md (v1.0)
- **Focus on**: Architecture decisions, component design, API contracts, data models, interface design
- **Avoid**: Detailed implementation code, specific test cases, deployment procedures
- Apply design priorities: Testability → Readability → Consistency → Simplicity → Reversibility

**Step 7**: Check decomposition signals. See `.cig/docs/workflow/decomposition-guide.md`.

**Step 8**: Checkpoint commit. See `.cig/docs/skills/checkpoint-commit.md`. Stage: `c-design-plan.md`

**Step 9 (Next Steps)**:
- **Primary**: Move to implementation → `/cig-implementation-plan <task-path>`
- **Alt**: Return to requirements if design reveals gaps
- **Alt**: Create spike/prototype if uncertainty is high

## Success Criteria
- [ ] Design file opened and updated
- [ ] Architecture choice documented with rationale and trade-offs
- [ ] Component overview with clear responsibilities
- [ ] Data flow documented
- [ ] Interface design specified
- [ ] Next steps suggested

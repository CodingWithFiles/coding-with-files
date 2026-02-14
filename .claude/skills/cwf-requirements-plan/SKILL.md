---
name: cwf-requirements-plan
description: Guide user through requirements phase
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

## Scope & Boundaries

**This step**: Complete b-requirements-plan.md with functional requirements, non-functional requirements, and acceptance criteria.
**Not this step**: Design decisions, implementation planning, code writing, or testing.
**If blocked or finished**: Call `workflow-manager control --current-step=b-requirements-plan --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cwf/scripts/command-helpers/task-context-inference` using the Bash tool.

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Steps 1-4 (Preamble)**: Read `.cwf/docs/skills/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `.cwf/docs/workflow/workflow-steps.md#requirements` for detailed requirements phase guidance.

**Step 6 (Execute)**:
- Open b-requirements-plan.md (v2.1) or b-requirements.md (v2.0) or requirements.md (v1.0)
- **Focus on**: Functional requirements (FR), non-functional requirements (NFR), acceptance criteria
- **Avoid**: Implementation approaches, code structure, deployment details
- Key questions: What must it do? How well? How do we verify? What are hard constraints?

**Step 7**: Check decomposition signals. See `.cwf/docs/workflow/decomposition-guide.md`.

**Step 8 (Next Steps)**:
- **Primary**: Move to design → `/cwf-design-plan <task-path>`
- **Alt**: Return to planning if requirements reveal scope issues
- **Alt**: Create subtasks if complexity signals triggered

## Success Criteria
- [ ] Requirements file opened and updated
- [ ] Functional requirements (FR1-FRn) defined with acceptance criteria
- [ ] Non-functional requirements (NFR1-NFR5) specified measurably
- [ ] Constraints documented
- [ ] Next steps suggested

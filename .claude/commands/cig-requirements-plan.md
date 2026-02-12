---
description: Guide user through requirements phase
argument-hint: {task-path}
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/*:*), Bash(git rev-parse:*)
---

## Scope & Boundaries

**This step**: Complete b-requirements-plan.md with functional requirements, non-functional requirements, and acceptance criteria.
**Not this step**: Design decisions, implementation planning, code writing, or testing.
**If blocked or finished**: Call `workflow-manager control --current-step=b-requirements-plan --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: !/current-task-wf

!{bash}
.cig/scripts/command-helpers/context-manager location

## Workflow

**Steps 1-4 (Preamble)**: Read `.cig/docs/commands/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `.cig/docs/workflow/workflow-steps.md#requirements` for detailed requirements phase guidance.

**Step 6 (Execute)**:
- Open b-requirements-plan.md (v2.1) or b-requirements.md (v2.0) or requirements.md (v1.0)
- **Focus on**: Functional requirements (FR), non-functional requirements (NFR), acceptance criteria
- **Avoid**: Implementation approaches, code structure, deployment details
- Key questions: What must it do? How well? How do we verify? What are hard constraints?

**Step 7**: Check decomposition signals. See `.cig/docs/workflow/decomposition-guide.md`.

**Step 8 (Next Steps)**:
- **Primary**: Move to design → `/cig-design-plan <task-path>`
- **Alt**: Return to planning if requirements reveal scope issues
- **Alt**: Create subtasks if complexity signals triggered

## Success Criteria
- [ ] Requirements file opened and updated
- [ ] Functional requirements (FR1-FRn) defined with acceptance criteria
- [ ] Non-functional requirements (NFR1-NFR5) specified measurably
- [ ] Constraints documented
- [ ] Next steps suggested

---
name: cwf-task-plan
description: Guide user through planning phase
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

## Scope & Boundaries

**This step**: Complete a-task-plan.md with goals, success criteria, milestones, risks, and decomposition check.
**Not this step**: Requirements gathering, design, implementation, testing, or deployment.
**If blocked or finished**: Call `.cwf/scripts/command-helpers/workflow-manager control --current-step=a-task-plan --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cwf/scripts/command-helpers/task-context-inference` using the Bash tool.

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Steps 1-4 (Preamble)**: Read `.cwf/docs/skills/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `.cwf/docs/workflow/workflow-steps.md#planning` for detailed planning phase guidance.

**Step 6 (Execute)**:
- Open a-task-plan.md (v2.1) or a-plan.md (v2.0) or plan.md (v1.0)
- **Focus on**: Goals, success criteria, milestones, risks, decomposition signals
- **Avoid**: Implementation details, code specifics, detailed design decisions
- Key questions: Single-sentence objective? 3-5 measurable success criteria? Major milestones? Top 3-5 risks? Dependencies? Constraints?

**Step 7**: Check decomposition signals (5 universal signals). See `.cwf/docs/workflow/decomposition-guide.md`. If 2+ triggered, strongly recommend subtasks.

**Step 8**: Checkpoint commit. See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `a-task-plan.md`

**Step 9 (Next Steps)**:
- **Primary**: Move to requirements → `/cwf-requirements-plan <task-path>`
- **Alt**: Create subtasks if decomposition triggered → `/cwf-new-subtask`
- **Alt**: Request clarification if planning reveals missing context
- **Alt**: Recommend spike if risks too high

## Success Criteria
- [ ] Planning file opened and updated
- [ ] Goals, success criteria, and milestones defined
- [ ] Risks identified with mitigation strategies
- [ ] Decomposition check completed
- [ ] Next steps suggested with clear reasoning

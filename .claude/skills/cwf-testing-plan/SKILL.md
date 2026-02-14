---
name: cwf-testing-plan
description: Guide user through testing phase
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

## Scope & Boundaries

**This step**: Complete e-testing-plan.md with test strategy, test cases, and validation criteria.
**Not this step**: Running tests (that's g-testing-exec), deployment, or maintenance.
**If blocked or finished**: Call `workflow-manager control --current-step=e-testing-plan --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cwf/scripts/command-helpers/task-context-inference` using the Bash tool.

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Steps 1-4 (Preamble)**: Read `.cwf/docs/skills/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `.cwf/docs/workflow/workflow-steps.md#testing` for detailed testing phase guidance.

**Step 6 (Execute)**:
- Open e-testing-plan.md (v2.1) or e-testing.md (v2.0) or testing.md (v1.0)
- **Focus on**: Test strategy, test cases, test environment, validation criteria
- **Avoid**: Implementation details, design rationale, deployment procedures
- Key content: test levels, coverage targets, functional/non-functional test cases, environment setup

**Step 7**: Check decomposition signals. See `.cwf/docs/workflow/decomposition-guide.md`.

**Step 8**: Checkpoint commit. See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `e-testing-plan.md`

**Step 9 (Next Steps)**:
- **Primary**: Move to implementation execution → `/cwf-implementation-exec <task-path>`
- **Alt**: Return to implementation if tests reveal defects
- **Alt**: Extend testing if coverage insufficient

## Success Criteria
- [ ] Testing file opened and updated
- [ ] Test strategy defined with test levels
- [ ] Test coverage targets specified
- [ ] Functional test cases documented (Given/When/Then)
- [ ] Non-functional test cases specified
- [ ] Test environment requirements defined
- [ ] Next steps suggested

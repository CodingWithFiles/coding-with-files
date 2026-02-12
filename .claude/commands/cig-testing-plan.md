---
description: Guide user through testing phase
argument-hint: {task-path}
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/*:*), Bash(git rev-parse:*), Bash(git add:*), Bash(git commit:*)
---

## Scope & Boundaries

**This step**: Complete e-testing-plan.md with test strategy, test cases, and validation criteria.
**Not this step**: Running tests (that's g-testing-exec), deployment, or maintenance.
**If blocked or finished**: Call `workflow-manager control --current-step=e-testing-plan --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: !/current-task-wf

!{bash}
.cig/scripts/command-helpers/context-manager location

## Workflow

**Steps 1-4 (Preamble)**: Read `.cig/docs/commands/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `.cig/docs/workflow/workflow-steps.md#testing` for detailed testing phase guidance.

**Step 6 (Execute)**:
- Open e-testing-plan.md (v2.1) or e-testing.md (v2.0) or testing.md (v1.0)
- **Focus on**: Test strategy, test cases, test environment, validation criteria
- **Avoid**: Implementation details, design rationale, deployment procedures
- Key content: test levels, coverage targets, functional/non-functional test cases, environment setup

**Step 7**: Check decomposition signals. See `.cig/docs/workflow/decomposition-guide.md`.

**Step 8**: Checkpoint commit. See `.cig/docs/commands/checkpoint-commit.md`. Stage: `e-testing-plan.md`

**Step 9 (Next Steps)**:
- **Primary**: Move to implementation execution → `/cig-implementation-exec <task-path>`
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

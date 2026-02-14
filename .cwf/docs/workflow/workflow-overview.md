# Workflow Overview

The CWF hierarchical workflow system guides tasks through structured steps from planning to retrospective. This system enables infinite task nesting while maintaining clarity and preventing scope creep through universal decomposition signals.

## Version Differences

**v2.0 Format** (8 phases): Eight lettered workflow steps (a-h) covering plan, requirements, design, implementation, testing, rollout, maintenance, retrospective.

**v2.1 Format** (10 phases): Extends v2.0 by separating planning from execution for implementation and testing. This creates distinct phases for "what we'll do" (planning) versus "what we did" (execution). File order was corrected to place test planning (e) before implementation execution (f), reflecting the philosophy that **test planning is a thinking tool** - it forces you to understand what "working" means before you start implementing.

This document describes the v2.1 workflow format.

## Ten Workflow Steps (v2.1)

Each task progresses through lettered workflow steps (a-j), with each step having a dedicated workflow file and command:

### Planning Phases
1. **a-task-plan** (`/cwf-task-plan`) - Define goals, success criteria, and high-level approach
2. **b-requirements-plan** (`/cwf-requirements-plan`) - Specify functional and non-functional requirements
3. **c-design-plan** (`/cwf-design-plan`) - Document architecture decisions and component design
4. **d-implementation-plan** (`/cwf-implementation-plan`) - Plan implementation approach, files to modify, steps
5. **e-testing-plan** (`/cwf-testing-plan`) - Define test strategy, test cases, validation criteria (moved before implementation execution)

### Execution Phases
6. **f-implementation-exec** (`/cwf-implementation-exec`) - Execute implementation following the plan (separated from planning)
7. **g-testing-exec** (`/cwf-testing-exec`) - Execute tests following the test plan (separated from planning)
8. **h-rollout** (`/cwf-rollout`) - Deploy with phased rollout and monitoring

### Support Phases
9. **i-maintenance** (`/cwf-maintenance`) - Establish ongoing support and optimization
10. **j-retrospective** (`/cwf-retrospective`) - Capture learnings and variance analysis

### Philosophy: Test Planning as Thinking Tool

The v2.1 workflow places test planning (e-testing-plan.md) before implementation execution (f-implementation-exec.md) because **test planning is fundamentally a thinking tool**. By defining what "working" means and how you'll verify it before you start writing implementation code, you:
- Clarify requirements and acceptance criteria
- Identify edge cases and error conditions early
- Establish measurable success criteria
- Enable true TDD workflow: plan tests → write failing tests → implement → tests pass

This is planning-driven development with TDD principles, not traditional TDD. You're not writing test code before implementation code - you're planning your test approach to force clarity about requirements and outcomes.

### Task Type Variations

Not all task types require all steps:
- **Feature**: All 10 steps (a-j)
- **Bugfix**: 7 steps (a, c, d, e, f, g, h) - skips requirements, maintenance, retrospective
- **Hotfix**: 5 steps (a, d, e, f, g) - emergency focus, minimal ceremony
- **Chore**: 4 steps (a, d, f, h) - maintenance work, skips test planning/execution
- **Discovery**: 7 steps (a, b, c, d, e, g, h) - research/analysis, skips implementation execution

## Universal Decomposition Principle

Tasks should be decomposed into subtasks when any 2+ of these signals trigger:

- **Time**: Estimated >1 week for a workflow step or >1 month total
- **People**: Requires >2 people working on different parts
- **Complexity**: Involves 3+ distinct technical concerns
- **Risk**: Contains high-risk components needing isolation
- **Independence**: Parts can be worked on separately without coordination

Decomposition creates hierarchical task structure (1 → 1.1 → 1.1.1) where each subtask inherits parent context but has focused scope. Context inheritance via structural maps (not full file reads) provides token efficiency while preserving LLM agency.

## Dynamic Workflow Transitions

Workflows are non-linear state machines. Each step suggests primary next step and alternative paths based on outcomes. Design failures may return to requirements. Implementation complexity may trigger decomposition into subtasks. Testing issues may return to implementation. This flexibility supports real-world project dynamics while maintaining structured progress tracking.

## Progressive Disclosure Pattern

Documentation follows progressive disclosure: commands reference detailed workflow step documentation rather than duplicating guidance. Helper scripts encapsulate deterministic operations. LLM receives structural information and decides what details matter. This pattern reduces token consumption while preserving decision-making agency.

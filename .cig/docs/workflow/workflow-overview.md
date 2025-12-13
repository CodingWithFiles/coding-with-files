# Workflow Overview

The CIG hierarchical workflow system guides tasks through 8 structured steps from planning to retrospective. This system enables infinite task nesting while maintaining clarity and preventing scope creep through universal decomposition signals.

## Eight Workflow Steps

Each task progresses through lettered workflow steps (a-h), with each step having a dedicated workflow file and command:

1. **a-plan** (`/cig-plan`) - Define goals, success criteria, and high-level approach
2. **b-requirements** (`/cig-requirements`) - Specify functional and non-functional requirements
3. **c-design** (`/cig-design`) - Document architecture decisions and component design
4. **d-implementation** (`/cig-implementation`) - Execute implementation with test-driven approach
5. **e-testing** (`/cig-testing`) - Validate functionality and non-functional requirements
6. **f-rollout** (`/cig-rollout`) - Deploy with phased rollout and monitoring
7. **g-maintenance** (`/cig-maintenance`) - Establish ongoing support and optimization
8. **h-retrospective** (`/cig-retrospective`) - Capture learnings and variance analysis

Not all task types require all steps. Bugfixes skip requirements and rollout. Hotfixes focus on emergency deployment. Chores skip requirements, design, rollout, and maintenance.

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

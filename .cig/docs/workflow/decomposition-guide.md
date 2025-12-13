# Task Decomposition Guide

Task decomposition breaks large tasks into focused subtasks, enabling parallel work, risk isolation, and manageable scope. The CIG system supports infinite hierarchical nesting using decimal notation.

## Universal Decomposition Signals

Decompose a task when **2 or more** of these signals trigger:

### 1. Time Signal
- **Trigger**: Estimated >1 week for a workflow step OR >1 month for entire task
- **Why**: Long durations increase risk, reduce feedback speed, and delay value delivery
- **Action**: Break into subtasks that can complete in <1 week per workflow step

### 2. People Signal
- **Trigger**: Requires >2 people working on different parts simultaneously
- **Why**: Coordination overhead grows quadratically with team size; parallel work needs clear boundaries
- **Action**: Decompose along natural work divisions allowing independent progress

### 3. Complexity Signal
- **Trigger**: Involves 3+ distinct technical concerns or architectural components
- **Why**: Mixing concerns increases coupling, reduces testability, and complicates understanding
- **Action**: Separate concerns into focused subtasks (e.g., data model, API, UI into separate tasks)

### 4. Risk Signal
- **Trigger**: Contains high-risk components that need isolation for mitigation
- **Why**: Risk isolation enables focused validation, easier rollback, and contained blast radius
- **Action**: Extract risky components into separate subtasks with their own validation

### 5. Independence Signal
- **Trigger**: Parts can be worked on separately without constant coordination
- **Why**: Independent work reduces dependencies, enables parallel progress, and improves velocity
- **Action**: Split into subtasks that have minimal inter-dependencies

## Hierarchical Numbering System

Tasks use decimal notation showing parent-child relationships:

- **Level 1**: 1, 2, 3 (main tasks)
- **Level 2**: 1.1, 1.2, 1.3 (subtasks of task 1)
- **Level 3**: 1.1.1, 1.1.2, 1.1.3 (micro-tasks of subtask 1.1)
- **Unlimited depth**: 1.1.1.1, 1.1.1.1.1, etc.

Directory structure mirrors numbering:
```
implementation-guide/
  1-feature-authentication/
    1.1-chore-database-schema/
      1.1.1-feature-user-model/
      1.1.2-feature-auth-tokens/
    1.2-feature-password-reset/
```

## Context Inheritance

Subtasks inherit parent context through token-efficient structural maps:

- **Automatic**: `/cig-subtask` and workflow commands automatically load parent context via `context-inheritance.pl`
- **Structural Maps**: Headers and line ranges (~50-100 tokens) instead of full files (~500-1000 tokens)
- **LLM Agency**: LLM decides which parent sections to read in detail using Read tool
- **Status Awareness**: Parent status markers indicate reliability of inherited context

## When NOT to Decompose

Avoid decomposition when:
- Task is already focused (0-1 decomposition signals)
- Overhead of coordination exceeds benefit
- Natural boundaries don't exist (forced decomposition creates artificial coupling)
- Team lacks capacity to manage additional tasks

## Creating Subtasks

Use `/cig-subtask <parent-path> <num> <type> "description"`:
```bash
# Create subtask 1.1 under parent task 1
/cig-subtask 1 1.1 chore "Database schema setup"

# Create subtask 1.1.1 under parent task 1.1
/cig-subtask 1.1 1.1.1 feature "User model"
```

Each subtask gets appropriate workflow files based on task type (feature: 8 files, bugfix: 5 files, hotfix: 5 files, chore: 4 files) with explicit parent reference for context inheritance.

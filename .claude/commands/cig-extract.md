---
description: Extract specific section from implementation guide (v2.0 - task-based)
argument-hint: {task-path} {section-name}
allowed-tools: Read, Bash(.cig/scripts/command-helpers/*:*), Bash(git rev-parse:*), Bash(awk:*)
---

## Your task
Extract section from task: **{arguments}**

!{bash}
.cig/scripts/command-helpers/context-manager location

**Parse arguments**: `<task-path> <section-name>`
- task-path: Task number (e.g., "1", "1.1") OR full file path (backward compatible)
- section-name: Section to extract (case-insensitive)

**Examples**:
- `/cig-extract 1 goal` — Extract Goal section from task 1's plan
- `/cig-extract 1.1 requirements` — Extract from task 1.1's requirements file

**Steps**:

### 1. Determine Input Type
- Contains "/" or ends with ".md": treat as file path (backward compatible)
- Otherwise: resolve via `context-manager hierarchy <task-path>`

### 2. Map Section to File
- "goal"/"plan" → a-task-plan.md / a-plan.md / plan.md
- "requirements" → b-requirements-plan.md / b-requirements.md / requirements.md
- "design" → c-design-plan.md / c-design.md / design.md
- "implementation" → d-implementation-plan.md / d-implementation.md / implementation.md
- "testing" → e-testing-plan.md / e-testing.md / testing.md
- "rollout" → h-rollout.md / f-rollout.md / rollout.md
- "maintenance" → i-maintenance.md / g-maintenance.md / maintenance.md
- "retrospective" → j-retrospective.md / h-retrospective.md
- Use `context-manager version <task-dir> <workflow-file>` to determine format

### 3. Extract Section
```bash
awk '/^## {section-name}/{p=1; print; next} p && /^## [^#]/{p=0} p' {file-path}
```

### 4. Error Handling
- If not found: list available sections, suggest closest match, ask for clarification

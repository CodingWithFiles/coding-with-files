---
description: Extract specific section from implementation guide (v2.0 - task-based)
argument-hint: <task-path> <section-name>
allowed-tools: Read, Bash(.cig/scripts/command-helpers/hierarchy-resolver.sh:*), Bash(.cig/scripts/command-helpers/format-detector.sh:*), Bash(awk:*), Bash(egrep:*), Bash(echo:*)
---

## Context
- Task resolution for path-based extraction

## Your task
Extract section from task: **$ARGUMENTS**

⚠️  **BREAKING CHANGE from v1.0**: New signature `<task-path> <section-name>` (task-based instead of file-based)

**Parse arguments**: `<task-path> <section-name>`
- task-path: Task number (e.g., "1", "1.1", "1.1.1") **OR** full file path (backward compatible)
- section-name: Section to extract (case-insensitive)

**Examples**:
- `/cig-extract 1 goal` - Extract Goal section from task 1's plan file
- `/cig-extract 1.1 requirements` - Extract from task 1.1's requirements file
- `/cig-extract 1 design` - Extract from task 1's design file
- `/cig-extract implementation-guide/1-feature-auth/a-plan.md goal` - Backward compatible file path

**Steps**:

### 1. Determine Input Type
- If argument contains "/" or ends with ".md": Treat as full file path (backward compatible)
- Otherwise: Treat as task-path and resolve using hierarchy-resolver.sh

### 2. Resolve Task and File (for task-based paths)
- Use `hierarchy-resolver.sh <task-path>` to find task directory
- Map section name to workflow file (case-insensitive):
  - "goal" or "plan" → plan.md (v1.0) / a-plan.md (v2.0)
  - "requirements" → requirements.md (v1.0) / b-requirements.md (v2.0)
  - "design" → design.md (v1.0) / c-design.md (v2.0)
  - "implementation" → implementation.md (v1.0) / d-implementation.md (v2.0)
  - "testing" → testing.md (v1.0) / e-testing.md (v2.0)
  - "rollout" → rollout.md (v1.0) / f-rollout.md (v2.0)
  - "maintenance" → maintenance.md (v1.0) / g-maintenance.md (v2.0)
  - "retrospective" → h-retrospective.md (v2.0 only)
- Use `format-detector.sh <task-dir> <workflow-file>` to determine which file to read

### 3. Extract Section Content
Use awk to extract section content from file:
```bash
awk '/^## {section-name}/{p=1; print; next} p && /^## [^#]/{p=0} p' {file-path}
```

Adapt pattern for different heading levels if needed.

### 4. LLM-in-the-Loop Error Handling
If file is corrupted or section not found:
- **Don't fail silently**: Present error to user
- **Show available sections**: List all ## headers in the file
- **Suggest closest match**: Use fuzzy matching to suggest similar section names
- **Ask for clarification**: "Did you mean 'Success Criteria' instead of 'Criteria'?"
- **Allow manual correction**: User can retry with corrected section name

### 5. Backward Compatibility
If full file path provided:
- Skip task resolution step
- Proceed directly to section extraction
- This maintains compatibility during migration period

**Common Section Names**:
- "Goal" - Single sentence objective
- "Requirements" - Functional and non-functional requirements
- "Design" - Architecture and design decisions
- "Implementation" - Implementation steps and code changes
- "Testing" - Test strategy and test cases
- "Current Status" or "Status" - Progress tracking
- "Lessons Learned" - Key insights

**Success**: Section content extracted cleanly with intelligent error handling and backward compatibility

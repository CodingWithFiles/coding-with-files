# Context Tools for Workflow Commands

This document describes the context tools used by workflow commands to provide task resolution and parent context awareness.

## Command Arguments

All workflow commands accept a single argument:
- `<task-path>`: Task identifier (e.g., "1", "1.1", "1/1.1/1.1.1")

## Context Tools

### hierarchy-resolver.sh
**Purpose**: Resolve task paths to full directory paths with metadata

**Usage**: `.cig/scripts/command-helpers/hierarchy-resolver.sh <task-path>`

**Returns**:
- Full directory path to task
- Task number, type, and slug
- Template format version (1.0 or 2.0)
- Parent path (if subtask)
- Task depth in hierarchy

**Exit codes**:
- 0: Success
- 1: Invalid path format
- 2: Task not found
- 3: Missing required argument

### context-inheritance.pl
**Purpose**: Extract parent task context with headers, line ranges, and status markers

**Usage**: `.cig/scripts/command-helpers/context-inheritance.pl <task-path>`

**Returns**:
- Structural map of all parent tasks
- For each parent workflow file:
  - File path and status marker
  - Section headers with line ranges (Lstart-end)
  - Read tool parameters (offset, limit)
- Token-efficient (~50-100 tokens per parent vs 500-1000 for full files)

**Exit codes**:
- 0: Success
- 1: Invalid path
- 2: Task not found
- 3: No parent tasks (top-level task)

**Value**: Enables progressive disclosure - LLM sees document structure and decides what to read in detail

## Context Section Usage in Commands

Workflow commands should include this context section:

```markdown
## Context
- Task resolution: !`.cig/scripts/command-helpers/hierarchy-resolver.sh $ARGUMENTS 2>/dev/null || echo "Task path required"`
- Parent context: !`.cig/scripts/command-helpers/context-inheritance.pl $ARGUMENTS 2>/dev/null || echo "No parent context (top-level task or invalid path)"`
```

This provides automatic task resolution and parent context loading for every workflow command invocation.

## Progressive Disclosure Pattern

1. **Step 1**: hierarchy-resolver.sh provides task location and metadata
2. **Step 2**: context-inheritance.pl provides structural map of parent context
3. **Step 3**: LLM reviews structural map and decides what parent sections are relevant
4. **Step 4**: LLM uses Read tool with offset/limit parameters to read only necessary parent sections

This pattern reduces token consumption while preserving LLM agency to decide what context matters.

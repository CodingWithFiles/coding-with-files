# Workflow Preamble (Steps 1-4)

Shared instructions for all CWF workflow commands. Follow these steps before executing phase-specific workflow.

**Helper scripts location**: `.cwf/scripts/command-helpers/`

## Argument Parsing

- If task arguments provided: Extract the FIRST space-separated word as the task path
- If NO task arguments: Use task_num from "Current task/workflow" context above
- Any additional words after the first provide user context about their intent
- Use the extra words to understand what the user wants, but do NOT pass them to script calls
- Example: "11 update the design" → task path is "11", extra text explains what to do
- If neither arguments nor inference available: Error "Cannot determine task. Specify task number or ensure context is inferrable."

## Task Path Validation

Task paths MUST match hierarchical number format: digits separated by dots.
- **Valid**: "11", "1.2", "12.2.3", "1.1.1.1"
- **Invalid**: "some text", "`date`", "11; rm -rf", "text.text"
- If first word does NOT match valid format: inform user and do NOT invoke scripts
- This prevents command injection and ensures only valid task identifiers reach scripts

## Step 1: Resolve Task Directory

- Call `.cwf/scripts/command-helpers/context-manager hierarchy <task-path>` using Bash tool
- If task not found: provide clear error with available tasks
- Extract task number, type, and slug from resolution

## Step 2: Load Parent Context

If subtask (not top-level):
- Call `.cwf/scripts/command-helpers/context-manager inheritance <task-path>` using Bash tool
- Parent context includes: file paths, status markers, section headers, line ranges
- Provides ~50-100 tokens per parent (vs 500-1000 for full files)

## Step 3: Present Context Summary

- Show navigable links with file paths and line ranges
- Display status markers to indicate reliability of parent context
- Highlight key parent decisions relevant to current phase

## Step 4: LLM Decision — Read Parent Details

- Use Read tool with offset/limit parameters from structural map
- Only read sections that directly inform current phase
- Skip irrelevant parent context to conserve tokens

## Status Field

Use valid status values only. See `.cwf/docs/workflow/workflow-steps.md#status-values`.

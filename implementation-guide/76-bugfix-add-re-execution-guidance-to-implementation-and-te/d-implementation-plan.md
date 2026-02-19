# Add Re-Execution Guidance to Implementation and Testing Exec Skills - Implementation Plan
**Task**: 76 (bugfix)

## Task Reference
- **Task ID**: internal-76
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/76-add-re-execution-guidance-to-exec-skills
- **Template Version**: 2.1

## Goal
Create `re-execution.md` shared doc and add a one-line reference to it in both exec
skill files, between Step 5 and Step 6.

## Files to Modify

### New File
- `.cwf/docs/skills/re-execution.md` — shared guidance doc (create)

### Edits
- `.claude/skills/cwf-implementation-exec/SKILL.md` — add re-execution check reference
- `.claude/skills/cwf-testing-exec/SKILL.md` — add re-execution check reference

## Implementation Steps

### Step 1: Create `.cwf/docs/skills/re-execution.md`

Content (four sections):

1. **Detection** — exec file has non-template content in Actual Results, or
   Status is not "Backlog"
2. **Core rule** — work forward, never backward:
   - Do NOT `git reset`, `git revert`, or amend prior checkpoint commits
   - Do NOT rewrite the exec file from scratch
3. **Commit naming** — `Task {N}: Pass {2}: {short description}`
4. **Doc handling** — append `## Pass {N} Results` section; prior results stay intact
5. **Non-blockers** — old results alone are never a blocker

### Step 2: Edit `cwf-implementation-exec/SKILL.md`

Insert between Step 5 and Step 6:

```
**Re-execution check**: If `f-implementation-exec.md` already has results from a
prior run, read `.cwf/docs/skills/re-execution.md` before proceeding.
```

### Step 3: Edit `cwf-testing-exec/SKILL.md`

Same insertion between Step 5 and Step 6, referencing `g-testing-exec.md`:

```
**Re-execution check**: If `g-testing-exec.md` already has results from a prior
run, read `.cwf/docs/skills/re-execution.md` before proceeding.
```

## Validation Criteria
- `re-execution.md` exists and covers all four design sections
- Both SKILL.md files reference it at the correct point (between plan-read and execute)
- First-execution flow (Pass 1) is unchanged — reference is conditional ("if … already has results")
- No commit-revert pattern appears anywhere in the new guidance

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 76
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All three steps executed as planned. Minor deviation: re-execution.md got a fifth
section heading ("What Is NOT a Blocker") for improved scannability.

## Lessons Learned
Plan was accurate and complete. No surprises.

# Add Re-Execution Guidance to Implementation and Testing Exec Skills - Design
**Task**: 76 (bugfix)

## Task Reference
- **Task ID**: internal-76
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/76-add-re-execution-guidance-to-exec-skills
- **Template Version**: 2.1

## Goal
Document the design for re-execution guidance: where it lives, what it says,
and how the two exec skills reference it.

## Key Decisions

### Decision 1: Shared doc, not inline

- **Chosen**: Create `.cwf/docs/skills/re-execution.md` and reference it from
  both exec skill files with a one-liner (same pattern as `checkpoint-commit.md`).
- **Rationale**: Both skills need identical guidance. A shared doc avoids drift
  between them and follows the established progressive disclosure pattern already
  used by `checkpoint-commit.md`.
- **Trade-off**: One extra file to maintain, but eliminates duplication entirely.

### Decision 2: Reference point in each skill

- **Chosen**: Add a reference between Step 5 (read plan) and Step 6 (execute) in
  both skills — as a new "Re-execution check" note before the execute block.
- **Rationale**: The agent needs to check for prior results *before* starting
  execution, not after. Step 5 is where it reads the plan; the re-execution check
  is the natural next gate.
- **Wording** (same in both skills):
  ```
  **Re-execution check**: If this skill has been run before on this task,
  see `.cwf/docs/skills/re-execution.md` before proceeding.
  ```

### Decision 3: Content of `re-execution.md`

Four sections:

1. **Detection** — how to recognise Pass 2+:
   - Exec file (`f-implementation-exec.md` / `g-testing-exec.md`) has non-template
     content in Actual Results, OR status is not "Backlog"

2. **Core rule** — work forward, never backward:
   - Do NOT `git reset`, `git revert`, or amend prior checkpoint commits
   - Do NOT clear or overwrite the existing exec file from scratch
   - Pick up from where execution left off

3. **Commit naming**:
   - `Task {N}: Pass {2}: {short description}`
   - Example: `Task 76: Pass 2: Fix edge case in re-execution detection`

4. **Doc handling**:
   - Append a `## Pass {N} Results` section to the exec file
   - Prior pass results remain intact for audit trail
   - Update the Status field and Next Action at the bottom

### Decision 4: What is NOT a blocker

Explicit negative: old exec file results are never a blocker by themselves.
Only real blockers are missing/corrupt plan files or fundamental architectural
incompatibility. Document this clearly to prevent agents from incorrectly
stalling on re-execution.

## Decomposition Check
- [ ] **Time**: No
- [ ] **People**: No
- [ ] **Complexity**: No — one new doc, two one-line additions to skill files
- [ ] **Risk**: No
- [ ] **Independence**: No

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 76
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design confirmed by reading both exec SKILL.md files in full. All decisions implemented
as designed; `re-execution.md` got one extra standalone heading for the non-blocker rule.

## Lessons Learned
Conditional one-liners ("If X, read Y") are a lightweight way to handle edge-case flows
without bloating happy-path skill instructions.

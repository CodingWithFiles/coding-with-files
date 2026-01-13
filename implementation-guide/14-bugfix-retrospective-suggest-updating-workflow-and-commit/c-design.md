# retrospective: suggest updating workflow docs and commit - Design

## Task Reference
- **Task ID**: internal-14
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/14-retrospective-suggest-updating-workflow-and-commit
- **Template Version**: 2.0

## Goal
Define architecture and design decisions for retrospective: suggest updating workflow docs and commit.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Design Approach: Add Step 1.5 and Step 6.5 to cig-retrospective.md

- **Decision**: Insert two new steps into cig-retrospective workflow
  - **Step 1.5**: Verify Git Branch (after Step 1: Resolve Task Directory)
  - **Step 6.5**: Update Workflow Statuses and Prepare Final Commit (after Step 6: Execute Retrospective)

- **Rationale**:
  - Follows established pattern from Task 13 (step insertion between existing steps)
  - Step 1.5 ensures consistency with all other workflow commands
  - Step 6.5 addresses root cause of task 12 issue (missing status updates)
  - More prominent than enhancing existing Step 8 (less likely to be missed)

- **Trade-offs**:
  - **Benefits**: Explicit guidance prevents status update errors, follows established patterns, includes verification step
  - **Drawbacks**: Adds complexity to retrospective workflow, assumes users follow checkpoint commit pattern

### Guidance Type: Non-Blocking Suggestions

- **Decision**: Step 6.5 provides guidance but doesn't enforce actions
- **Rationale**:
  - Users may have different git workflows (checkpoint commit vs incremental commits)
  - Flexibility for users not following Task 13's recommended workflow
  - Command suggests best practices without being prescriptive
- **Trade-offs**:
  - **Benefits**: Flexible, doesn't break existing workflows, graceful for different environments
  - **Drawbacks**: Users might skip guidance (mitigated by making it prominent and including verification step)

## System Design

### Problem Analysis

**Issue Identified in Task 12**:
During task 12 retrospective, h-retrospective.md was completed but workflow document statuses (a-plan.md, c-design.md, d-implementation.md, e-testing.md) weren't updated to "Finished" before final commit. This caused status-aggregator.pl to report 25% completion instead of 100%.

**Root Cause**:
cig-retrospective.md lacks explicit guidance on:
1. Updating all workflow file status fields to "Finished"
2. Amending checkpoint commit with retrospective + status updates
3. The recommended workflow: retrospective → update statuses → amend commit → merge

### Current State of cig-retrospective.md

**8-Step Structure**:
1. Resolve Task Directory
2. Load Parent Context
3. Present Context Summary
4. LLM Decision - Read Parent Details
5. Reference Workflow Documentation
6. Execute Retrospective Workflow
7. Check Decomposition Signals (N/A for retrospective)
8. Suggest Next Steps

**Gaps Identified**:
- Line 60: Mentions "Update task documents" but doesn't specify HOW
- Line 62: References "Status Field: Use valid status values" but no guidance on setting to "Finished"
- Line 80: Success criteria includes "Task marked as complete" but no explicit steps
- No git operations guidance for checkpoint commits or amending

### Solution Design

#### Step 1.5: Verify Git Branch

**Purpose**: Ensure retrospective is executed on correct task branch (consistency with Task 13 pattern)

**Implementation**: Copy Step 1.5 pattern from Task 13 workflow commands

#### Retrospective Two-Phase Approach

**Purpose Clarification**: Retrospective serves two distinct purposes:
1. **Verify status** (Step 6): Workflow docs match reality, task ready to proceed (gating)
2. **Capture learnings** (Step 7): What worked, what didn't, future improvements (reflection)

**Order rationale**: Verify status first - no point documenting learnings if task isn't finished and things may change.

#### Step 6: Verify Task Status

**Purpose**: Gate on actual status - verify workflow docs match reality before retrospective

**Workflow Sequence**:
1. **Verify workflow docs match reality**:
   - Update all workflow step docs to match what has been finished
   - If any required phase isn't finished, task cannot proceed to merge

2. **Verify Task Status**:
   - Run `/cig-status <task-path>` to verify 100% (all phases "Finished")
   - **If <100%**: Task not finished - identify and finish missing work or create follow-up tasks
   - **If 100%**: Proceed to Step 7 (Execute Retrospective)

#### Step 7: Execute Retrospective Workflow

**Purpose**: Document what worked, what didn't, lessons learned (only executed if Step 6 verification passes)

**Workflow**: Complete h-retrospective.md with variance analysis, successes, improvements, key learnings, and recommendations

#### Step 8: Prepare Final Commit and Suggest Next Steps

**Purpose**: Stage all files including retrospective, create final commit, suggest merge

**Workflow Sequence**:
1. **Stage all files**:
   ```bash
   git add implementation-guide/<task-dir>/*.md <other-changed-files>
   ```

2. **Decision Tree for Git Operations**:
   - **Checkpoint commit exists** (WIP commit from planning) → Amend it and update commit message
   - **No checkpoint commit** (incremental commits during implementation) → Create new commit

3. **Git Commands**:
   - Amend checkpoint: `git commit --amend` (update message: remove "planning complete", add "Finished with retrospective")
   - New commit: `git commit -m "Task <num>: [description] - Finished with retrospective"`

4. **Suggest Next Steps**: Fast-forward merge to main

#### Summary of Changes to cig-retrospective.md

1. **Update allowed-tools** (line 3):
   - Add `Bash(git branch:*)` and `Bash(git add:*)` (git commit requires user permission)

2. **Insert Step 1.5**: Verify Git Branch (after Step 1)

3. **Replace Step 6**: Change from "Execute Retrospective Workflow" to "Verify Task Status" (gating)

4. **Insert new Step 7**: "Execute Retrospective Workflow" (write h-retrospective.md)

5. **Remove old Step 7**: "Check Decomposition Signals" (N/A for retrospective)

6. **Update Step 8**: "Prepare Final Commit and Suggest Next Steps" (stage all files, commit, merge)

7. **Update Success Criteria**: Add verification checkpoints

## Data Flow

### Retrospective Workflow with New Steps

```
1. Resolve Task Directory
   ↓
1.5. Verify Git Branch [NEW]
   ↓
2. Load Parent Context
   ↓
3. Present Context Summary
   ↓
4. LLM Decision - Read Parent Details
   ↓
5. Reference Workflow Documentation
   ↓
6. Verify Task Status [NEW - GATING]
   - Update workflow docs to match reality
   - Verify with /cig-status (100% required)
   - If not finished: STOP, finish work or create follow-ups
   - If finished: Proceed to Step 7
   ↓
7. Execute Retrospective Workflow [REFLECTION]
   - Complete h-retrospective.md content
   - Document what worked, what didn't, lessons learned
   ↓
8. Prepare Final Commit and Suggest Next Steps [UPDATED]
   - Stage all files including retrospective
   - Amend checkpoint commit with updated message
   - Suggest merge to main
```

## Interface Design

### Step 6 Guidance Structure (Verification/Gating)

```markdown
### Step 6: Verify Task Status

Before documenting retrospective learnings, verify task is actually finished:

1. **Verify workflow docs match reality**
   - Update all workflow step docs to match what has been finished
   - If any required phase isn't finished, task cannot proceed to merge

2. **Verify Task Status**
   - Run `/cig-status <task-path>` to verify 100% (all phases "Finished")
   - **If <100%**: Task not finished - finish missing work or create follow-up tasks
   - **If 100%**: Proceed to Step 7 (Execute Retrospective)
```

### Step 7 Guidance Structure (Retrospective/Reflection)

```markdown
### Step 7: Execute Retrospective Workflow

Complete h-retrospective.md with:
- Variance analysis (time, scope, quality)
- What went well
- What could be improved
- Key learnings (technical and process)
- Recommendations for future work
```

### Step 8 Guidance Structure (Final Commit)

```markdown
### Step 8: Prepare Final Commit and Suggest Next Steps

1. **Stage all files**:
   ```bash
   git add implementation-guide/<task-dir>/*.md <other-changed-files>
   ```

2. **Amend checkpoint commit** (if exists):
   ```bash
   git commit --amend
   ```
   Update message: remove "planning complete", add "Finished with retrospective"

3. **Or create new commit** (if no checkpoint):
   ```bash
   git commit -m "Task <num>: [description] - Finished with retrospective"
   ```

4. **Suggest merge to main**:
   ```bash
   git checkout main
   git merge --ff-only <task-branch>
   ```
```

### Integration with Task 13 Workflow Pattern

Task 13 established the "Recommended Implementation Workflow" (c-design.md lines 159-187):
1. cig-implementation - Define implementation plan
2. cig-testing - Define testing regime
3. **Checkpoint Commit** - Save planning work
4. Execute Implementation - Make code changes
5. Execute Testing - Validate implementation

Steps 6, 7, and 8 finish this pattern:
6. **Verify Status** (Step 6) - Ensure workflow docs match reality, gate on 100% (all "Finished")
7. **Execute Retrospective** (Step 7) - Document what worked, what didn't, lessons learned
8. **Prepare Final Commit** (Step 8) - Stage all files, amend checkpoint commit with accurate final status, suggest merge to main

## Constraints

### Technical Constraints
- Must work within allowed-tools constraints for cig-retrospective command
- Git operations must be available (`Bash(git:*)` in allowed-tools)
- Must not break existing retrospective workflow for users not using checkpoint commits

### Workflow Constraints
- Should be opt-in guidance, not mandatory steps
- Must gracefully handle different git workflows (checkpoint vs incremental)
- Must work for users in non-git environments (guidance degrades gracefully)

### Design Constraints
- Maintain 8-step structure with clean integer numbering (no decimals)
- Keep guidance concise and actionable
- Step 6 gates on verification, Step 7 writes retrospective, Step 8 commits

## Validation
- [x] Design review completed
- [x] Architecture approved by team
- [x] Integration points verified
- [x] Step 1.5 branch verification decision confirmed
- [x] Step 6/7 order corrected (verify status, then execute retrospective)
- [x] Step 6 as gating mechanism confirmed (verify, not force)
- [x] Step 7 removed (decomposition check - N/A for retrospective)
- [x] Clean integer numbering restored (6, 7, 8 - no decimals)
- [x] Commit message update requirement added (no --no-edit)
- [x] Architectural alignment verified (retrospective written before final commit)
- [x] Consistent "Finished" terminology throughout

## Status
**Status**: Finished
**Next Action**: Design updated - 8-step structure with clean numbering, verification-first, consistent terminology - ready for implementation updates
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

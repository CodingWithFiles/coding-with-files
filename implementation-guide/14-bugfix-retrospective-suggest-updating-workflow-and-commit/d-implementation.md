# retrospective: suggest updating workflow docs and commit - Implementation

## Task Reference
- **Task ID**: internal-14
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/14-retrospective-suggest-updating-workflow-and-commit
- **Template Version**: 2.0

## Goal
Implement retrospective: suggest updating workflow docs and commit following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- `.claude/commands/cig-retrospective.md` - Restructure Steps 6-8, add Step 1.5, update allowed-tools, update success criteria

### Reference Files (Read Only)
- Task 13 workflow commands (for Step 1.5 pattern): `.claude/commands/cig-plan.md`
- Updated design document: `implementation-guide/14-bugfix-retrospective-suggest-updating-workflow-and-commit/c-design.md`

## Implementation Steps

### Step 1: Update allowed-tools (Line 3)
- [ ] Change from `Bash(git:*)` to `Bash(git branch:*)` and `Bash(git add:*)`
- [ ] Reason: git commit should require user permission, not be automatic

### Step 2: Insert Step 1.5 - Verify Git Branch
- [ ] Insert Step 1.5 between Step 1 and Step 2
- [ ] Copy pattern from Task 13 workflow commands (`.claude/commands/cig-plan.md`)
- [ ] Adapt references to be retrospective-specific

### Step 3: Replace Step 6 - Change to "Verify Task Status"
- [ ] Replace "Execute Retrospective Workflow" with "Verify Task Status"
- [ ] Add subsection 1: Verify workflow docs match reality
- [ ] Add subsection 2: Run `/cig-status` to verify 100%
- [ ] Add failure path: If <100%, identify missing work
- [ ] Remove commit preparation from Step 6

### Step 4: Renumber old Step 6 to new Step 7 - "Execute Retrospective Workflow"
- [ ] Move retrospective execution to Step 7
- [ ] Keep content focused on writing h-retrospective.md
- [ ] Add note: Only executed if Step 6 verification passes

### Step 5: Remove old Step 7 - "Check Decomposition Signals"
- [ ] Delete entire Step 7 section
- [ ] Reason: Decomposition check is N/A for retrospective (task already executed)

### Step 6: Update Step 8 - "Prepare Final Commit and Suggest Next Steps"
- [ ] Add subsection: Stage all files (including h-retrospective.md)
- [ ] Add subsection: Amend checkpoint commit (without --no-edit)
- [ ] Add guidance to update commit message: remove "planning complete", add "Finished with retrospective"
- [ ] Add subsection: Suggest merge to main

### Step 7: Update Success Criteria
- [ ] Add "Workflow file statuses verified to match reality"
- [ ] Add "Task verified at 100% via /cig-status"
- [ ] Add "Final commit created/amended with retrospective"
- [ ] Change "Task marked as complete" to "Verify task completion and update retrospective date"

### Step 8: Validation
- [ ] Verify clean 8-step structure (no decimals)
- [ ] Verify Step 6 is gating (verify status)
- [ ] Verify Step 7 is reflection (execute retrospective)
- [ ] Verify Step 8 prepares commit AFTER retrospective written
- [ ] Verify allowed-tools correct (git branch, git add - not git commit)
- [ ] Verify no markdown syntax errors

## Code Changes

### File: `.claude/commands/cig-retrospective.md`

#### Change 1: Update allowed-tools (Line 3)

**Before**:
```markdown
allowed-tools: Read, Write, Edit, Bash(...)
```

**After**:
```markdown
allowed-tools: Read, Write, Edit, Bash(git branch:*), Bash(git add:*), Bash(...)
```

**Reason**: Only allow git branch and git add by default; git commit requires user permission

#### Change 2: Insert Step 1.5 (After Step 1, Before Step 2)

**Insert new section**:
```markdown
### Step 1.5: Verify Git Branch

Before proceeding with retrospective, verify you're on the correct task branch:

1. **Check current branch**:
   ```bash
   git branch --show-current
   ```

2. **Expected branch format**:
   - Feature: `feature/<task-num>-<slug>`
   - Bugfix: `bugfix/<task-num>-<slug>`
   - Hotfix: `hotfix/<task-num>-<slug>`
   - Chore: `chore/<task-num>-<slug>`

3. **If on wrong branch**:
   - STOP execution
   - Inform user they should be on task branch for retrospective
   - Suggest checking out correct branch: `git checkout <task-branch>`
   - Do not proceed with retrospective until on correct branch

**Rationale**: Retrospective should be executed on task branch to ensure git operations (status updates, commit amendments) are applied to correct branch before merging to main.
```

#### Change 3: Replace Step 6 - Change to "Verify Task Status"

**Before**:
```markdown
6. **Execute Retrospective Workflow**:
   - Open h-retrospective.md (v2.0 only - retrospective is new format only)
   - **Focus on**: Variance analysis, what went well, what could be improved, key learnings, recommendations
   ...
```

**After**:
```markdown
6. **Verify Task Status**:

Before documenting retrospective learnings, verify task is actually finished:

1. **Verify workflow docs match reality**:
   - Update all workflow step docs to match what has been finished
   - If any required phase isn't finished, task cannot proceed to merge

2. **Verify Task Status**:
   - Run `/cig-status <task-path>` to verify 100% (all phases "Finished")
   - **If <100%**: Task not finished - identify and finish missing work or create follow-up tasks
   - **If 100%**: Proceed to Step 7 (Execute Retrospective)
```

#### Change 4: Renumber old Step 6 to Step 7 - "Execute Retrospective Workflow"

**Move and keep content**:
```markdown
7. **Execute Retrospective Workflow**:
   - Open h-retrospective.md (v2.0 only - retrospective is new format only)
   - **Focus on**: Variance analysis, what went well, what could be improved, key learnings, recommendations
   - **Avoid**: Future work planning (unless captured as recommendations)

   Steps to complete retrospective:
   - **Extract planning data**: Read original estimates, success criteria, goals from a-plan.md/plan.md
   - **Gather actual results**: Review status sections, implementation timeline
   - **Calculate variances**: Compare time estimates vs actual, scope changes, dependency resolution
   - **Generate retrospective report**:
     - Executive Summary: Duration, scope comparison, outcome
     - Variance Analysis: Time/effort, scope changes, quality metrics
     - What Went Well: Successes, effective processes, collaboration highlights
     - What Could Be Improved: Challenges, inefficiencies, gaps
     - Key Learnings: Technical insights, process learnings, risk mitigation strategies
     - Recommendations: Process improvements, tool recommendations, future work
   - **Update task documents**: Fill in Actual Results and Lessons Learned sections in all workflow files

   **Status Field**: Use valid status values only. See `.cig/docs/workflow/workflow-steps.md#status-values`.
```

#### Change 5: Remove old Step 7 - "Check Decomposition Signals"

**Delete this section**:
```markdown
7. **Check Decomposition Signals**: N/A for retrospective (task is complete)
```

**Reason**: Decomposition check is N/A for retrospective - task already executed

#### Change 6: Update Step 8 - "Prepare Final Commit and Suggest Next Steps"

**Before** (approximate):
```markdown
8. **Suggest Next Steps**:
   - **Primary**: Task complete, archive materials, update knowledge base
   - **Alternative**: Create follow-up tasks based on recommendations
   - **Alternative**: Share learnings with team
```

**After**:
```markdown
8. **Prepare Final Commit and Suggest Next Steps**:

With verification and retrospective finished (Steps 6-7):

1. **Stage all files**:
   ```bash
   git add implementation-guide/<task-dir>/*.md <other-changed-files>
   ```

2. **Amend checkpoint commit** (if exists):
   ```bash
   git commit --amend
   ```
   Update commit message:
   - Remove "(planning complete)" suffix from title
   - Update status line from "Planning complete, ready for..." to "Finished with retrospective"
   - Keep all technical details about changes made

3. **Or create new commit** (if no checkpoint):
   ```bash
   git commit -m "Task <num>: [description] - Finished with retrospective

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   ```

4. **Suggest merge to main**:
   ```bash
   git checkout main
   git merge --ff-only <task-branch>
   ```

**Primary Path**: Merge to main (task 100% finished with retrospective)
**Alternative Paths**: Create follow-up tasks, share learnings with team
```

#### Change 7: Update Success Criteria

**Add new criteria**:
```markdown
- [ ] Workflow file statuses verified to match reality
- [ ] Task verified at 100% via /cig-status
- [ ] Final commit created/amended with retrospective
- [ ] Verify task completion and update retrospective date (not "Task marked as complete")
```

## Test Coverage
- Manual testing: Run `/cig-retrospective 14` on this task to validate new 8-step workflow
- Integration testing: Verify Step 6 verification gates properly
- Integration testing: Verify Step 7 retrospective writes h-retrospective.md
- Integration testing: Verify Step 8 stages all files and prepares commit
- Validation: Confirm `/cig-status 14` shows 100% after Step 6 verification

## Validation Criteria
- [ ] Clean 8-step structure (no decimal numbering)
- [ ] Step 1.5 inserted between Step 1 and Step 2
- [ ] Step 6 replaced with "Verify Task Status" (gating)
- [ ] Old Step 6 moved to Step 7 "Execute Retrospective Workflow" (reflection)
- [ ] Old Step 7 "Check Decomposition Signals" removed
- [ ] Step 8 updated to prepare final commit AFTER retrospective written
- [ ] allowed-tools correct: `Bash(git branch:*)`, `Bash(git add:*)` (not git commit)
- [ ] Success criteria updated with verification checkpoints
- [ ] No markdown syntax errors
- [ ] Architectural alignment: retrospective written before final commit

## Status
**Status**: Finished
**Next Action**: Implementation plan updated - clean 8-step structure, verification-first approach
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

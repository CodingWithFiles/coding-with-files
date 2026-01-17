---
description: Guide user through retrospective phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(git branch:*), Bash(git add:*), Bash(.cig/scripts/command-helpers/hierarchy-resolver.pl:*), Bash(.cig/scripts/command-helpers/context-inheritance.pl:*), Bash(.cig/scripts/command-helpers/format-detector.pl:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

**Task arguments**: $ARGUMENTS

**Helper scripts location**: `.cig/scripts/command-helpers/`

## Your task
Guide the user through the retrospective phase.

**CRITICAL - Argument Parsing**:
- Extract the FIRST space-separated word from the task arguments above as the task path
- Any additional words after the first provide user context about their intent
- Use the extra words to understand what the user wants, but do NOT pass them to script calls
- Example: "11 update the design" → task path is "11", extra text explains what to do

**CRITICAL - Task Path Validation**:
- Task paths MUST match hierarchical number format: digits separated by dots
- Valid formats: "11", "1.2", "12.2.3", "1.1.1.1"
- Invalid formats: "some text", "`date`", "11; rm -rf", "text.text"
- If first word does NOT match valid format, inform user and do not invoke scripts
- This prevents command injection and ensures only valid task identifiers reach scripts

Follow the 10-step workflow structure:

1. **Resolve Task Directory**:
   - Extract first word from task arguments
   - Validate it matches hierarchical number format (digits and dots only)
   - If valid: call `.cig/scripts/command-helpers/hierarchy-resolver.pl <task-path>` using the Bash tool
   - If invalid: inform user the task path format is invalid, do not invoke script

2. **Verify Git Branch**:

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

3. **Load Parent Context**:
   - Use the validated task path from step 1
   - Call `.cig/scripts/command-helpers/context-inheritance.pl <task-path>` using the Bash tool
4. **Present Context Summary**: Show structural map with status markers
5. **LLM Decision**: Read specific parent sections and all task workflow files
6. **Reference Workflow Documentation**: Read `.cig/docs/workflow/workflow-steps.md#retrospective`
7. **Verify Task Status**:

Before documenting retrospective learnings, verify task is actually finished:

1. **Verify workflow docs match reality**:
   - Update all workflow step docs to match what has been finished
   - If any required phase isn't finished, task cannot proceed to merge

2. **Verify Task Status**:
   - Run `/cig-status <task-path>` to verify 100% (all phases "Finished")
   - **If <100%**: Task not finished - identify and finish missing work or create follow-up tasks
   - **If 100%**: Proceed to Step 8 (Execute Retrospective)

8. **Execute Retrospective Workflow**:
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

9. **Update BACKLOG.md**:

Synchronise BACKLOG.md with task completion and retrospective findings:

1. **Check for completed BACKLOG items**:
   - Review BACKLOG.md for items this task addressed
   - Mark items complete or remove them from BACKLOG.md
   - Example: Task 20 completed "Fix d-implementation.md Template to Reference e-testing.md"

2. **Check retrospective for new items**:
   - Review h-retrospective.md Recommendations/Future Work sections
   - Add new tasks identified during retrospective to BACKLOG.md
   - Example: Task 20 identified "Rename Constraints section headers in templates"

3. **Stage changes if BACKLOG.md modified**:
   ```bash
   git add BACKLOG.md
   ```

**Rationale**: BACKLOG.md synchronisation ensures completed work is tracked and new discoveries captured atomically with task completion.

10. **Prepare Final Commit and Suggest Next Steps**:

With verification, retrospective, and BACKLOG.md update finished (Steps 7-9):

**Commit Message Guidelines**:
- Keep title concise (~50 chars): "Task N: Brief description"
- Body should explain WHY, not just WHAT
  - What changed is visible in the diff
  - Why it changed provides context for future readers
- Include technical details that aren't obvious from code
- Avoid redundant suffixes like "Finished with retrospective" (wastes signal-to-noise ratio)
- End with Co-Authored-By line

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

## Success Criteria
- [ ] Retrospective file (h-retrospective.md) opened and updated
- [ ] Planning data extracted from workflow files
- [ ] Actual results gathered from task execution
- [ ] Variance analysis completed (time, scope, quality)
- [ ] What went well documented
- [ ] What could be improved identified
- [ ] Key learnings captured
- [ ] Recommendations provided for future work
- [ ] Actual Results sections updated in all workflow files
- [ ] Verify task completion and update retrospective date
- [ ] All workflow file statuses updated to "Finished"
- [ ] Task verified at 100% via /cig-status
- [ ] BACKLOG.md updated if task completed items or identified new ones
- [ ] Final commit created/amended with retrospective
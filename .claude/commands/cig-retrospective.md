---
description: Guide user through retrospective phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(git rev-parse:*), Bash(git branch:*), Bash(.cig/scripts/command-helpers/*:*), Bash(git add:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Scope & Boundaries

**This step**: Complete the retrospective document (j-retrospective.md) with learnings, metrics analysis, and process improvements for future tasks.

**Not this step**: Implementation, testing, or deployment (those are complete). This is reflection only.

**If blocked or finished**: Call `workflow-manager control --current-step=j-retrospective --task-path=<path>` to determine next action. See `.cig/docs/workflow/blocker-patterns.md` for detailed blocker handling guidance.

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

**Task arguments**: $ARGUMENTS

**Current task/workflow (if available)**: !/current-task-wf

**Helper scripts location**: `.cig/scripts/command-helpers/`

## Your task
Guide the user through the retrospective phase.

**Implementation**: First ensure we're in git repository root:

!{bash}
.cig/scripts/command-helpers/context-manager location

**CRITICAL - Argument Parsing**:
- If task arguments provided: Extract the FIRST space-separated word as the task path
- If NO task arguments: Use task_num from "Current task/workflow" context above
- Any additional words after the first provide user context about their intent
- Use the extra words to understand what the user wants, but do NOT pass them to script calls
- Example: "11 update the design" → task path is "11", extra text explains what to do
- If neither arguments nor inference available: Error "Cannot determine task. Specify task number or ensure context is inferrable."

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
   - If valid: call `.cig/scripts/command-helpers/context-manager hierarchy <task-path>` using the Bash tool
   - If invalid: inform user the task path format is invalid, do not invoke script

2. **Verify Git Branch**:

Before proceeding with retrospective, verify you're on the correct task branch:

2.1. **Check current branch**:
   ```bash
   git branch --show-current
   ```

2.2. **Expected branch format**:
   - Feature: `feature/<task-num>-<slug>`
   - Bugfix: `bugfix/<task-num>-<slug>`
   - Hotfix: `hotfix/<task-num>-<slug>`
   - Chore: `chore/<task-num>-<slug>`

2.3. **If on wrong branch**:
   - STOP execution
   - Inform user they should be on task branch for retrospective
   - Suggest checking out correct branch: `git checkout <task-branch>`
   - Do not proceed with retrospective until on correct branch

**Rationale**: Retrospective should be executed on task branch to ensure git operations (status updates, commit amendments) are applied to correct branch before merging to main.

3. **Load Parent Context**:
   - Use the validated task path from step 1
   - Call `.cig/scripts/command-helpers/context-manager inheritance <task-path>` using the Bash tool
4. **Present Context Summary**: Show structural map with status markers
5. **LLM Decision**: Read specific parent sections and all task workflow files
6. **Reference Workflow Documentation**: Read `.cig/docs/workflow/workflow-steps.md#retrospective`
7. **Verify Task Status**:

Before documenting retrospective learnings, verify task is actually finished:

7.1. **Verify workflow docs match reality**:
   - Update all workflow step docs to match what has been finished
   - If any required phase isn't finished, task cannot proceed to merge

7.2. **Verify Task Status**:
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

9. **Update CHANGELOG.md and BACKLOG.md**:

Document completed work and synchronize backlog with task completion:

9.1. **Update CHANGELOG.md with task completion**:
   - Read CHANGELOG.md (first ~100 lines using Read tool with limit parameter) to understand format pattern
   - Create new entry at top using Edit tool for current task including:
     - Task number and title
     - Completion date, duration vs estimate
     - What problems were addressed
     - Key changes made
     - BACKLOG items completed (if any)
   - Follow existing entry style - keep it concise
   - Example: See Task 40 entry for reference format

9.2. **Remove completed BACKLOG items**:
   - Use Grep tool to find all task headers in BACKLOG.md (pattern: `^## Task:`)
   - This returns line numbers efficiently - agent can see all tasks at a glance
   - If details needed to confirm completion, use Read with offset/limit around specific line numbers
   - Use Edit tool to remove completed items (they're now documented in CHANGELOG)
   - Note in CHANGELOG entry which BACKLOG items were addressed
   - Example: Task 40 removed "Complete Helper Script Migration to Trampoline Pattern"

9.3. **Add new BACKLOG items**:
   - Read j-retrospective.md Recommendations/Future Work sections
   - Add new items to BACKLOG.md using Edit tool with standard format:
     - `## Task: {descriptive-name}`
     - `**Task-Type**: bugfix|chore|feature|hotfix|discovery`
     - `**Priority**: High|Medium|Low`
     - `**Status**: Follow-up from Task X`
     - Description, Problems, Solution, Scope, Rationale
     - `**Identified in**: Task X retrospective (j-retrospective.md)`
   - Example: Task 44 added "Clarify Maintenance Phase Applicability"

9.4. **Stage changes**:
   ```bash
   git add CHANGELOG.md BACKLOG.md
   ```

**Rationale**: CHANGELOG documents what was accomplished, BACKLOG tracks future work. Synchronizing atomically ensures project history is complete and work items properly tracked.

**Token-Efficient Approach**:
- Use Read with offset/limit to sample existing format (don't read entire files)
- Use Grep to find task headers with line numbers (efficient task discovery)
- Use Edit for targeted changes (preserves formatting, more reliable than Write)
- Let agent match existing patterns rather than rigid templates

10. **Create Checkpoints Branch and Squash Commits**:

After retrospective document is complete, preserve detailed commit history and create a clean commit for review:

10.1. **Create checkpoints branch** to preserve detailed archaeology:
   ```bash
   git branch "$(git rev-parse --abbrev-ref HEAD)-checkpoints"
   ```
   This creates a backup branch (e.g., `feature/44-refactor-template-generation-system-checkpoints`) preserving all checkpoint commits for future reference.

10.2. **Squash all task commits** into a single commit:
   ```bash
   # Find the base commit (commit before this task branch was created)
   git log --oneline --graph -20  # Identify base commit

   # Interactive rebase to squash commits
   git rebase -i <base-commit-hash>
   ```

   In the interactive rebase editor:
   - Keep the first commit as `pick`
   - Change all subsequent commits to `squash` (or `s`)
   - Save and exit

10.3. **Write brief "why"-focused commit message**:
   When prompted for the squashed commit message:
   - **Title**: Brief (< 50 chars), focus on problem solved
   - **Body**: Explain WHY the change was needed, not WHAT changed (diff shows that)
   - **Include**: Co-Authored-By trailer
   - **Example**:
     ```
     Task 44: Refactor template generation system

     Template generation wasn't leveraging Task 32's inference system,
     task types weren't visible at a glance, and cross-references were
     broken. This refactor enables inference-based workflows and adds
     git automation for checkpoint commits.

     Co-developed-by: Claude Sonnet 4.5 <noreply@anthropic.com>
     ```

10.4. **Verify checkpoints branch preserved history**:
   ```bash
   git log "$(git rev-parse --abbrev-ref HEAD)-checkpoints" --oneline
   ```
   Confirm all detailed checkpoint commits are preserved.

11. **Suggest Next Steps**:

With verification, retrospective, BACKLOG.md update, and commit squashing finished:

11.1. **Suggest merge to main**:
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
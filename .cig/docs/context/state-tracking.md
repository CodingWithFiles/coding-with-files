# State Tracking: Signal-Based Inference System

## Overview

The CIG state tracking system uses **probabilistic signal aggregation** to infer the user's current context (task number and workflow step) without requiring explicit state management. This approach aligns with how humans naturally work - context is inferred from multiple environmental signals rather than rigid state machines.

**Core Principle:** Multiple weak signals, when correlated, create strong confidence. When signals disagree, ask for clarification.

## Motivation

**Problem:** Traditional approaches have limitations:
- **Deterministic (branch-only):** Breaks on main branch, doesn't handle worktrees well
- **Explicit state file:** Gets stale, requires manual updates, conflicts in worktrees
- **Status aggregator:** Slow to scan, ambiguous with multiple in-progress tasks

**Solution:** Aggregate multiple signals, each providing partial evidence of current context. The system becomes self-correcting as users work naturally - file timestamps update, status changes, branches switch.

## Signal Sources

### Task Inference Signals

**Note:** As of Task 32 Phase 1 implementation (2026-01), "Workflow Status" signal was removed from task inference. Testing revealed it to be lower quality (manual, can be stale) while heavily correlating with Progress signal. Completed tasks ("Finished" = 100 pts) dominated current task ("In Progress" = 80 pts), causing false negatives. Status signal retained only for workflow step inference.

| Signal | Type | Weight | Characteristics | Example |
|--------|------|--------|-----------------|---------|
| **Git Branch** | Singular/Null | 100 | Strongest when present, null on main | `chore/31-update` → task 31 |
| **Worktree Context** | Singular/Null | 95 | Directory path indicates task isolation | `~/cig-task-31/` → task 31 |
| **State File** | Singular/Null | 85 | Explicit but can be stale | `.cig/current-task` = "31" |
| **File Recency** | Continuous | 0-90 | Decays over time | Modified 5 min ago = 85 pts |
| ~~**Workflow Status**~~ | ~~Ordered~~ | ~~0-80~~ | **REMOVED** - Low quality, correlates with Progress | ~~Step "In Progress" = 80 pts~~ |
| **Task Progress** | Percentage | 0-60 | Linear ramp (cliff function) | 75% work potential = 45 pts |

### Workflow Step Inference Signals

| Signal | Type | Weight | Characteristics | Example |
|--------|------|--------|-----------------|---------|
| **Step Status** | Ordered | 100 | "In Progress" = current step | d-implementation "In Progress" |
| **Step Recency** | Continuous | 0-90 | Most recently modified file | e-testing.md edited 2 min ago |
| **Workflow Order** | Sequential | 70 | Next step after last "Finished" | a,d,e Finished → f next |
| **Command Context** | Singular | 80 | Inferred from command invoked | `/cig-testing` → e-testing-plan |

## Correlation Logic

### Top-N Scoring Per Signal

Each signal returns its **top 5 candidates** with scores (not winner-takes-all):

```bash
# Recency signal
score_recency:
  31:90 (modified 5 min ago)
  32:85 (modified 10 min ago)
  30:70 (modified 30 min ago)
  29:50 (modified 60 min ago)
  28:30 (modified 120 min ago)

# Progress signal (cliff function: work potential)
score_progress:
  31:45 (75% work potential - strong momentum to finish)
  32:30 (50% work potential)
  30:15 (25% work potential)
  29:6  (10% work potential - fresh task)
  28:0  (0% work potential - complete or blocked)

# Workflow status signal
score_workflow_status:
  31:80 (d-implementation "In Progress")
  32:80 (e-testing "In Progress")
  30:70 (testing)
  ...
```

### Correlation Check

**Rule:** If all non-null signals **have the same task in their top result**, signals are correlated.

```bash
function check_correlation() {
    # Get top task from each signal (null if signal not present)
    branch_top=$(get_branch_task)           # 31 or null
    worktree_top=$(get_worktree_task)       # 31 or null
    state_top=$(get_state_task)             # 31 or null
    recency_top=$(score_recency | head -1)  # 31:90
    progress_top=$(score_progress | head -1) # 31:60
    status_top=$(score_workflow_status | head -1) # 31:80

    # Extract task numbers, skip nulls
    top_tasks=()
    [ -n "$branch_top" ] && top_tasks+=("$branch_top")
    [ -n "$worktree_top" ] && top_tasks+=("$worktree_top")
    [ -n "$state_top" ] && top_tasks+=("$state_top")
    [ -n "$recency_top" ] && top_tasks+=("${recency_top%%:*}")
    [ -n "$progress_top" ] && top_tasks+=("${progress_top%%:*}")
    [ -n "$status_top" ] && top_tasks+=("${status_top%%:*}")

    # Check if all point to same task
    unique_count=$(printf '%s\n' "${top_tasks[@]}" | sort -u | wc -l)

    if [ $unique_count -eq 1 ]; then
        echo "correlated"  # All agree
    else
        echo "uncorrelated"  # Disagreement
    fi
}
```

### Decision Logic

**Correlated (All Top Signals Agree):**
```
branch:100     → Task 31 ✓
worktree:95    → Task 31 ✓
recency:90     → Task 31 ✓
progress:60    → Task 31 ✓
status:80      → Task 31 ✓

ALL AGREE → Return: task_num:31, task_slug:chore-update-backlog-and-changelog, workflow_step:d-implementation-plan
```

**Uncorrelated (Top Signals Disagree):**
```
branch:100     → Task 31
recency:90     → Task 32  ← CONFLICT
state:85       → Task 31
progress:58    → Task 32  ← CONFLICT

DISAGREE → Ask user to choose
```

**All Null (No Signals):**
```
branch:null
state:null
recency:<5 (all very old)

NO SIGNALS → Error: "Cannot infer current task"
```

### Output Formats

**Default (Simple):**
```
task_num: 31
task_slug: chore-update-backlog-and-changelog
workflow_step: d-implementation-plan
```

**Verbose (Full Breakdown):**
```
task_num: 31
task_slug: chore-update-backlog-and-changelog
workflow_step: d-implementation-plan

Signal Breakdown:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Task Signals (all correlated):
  branch:100     ✓ chore/31-update-backlog-and-changelog
  worktree:95    ✓ /home/user/cig-task-31
  state:85       ✓ .cig/current-task = "31"
  recency:90     ✓ modified 5 minutes ago (top of 5)
  progress:60    ✓ 50% complete (top of 5, sweet spot)
  wf-status:80   ✓ d-implementation "In Progress" (top of 5)

Step Signals (all correlated):
  status:100     ✓ d-implementation-plan "In Progress"
  recency:85     ✓ d-implementation-plan.md modified 3 min ago
  sequence:70    ✓ next after a-task-plan "Finished"

Correlation: ALL SIGNALS AGREE
Total task score: 510 pts
```

## Workflow Dependencies

### Dependency Graph

Steps have natural dependencies that must be satisfied:

**Chore tasks (v2.1):**
```
a-task-plan (always first)
  ↓
d-implementation-plan (requires: a)
  ↓
e-testing-plan (requires: a, d)
  ↓
f-implementation-exec (requires: a, d, e)
  ↓
g-testing-exec (requires: a, d, e, f)
  ↓
j-retrospective (requires: a, d, e, f, g)
```

**Feature tasks (v2.1):**
```
a → b → c → d → e → f → g → h → i → j
(All steps required, linear progression)
```

**Bugfix tasks (v2.1):**
```
a → c → d → e → f → g → j
(Skips b-requirements, uses existing requirements)
```

**Hotfix tasks (v2.1):**
```
a → d → e → h → j
(Minimal workflow: plan, implement, test, rollout, retrospective)
```

### Validation Rules

**Prerequisite Check (Warning):**
```bash
$ /cig-retrospective 31

System checks:
✓ a-task-plan:            Finished
✗ d-implementation-plan:  Backlog  ← MISSING
✗ e-testing-plan:         Backlog  ← MISSING
✗ f-implementation-exec:  Backlog  ← MISSING
✗ g-testing-exec:         Backlog  ← MISSING

⚠️  Warning: Dependent workflow steps haven't been completed.
Missing: implementation-plan, testing-plan, implementation-exec, testing-exec
Continue with retrospective anyway? [y/N]
```

**Validation Levels:**

1. **Strict (blocking):** Prevents proceeding without dependencies
   - Use for: Critical steps where skipping causes corruption

2. **Warning (non-blocking):** Shows warning, allows override
   - Use for: Most workflow steps (recommended default)
   - Helps users without getting in the way

3. **Permissive:** No checks, trust user
   - Use for: Experienced users, rapid iteration, edge cases

**Recommended:** Start with Warning level - balances guidance and flexibility.

## Implementation Approach

### Phase 1: Task Inference (MVP)

**Goal:** Reliably detect current task across all scenarios

**Implementation:**
1. Implement scoring algorithm for all task signals
2. Aggregate scores across all tasks
3. Apply confidence logic (agreement check)
4. User prompt on ambiguity

**Deliverables:**
- `.cig/scripts/command-helpers/get-current-task` (helper script)
- Returns: task number or error
- Flag: `--explain` to show scoring breakdown

### Phase 2: Step Inference

**Goal:** Detect current workflow step within task

**Implementation:**
1. Scan workflow files for status
2. Check file modification times
3. Apply workflow ordering rules
4. Infer from command context

**Deliverables:**
- `.cig/scripts/command-helpers/get-current-step` (helper script)
- Returns: step filename (e.g., "d-implementation-plan")

### Phase 3: Workflow Validation

**Goal:** Prevent workflow errors, guide users

**Implementation:**
1. Define dependency graphs for each task type
2. Check prerequisites before executing commands
3. Show warnings for missing dependencies
4. Allow override for edge cases

**Deliverables:**
- `.cig/scripts/command-helpers/check-workflow-deps` (validator)
- Integration with all `/cig-*` commands

## Usage Examples

### Example 1: Clean Workflow (High Confidence)

```bash
# User is on task branch, working normally
$ git branch --show-current
chore/31-update-backlog-and-changelog

$ /cig-requirements
[Inferred: Task 31 (confidence: high)]
Proceeding with requirements planning for Task 31...
```

**Signal breakdown:**
- branch:100 → 31
- state:85 → 31
- recency:75 → 31
- All agree → High confidence → Auto-proceed

---

### Example 2: Worktree Isolation (High Confidence)

```bash
# User has multiple worktrees
$ pwd
/home/user/cig-task-31

$ git worktree list
/home/user/cig              [main]
/home/user/cig-task-31      [chore/31-update-backlog]
/home/user/cig-task-32      [feature/32-new-feature]

$ /cig-implementation
[Inferred: Task 31 (confidence: high, from worktree context)]
Proceeding with implementation planning...
```

**Signal breakdown:**
- worktree:95 → 31 (directory path)
- branch:100 → 31
- All agree → High confidence

---

### Example 3: Ambiguity (Low Confidence)

```bash
# User on main branch, recently worked on two tasks
$ git branch --show-current
main

$ /cig-testing
[Inference ambiguous - multiple candidates found]

Multiple tasks appear active. Which one?
  1. Task 31 (chore) - 75% complete, modified 5 mins ago
     Signals: recency:75, progress:40, state:85
  2. Task 32 (feature) - 25% complete, modified 10 mins ago
     Signals: recency:80, progress:60

Select task [1-2]: 1

[Proceeding with Task 31...]
```

**Signal breakdown:**
- branch:null (on main)
- Task 31: recency:75, state:85, progress:40 = 200 pts
- Task 32: recency:80, progress:60 = 140 pts
- Margin:60 > 20 → Would auto-select Task 31
- BUT let's say Task 32 had recency:85 → margin:15 < 20 → Ask user

---

### Example 4: Workflow Validation (Warning)

```bash
# User tries to skip steps
$ /cig-retrospective 31

Task 31 status:
✓ a-task-plan:            Finished (100%)
✗ d-implementation-plan:  Backlog (0%)
✗ e-testing-plan:         Backlog (0%)
...

⚠️  Warning: Dependent workflow steps haven't been completed.
Missing: implementation-plan, testing-plan, implementation-exec, testing-exec

This is a retrospective for work that's not complete. Are you documenting
work that was already done outside the workflow?

Continue with retrospective anyway? [y/N]: y

[Proceeding with retrospective for Task 31...]
```

**Use case:** Retrospective documentation (like Task 31) where work was done, just not tracked in workflow steps.

---

### Example 5: Step Resumption

```bash
# User left mid-implementation yesterday
$ /cig-status 31
Task 31 (chore): 62% complete
  ✓ a-task-plan:            Finished
  ✓ d-implementation-plan:  Finished
  ○ e-testing-plan:         In Progress (last modified: yesterday 5pm)
  - f-implementation-exec:  Backlog
  - g-testing-exec:         Backlog
  - j-retrospective:        Backlog

# User wants to continue (no command specified)
$ /cig-continue
[Inferred: Task 31, step e-testing-plan (was In Progress)]
Resuming testing planning for Task 31...
```

**Signal breakdown:**
- Step status: e-testing-plan "In Progress" = 100 pts
- Auto-resume where left off

---

## Edge Cases & Solutions

### Edge Case 1: All Tasks Complete
**Scenario:** User completed all tasks, BACKLOG empty, trying to start new work

**Signals:** All tasks at 100%, no "In Progress"

**Solution:** Error with guidance
```
No current task found. All tasks are complete.
Create a new task: /cig-new-task <num> <type> "description"
Or switch to existing: /cig-switch <task-num>
```

---

### Edge Case 2: Stale State File
**Scenario:** User has `.cig/current-task` = "25" but hasn't worked on Task 25 in weeks, recently active on Task 31

**Signals:**
- state:85 → Task 25 (stale)
- recency:90 → Task 31 (recent work)
- branch:100 → Task 31 (current branch)

**Solution:** Recency + branch override state file
- Task 25: 85 pts
- Task 31: 190 pts
- Auto-select Task 31 (state file ignored due to low overall score)

---

### Edge Case 3: Detached HEAD
**Scenario:** User is on detached HEAD (reviewing old commit)

**Signals:**
- branch:null (detached HEAD)
- state:null (no file)
- All recency very old

**Solution:** Cannot infer, ask user or error
```
Cannot infer current task (detached HEAD, no recent activity).
Use /cig-switch <task-num> to set current task.
```

---

## Performance Considerations

### Optimization Strategies

1. **Lazy Evaluation:** Only compute scores when needed
   - Don't scan on every command
   - Cache for 60 seconds within same session

2. **Selective Scanning:** Only check tasks with recent activity
   - Filter by: modified in last 7 days
   - Skip: tasks at 100% (complete)

3. **Fast Paths:** Check strongest signals first
   - Branch parse: <1ms
   - State file read: <1ms
   - Only scan files if needed

4. **Parallel Scoring:** Score tasks in parallel (bash background jobs)
   ```bash
   for task in $tasks; do
       score_task "$task" &
   done
   wait
   ```

### Expected Performance

- **Fast path (branch match):** <10ms
- **Full scoring (10 tasks):** <100ms
- **Full scoring (100 tasks):** <500ms (with optimizations)

**Target:** <100ms for 95% of invocations

---

## Debugging & Observability

### Debug Mode

**Flag:** `--explain` shows scoring breakdown
```bash
$ get-current-task --explain

Task Inference Results:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Task 31 (chore/update-backlog): 340 pts ✓ SELECTED
  branch:100    ✓ chore/31-update-backlog-and-changelog
  worktree:95   ✓ /home/user/cig-task-31
  state:85      ✓ .cig/current-task = "31"
  recency:75    ✓ modified 5 minutes ago
  wf-status:80  ✓ f-implementation-exec "In Progress"
  progress:60   ✓ 62% complete (active range)

Task 32 (feature/new-feature): 145 pts
  recency:85    ✓ modified 2 minutes ago
  progress:60   ✓ 25% complete (active range)

Confidence: HIGH (all signals agree on Task 31)
Margin: 195 pts (well above ambiguity threshold of 20)
```

### Logging

Optional logging for troubleshooting:
```bash
# Enable debug logging
export CIG_STATE_TRACKING_DEBUG=1

# Logs to: .cig/logs/state-tracking.log
[2026-01-27 16:00:00] Task inference: 31 (confidence: high, score: 340)
[2026-01-27 16:00:00] Signals: branch=100, worktree=95, state=85, recency=75
[2026-01-27 16:05:30] Step inference: e-testing-plan (status=In Progress)
```

---

## Migration Path

### Current State (Commands with Arguments)
```bash
/cig-requirements 31
/cig-design 31
/cig-implementation 31
```

### Future State (Skills without Arguments)
```bash
/cig-requirements   # Infers: Task 31, step b-requirements-plan
/cig-design         # Infers: Task 31, step c-design-plan
/cig-implementation # Infers: Task 31, step d-implementation-plan
```

### Transition Period (Both Supported)
```bash
# Explicit (always works)
/cig-requirements 31

# Implicit (works when inference confident)
/cig-requirements
[Inferred: Task 31]

# Explicit override (when inference wrong)
/cig-requirements 32  # Overrides inference, uses 32
```

**Rollout Strategy:**
1. Phase 1: Implement inference, keep arguments required
2. Phase 2: Make arguments optional, fall back to inference
3. Phase 3: Migrate to skills (no arguments), full inference

---

## Design Rationale

### Why Multi-Signal vs. Deterministic?

**Deterministic (branch-only):**
- ✅ Simple, fast
- ❌ Fragile (breaks on main branch, worktree edge cases)

**Multi-Signal (probabilistic aggregation):**
- ✅ Robust, self-correcting
- ✅ Meets user expectations (AI-like inference from context)
- ❌ More complex, requires tuning

**Decision:** Multi-signal approach better aligns with how humans and AI agents work - context emerges from environment, not rigid state.

### Why Confidence = Agreement?

Alternative: Threshold-based (score > 200 = confident)

**Problems:**
- Hard to tune (what's the right threshold?)
- Doesn't capture signal disagreement
- Single strong signal (branch:100) could dominate

**Agreement-based:**
- Natural: if all signals point same way, high confidence
- Catches conflicts: branch says 31, recency says 32 → ask user
- Explainable: "All signals agree on Task 31"

### Why Allow Override?

**Philosophy:** The system should guide, not block.

Users know their intent better than any inference system. When signals disagree or validation fails, ask don't prevent.

**Exception:** Hard blocks for data corruption (e.g., can't run retrospective if task directory doesn't exist).

---

## Future Enhancements

### Machine Learning (Optional)

If we collect user choices when system asks:
```
Ambiguous: Task 31 (score:200) vs Task 32 (score:195)
User chose: Task 31
```

Learn patterns:
- User prefers higher-number tasks when close?
- User prefers chore tasks over features?
- Time-of-day patterns?

**Trade-off:** Complexity vs. marginal improvement. Likely not worth it for v1.

### Contextual Signals

Additional signals to consider:
- **Calendar:** Time of day, day of week (morning = fresh work?)
- **Commit history:** Tasks with recent commits more likely current
- **External trackers:** JIRA/GitHub issue status
- **Team context:** What are teammates working on?

**Trade-off:** Richer signals vs. privacy, performance, complexity.

---

## References

- Workflow steps: `.cig/docs/workflow/workflow-steps.md`
- Blocker patterns: `.cig/docs/workflow/blocker-patterns.md`
- Context tools: `.cig/docs/context/tools.md`
- Task hierarchy: `.cig/docs/workflow/workflow-overview.md`

---

**Version:** 1.0 (Draft)
**Last Updated:** 2026-01-27
**Status:** Design Proposal

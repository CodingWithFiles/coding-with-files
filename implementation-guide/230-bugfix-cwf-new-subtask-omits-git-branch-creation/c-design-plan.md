# cwf-new-subtask omits git branch creation - Design
**Task**: 230 (bugfix)

## Task Reference
- **Task ID**: internal-230
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/230-cwf-new-subtask-omits-git-branch-creation
- **Template Version**: 2.1

## Goal
Add a branch-creation step to `cwf-new-subtask/SKILL.md` so subtask creation leaves the
user on a subtask-specific branch, and remove the prose that blessed the omission. The fix
is confined to one file; the correct branch name and base are already dictated by
`cwf-new-task` and the retrospective's merge-suggestion.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Decision 1 — Branch name and base (dictated, not chosen)
- **Decision**: Insert `git checkout -b "<type>/<num>-<slug>"`, mirroring `cwf-new-task`
  step 4 verbatim. `<num>` is the subtask's full decimal (e.g. `48.1`), `<type>`/`<slug>`
  the subtask's own. It branches off current `HEAD` — the parent branch you are on when
  invoking the skill.
- **Slug source (security invariant)**: `<slug>` must be the slug the script produced —
  i.e. the one embodied in the directory `task-workflow create` just made — **not** an
  independently re-derived slug. Re-slugifying could both diverge the branch name from the
  directory and escape the slugifier's sanitisation (lowercase, spaces→hyphens, special
  chars removed, ≤50 chars), reopening the FR4(e) injection hazard. `<num>` is decimal-only
  and `<type>` a fixed enum, so the slug is the only user-derived component. `cwf-new-task`
  carries the same latent ambiguity; state the constraint here so the implementation pins it.
- **Precondition (make explicit)**: correct ff-merge later depends on `HEAD` being the
  parent branch tip at invocation. If run from `main` or a sibling subtask branch, the branch
  is based off the wrong commit and the retrospective ff-merge targets the wrong ref. The
  guard is the existing step-3 note "Verify you are on the intended base branch before
  running"; the new branch step relies on it rather than guaranteeing it.
- **Rationale**: `.cwf/docs/skills/retrospective-extras.md:147` computes the current-task
  branch as `<task_type>/<task_num>-<task_slug>` and (line 152-155) ff-merges it into the
  parent branch. Branching off `HEAD` makes the parent branch an ancestor of the subtask
  branch, which is exactly the precondition that ff-merge requires. Both facts are fixed by
  existing consumers, so there is nothing to invent.
- **Trade-offs**: None material — matching the existing pattern is the whole point.

### Decision 2 — Mirror step 4 as a bare command; default stop-on-error is the semantics (resolves open decision)
- **Decision**: Insert the **bare** command with **no** fatal/non-fatal annotation, exactly
  as `cwf-new-task` step 4 carries it. Do **not** copy the scratch step's explicit "non-fatal"
  treatment onto it, and equally do **not** add new "this step is fatal" prose that
  `cwf-new-task` does not have — either would diverge from the skill this is meant to mirror.
  The fatal semantics come for free from default stop-on-error.
- **Rationale**: The branch is load-bearing — the retrospective ff-merge depends on it.
  Letting a failure (e.g. branch already exists) stop the skill surfaces the error; swallowing
  it would silently reintroduce exactly this bug. The scratch `mkdir` is non-fatal only because
  subtask creation does not need scratch; the branch is not in that category. Keeping the
  command bare keeps the two creation skills character-for-character aligned on this step.

### Decision 3 — Duplicate the step, do not build a shared source (resolves open decision)
- **Decision**: Duplicate the two-line branch step in `cwf-new-subtask`, worded identically
  to `cwf-new-task`. No new include/shared-source mechanism.
- **Rationale**: design-alignment's single-source rule governs whole artefacts (a skill), not
  instructional prose inside one, and no include mechanism exists for `SKILL.md` text. The two
  creation skills already duplicate the entire Type Inference section verbatim, so duplication
  with consistent wording is the established pattern. Inventing a shared source for two lines
  violates "the best part is no part".

### Decision 4 — Regression guard stays minimal (resolves open decision)
- **Decision**: No new automated harness. Verification is a reproducible smoke-test in the
  testing phase: create a throwaway subtask, assert `HEAD` is the subtask branch, assert the
  parent branch is an ancestor. The retrospective round-trip is the natural functional guard.
- **Rationale**: `t/` covers Perl helpers only; there is no skill-prose test harness, and
  building one for a prose file is disproportionate. Keep the fix small and reversible.

## System Design
### Component Overview
Single file changed: `.claude/skills/cwf-new-subtask/SKILL.md`. The edits:
- **Scope & Boundaries** (line 13): add "and git branch" to the "This step" summary, matching
  `.claude/skills/cwf-new-task/SKILL.md`'s wording.
- **New step 4 "Create Git Branch"**: inserted after step 3 (Validate and Create Subtask),
  before scratch provisioning — the same position it holds in `cwf-new-task`.
- **Renumber**: Provision Scratch 4→5, Provide Next Steps 5→6.
- **Correct the prose** (current lines 102-103): delete "There is **no `git checkout -b`** in
  this skill — the subtask stays on the parent branch"; reword the scratch step's lead-in so it
  no longer depends on that false premise.
- **Provide Next Steps (step 6) output body**: surface the created branch ("branch checked
  out"), matching `cwf-new-task` step 6 — not only the Success Criteria checkbox.
- **Success Criteria**: add "Git branch created and checked out".
- The Type Inference failure-path lines ("no directory, no branch checkout") need no change —
  they become internally consistent once the branch step exists.

### Failure mode (accepted, pre-existing)
Step 3 (`task-workflow create`) creates the subtask directory before step 4 branches. A fatal
`git checkout -b` failure therefore leaves the new subtask directory in place on the parent
branch with no branch created — a half-created state. This is **consistent with `cwf-new-task`**,
which has the identical step-3→4 ordering, so it is accepted pre-existing behaviour, not a
regression this task introduces. Recovery is manual and ordinary: resolve the cause (e.g. the
branch name already exists), then delete the directory and re-run, or pick a fresh subtask
number. No new rollback machinery is added.

### Data Flow
1. User runs `/cwf-new-subtask <parent> <num> <type> "desc"` while on the parent branch.
2. Steps 1-3 resolve parent, load context, and create the nested subtask dir (baseline = HEAD).
3. **Step 4** `git checkout -b "<type>/<num>-<slug>"` → HEAD is now the subtask branch at the
   parent tip.
4. Step 5 provisions the scratch leaf (non-fatal).
5. Later, the retrospective's Suggest Merge ff-merges the subtask branch back into the parent
   branch — now possible because the branch exists and the parent is its ancestor.

## Interface Design
The only contract is the branch command, identical to `cwf-new-task` step 4:
```bash
git checkout -b "<type>/<num>-<slug>"
```
No script, flag, or data-model change. `task-workflow create` is untouched.

## Constraints
- `SKILL.md` is LLM-executed instruction prose, not compiled code — no unit test; verification
  is a reproducible smoke-test.
- The retrospective and other consumers already assume the correct behaviour and must not be
  altered to accommodate the bug.
- Fix is forward-only; subtasks already created on parent branches are not retro-fitted.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? If yes, consider decomposition
- [ ] **People**: Does this need >2 people working on different parts? If yes, consider decomposition
- [ ] **Complexity**: Does this involve 3+ distinct concerns? If yes, consider decomposition
- [ ] **Risk**: Are there high-risk components that need isolation? If yes, consider decomposition
- [ ] **Independence**: Can parts be worked on separately? If yes, consider decomposition

**Assessment**: No signals triggered — one file, one concern.

## Validation
- [ ] Branch name and base match `cwf-new-task` and `retrospective-extras.md:147`
- [ ] Branch command is the bare `cwf-new-task` step 4 form — no added fatal/non-fatal annotation
- [ ] Branch uses the script-produced slug (== created directory), not a re-derived one
- [ ] Erroneous "stays on the parent branch" prose removed and remaining steps read consistently
- [ ] "Provide Next Steps" output surfaces the created branch (parity with `cwf-new-task` step 6)
- [ ] Smoke-test path defined for the testing phase (create → on subtask branch → parent is ancestor)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

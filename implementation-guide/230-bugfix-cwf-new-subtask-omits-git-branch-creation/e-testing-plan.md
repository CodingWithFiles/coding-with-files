# cwf-new-subtask omits git branch creation - Testing Plan
**Task**: 230 (bugfix)

## Task Reference
- **Task ID**: internal-230
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/230-cwf-new-subtask-omits-git-branch-creation
- **Template Version**: 2.1

## Goal
Verify the edited `.claude/skills/cwf-new-subtask/SKILL.md` documents a correct branch-creation
step, that the documented procedure actually produces a subtask branch the workflow can ff-merge
back into its parent, and that no existing consumer regresses.

## Test Strategy
### Test Levels
- **Static (prose) verification**: read/grep the edited `SKILL.md` — the change itself is prose, so its correctness is first a content check (steps present, numbering, no stale prose, command matches the mirror source).
- **Procedure simulation (integration)**: execute the sequence the edited skill now documents (`task-workflow create` a throwaway subtask, then `git checkout -b`) and assert the resulting git state. This tests the *procedure*, independent of the skill-invocation cache (see Environment constraint).
- **Consumer/regression**: confirm downstream consumers (`CWF::TaskContextInference` branch signal; the retrospective merge round-trip) and the existing `t/` suite still behave.
- **Acceptance (fresh session, deferred)**: a live `/cwf-new-subtask` invocation once the skill cache reloads.

### Test Coverage Targets
- **Critical path** (create → on own branch → parent is ancestor → ff-mergeable): must pass.
- **Prose correctness** (no residual "stays on the parent branch"; command byte-identical to `cwf-new-task` step 4): must pass.
- **Regression**: full `prove -r t/` green; no throwaway artefacts left behind.

## Test Cases
### Functional Test Cases

- **TC-1 (static): Branch step present and command-identical**
  - **Given**: the edited `cwf-new-subtask/SKILL.md`
  - **When**: reading the new `### 4. Create Git Branch` step
  - **Then**: it contains `git checkout -b "<type>/<num>-<slug>"` byte-identical to `cwf-new-task/SKILL.md` step 4; step headings are contiguous `1`→`6`.

- **TC-2 (static): False prose removed, failure-path lines intact**
  - **Given**: the edited file
  - **When**: `grep -n "stays on the parent branch"` and `grep -n "no \`git checkout -b\`"`
  - **Then**: zero matches for both; the two Type-Inference failure-path lines ("no directory, no branch" / "no branch checkout") remain and now read as accurate.

- **TC-3 (static): Next Steps and Success Criteria surface the branch**
  - **Given**: the edited file
  - **When**: reading the Provide Next Steps body and Success Criteria
  - **Then**: Next Steps surfaces the created branch name; Success Criteria includes "Git branch created and checked out".

- **TC-4 (integration): documented procedure yields an ff-mergeable subtask branch**
  - **Given**: a real parent task checked out on its own branch (a throwaway parent created for the test, or an existing task tip)
  - **When**: following the edited skill's steps — `task-workflow create` a throwaway subtask `<P>.<n>`, then `git checkout -b "<type>/<P>.<n>-<slug>"` off HEAD
  - **Then**: `git rev-parse --abbrev-ref HEAD` is the subtask branch, and `git merge-base --is-ancestor <parent-branch> <subtask-branch>` exits 0 (the ff-merge precondition holds). **Cleanup**: delete the throwaway subtask dir and branch; return to the task tip.

- **TC-5 (integration): TaskContextInference branch signal correlates for a subtask on its own branch**
  - **Given**: the throwaway subtask from TC-4 checked out on its own branch
  - **When**: running `task-context-inference`
  - **Then**: it resolves the subtask's *own* decimal `task_num` (not an error, not the parent's) — confirming the Task 166 behaviour change is benign and `TaskContextInference` needs no code change.

- **TC-6 (acceptance): retrospective merge round-trip**
  - **Given**: the throwaway subtask branch exists (TC-4)
  - **When**: deriving the merge target per `.cwf/docs/skills/retrospective-extras.md` (compute subtask branch `<type>/<num>-<slug>` and parent branch, then `git merge --ff-only <parent-branch> <subtask-branch>`)
  - **Then**: the computed subtask branch name equals the one TC-4 created, and the ff-merge into the parent branch succeeds. **Cleanup**: reset the parent branch and delete throwaway artefacts.

- **TC-7 (regression): existing suite green**
  - **Given**: the repo after the edit
  - **When**: `prove -r t/`
  - **Then**: all tests pass (no Perl changed; this guards against accidental breakage and confirms `scratch.t` / `security-review-changeset.t` remain green).

- **TC-8 (acceptance, deferred to a fresh session): live skill invocation**
  - **Given**: a NEW Claude Code session (so the edited `SKILL.md` is loaded, not the session-cached old one)
  - **When**: running `/cwf-new-subtask <parent> <subnum> <type> "desc"`
  - **Then**: on completion HEAD is the subtask branch and the branch/scratch/next-steps are surfaced. Recorded as a post-merge manual acceptance check.

### Non-Functional Test Cases
- **Security (FR4(e))**: confirm the branch name uses the script-produced slug — a description containing shell metacharacters is slugified by `task-workflow create` before it reaches `git checkout -b`, so no unsanitised input is interpolated. (Spot-check within TC-4 using a description with spaces/punctuation.)
- **Reliability**: the branch step is fatal-on-failure by default stop-on-error — if the branch already exists, `git checkout -b` errors and the procedure stops rather than silently continuing (observed, not forced).
- **Usability**: `SKILL.md` reads cleanly end-to-end with contiguous numbering (covered by TC-1/TC-3).

## Test Environment
### Setup Requirements
- Run against the **actual repo** — `cwf-manage validate` and the helpers use `find_git_root` and cannot be pointed at a temp dir (per project memory). Every throwaway artefact (subtask directory, branch, any parent-branch ff-merge) MUST be reverted so the repo returns to the task-branch tip.
- `/cwf-delete-task` (or manual `rm -rf` of the throwaway dir + `git branch -D`) reverses a throwaway subtask.

### Critical constraint — skill session cache
The edited `SKILL.md` is **not live in the current session**: skills load at session start, so invoking `/cwf-new-subtask` now would execute the pre-edit cached skill. Therefore TC-4/5/6 **simulate the documented procedure by hand** (helper + `git` commands), which validates the behaviour the skill now prescribes; TC-8 defers the true live-invocation check to a fresh session.

### Automation
- No new automated harness (design Decision 4). TC-7 uses the existing `prove -r t/`; TC-1–TC-6 are executed and recorded in `g-testing-exec.md`.

## Validation Criteria
- [ ] TC-1..TC-3 static checks pass (branch step present & command-identical; false prose gone; Next Steps/Success Criteria updated)
- [ ] TC-4 subtask branch created and parent is an ancestor (ff-mergeable)
- [ ] TC-5 branch signal correlates to the subtask's own number
- [ ] TC-6 retrospective merge round-trip succeeds with the expected branch name
- [ ] TC-7 `prove -r t/` green; no throwaway artefacts remain
- [ ] TC-8 recorded as deferred fresh-session acceptance check

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

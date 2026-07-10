# Gate exec phases on terminal subtask status - Plan
**Task**: 225 (bugfix)

## Task Reference
- **Task ID**: internal-225
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/225-gate-exec-phases-on-terminal-subtask-status
- **Baseline Commit**: ffb4fd8ebb0c8ba8fcca9082d6c034fe4004b74b
- **Template Version**: 2.1

## Goal
A parent task must never proceed to an exec or later workflow step (`f`, `g`, `h`,
`i`, `j`) while any of its child subtasks is in a non-terminal status.

## Problem Statement

Reported by a CwF user against their own Task 68. The parent squashed its branch at
retrospective (`j`) while subtask 68.1 was still open, rewriting the commit that 68.1
was branched from. 68.1's merge-base regressed to the grandparent task, so the
suggested `git merge --ff-only` into the parent could no longer fast-forward.

Two observations shape the fix:

1. **The reported symptom is downstream of the real defect.** No CWF phase consults a
   task's children before proceeding. `cwf-retrospective/SKILL.md:41` (Step 6) gates
   on "all phases Finished (100%)", but "phases" means *this* task's own `a`–`j`
   files. `workflow-manager status --workflow` enriches wf-file detail and never
   descends into children. A parent with a live subtask therefore reads as 100% and
   proceeds through `f`, `g`, `h`, `i`, and `j` unchallenged.

2. **The omission is inconsistent with CWF's own precedent.** `find_children()` exists
   at `.cwf/lib/CWF/TaskPath.pm:373`, and `/cwf-delete-task` already uses it as a hard
   refusal (`task-workflow.d/delete:115`, "Check 5: leaf"). Delete refuses to act on a
   non-leaf task; the exec phases do not care. The helper and the precedent both exist
   — the exec-and-later phases simply never call them.

**Blast radius, stated accurately**: the damage is loud, not silent. CWF suggests
`git merge --ff-only` for subtask merges, and after a parent squash the parent tip is
no longer an ancestor of the child, so that merge *fails* rather than silently
resurrecting the pre-squash commits. The ff-only discipline contained the corruption.
What the user actually lost was a documented path forward; their agent had to invent
`git rebase --onto` unaided.

## Settled Position

A subtask is **blocking by definition**. Work that does not block the parent's
deliverable is a top-level follow-up task or a backlog item — not a child. Deferring a
subtask therefore means cancelling it and opening a follow-up, not leaving it open
beneath a completed parent.

Consequently the gate is strict: the only non-blocking child states are the terminal
statuses **Finished**, **Skipped**, and **Cancelled**. Any other status
(Backlog, To-Do, In Progress, Testing, Blocked) halts the parent.

## Success Criteria
- [ ] Entering `f`, `g`, `h`, `i`, or `j` on a task with any non-terminal child halts
      with a message naming each offending child and its status
- [ ] The three terminal statuses (Finished, Skipped, Cancelled) do not halt the parent
- [ ] A task with no children is unaffected (no behaviour change, no new failure mode)
- [ ] Plan phases (`a`–`e`) remain ungated — creating a subtask mid-`f` and returning
      to `f` after the child completes does not deadlock
- [ ] Child discovery reuses `find_children()`; terminal-status classification reuses a
      single predicate rather than a second open-coded status list
- [ ] `cwf-manage validate` clean; full `prove -r t/` suite green

## Original Estimate
**Effort**: ~0.5 day
**Complexity**: Low
**Dependencies**: `CWF::TaskPath::find_children()`, `CWF::TaskState` status predicates

## Major Milestones
1. **Gate mechanism**: a single reusable check answering "does this task have any
   non-terminal child?", built from existing helpers
2. **Wire into phases**: `f`, `g`, `h`, `i`, `j` skills call the gate before doing work
3. **Regression cover**: tests for the no-children, terminal-children, and
   non-terminal-children cases

## Risk Assessment

### High Priority Risks
- **Mid-`f` deadlock**: decomposition normally *happens during* `f`. A gate that fires
  on subtask creation, or that cannot be re-entered, would make the documented
  decomposition flow impossible.
  - **Mitigation**: gate fires on *entering* a phase, never on creating a subtask.
    Explicit test: create child mid-`f`, complete child, re-enter `f` successfully.

### Medium Priority Risks
- **Retroactive breakage of in-flight tasks**: an existing parent with a stale
  non-terminal child would suddenly refuse to proceed.
  - **Mitigation**: this repo has no subtasks at all (verified — no nested task
    directories exist), so CWF's own dogfooding is unaffected. The halt message must
    name the remedy (finish, skip, or cancel the child) so an external adopter is never
    stuck without a next action.

- **Gate placement drift**: five skills each needing an identical pre-step invites
  copy-paste divergence.
  - **Mitigation**: one helper, one invocation line; the design phase chooses whether
    that line lives in each SKILL.md or in a shared preamble keyed by phase letter.

- **"Finished" does not imply "merged"**: the strict gate makes the reported squash
  stranding unreachable at `j` only if Finished children have actually been merged into
  the parent. A child can be Finished and unmerged today.
  - **Mitigation**: surface as an explicit design-phase question. Deliberately *not*
    pre-decided here; may resolve as a follow-up task rather than scope creep.

## Dependencies
- `.cwf/lib/CWF/TaskPath.pm` — `find_children()` (existing, used by delete)
- `.cwf/lib/CWF/TaskState.pm` — `_is_closed()` (existing, private, currently unused)
- Skill files for phases `f`, `g`, `h`, `i`, `j`

## Constraints
- Perl core modules only; `use utf8;` in every `.cwf` Perl file
- Any edit to a hashed script requires a same-commit `script-hashes.json` refresh
- No new child-discovery or status-classification code path where one already exists

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — roughly half a day.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — one gate, one wiring
      pass, one test file.
- [ ] **Risk**: Are there high-risk components that need isolation? No — the sole high
      risk (mid-`f` deadlock) is a test case, not a separable component.
- [ ] **Independence**: Can parts be worked on separately? No — the gate and its wiring
      are meaningless apart.

**Result**: 0 of 5 signals triggered. No decomposition. (A task about subtask gating
requires no subtasks; had it needed them, this plan could not have reached `f`.)

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 225
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All six success criteria met. `CWF::SubtaskGate` gates `f`, `g`, `h`, `i`, `j` at three
chokepoints (SKILL Pre-Step, `cwf-checkpoint-commit`, `checkpoints-branch-manager
create`). Terminal children (Finished/Skipped/Cancelled) pass; childless tasks are
unaffected; plan phases `a`–`e` stay ungated. Child discovery reuses `find_children()`;
`TaskState::_is_closed()` was promoted to the exported `status_is_terminal()` and now
delegates, so one status list exists rather than two. `prove -r t/`: 78 files, 1073
tests, all PASS. `cwf-manage validate`: OK. Actual effort ~1.5h against a 0.5-day
estimate.

## Lessons Learned
The estimate was formed before confirming that both named dependencies already existed,
so it priced construction where the work turned out to be assembly. The high-priority
mid-`f` deadlock risk was mitigated exactly as designed — the gate fires on phase entry,
never on subtask creation. The deferred "Finished does not imply merged" question
survived design review unchanged and is carried out as a follow-up backlog item.

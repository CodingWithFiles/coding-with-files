# Adopt guarded worktree enter/exit process - Plan
**Task**: 181 (feature)

## Task Reference
- **Task ID**: internal-181
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/181-adopt-guarded-worktree-process
- **Baseline Commit**: 264f7288aa9794cb22c092d39368994f70d62d74
- **Template Version**: 2.1

## Goal
Define and document a robust, guarded CWF worktree process built on the harness's
`EnterWorktree`/`ExitWorktree` tools, so that worktree use with CWF (model-initiated,
manual, or operator) follows one safe path instead of the unguarded raw-`git worktree`
chain that caused the Task 172 data-loss incident.

## Success Criteria
- [ ] A defined worktree-process convention doc exists and is referenced from the
      CLAUDE.md conventions list (and surfaced in MEMORY): it mandates create-via-
      `EnterWorktree`, `worktree.baseRef: head`, a `ToolSearch` load of the deferred
      tools at point of use, and teardown surfaced to the operator.
- [ ] `worktree.baseRef: head` is configured so new worktrees branch from current
      HEAD, not `origin/<default>` (resolves C3 vs `feedback_branch_from_current_commit`).
- [ ] The C2 uncommitted-changes removal refusal is confirmed first-hand once, against
      scratch-only content, closing the Task-177 runtime residual (evidenced in g).
- [ ] The process forbids unprompted `discard_changes: true` / auto-remove, and the
      security review confirms no process/skill text functions as blanket pre-
      authorisation to remove a worktree (the refusal gate stays intact).
- [ ] No permission-allowlist broadening is introduced as the friction fix; the
      no-needless-`cd`/absolute-path discipline (R6) is captured, and `tmp-paths.md`
      is updated where worktree scratch paths intersect it.

## Original Estimate
**Effort**: ~1 day
**Complexity**: Medium (low code, but a live data-loss-class probe and a security gate)
**Dependencies**: Harness `EnterWorktree`/`ExitWorktree` (deferred, `ToolSearch`-loaded);
Task 177 findings C1–C6; harness `worktree.baseRef` setting.

## Major Milestones
1. **Requirements**: Pin what the process must mandate and forbid; decide where the
   process lives and what references it; restate the C1–C4 facts as fixed inputs.
2. **Design**: Choose the doc home and the config mechanism, and define how the process
   integrates with existing CWF flows (skills / CLAUDE.md / memory) and steers ad-hoc
   raw `git worktree add` onto the guarded path.
3. **Implementation**: Write the process doc, set `worktree.baseRef: head`, update the
   CLAUDE.md/MEMORY references and `tmp-paths.md`; hash-refresh any edited helper in the
   same commit.
4. **Testing**: Confirm the C2 refusal first-hand against scratch-only content; verify
   `baseRef: head` takes effect; security review of the process-as-authorisation surface.
5. **Rollout & Retrospective**: Retire the backlog item; capture the runtime-probe result.

## Risk Assessment
### High Priority Risks
- **Confirming C2 means exercising the data-loss-class path.** The only way to watch the
  refusal is to create via `EnterWorktree`, which switches the session CWD — the exact
  hazard in `feedback_worktree_cwd_dataloss`.
  - **Mitigation**: Run the probe against scratch-only content with no uncommitted
    primary-tree work present; follow the very discipline being documented (absolute
    paths, no `cd` into the disposable tree). Treat it as the first dogfood of the process.
- **The process doc could be over-read as blanket pre-authorisation.** A future skill or
  model might treat "there is a documented process" as standing permission to auto-remove
  worktrees, eroding the `discard_changes` refusal gate (Task 177 carry-forward note 2).
  - **Mitigation**: Process text explicitly forbids unprompted `discard_changes`/auto-
    remove and requires surfacing teardown to the operator; the security review (FR4(e))
    gates on this invariant before rollout.

### Medium Priority Risks
- **`worktree.baseRef` is a harness-global setting**, so it affects non-CWF worktree use
  too.
  - **Mitigation**: Document the setting and its rationale; `head` aligns with the
    branch-off-HEAD rule generally, so the cross-effect is benign.
- **Scope creep into the `--show-toplevel` call sites.** Task 173 already made the
  canonical root resolvers worktree-safe; the 6 remaining sites are read-only resolution,
  not create/teardown.
  - **Mitigation**: Explicitly out of scope — this feature governs create/teardown, not
    root inspection.

## Dependencies
- Harness `EnterWorktree`/`ExitWorktree` tools — deferred; a CWF skill must `ToolSearch`
  (`select:EnterWorktree,ExitWorktree`) to load them, and the gate is satisfied by
  "project instructions (CLAUDE.md/memory)".
- Task 177 evidentiary base (C1–C6) — treated as fixed input, not re-litigated.
- The harness `worktree.baseRef` setting (`fresh` default → must set `head`).

## Constraints
- **Documentation-primary**: minimise new code (planning simplicity principle); the
  deliverable is a process + a config setting, not a new helper.
- The guard is **`EnterWorktree`-scoped** (C1): the process cannot bolt protection onto
  raw `git worktree add`; it must steer all use through `EnterWorktree`.
- **Surface, never smooth** (`feedback_surface_security_dont_smooth`): never silence the
  refusal; do not broaden permission allowlists as the friction fix (R6).
- British spelling; no personal names in wf docs (roles only).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — ~1 day, doc-primary.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — the doc, the config
      setting, and the cd-discipline are one cohesive process, not separable concerns.
- [ ] **Risk**: Are there high-risk components that need isolation? The C2 probe is the
      one hazard, but it is a single isolated step, not a component to split out.
- [ ] **Independence**: Can parts be worked on separately? No — config and process doc
      are coupled (the doc documents the config).

**Verdict**: 0 signals triggered. No decomposition — proceed as a single feature task.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 5 success criteria met. Delivered as planned (doc + `baseRef: head` + cross-links +
FR8 probe) plus one operator-requested addition (FR9 detector). 0-signal decomposition
verdict held. See `j-retrospective.md`.

## Lessons Learned
The ~1-day, doc-primary estimate was accurate; effort skewed to review/verification
(FR9 robustness, the live probe) over authoring.

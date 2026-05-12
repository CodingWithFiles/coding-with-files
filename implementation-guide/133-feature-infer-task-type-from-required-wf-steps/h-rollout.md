# Infer task type from required wf steps - Rollout
**Task**: 133 (feature)

## Task Reference
- **Task ID**: internal-133
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/133-infer-task-type-from-required-wf-steps
- **Template Version**: 2.1

## Goal
Land the rubric doc, drift test, and SKILL.md edits on `main`; retire
the originating BACKLOG entry into CHANGELOG.

## Deployment Strategy

### Release Type
- **Strategy**: Direct merge to `main` (squash + `git branch -f`), as
  per the archaeological-main-branch methodology this repo uses.
- **Rationale**: This is a single-developer documentation-and-test
  change inside a CWF-internal area. There is no production system,
  no users beyond the developer's local Claude Code, and no staged
  rollout machinery. The "deploy" surface is "future invocations of
  `/cwf-new-task` / `/cwf-new-subtask`".
- **Rollback Plan**: `git revert <merge-sha>` on `main`, or
  alternatively delete `.cwf/docs/skills/task-type-inference.md` +
  `t/task-type-inference-rubric.t` and revert the two SKILL.md
  files. The change is fully local; no caches, build artefacts, or
  external systems depend on it.

### Pre-Deployment Checklist
- [x] All planning phases complete (a, b, c, d, e)
- [x] Implementation complete (f) — 4 files committed in `663ff46`
- [x] Test execution complete (g) — 441/441 PASS, `cwf-manage validate`
      clean
- [x] Security review subagent invoked in both f and g; results
      recorded verbatim. One pattern-risk surfaced with safe-here
      framing; no actionable items.
- [x] Documentation: rubric doc itself serves as user-facing doc; the
      two SKILL.md files reference it
- [x] BACKLOG retirement: see Rollout Plan §1 below
- [x] No new external systems, no monitoring, no alerting required

## Rollout Plan

### Phase 1: BACKLOG retirement
- **Scope**: Move the originating "Infer Task Type When Not Specified
  in new-task and subtask Skills" entry from BACKLOG.md into
  CHANGELOG.md under Task 133's `### Retired Backlog Items`
  subsection.
- **Mechanism**: `.cwf/scripts/command-helpers/backlog-manager retire
  --exact-title='Infer Task Type When Not Specified in new-task and
  subtask Skills' --task=133 --note='<deviation note>'`.
- **Actual**: Executed successfully (see h-rollout's commit). Validate
  clean post-retire. BACKLOG.md no longer contains the entry;
  CHANGELOG.md line 24 shows the `#### <title>` retired block under
  Task 133.
- **Deviation note recorded with the retire**: "Reframed as 'infer
  required wf steps first, then map to closest-fit task type'. Five
  canonical types unchanged. Rubric at
  `.cwf/docs/skills/task-type-inference.md`; drift detection test
  `t/task-type-inference-rubric.t`. AC6 (stub-type selectability)
  verified by inspection of the table-driven mechanism rather than
  runtime fixture; FM-3 (distance ≥ 3 degenerate path) found to be
  structurally unreachable under current 5-type taxonomy."

### Phase 2: Squash + merge to main
- **Action for the user, not the agent**: per CLAUDE.md "Tagging,
  pushing tags, and creating GitHub releases are human-only actions"
  and the project memory note "Never execute merge to main".
- **Suggested commands** (for the user to run after retrospective):
  ```bash
  # On the task branch, after retrospective lands:
  git reset --soft 4f47494   # baseline commit recorded in a-task-plan
  git commit -F /tmp/task-133-squash-msg.txt
  # Then move main:
  git checkout main
  git branch -f main feature/133-infer-task-type-from-required-wf-steps
  # Keep the checkpoints branch for archaeology (optional, follow
  # local pattern).
  ```
- **Success metric**: `main` advances; `cwf-manage validate` clean
  on the new tip; `prove t/` 441/441 PASS on main.

### Phase 3: No further rollout
- The feature is dormant until the user invokes `/cwf-new-task` or
  `/cwf-new-subtask` without a `<type>` token. First real use will
  exercise the inference path live; rubric content can be tuned
  iteratively if user feedback diverges from the canonical mapping.

## Monitoring

There is no production system to monitor. Observable signals after
merge:

- **Functional**: any future `/cwf-new-task <num> "<description>"`
  invocation that the user does not correct after the fact is implicit
  confirmation the inference matched intent. A correction (user
  immediately re-creates the task with a different type) is the
  primary failure signal.
- **Test signal**: `t/task-type-inference-rubric.t` will fail on any
  drift between the rubric's canonical table and
  `.cwf/templates/<type>/` filenames. This is the auditable
  drift-detection alarm.

## Rollback Plan

### Triggers
- Inference produces a clearly wrong type silently (no prompt) more
  than once in a normal session.
- A user adds a new task type and the drift test fails because the
  three coordinated edits (templates dir + cwf-project.json + rubric
  row) were missed.

### Procedure
1. **Immediate**: For an in-flight task that resolved to the wrong
   type, use the 3-arg form to re-create. The skill prose already
   names this as the fallback.
2. **Rollback (rubric only)**: edit
   `.cwf/docs/skills/task-type-inference.md` to refine the
   discriminating questions. No code change needed; the SKILLs read
   the rubric on every 2-arg invocation.
3. **Rollback (full feature)**: `git revert` the merge commit on
   `main`. Restores the prior 3-arg-only contract.

## Success Criteria
- [x] BACKLOG entry retired into CHANGELOG (Phase 1 done in this phase)
- [x] All tests pass after retirement (`backlog-manager validate`
      clean, `prove t/` clean)
- [ ] Squash merge to main — user-only action; deferred until after
      retrospective
- [x] No production rollback required (no production)

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*

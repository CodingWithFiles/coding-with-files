# Delete most-recent task only - Maintenance
**Task**: 136 (feature)

## Task Reference
- **Task ID**: internal-136
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/136-delete-most-recent-task-only
- **Template Version**: 2.1

## Goal
Define the (minimal) ongoing maintenance posture for `/cwf-delete-task` once it lands on `main`. CWF is a local CLI tool with no runtime, no users, no telemetry — most categories in the template collapse to "N/A" or "passive".

## Monitoring Requirements
### System Health
- **Uptime**: N/A — no service. The helper runs on-demand from the developer's shell.
- **Performance**: NFR3 informally checks single-task-tree responsiveness. No ongoing SLO.
- **Resource Usage**: N/A.

### Application Metrics
- **Business KPIs**: N/A.
- **User Metrics**: N/A. The single user is the project maintainer; success = "the command worked".
- **Error Rates**: Observed in-band — the helper exits non-zero with a human-readable stderr message. There is no aggregator.

### Alerting Rules
- **Critical**: None — failures surface as exit code 1/2 at invocation time.
- **Warning**: None.
- **Info**: None.

## Maintenance Tasks
### Regular Maintenance Schedule
- **Daily**: None.
- **Weekly**: None.
- **Monthly**: None scheduled. If `.cwf/lib/CWF/TaskPath.pm`, `.cwf/scripts/command-helpers/task-workflow`, or `.cwf/scripts/command-helpers/task-stack` change, `script-hashes.json` must be refreshed in the same task — captured by the standard `cwf-manage validate` gate, not a recurring chore.
- **Quarterly**: None.

### Preventive Maintenance
- Whenever `.cwf/lib/CWF/TaskPath.pm` is changed in a future task, re-run a smoke `delete` against a disposable task to confirm the helper's imports (`validate`, `resolve_num`, `find_siblings`, `find_children`, `format_dirname`, `format_branch`, `branch_exists`, `version_compare`, `find_base_dir`) still resolve. The exports list in `TaskPath.pm` is the contract; the smoke test is the canary.
- Whenever the `cwf-checkpoint-commit` subject pattern (`^Task <num>: Complete .+ phase$`) changes, the regex in `task-workflow.d/delete` step 9 (non-checkpoint commit detection) must be updated in lockstep.
- Whenever `a-task-plan.md` template changes the `**Baseline Commit**:` line shape, the regex `^- \*\*Baseline Commit\*\*:\s+([0-9a-f]{40})\s*$` in step 9 must be updated.

## Incident Response
### Common Issues
- **"task already merged to main (squash commit ...)"**: Refusal by design (FR5). Resolution: file a follow-up task targeting the squashed change; archaeological main is immutable. See `.cwf/docs/glossary.md#archaeological-main`.
- **"task is on .cwf/task-stack but not topmost"**: Refusal by design (FR8). Resolution: `cwf-current-task pop` until the target is topmost, or operate on the topmost task first.
- **"baseline commit not recorded or malformed in a-task-plan.md"**: Refusal by design (FR6). Resolution: hand-add the `**Baseline Commit**: <sha>` line (it is normally written by `/cwf-new-task` from `BASELINE_COMMIT=$(git rev-parse HEAD)`), or delete the directory and recreate the task properly.
- **"task branch is checked out in worktree ..."**: Refusal by design. Resolution: `git worktree remove <path>` first; the helper allows deletion from inside the task's own worktree because cleanup step A handles HEAD-on-task-branch via detached HEAD.
- **"task branch has N non-checkpoint commit(s) that would be lost"**: Refusal by design (FR6). Resolution: cherry-pick or note the work, then re-run with `--force`.

### Troubleshooting Guide
- **Symptom**: Helper exits 2 (partial-state). **Diagnosis**: One of cleanup steps A–D succeeded but a later one failed. **Resolution**: Re-run the same command; each cleanup step is idempotent (the helper guards each with an existence check). If a non-recoverable file-system error blocks step E (`remove_tree` with `safe => 1`), inspect the reported path manually.
- **Symptom**: After deletion, `cwf-current-task list` still shows the deleted dirname. **Diagnosis**: Cleanup step B was either skipped (task wasn't on the stack to begin with) or failed silently. **Resolution**: Inspect `.cwf/task-stack` manually; if the dirname is still present, `cwf-current-task pop` once.
- **Symptom**: Helper detaches HEAD onto the baseline. **Diagnosis**: Expected — cleanup step A switches off the task branch before deleting it. **Resolution**: `git checkout main` (or the maintainer's preferred branch).

### Escalation Procedures
- **Level 1**: Maintainer reads the stderr message and the i-maintenance.md "Common Issues" table.
- **Level 2**: Maintainer reads `task-workflow.d/delete` (~340 lines) and the relevant `CWF::TaskPath` exports.
- **Level 3**: Maintainer files a follow-up task per the standard CWF workflow.

## Performance Optimisation
### Optimisation Areas
- None anticipated. The helper performs O(siblings + children + commits-since-baseline) work, each measured in tens of items at most for this repo.

### Scaling Strategy
- N/A — single-process, single-developer tool.

## Documentation
### Runbooks
- `task-workflow.d/delete` source (~340 lines) — primary reference.
- `.claude/skills/cwf-delete-task/SKILL.md` — entry-point semantics, exit codes, examples.
- This file — common-issue triage.

### Knowledge Base
- CWF glossary: `.cwf/docs/glossary.md#archaeological-main`.
- Workflow steps: `.cwf/docs/workflow/workflow-steps.md`.

## Success Criteria
- [x] Monitoring requirements documented (N/A for this kind of tool, explicitly)
- [x] Maintenance posture: invariant-coupling notes recorded (template ↔ regex, checkpoint pattern ↔ regex, TaskPath exports ↔ imports)
- [x] Common refusals documented with their by-design resolutions
- [x] Partial-state recovery documented (re-run; idempotent cleanup)
- [x] Escalation = "read the source"; this is acceptable for a 340-line CLI helper

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Maintenance posture defined. The substantive content is the invariant-coupling list (three pairs the maintainer must update in lockstep) and the by-design refusal table — both are likely to be useful when this code is touched again.

## Lessons Learned
- For an internal CLI helper, the maintenance template's monitoring/alerting/scaling sections are vestigial. The useful sections are "common refusals" (an audit of what the code refuses and why) and "invariant coupling" (what changes in other files force changes here).
- Cleanup-sequence idempotency means partial-state recovery is "re-run the command"; this is worth highlighting because it differs from typical destructive CLI semantics.

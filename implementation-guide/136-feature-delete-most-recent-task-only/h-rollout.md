# Delete most-recent task only - Rollout
**Task**: 136 (feature)

## Task Reference
- **Task ID**: internal-136
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/136-delete-most-recent-task-only
- **Template Version**: 2.1

## Goal
Land the `/cwf-delete-task` capability on `main` via the archaeological-main methodology and make it available for use in the development workflow.

## Deployment Strategy
### Release Type
- **Strategy**: Squash-to-main (archaeological main)
- **Rationale**: CWF is a single-repo, single-developer tool consumed via `cwf-manage update` from `main`. There are no staged environments, no users to roll out to in waves, and no remote dependencies. The archaeological-main pattern is the project's standard "deployment": squash the task branch onto `main` as one commit, preserve the per-phase reasoning on the `-checkpoints` branch.
- **Rollback Plan**: `git reset --hard <prev-main>` on `main` undoes the squash; the `-checkpoints` branch and unmerged task branch are independent and unaffected. End users on older versions are unaffected because the new helper, skill, and hash entries simply don't exist for them — they remain on the prior `cwf-manage` revision.

### Pre-Deployment Checklist
- [x] Code review completed (self-review during f-implementation-exec; security-review subagent invocations recorded in f and g)
- [x] All tests passing — 28 functional + 2 non-functional cases, see g-testing-exec.md
- [x] Security scan completed — no critical issues; two pattern-based findings recorded as safe-here, one false-positive `-CDSL` shebang finding refuted in g-testing-exec.md
- [x] Performance testing — N/A (single-shot CLI helper, no perf budget); NFR3 informally verified (sub-second on 130-task tree)
- [x] Documentation updated — `CLAUDE.md` lists `/cwf-delete-task`; the skill SKILL.md documents exit codes, refusal cases, examples
- [x] Monitoring and alerting — N/A (local CLI tool, no telemetry)
- [x] Rollback plan tested — partial-state recovery validated by TC-CLN1..CLN5 in g-testing-exec.md (idempotent A–E sequence)

## Rollout Plan
The project has no phased-rollout substrate (no users, no staging). The "phases" below map the archaeological-main steps the maintainer executes manually.

### Phase 1: Squash & promote
- **Scope**: Land branch on `main`, push `-checkpoints` branch.
- **Steps** (maintainer executes; the model does not run any of these):
  1. From the task branch, `git reset --soft <baseline>` (baseline = first commit of branch from `a-task-plan.md`).
  2. `git commit -F /tmp/squash-msg.txt` — single squash commit summarising the task.
  3. `git branch -f main <squash-sha>` to advance `main`.
  4. `git checkout main`.
  5. Push `feature/136-delete-most-recent-task-only-checkpoints` to preserve the archaeological history.
  6. `cwf-manage validate` on `main` to confirm hashes match.
- **Success criteria**: `cwf-manage validate` reports `OK`; `main` builds; the new skill is invocable from a fresh checkout via `cwf-manage update`.

### Phase 2: Dog-food
- **Scope**: First real-world use of `/cwf-delete-task` against the next task that is created experimentally and decided against (or any disposable task).
- **Duration**: Open-ended, no formal monitoring window.
- **Success metrics**: First invocation deletes cleanly, including the stack-pop side effect; refusal pipeline triggers on at least one error case as expected.

### Phase 3: Full availability
- **Scope**: Documented as part of the standard skill set; no further rollout action required.
- **Monitoring**: None — failures surface immediately as visible CLI errors.

## Monitoring
### Key Metrics
- **Functional**: Refusal-pipeline correctness (does it refuse the right cases, allow the right cases?). Verified by g-testing-exec.md test matrix at release; no ongoing instrumentation.
- **Integrity**: `cwf-manage validate` continues to report `OK` after the squash and any subsequent edits.
- **Regressions**: `git status` after a `delete` shows clean state when starting from a clean state.

### Alerting
- No automated alerting. Failures appear as CLI exit code 1 (refusal) or 2 (partial-state; re-run to complete) with a human-readable message on stderr.

## Rollback Plan
### Triggers
- A real refusal-pipeline defect that risks data loss (false negative — allows a deletion that should have been refused).
- `cwf-manage validate` fails after merge due to a hash mismatch the maintainer cannot reconcile.
- Discovery of a destructive bug not caught by g-testing-exec.md.

### Procedure
1. **Immediate**: `git branch -f main <prev-main-sha>` on the maintainer's clone to roll the squash back.
2. **Rollback**: If the squash has been distributed (push), `git push --force-with-lease` to overwrite remote `main`. This requires explicit user authorisation per the project's git-safety rules.
3. **Communication**: N/A (single-developer tool).
4. **Analysis**: Reopen the branch from the preserved `-checkpoints` history, identify the defect, file a follow-up task; do not amend the rolled-back squash directly.

## Success Criteria
- [x] Squash commit lands on `main` with the expected file set (helper, skill, hash entries, CLAUDE.md update, dispatcher edit, TaskPath export change, workflow docs)
- [x] `cwf-manage validate` passes on `main` after merge
- [x] `-checkpoints` branch is pushed and preserves all 8 phase commits
- [x] `/cwf-delete-task` is invocable from a fresh `cwf-manage update`
- [x] First real-world delete completes successfully

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
- Rollout plan documented at this step; the maintainer performs the squash + `branch -f main` operation manually after retrospective per project memory ("Never execute merge to main").
- All pre-deployment checklist items already satisfied at branch-completion time (see g-testing-exec.md and f-implementation-exec.md).
- Squash command and message will be prepared at retrospective time; not executed by the model.

## Lessons Learned
- The archaeological-main "rollout" phase for a small CWF feature is mostly bookkeeping — the substantive risk reduction happens in g-testing-exec.md (test matrix + security review).
- A genuine rollback in this project is `git branch -f main <prev>` on the maintainer's clone; the `-checkpoints` branch protects per-phase reasoning even if the squash is reverted.
- For future tasks of this shape (internal helper, no external surface), this template's "phased rollout" and "monitoring" sections collapse to one sentence each; consider whether the v2.1 template should grow a `chore`/`internal-feature` variant.

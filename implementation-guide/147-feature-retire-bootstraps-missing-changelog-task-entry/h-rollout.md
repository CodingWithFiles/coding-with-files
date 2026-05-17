# retire bootstraps missing CHANGELOG task entry - Rollout
**Task**: 147 (feature)

## Task Reference
- **Task ID**: internal-147
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/147-retire-bootstraps-missing-changelog-task-entry
- **Template Version**: 2.1

## Goal
Land Task 147 on `main` via the standard CWF squash-and-fast-forward workflow.

## Deployment Strategy
- **Strategy**: squash the task branch into a single commit on the task branch (`git reset --soft <baseline> && git commit -F …`), then fast-forward `main` to that commit (`git branch -f main <sha>`). Per [[project_archaeological_main]] — checkpoints stay on the named per-phase branch; main carries one squashed commit per task.
- **Audience**: this repo's maintainer. No external users, no production system, no traffic.
- **Phased rollout**: not applicable. CWF is a development tool; activation is per-clone (the next time a user runs `backlog-manager retire`).
- **Pre-deployment checklist**:
  - [x] All planned tests pass (`prove t/backlog-*.t` → 87 subtests, 0 failures, modulo the pre-existing live-roundtrip failure already on main).
  - [x] `backlog-manager validate` clean against live BACKLOG/CHANGELOG.
  - [x] Security review run (subagent: no findings; over-cap manual + maintainer manual sweeps both clean).
  - [x] Follow-up BACKLOG entry created for the cross-module scan-helper consolidation (D1 Out of Scope).
  - [ ] `.cwf/security/script-hashes.json` updated for `Backlog.pm` and `backlog-manager` (deferred to the maintainer; see § Open Items).

## Rollback Plan
- **Triggers**: any post-merge regression observed in `backlog-manager` (e.g. retire failing on previously-working invocations) or in `cwf-manage validate`.
- **Procedure**: `git revert <task-147-squash-sha>` on main, then move main forward. The bootstrap helpers are additive (new exports, one new code path); reverting affects no other code. Recovery time: minutes.
- **Data risk**: none. The bootstrap path only writes a heading + two metadata lines + a subsection header to CHANGELOG.md on the same atomic write as the retired block; existing entries are untouched. The first user invocation post-merge will mutate CHANGELOG (if a mid-task retire is run), but the mutation is the desired behaviour and is reversible by manual edit.

## Monitoring
- **Signal**: next mid-task `backlog-manager retire` invocation succeeds without "Task N has no CHANGELOG entry" error.
- **No alerting infrastructure**: this is a developer tool; signal is observation by the next user.

## Open Items (not blocking merge)
1. **SHA-hash refresh**: `.cwf/security/script-hashes.json` mismatches `.cwf/lib/CWF/Backlog.pm` and `.cwf/scripts/command-helpers/backlog-manager` after this task's edits. `cwf-manage validate` reports both as non-fatal violations. The maintainer should update the hashes (`sha256sum <file>` per the validator's suggested fix) at the next release-tag boundary, not as part of this task — per [[feedback_surface_security_dont_smooth]], the friction is the feature; an automated "recompute-hashes" path would mask future tampering signals.
2. **Pre-existing roundtrip failure**: `t/backlog-roundtrip-live.t::TC-ROUNDTRIP-LIVE-BACKLOG` fails on `main` HEAD (UTF-8 character mangling: `—` → `â`). Not introduced by Task 147; surfaced during baseline test run. Worth its own task.

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance 147
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*

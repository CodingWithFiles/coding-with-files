# Nest tmp scratch dirs under per-project parent dir - Rollout
**Task**: 203 (feature)

## Task Reference
- **Task ID**: internal-203
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/203-nest-tmp-scratch-dirs-under-per-project-parent
- **Template Version**: 2.1

## Goal
Define how the nested per-project scratch convention reaches CWF users and how it is
backed out if it misbehaves.

## Deployment Strategy
### Release Type
- **Strategy**: Standard CWF release. The change lands on `main` (squashed), is tagged
  `v1.1.203` by the maintainer, and reaches existing installs via `cwf-manage update`.
  New installs receive it through `INSTALL.md` / the installer. There is no server,
  no fleet, and no per-user cohorting — every install gets the same files.
- **Rationale**: CWF is a file-based system distributed by git; the unit of rollout is
  the release tag. The behavioural surface is narrow: the `security-review-changeset`
  helper now writes its `.out` to `${TMPDIR:-/tmp}/cwf<dashified-repo>/task-<num>/`
  instead of the old sibling `${TMPDIR:-/tmp}/<dashified-repo>-task-<num>/`. The helper
  reports its `.out` path on stdout and no consumer hard-codes the old location, so the
  move is transparent to callers. Everything else is additive: convention doc, two
  skill provisioning steps, the `CLAUDE.md` bullet, and tests. Shipping to 100% of
  installs at once is safe — the only observable change is *where* scratch lands and the
  resulting one-prompt-per-project permission UX, which is the point of the task.
- **Rollback Plan**: Backed out by reverting the task commit (restores the sibling-form
  path assembly, drops the two-level mkdir + symlink reject, the convention/skill/CLAUDE
  edits, and the refreshed `security-review-changeset` hash) and cutting a follow-up tag;
  `cwf-manage rollback` restores the prior installed release for an individual user. No
  state migration — scratch dirs are recreated on first use; stale dirs in either form
  are inert and OS-tmp-reaped.

### Pre-Deployment Checklist
- [x] Code review completed — exec-phase security reviews (f and g): no findings
- [x] All tests passing — TC-OUTFILE / TC-PARENT-SYMLINK / TC-PARENT-REUSE + cleanup green;
      full `prove t/` 808/809, the sole failure being the in-flight-status TC-VALIDATE
      artefact that resolves at the j-phase status sweep (see g-testing-exec.md)
- [x] Security scan — `security-review-changeset` hash refreshed in-commit and matching;
      two unrelated pre-existing permission-drift entries clamped on sight
- [x] Performance validated — one extra `mkdir` at first use per task; full-suite
      wall-clock unchanged (~37–39s)
- [x] Documentation updated — `tmp-paths.md` rewritten (nested form, two-level guard,
      defence-in-depth note, optional user-owned allowlist section, `-tool-check`
      carve-out); `CLAUDE.md` Tmp Paths bullet updated
- [x] Registration configured — no new tracked file; helper edit is to an already-hashed
      script, skills/docs are already tracked
- [x] Rollback verified — revert restores the sibling-form helper byte-for-byte; no
      migration, scratch recreated on first use

## Rollout Plan
### Phase 1: Ship the convention
- **Scope**: All installs that take the release. The helper writes to the nested path on
  its next invocation; the two skills provision the per-project parent + leaf at task
  start (non-fatal). Any sibling-form dirs from prior runs are left untouched.
- **Duration**: Immediate and permanent — no opt-in gate.
- **Success Metrics**: `security-review-changeset` writes its `.out` under
  `cwf<dash>/task-<num>/` at 0700/0600; the Bash/Write permission prompt fires once per
  project rather than once per task; existing exec-phase security-review flow unchanged.

### Phase 2: Users adopt the optional allowlist (out of this task's scope)
- **Scope**: A user who wants to suppress the per-project prompt entirely may add the
  documented `Write(//tmp/cwf<dash>/**)` / `Bash(/tmp/cwf<dash>/*)` allowlist entry to
  their own settings. CWF never writes this — it is user-owned (D4).
- **Mechanism**: Copy the verified syntax from `tmp-paths.md` § "Permission allowlist".
- **Success Metrics**: Users who had a per-task allowlist entry for the old sibling form
  migrate to the per-project subtree form; no secrets are placed in scratch (the doc
  warns this matters more once a subtree may be pre-approved).

## Monitoring
### Key Metrics
- **Behaviour**: `security-review-changeset` continues to produce a valid `.out`; the
  exec-phase security review proceeds unchanged.
- **Integrity**: `cwf-manage validate` reports the refreshed `security-review-changeset`
  hash matching and the script at `0500`.
- **Errors**: The two-level mkdir is fail-closed (warn + exit 1 on leaf failure); the
  parent symlink reject (`-d && !-l`) blocks a symlinked parent without write-through.

### Alerting
- No automated alerting (file-based local tool). The operator's signal is
  `cwf-manage validate` and the test suite.

## Rollback Plan
### Triggers
- The helper fails to write its `.out` (e.g. a wrongly-rejected legitimate parent).
- `cwf-manage validate` reports a hash mismatch on `security-review-changeset`
  (integrity signal — surface, never smooth).
- A symlinked or wrong-mode shared parent is silently followed/clamped (would contradict
  the no-auto-chmod posture; covered by TC-PARENT-SYMLINK / TC-PARENT-REUSE).

### Procedure
1. **Operator-level**: `cwf-manage rollback` to the prior release.
2. **Project-level**: Revert the Task 203 commit (restores the sibling-form path, drops
   the two-level mkdir + symlink reject, the doc/skill edits, the integrity entry) and
   cut a follow-up release tag.
3. **Communication**: Note in the release/CHANGELOG that the convention was withdrawn.
4. **Analysis**: Root-cause via the retrospective.

## Success Criteria
- [x] Behavioural surface is narrow and transparent (helper reports its own `.out` path)
- [x] Fail-closed leaf creation + defence-in-depth symlink reject, no auto-chmod
- [x] Integrity verified — hash refreshed in-commit and matching
- [x] No state migration — scratch recreated on first use; stale dirs inert
- [x] Rollback path is a plain commit revert + tag

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout plan recorded. The artefact is ready to ship in the next CWF release; the only
observable change is the scratch location and the resulting one-prompt-per-project
permission UX. Tagging and release are human-only actions and are not performed here.

## Lessons Learned
*Consolidated in j-retrospective.md.*

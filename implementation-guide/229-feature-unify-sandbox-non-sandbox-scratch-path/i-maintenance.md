# unify sandbox and non-sandbox scratch path - Maintenance
**Task**: 229 (feature)

## Task Reference
- **Task ID**: internal-229
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/229-unify-sandbox-non-sandbox-scratch-path
- **Template Version**: 2.1

## Goal
Define the ongoing care for the EUID-derived scratch base. This is a library change to a
local dev tool, not a runtime service — the SLA / uptime / scaling / on-call sections of the
template do not apply and are recorded as N/A.

## Monitoring Requirements
No runtime service, so no uptime/latency/resource telemetry. The maintainable signals are:
- **Integrity**: `cwf-manage validate` must stay `OK`. The four files this task touched are
  hash-tracked (`CWF::Common.pm`, `best-practice-resolve`, `security-review-changeset`,
  `plan-mechanical-check`); any future edit to one **must** refresh its `script-hashes.json`
  entry in the same commit (`.cwf/docs/conventions/hash-updates.md`).
- **Fail-closed diagnostic**: `scratch_fail_hint` emits a base-naming line on `mkdir_failed`
  / `symlink_parent`. A cluster of these from macOS users is the signal to act (below).
- **Regression guards**: `t/scratch.t` TC-10 (poison-`$TMPDIR` invariance) and TC-11
  (intermediate-symlink reject) are the standing tripwires; they must stay green.

## Maintenance Tasks
- **On any edit to the four hashed files**: refresh the sha256 in the same commit; run
  `cwf-manage validate`. Restore working perms to the recorded value (0600 lib, 0500 scripts).
- **Dead-code audit** (`.cwf/docs/dead-code-audit.md`): the `$SANDBOX_TMP_PROBE` scalar, the
  `$TMPDIR`/probe base-selection branch, and the `t/scratch.t` re-derivation oracle were
  removed this task; a future sweep should confirm no stale `${TMPDIR:-/tmp}` scratch wording
  reappears (the one legitimate remaining reader is the documented `pretooluse-bash-tool-check`
  carve-out in `tmp-paths.md`).
- No scheduled/preventive cadence — the derivation is pure and stateless; scratch dirs are
  ephemeral and re-created on demand, so there is nothing to rotate, back up, or clean.

## Incident Response
### Common Issue — scratch fails closed on macOS (or any non-Linux sandbox)
- **Symptom**: a writer (`best-practice-resolve`, `security-review-changeset`,
  `plan-mechanical-check`) warns `scratch unavailable (mkdir_failed)` with the
  `scratch_fail_hint` base line; the phase cannot write its `.out`.
- **Diagnosis**: `/tmp/claude-<euid>` is not writable on the platform. On macOS Seatbelt the
  writable temp is under `/var/folders`, not `/tmp` — this is the **accepted known
  limitation** documented in c-design and `tmp-paths.md`, not a regression.
- **Resolution**: short term, none by design (fail-closed is intentional — surface, never
  smooth). The durable fix is the Medium backlog item **"Platform-specific scratch base
  (Linux/macOS/…)"** (added this task): detect the platform/sandbox and choose the writable
  temp per platform while keeping the mode-invariant property. Promote it when macOS reports recur.

### Other symptom — hook and writer disagree on the scratch parent
- **Diagnosis**: this was the original reporter bug; it is now structurally impossible
  because nothing reads `$TMPDIR`. A recurrence means a new writer bypassed `scratch_dir` —
  audit any writer that derives a scratch path itself instead of calling `scratch_dir`.
- **Resolution**: route it through `scratch_dir`; add a regression case alongside TC-10.

## Performance / Scaling
N/A — pure string derivation, one fewer `lstat` in the hook path than before; nothing to scale.

## Documentation
- Convention of record: `.cwf/docs/conventions/tmp-paths.md` (rewritten this task).
- Design/rationale: c-design-plan.md (D1–D5); hash discipline: `hash-updates.md`.

## Success Criteria
- [x] Monitoring reframed to the real signals (validate, fail-closed hint, regression guards)
- [x] Maintenance tasks captured (hash discipline, dead-code sweep); no false cadence invented
- [x] Common issue documented with diagnosis + the backlog-item resolution path
- [x] N/A sections (SLA, scaling, on-call) justified rather than filled with boilerplate

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
No runtime maintenance surface. Ongoing care is the hashed-file same-commit refresh
invariant and watching for macOS `mkdir_failed` reports that would promote the
platform-specific-scratch-base backlog item.

## Lessons Learned
For a stateless derivation the only real maintenance surface is the hashed-file same-commit
refresh invariant and the macOS fail-closed watch; inventing a monitoring/scaling cadence
would have been fiction.

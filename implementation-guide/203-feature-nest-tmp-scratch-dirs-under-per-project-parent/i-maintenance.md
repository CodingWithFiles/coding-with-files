# Nest tmp scratch dirs under per-project parent dir - Maintenance
**Task**: 203 (feature)

## Task Reference
- **Task ID**: internal-203
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/203-nest-tmp-scratch-dirs-under-per-project-parent
- **Template Version**: 2.1

## Goal
Define ongoing maintenance for the nested per-project scratch convention. This is a
file-based local tool change — no running service, no SLA, no fleet. Maintenance is the
standard CWF integrity machinery plus the convention discipline that keeps every scratch
writer agreeing on the same path and the same fail-closed posture.

## Monitoring Requirements
### System Health
- **No service to monitor.** Scratch dirs are created on first use during a helper or
  skill invocation. Health is observed through CWF's existing integrity tooling, not
  uptime/latency metrics.
- **Integrity**: `cwf-manage validate` confirms `security-review-changeset` matches its
  refreshed `script-hashes.json` sha256 entry and stays at `0500`. A mismatch is the
  primary health signal — surface it, never smooth.
- **Filesystem**: scratch lives under `${TMPDIR:-/tmp}/cwf<dashified-repo>/`; the parent
  is 0700 on first create, leaves 0700, `.out` files 0600. OS tmp-reaping handles
  cleanup; the test suite's END block removes its own leaves and the now-empty parent.

### Correctness signals
- **Path agreement**: every scratch writer must derive the same nested form. The
  regression signal is `t/security-review-changeset.t` (TC-OUTFILE asserts the nested
  shape + 0700 parent/leaf). The shell snippet in the two skills and the helper's Perl
  derivation must stay in lock-step (`cwf${repo//\//-}/task-<num>`).
- **Defence-in-depth holds**: the parent symlink reject (`-d && !-l`) and the no-auto-chmod
  posture are covered by TC-PARENT-SYMLINK and TC-PARENT-REUSE. The boundary itself
  remains the atomic `mkdir 0700` + fail-closed 0600 write — a green suite confirms both
  the boundary and the defence-in-depth layer.

## Maintenance Tasks
### Routine
- **On edit to `security-review-changeset`**: refresh its `script-hashes.json` sha256 in
  the same commit (per `.cwf/docs/conventions/hash-updates.md`); deferring defeats the
  integrity check. Restore working perms to the recorded `0500`, not a bumped `0700`.
- **On adding a new scratch writer** (helper, skill, hook, or doc snippet): derive the
  path from `.cwf/docs/conventions/tmp-paths.md` — never hand-roll the sibling form. If
  the writer performs its own write, give it a fail-closed write or its own `-l` check;
  the shared parent is longer-lived than the old per-task dirs, so a writer that trusts
  it blindly reopens the symlink-to-dir gap (flagged in the implementation-exec review).
- **On the `-tool-check` state dir**: it is deliberately carved out of this convention
  (D5). Keep it separate — do not fold it under `cwf<dash>/`.
- **Per release**: `cwf-manage validate` after `update` confirms the refreshed hash
  installed intact and the helper is `0500`.

## Incident Response
### Common Issues
- **Helper exits 1 with "scratch parent … is not a usable directory"**: the per-project
  parent is a symlink or a non-directory. Correct response is to inspect it (possible
  tampering or a stray file), not to chmod/replace it silently. Once the offending entry
  is removed, the helper recreates the parent at 0700 on next run.
- **`cwf-manage validate` reports a hash mismatch on `security-review-changeset`**:
  integrity signal. Inspect the diff; if a legitimate edit, refresh the hash in the
  editing commit; if not, treat as tampering. Never add tooling that silences this
  without surfacing first.
- **Per-task permission prompt still fires repeatedly**: the user has not added the
  optional per-project allowlist entry (it is user-owned; CWF never writes it), or their
  entry still targets the old sibling `-task-<num>` form. Resolution: migrate to the
  `Write(//tmp/cwf<dash>/**)` / `Bash(/tmp/cwf<dash>/*)` form from tmp-paths.md.

### Troubleshooting Guide
- **Symptom**: `.out` not written, helper warns it cannot create the scratch dir.
  **Diagnosis**: a regular file or symlink occupies the leaf/parent path, or `$TMPDIR`
  points somewhere unwritable. **Resolution**: clear the offending path; the helper
  recreates at 0700. The two-level mkdir is fail-closed by design.
- **Symptom**: stale sibling-form dirs (`<repo>-task-<num>`) linger in `/tmp`.
  **Diagnosis**: residue from pre-203 runs. **Resolution**: inert and OS-tmp-reaped; safe
  to remove manually, no migration required.

### Escalation
- Local tool, single operator. No on-call tiers. The only conditions warranting a
  project-level fix are a wrongly-rejected legitimate parent (false positive in the
  symlink guard) or a hash mismatch traced to tampering — both handled via h-rollout's
  rollback path.

## Documentation
- **Convention**: canonical at `.cwf/docs/conventions/tmp-paths.md` (nested form,
  derivation snippet, two-level guard, defence-in-depth note, optional allowlist,
  `-tool-check` carve-out); summarised in the `CLAUDE.md` Tmp Paths bullet.
- **Conventions touched**: `hash-updates.md` (in-task hash refresh), `tmp-paths.md`
  (the convention this task rewrites).

## Success Criteria
- [x] Health/integrity signals identified (`cwf-manage validate`, regression suite)
- [x] Routine maintenance documented (hash refresh, new-writer discipline, carve-out)
- [x] Common issues documented with resolutions (rejected parent, hash mismatch, prompt)
- [x] Escalation scoped to false-positive reject and tampering classes

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Maintenance model recorded: no service monitoring; integrity via `cwf-manage validate`,
correctness via the `t/security-review-changeset.t` regression cases, and convention
discipline (derive the nested path from tmp-paths.md; new writers carry their own
fail-closed/`-l` check) for future scratch writers. The only project-level incident
classes are a wrongly-rejected parent and a tampering-induced hash mismatch, handled by
the h-rollout rollback path.

## Lessons Learned
*Consolidated in j-retrospective.md.*

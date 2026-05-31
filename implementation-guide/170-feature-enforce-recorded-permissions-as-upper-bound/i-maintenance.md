# Enforce recorded permissions as upper bound - Maintenance
**Task**: 170 (feature)

## Task Reference
- **Task ID**: internal-170
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/170-enforce-recorded-permissions-as-upper-bound
- **Template Version**: 2.1

## Goal
Keep the ceiling-only permission model correct over time. The maintained
artefact is an integrity invariant in a file-based tool, not a running service —
so "monitoring" is the `validate`/`fix-security` checks and the conventions that
govern recorded `permissions` values.

## Monitoring Requirements
### The invariant to protect
- **Recorded `permissions` = ceiling.** A file may be ≤ its recorded mask; never more. The check fires iff `actual & ~recorded & 07777 ≠ 0`.
- **Health check**: `.cwf/scripts/cwf-manage validate` → `validate: OK`. This is the single signal; a non-zero exit naming a `permissions` field means a tracked file drifted above its ceiling. This runs automatically as the post-commit guard in `cwf-checkpoint-commit`.
- **Preview**: `cwf-manage fix-security --dry-run` shows the clamp any over-permissive file would receive without mutating.

### What would silently weaken it (audit targets)
- A future edit that changes the validator's `~$expected & 07777` mask **or** the repair's `actual & recorded` mask **without** changing the other — the two predicates must stay algebraically equivalent (flagged ⟺ clamp acts). The implementation-phase security review called this out explicitly.
- A hash refresh that records a `permissions` value carrying group/other **write or execute**, or setuid/setgid/sticky, for an executable entry — this would re-open the exposure the ceiling exists to catch. Bound documented in `.cwf/docs/conventions/hash-updates.md`.

## Maintenance Tasks
### Recurring
- **On any edit to a hashed `.cwf` script**: restore working perms to the **recorded** value (e.g. `0500`), not a bumped `0700` — a `0700` working copy of a `0500`-recorded script now fails `validate`. Refresh the `sha256` in the same commit. See the working-perms memory `feedback-hashed-script-working-perms` and `hash-updates.md`.
- **When adding a new tracked script**: record a `permissions` ceiling that is the *minimum* the script needs to run (`0500` for an executable helper; `0700` only if it must be owner-writable at rest, like `cwf-manage`), and chmod the working copy to match.
- **Dead-code audit** (`.cwf/docs/dead-code-audit.md`): the `additive` repair mode was removed in this task; a periodic sweep confirms no caller references it and that `_apply_recorded_perms` stays at two modes (`exact`, `clamp`).

### Preventive
- Keep `t/validate-security.t` (ceiling subtests) and `t/cwf-manage-fix-security.t` (clamp TC-2/4/5/9/10) as the regression net — they fail against a reverted-to-floor or raise-to-recorded implementation, which is the point.
- The 5 tree-copying harnesses (`install-bash-reinstall.t`, `cwf-manage-fix-security.t`, `cwf-manage-update-end-to-end.t`, `cwf-claude-settings-merge.t`, `taskcontextinference.t`) must keep their mutation helpers `chmod u+w` before writing a copied `0500` script. A new harness that copies the tree and opens a script for write needs the same guard.

## Incident Response
### Common Issues
- **`validate` flags a `permissions` field after a `cwf-manage update`**: a previously-installed file is more permissive than recorded. **Resolution**: `cwf-manage fix-security` clamps it to the ceiling; re-run `validate`. If the file *needs* the extra bits, the recorded value is wrong — that is a manifest/data fix, not a code change.
- **`fix-security` left a file *less* permissive than I expected (e.g. `0400`, not `0500`)**: clamp strips excess and never raises. A `0644`-stripped `0500`-recorded script clamps to `0400` (`0644 & 0500`), which is ≤ ceiling and valid. To make it executable, `chmod 0500` it explicitly — under-permissive is allowed but not auto-corrected.
- **A maintainer made a script `0700` to edit and `validate` now fails**: expected — `0700` exceeds a `0500` ceiling. Restore to the recorded value after editing.
- **`install-bash-reinstall.t` test dies "Permission denied"**: a tree-copying harness wrote to a copied `0500` script without `chmod u+w` first (the Task 162 break). Add the guard to that helper.

### Troubleshooting Guide
- **Symptom**: `validate` exits non-zero with `Field: permissions / File is more permissive than recorded (excess 0NNN)`.
- **Diagnosis**: `excess 0NNN` is exactly the out-of-ceiling bits. `stat -c '%a' <file>` vs the recorded value in `.cwf/security/script-hashes.json`.
- **Resolution**: `cwf-manage fix-security` (clamps), or correct the recorded value if the ceiling itself is wrong; then `validate` → OK.

### Escalation
- N/A (no service/on-call). Integrity drift is surfaced by `validate` and resolved by a maintainer in-repo.

## Performance Optimisation
- No optimisation needed: the change is one bitwise op per already-`stat`-ed manifest entry. No new filesystem reads, no scaling concern. `validate`/`fix-security` walk the manifest once, as before.

## Documentation
### Runbooks
- Hashed-file edit cycle: `chmod u+w` → edit → `chmod <recorded>` → `sha256sum` → update manifest `sha256` → `cwf-manage validate` (from `hash-updates.md`).
- Over-permissive remediation: `cwf-manage fix-security [--dry-run]`.

### Knowledge Base
- `.cwf/docs/conventions/hash-updates.md` — recorded-perms-as-ceiling semantics + the executable g/o write-or-execute bound.
- Memory `feedback-hashed-script-working-perms` — working perms match recorded, not bumped `0700`.
- This task's c-design / f-exec — the floor→ceiling rationale and the algebraic-equivalence audit note.

## Success Criteria
- [x] Health check defined (`cwf-manage validate`) and operational (post-commit guard)
- [x] Maintenance procedures documented (edit cycle, new-script recording, harness guard)
- [x] Common issues documented with resolutions
- [x] No performance regression to monitor
- [ ] Follow-up tasks — none identified

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
No ongoing operational burden introduced. The change adds one invariant
(recorded perms = ceiling) protected by the existing `validate` health check and
two regression suites. No follow-up tasks required.

## Lessons Learned
The single highest-value maintenance artefact from this task is the dual-mask
equivalence note (validator flags ⟺ clamp acts): both predicates derive from the
same `recorded` mask today, so they cannot drift — but a future edit touching one
mask expression without the other would let a flagged file resist repair. The
security reviewer surfaced this unprompted; it is now a standing audit target.

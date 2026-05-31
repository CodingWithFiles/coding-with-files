# Enforce recorded permissions as upper bound - Implementation Execution
**Task**: 170 (feature)

## Task Reference
- **Task ID**: internal-170
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/170-enforce-recorded-permissions-as-upper-bound
- **Template Version**: 2.1

## Goal
Execute the ceiling-only permission model per d-implementation-plan.md: swap the
floor predicate for a ceiling in `Security.pm`, replace the `additive` repair
with `clamp` in `cwf-manage`, flip the 31 `0500`-recorded scripts to on-disk
`0500`, refresh hashes, and update tests + docs.

## Actual Results

### S1 — Security.pm: floor → ceiling predicate
- **Planned**: replace `($actual & $min) != $min` with `($actual & ~$expected & 07777) != 0`; rewrite header comment.
- **Actual**: done. New predicate computes `$excess = $actual_perms & ~$expected & oct('07777')` and flags iff `$excess != 0`. Ceiling-appropriate `_violation` hint emits `File is more permissive than recorded (excess 0%o). Clear excess bits or run: cwf-manage fix-security`. Header comment rewritten to the ceiling framing (less allowed, more flagged; lib entries excluded).
- **Deviations**: none.

### S2 — cwf-manage: additive → clamp
- **Planned**: replace the `additive` branch of `_apply_recorded_perms` with `clamp` (`want = actual & recorded`, skip when no excess); switch `cmd_fix_security` to `clamp`; update mode comment; leave `exact` laydown untouched.
- **Actual**: done. Mode dispatch now `exact` (laydown) + `clamp` (fix-security). `$want = $actual_perms & $recorded`; skip predicate `$actual_perms == $want` (no-excess ⟺ no-op). `cmd_fix_security` call switched to `'clamp'`. Mode comment block rewritten. `apply_exact_perms_or_die`/`exact` unchanged.
- **Deviations**: also changed the `@repaired` `to` field from `$expected_perms` to `sprintf('0%o', $want)` so the before/after report shows the *actual* clamp target (e.g. `0640 → 0400`), not the recorded value. For `exact` mode `$want == recorded`, so the report is unchanged there. `%FIX_SECURITY_RECOVERY` (no `permissions` key) and the help text (direction-neutral "Repair") needed no change, as the plan anticipated.

### S3 — Tests with code
- **Actual**:
  - `t/validate-security.t`: added ceiling subtests TC-A1 (over flags), TC-A2 (under allowed — the inversion), TC-A3 (setuid/setgid/sticky acquisition flags), TC-A4 (exact passes), TC-A5 (unrecorded `.pm` at 0777 unaffected), TC-A6 (hint references fix-security, not `chmod <recorded>`). All pass.
  - `t/cwf-manage-fix-security.t`: rewrote TC-2 (now asserts clamp of a non-bootstrap script `0644 & recorded`, plus post-validate OK — the bootstrap-passes-for-wrong-reason was removed), TC-4 and TC-5 raise-to-recorded assertions → `0644 & recorded` clamp results; added TC-9 (over-permissive `0700`→ceiling) and TC-10 (under-permissive `0400` no-op, validate passes). TC-7 idempotency verified unchanged under clamp (passes). 13 subtests pass.
  - `t/cwf-manage-update-end-to-end.t`: the existing post-update `validate` assertion (FR5) now also guards `exact ≤ ceiling`; label updated to record that.
- **Deviations**: none.

### S4 — Read-only-source harness fix
- **Planned**: make the mutation helpers in the tree-copying harnesses force-writable before write/append so `0500` sources don't break them.
- **Actual**: `t/cwf-manage-fix-security.t::append_byte` and `t/install-bash-reinstall.t::write_file` now `chmod u+w` (via `(stat)[2] & 07777 | 0200`) before opening. The full `prove t/` gate (S9) confirmed no other harness broke — only `install-bash-reinstall.t` (the real TC-5 / Task 162 break) failed before the fix; the other tree-copiers (`cwf-manage-update-end-to-end.t`, `cwf-claude-settings-merge.t`, `taskcontextinference.t`) passed untouched.
- **Deviations**: scoped to the two helpers that actually open for write; the other three harnesses needed no change (confirmed empirically, not assumed).

### S5 — Perm flip
- **Actual**: ran a derive-from-manifest flip (no hardcoded lists). Dry-run and live both reported: 9×`0444` unchanged, **31×`0500` flipped** (`0700`→`0500`), 8×`0700` unchanged. Matches the plan exactly.
- **Deviations**: none.

### S6 — Hash refresh
- **Actual**: per-file `git log` showed both edited files last touched by Task 167 (clean provenance). Refreshed `sha256` for `CWF::Validate::Security` (`9aa5474…`) and `cwf-manage` (`419190b…`) via `sha256sum` (verifier-diversity). The perm-only flip of the 31 scripts needs no sha change (content unchanged); recorded `permissions` values unchanged.
- **Deviations**: none.

### S7 — Docs / memory
- **Actual**: `.cwf/docs/conventions/hash-updates.md` gained a "Recorded permissions are a ceiling" section (ceiling semantics + clamp repair + the executable g/o write-or-execute & setuid/setgid/sticky bound; data entries keep g/o read). Working-perms memory `feedback-hashed-script-working-perms` rewritten: working perms now match recorded (not bumped to 0700); the `0700` rationale and the TC-5-break premise are retired (TC-5 is now fixed in the harness). MEMORY.md index pointer updated.
- **Deviations**: none.

### S8 — Restore working perms
- **Actual**: `cwf-manage` is on-disk `0700` (== recorded; the flip excluded it and Edit preserved its perms). `Security.pm` is `0600` (lib, no perms key). Confirmed via `stat`.
- **Deviations**: none.

### S9 — Full gate
- **Actual**:
  - `prove t/`: **all 53 files, 634 tests pass**.
  - `.cwf/scripts/cwf-manage validate` → `validate: OK` on this repo.
  - Output-level smoke: `chmod 0755` a `0500`-recorded script → `validate` emits `Field: permissions / File is more permissive than recorded (excess 0255). Clear excess bits or run: cwf-manage fix-security`; restored → `validate: OK`.
- **Deviations**: none.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed (S1–S9)
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed (FR1–FR5, AC1–AC8)
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

I now have full context to complete the review. Let me reason through the threat model.

## Security review — implementation phase

This changeset inverts the permission-check semantics in two places that share a recorded-permissions source (`.cwf/security/script-hashes.json`): the validator (`CWF::Validate::Security::validate`) and the repairer (`cwf-manage` `_apply_recorded_perms` / `cmd_fix_security`). The old model treated recorded perms as a *floor* (at least these bits must be present; additive repair raised missing bits). The new model treats them as a *ceiling* (no bits beyond the recorded mask; clamp repair strips excess bits, never raises). I reviewed both the diff and the surrounding code in `/home/matt/repo/coding-with-files/.cwf/lib/CWF/Validate/Security.pm` (lines 114-134) and `/home/matt/repo/coding-with-files/.cwf/scripts/cwf-manage` (lines 626-724, 739, 773).

**(a) Bash injection / unsafe command construction.** No shell command construction is introduced or modified. The repair uses Perl's built-in `chmod $want, $abs` (list-form, no shell) and the only string interpolation feeds `sprintf '0%o'` formatting and `_violation` hashref fields, all numeric or path-from-trusted-JSON. No new `system`/`qx`/backticks. Clean.

**(b) Perl helpers consuming git/user output without `-z`.** No git porcelain parsing is added. `$abs` paths come from the recorded JSON entries (already trusted, hash-pinned via the manifest pin in `validate_install_manifest`), not from git output. The hashes file itself is the integrity root; no newline-splitting introduced. Clean.

**(c) Prompt injection.** No LLM-context surface touched. The changed validator hint string (lines 129-131) is a deterministic CLI message, not LLM-routed. Clean.

**(d) Unsafe environment-variable handling.** No env vars introduced or consumed in the changed code. `$git_root` is the same trusted value already used throughout. Clean.

**(e) Pattern-based risks.** I checked the bitmask arithmetic closely, since that is where a ceiling-semantics bug would silently weaken the integrity check:

- Validator excess detection: `$excess = $actual_perms & ~$expected & oct('07777')`. The trailing `& 07777` confines the bitwise complement to the 12 low mode bits. Without it, `~$expected` would set all high bits and `$excess` would be non-zero for nearly every file — but here it correctly isolates the 12 permission/special bits. Setuid (04000), setgid (02000), and sticky (01000) acquisition on a file recorded without those bits yields a non-zero `$excess`, so they are flagged. This is the security-positive direction: the new check *catches* privilege-escalation bits that the old `($actual & $min) != $min` floor-check would have missed entirely (the old check ignored any bits beyond the recorded floor). This is a genuine hardening, not a regression.

- Repair clamp: `$want = $actual_perms & $recorded`. This can only clear bits, never set them, so `fix-security` cannot be coerced into *granting* permissions — it can only reduce them toward the recorded ceiling. A file already at-or-below the ceiling short-circuits (`next if $actual_perms == $want`). This is the safe direction for a repair tool.

- One asymmetry worth noting (not a defect, recorded for audit): the validator and the clamp repairer now have *aligned* but not *identical* predicates. The validator flags iff `$excess != 0`, i.e. iff `($actual & ~$recorded & 07777) != 0`. The clamp repairer acts iff `$actual != ($actual & $recorded)`, which is algebraically the same condition (excess bits present). So `fix-security` repairs exactly what `validate` flags — no drift, no file that validate rejects but fix-security declines to touch (provided sha matches). I confirmed this equivalence holds across all 12 bits. Safe here because both predicates derive from the same `$recorded` mask; audit any future change that alters one mask expression without the other, since divergence would let a flagged file resist repair (or vice versa).

- The `'exact'` post-laydown path (line 773, `apply_exact_perms_or_die`) is unchanged in intent: it sets the exact recorded mode. The comment correctly notes `exact <= ceiling`, so a freshly laid-down tree validates clean under the new ceiling check. I verified that exact-mode still sets `$want = $recorded` unconditionally, so the laydown enforcement remains least-privilege. No weakening.

**Under-permissive allowance.** The new semantics deliberately allow a file *less* permissive than recorded (e.g. a hashed script at 0400 when recorded 0500). This is the documented intent and is security-neutral-to-positive: an under-permissive file cannot be an escalation vector. The only functional consequence is that an over-restrictive file no longer self-heals via `fix-security` (clamp won't raise it) — but that is an availability/usability matter the maintainer chose deliberately, not a security concern.

I did not run the test suite (review scope is the diff). No actionable security findings.

```cwf-review
state: no findings
summary: Ceiling/clamp permission semantics are a hardening (flags setuid/excess bits the old floor-check ignored); chmod is list-form, no shell/env/git-output surface touched; validator-flag and clamp-repair predicates are algebraically equivalent over the 12 mode bits.
```

## Lessons Learned
Reporting the clamp target (`sprintf('0%o', $want)`) rather than the recorded value
in the `@repaired` `to` field was a small but necessary deviation — otherwise a
`0640`→`0400` clamp would have mis-reported as `→ 0500`. For `exact` mode the two
coincide, so the change is invisible there. Accurate before/after output matters
for a security tool whose whole job is to be trustworthy about what it changed.

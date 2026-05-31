# Enforce recorded permissions as upper bound - Testing Execution
**Task**: 170 (feature)

## Task Reference
- **Task ID**: internal-170
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/170-enforce-recorded-permissions-as-upper-bound
- **Template Version**: 2.1

## Goal
Execute the test cases from e-testing-plan.md and record results, confirming the
ceiling-only permission model.

## Test Execution Summary

| Suite | Tests | Result |
|---|---|---|
| `t/validate-security.t` (ceiling check, TC-A1..A6) | 11 subtests | PASS |
| `t/cwf-manage-fix-security.t` (clamp repair, TC-1..10) | 13 subtests | PASS |
| `t/install-bash-reinstall.t` (read-only source / TC-D1) | 10 subtests | PASS |
| `t/cwf-manage-update-end-to-end.t` (exact ≤ ceiling / TC-D2) | 22 subtests | PASS |
| **Full suite** `prove t/` | **53 files, 634 tests** | **PASS** |

## Results by test case (e-testing-plan map)

### A. Ceiling check — `t/validate-security.t`
- **TC-A1 over-permissive flags** (recorded 0444, on disk 0666): PASS — one `permissions` violation, actual `0666`, recorded `0444`, no other violations.
- **TC-A2 under-permissive allowed** (recorded 0500, on disk 0400): PASS — zero violations (the inversion of the old floor check).
- **TC-A3 setuid/setgid/sticky acquisition**: PASS — `04500`, `02500`, `01500` each flagged (high bit is excess).
- **TC-A4 exact recorded**: PASS — no violation.
- **TC-A5 unrecorded `.pm` at 0777**: PASS — no permissions check on entries without a `permissions` key.
- **TC-A6 ceiling hint**: PASS — hint references `fix-security`, not `chmod <recorded>`.

### B. Clamp repair — `t/cwf-manage-fix-security.t`
- **TC-1 clean install no-op**: PASS (exit 0, repaired 0, validate OK).
- **TC-2 stripped → clamp to ceiling**: PASS — a non-bootstrap `0500`-recorded script stripped to `0644` clamps to `0400` (`0644 & 0500`); post-validate OK. (Rewritten from the old raise-to-recorded assertion.)
- **TC-3 sha mismatch**: PASS — refused, no chmod, recovery hint, exit 1.
- **TC-4 missing file + best-effort clamp**: PASS — other file clamped to `0644 & recorded`, not raised.
- **TC-5 mixed fixable/unfixable**: PASS — fixable A clamped, unfixable B untouched.
- **TC-6 unparseable hashes**: PASS — exit 1, recovery hint.
- **TC-7 idempotency**: PASS — second run reports repaired 0 (verified unchanged under clamp).
- **TC-9 over-permissive** (0700 → ceiling): PASS — clamped to `0700 & recorded`, validate OK.
- **TC-10 under-permissive** (0400 no-op): PASS — repaired 0, file left at 0400, validate OK.
- **Dry-run + unknown-arg + sha-mismatch-under-dry-run**: PASS — preview only, no mutation, no false "validate: OK".

### C. Read-only-source harness robustness
- **TC-C1**: PASS — `install-bash-reinstall.t::write_file` and `cwf-manage-fix-security.t::append_byte` `chmod u+w` before opening a copied `0500` script. Before the fix, `install-bash-reinstall.t` test 5 died "Permission denied" (the Task 162 break); after, the full suite is green. The other three tree-copiers (`cwf-manage-update-end-to-end.t`, `cwf-claude-settings-merge.t`, `taskcontextinference.t`) passed untouched (verified empirically).

### D. Install / update e2e
- **TC-D1** (`install-bash-reinstall.t`, AC7): PASS — full suite green with `0500` sources.
- **TC-D2** (`cwf-manage-update-end-to-end.t`, exact ⊆ ceiling): PASS — post-`update` laid-down tree validates clean under the new ceiling (FR5 assertion).

### E. Self-host system test
- **TC-E1** (AC7): PASS — `.cwf/scripts/cwf-manage validate` on this repo → `validate: OK`.
- **TC-E2** (AC7b working-edit cycle): PASS — `chmod u+w` a `0500` script makes it `0700` and `validate` flags it (1 violation, ceiling working); restoring to `0500` → `validate: OK` (no false positive).
- **TC-E3** (output smoke): PASS — `chmod 0755` a tracked `0500` script → `validate` emits `File is more permissive than recorded (excess 0255). Clear excess bits or run: cwf-manage fix-security`; restore → `validate: OK`.

### Non-Functional
- **Performance (NFR1)**: the ceiling test is one extra bitwise op on the already-`stat`-ed mode; no new filesystem reads. No measurable regression (inspection).
- **Security (NFR4)**: TC-3 + sha-gate proves clamp stays sha-gated and never raises; TC-A3 proves setuid/setgid/sticky acquisition is caught; the implementation-phase security review found no actionable issues (hardening confirmed).
- **Reliability (NFR5)**: dry-run never mutates; chmod-failure surfaces as unfixable (covered by existing TC paths).

## Test Failures
None.

## Coverage Report
- Every AC (AC1–AC8) maps to ≥1 passing test case (see map above).
- Critical paths (ceiling predicate, clamp chmod, sha-gate) exercised by TC-A1/A3, TC-B/9/10, TC-3.
- Regression: full `prove t/` green; no validator other than `Security.pm`'s perm-check changed behaviour.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

I now have a full picture. Let me reason through the threat categories for the test-change focus.

## Review

The production code in this changeset is unchanged from the implementation-phase review (which returned no findings): `Security.pm` flips the permission check from a floor (`(actual & min) == min`) to a ceiling (excess = `actual & ~recorded & 07777`, flag iff non-zero), and `_apply_recorded_perms` gains a `clamp` mode (`want = actual & recorded`, never raising bits). The testing-phase question is whether the test changes weaken or misrepresent these security properties.

**(a) Bash injection / unsafe command construction.** The new/changed test code introduces `system("mkdir","-p",$dir)` and `system("cp","-p",$src,$dst)` in `_provision_extra_manifest_paths` (cwf-manage-fix-security.t) and `system('mkdir','-p',$dir)` in install-bash-reinstall.t's `write_file`. All are list-form `system` — no shell, no interpolation into a single string. The `$rel` values feeding these come from the repo's own integrity-tracked manifest and are additionally guarded by an explicit `die "refusing unsafe manifest path"` traversal/absolute check at lines 81-82 before use. `strip_perms_recursive` uses list-form `find ... -exec chmod ... ;`. No injection surface introduced. Test helpers, not production, but clean regardless.

**(b) Perl consuming git/user output without `-z`.** The test helpers read the manifest via `decode_json` of a slurped file, not via newline-split git porcelain. The only `git` invocations are list-form `git -C $tmp init -q`. No porcelain parsing. Clean.

**(c) Prompt injection.** No LLM-context surface in test files. N/A.

**(d) Unsafe env-var handling.** No new env-var reads in the test changes. N/A.

**(e) Pattern-based risk — and the core question: do the tests faithfully pin the ceiling/clamp semantics?** This is where a testing-phase review earns its keep. I checked whether the rewritten assertions could pass against a *broken* (e.g. reverted-to-floor or raise-to-recorded) implementation:

- The chmod-u+w mutation in `append_byte`/`write_file` (`(stat)[2] & 07777 | 0200`) is a fixture-prep concession to copied 0500 scripts. It only adds owner-write so the test can append/overwrite; it does not mask the property under test. In the sha-mismatch tests (TC-3, TC-5, FR2-sha) the subsequent `chmod 0644` resets the mode and the assertion is on *content* (`qr{X$}`) and *no-chmod*, so the u+w prep cannot create a false pass.

- The clamp assertions use `0644 & _read_recorded_perms(...)` (TC-2, TC-4, TC-5) and `0700 & recorded` (TC-9) as the expected value — read from JSON, no magic numbers. Crucially these would **fail** against a raise-to-recorded implementation: for a 0500-recorded script, `0644 & 0500 = 0400 ≠ 0500`, and TC-2's comment explicitly pins "owner-x NOT raised". So the clamp direction is genuinely asserted, not merely "validate passes."

- TC-10 (under-permissive 0400 left at 0400, not raised) and TC-A2 (recorded 0500 / on-disk 0400 → no violation) pin the inversion that is the whole point of the change. TC-A1 pins over-permissive flagging with the actual/expected modes checked.

- TC-A3 is the security-load-bearing addition: it asserts setuid/setgid/sticky acquisition (04500/02500/01500 over a 0500 ceiling) is flagged. This confirms `& ~$expected & 07777` keeps the high three mode bits in scope rather than letting a setuid bit slip past — exactly the bits an attacker would want. Good coverage of the dangerous case.

- TC-A5 confirms an unrecorded `.pm` entry (no `permissions` key) is not subjected to the ceiling at 0777, matching the production `defined $expected_perms` guard — this correctly documents that lib files are *intentionally* unchecked on permissions and would not regress into spurious failures.

- TC-A6 / hint-wording tests pin that the fix hint no longer says `chmod <recorded>` (which under a ceiling could *raise* perms and would be wrong advice) and instead points at excess/fix-security. This is a real correctness property, not cosmetic.

One thing I confirmed is **not** a gap: the ceiling check intentionally does not flag under-permissive files, which means a script chmod'd to `0000` would pass `validate`'s permission check. That is a denial-of-function, not a privilege-escalation, and is the deliberate, documented semantics of the change (a ceiling). The tests assert this is intended (TC-A2/TC-10), so they correctly represent the property rather than hiding a weakness. No finding.

I also confirmed the tests do not silence any integrity signal: sha256 mismatch remains unfixable and refused in every relevant test (TC-3/5, FR2-sha), so the clamp path can never chmod a tampered file — and the tests assert the no-chmod/content-unchanged invariant. This aligns with the standing "surface, never smooth" rule.

The test changes faithfully pin the new ceiling/clamp semantics, including the security-critical setuid/setgid/sticky case and the never-raise direction, and they preserve the sha-mismatch refusal. The fixture-prep chmod-u+w concessions are scoped to enabling the mutation and cannot manufacture a false pass on the property under test. No security concerns.

```cwf-review
state: no findings
summary: Testing-phase test changes faithfully pin ceiling/clamp semantics (incl. setuid/setgid/sticky and never-raise), preserve sha-mismatch refusal; fixture chmod-u+w prep does not mask the asserted property.
```

## Lessons Learned
The self-host E2 working-edit cycle is the test that best models real maintainer
behaviour: making a script `u+w` (→`0700`) to edit it transiently *exceeds* the
`0500` ceiling and `validate` flags it — correctly. The assertion that matters is
that restoring to recorded clears the flag. This is the working-perms convention
made executable, and it pins that the ceiling has no false positive on a clean tree.

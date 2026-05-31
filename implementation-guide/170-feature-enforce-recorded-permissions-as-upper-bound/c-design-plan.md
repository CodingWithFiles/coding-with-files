# Enforce recorded permissions as upper bound - Design
**Task**: 170 (feature)

## Task Reference
- **Task ID**: internal-170
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/170-enforce-recorded-permissions-as-upper-bound
- **Template Version**: 2.1

## Goal
Make recorded perms a ceiling-only check: `validate` flags a file *more* permissive than recorded and allows any file *less* permissive (replacing the existing floor check), and `fix-security` strips out-of-mask bits (`actual & recorded`) without raising. Flip this repo's 31 scripts recorded `0500` from on-disk `0700`→`0500` so the dev tree validates clean.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Decision Record (from requirements + user clarification)
- **D1 — Strict, keep 0500** (user choice): recorded perms are a per-file ceiling over all `07777` bits. Recorded values unchanged (9×`0444`, 31×`0500`, 8×`0700`) so installs stay least-privilege. This repo's 31 scripts recorded `0500` flip on-disk `0700`→`0500`; the working-perms convention flips from "bump to 0700" to "match recorded".
- **D2 — Ceiling REPLACES floor; under-permissive is allowed** (user clarification): the central point is that a file *less* permissive than recorded is acceptable and must NOT be flagged; only *more* permissive flags. So the existing floor check (which flags missing recorded bits) is **removed**, not kept, and replaced by the ceiling check. `fix-security` strips excess (`actual & recorded`) and never raises — so an under-permissive file is left as-is and a both-over-and-under file (`0640`/rec`0500` → `0400`) lands ≤ recorded and passes `validate`. The previous additive ("repair stripped perms up to recorded") behaviour is intentionally dropped, because raising perms now contradicts "less is OK". This is a deliberate, recorded behaviour change; existing tests asserting raise-to-recorded are rewritten to the ceiling semantics.

## Key Decisions
### Architecture Choice
- **Decision**: Modify the three existing integrity surfaces in place — the permission check in `CWF::Validate::Security::validate` (floor predicate swapped for ceiling), the `_apply_recorded_perms` mode set in `cwf-manage` (add `clamp`), and the dev-tree working perms — rather than introduce a new module or parallel code path.
- **Rationale**: The machinery (per-entry stat, sha-gated chmod, mode-dispatched repair, `_violation` records) already exists; the change is a swapped bitwise predicate plus one new repair mode. Reuse keeps one source of truth for "iterate manifest entries" and "gate chmod on sha".
- **Trade-offs**: Adds a third repair mode (`clamp`, mild cognitive load) and removes the under-permissive signal entirely (deliberate per D2 — "less is OK"). The simpler alternative (reuse `exact`: chmod to recorded) was rejected because it *raises* under-permissive files, contradicting "less is allowed" and the user's "strip the out-of-mask bits" instruction.

### Technology Stack
N/A — Perl core only (`Digest::SHA`, `JSON::PP`), POSIX `chmod`/`stat`. No new dependencies.

## System Design
### Component Overview
- **`CWF::Validate::Security::validate`** (`.cwf/lib/CWF/Validate/Security.pm`): inside the existing `if (defined $expected_perms)` block, **replace** the floor test (`(actual & recorded) != recorded`) with the ceiling test (`(actual & ~recorded & 07777) != 0`). Emits a `_violation` with a ceiling-appropriate fix hint (clear excess / run `fix-security`), never the old floor hint `chmod <recorded>`.
- **`_apply_recorded_perms`** (`.cwf/scripts/cwf-manage`): add a `'clamp'` mode → `want = actual & recorded`, with its own skip predicate `($actual & ~$want & 07777) == 0` (no excess ⇒ no-op). This is a third branch in the `if ($mode eq 'exact') … else …` guard at `cwf-manage:685`, NOT a fold into either existing branch. Existing `additive` and `exact` modes unchanged. Update the function's mode comment block to describe all three.
- **`cmd_fix_security`** (`.cwf/scripts/cwf-manage`): switch its single `_apply_recorded_perms` call from `'additive'` to `'clamp'` (strip excess only). Single chmod per entry, single result set — existing reporting/exit logic at `cwf-manage:735-754` is unchanged. Reporting lists each chmod with before/after.
- **Dev working perms**: flip the 31 scripts recorded `0500` from on-disk `0700` → `0500` (chmod only; content unchanged ⇒ no sha refresh for the flip). The two edited code files get sha refresh per hash-updates convention: `cwf-manage` (a script — restore its working perms to its **recorded `0700`**, NOT `0500`; it is one of the 8 already-`0700` entries) and `Security.pm` (a lib `.pm` with no perms key — stays `0600`/`100644` like its siblings, no perm change). The 8 scripts recorded `0700` are left at on-disk `0700` (recorded == on-disk; the ceiling never fires). Their `0700` ceiling carries no group/other bits so it remains a valid least-privilege ceiling; whether `0700` vs `0500` is the right recorded value per entry is out of scope (D1 keeps recorded values unchanged).
- **`install.bash` / TC-5**: verify a `0500` source survives `install_copy` (`rm -rf` + `cp -r` + `chmod u+rx`) and `cwf-manage update` reinstall-over; fix only if empirically broken (e.g. ensure laydown re-establishes perms regardless of source mode). The existing `chmod u+rx` at install.bash:251 is additive and mode-agnostic, so breakage is not expected — but TC-5 + the full `prove` suite is the gate.
- **Docs/memory**: update the security-model / hash-updates docs (FR5) to state ceiling semantics and the recorded-value bound — recorded ceilings for scripts MUST NOT carry group/other **write or execute** bits, nor setuid/setgid/sticky (note: the 9 data entries legitimately keep group/other **read** at `0444`, so the bound is write-or-execute, not "no group/other bits"). Update the working-perms guidance to "restore to recorded (e.g. `0500`), not bump to `0700`".

### Ceiling check (Security.pm)
The critical predicate (shown because the masking is the crux):
```perl
my $actual_perms = (stat($file))[2] & oct('07777');   # match Security.pm:114 style
my $expected     = oct($expected_perms);

# Ceiling-only (REPLACES the old floor check): flag iff more permissive than
# recorded. A file <= recorded (bitwise subset) passes — less is allowed.
my $excess = $actual_perms & ~$expected & oct('07777');
if ($excess != 0) {
    push @violations, _violation($file, 'permissions',
        sprintf('0%o', $actual_perms), $expected_perms,
        sprintf('File is more permissive than recorded (excess 0%o). '
              . 'Clear excess bits or run: cwf-manage fix-security', $excess));
}
```
Note `~$expected & oct('07777')` confines the complement to the 12 permission bits (Perl integers are wider), so setuid/setgid/sticky acquisition (high bits) is caught (AC1b). The old floor branch (`(actual & recorded) != recorded`) is deleted — under-permissive files no longer flag (AC2).

### Repair bit-math (cwf-manage)
```perl
# clamp (new, the fix-security repair): clear excess only — never raises bits.
my $want = $actual_perms & oct($expected_perms);
my $skip = ($actual_perms & ~$want & 07777) == 0;   # no excess ⇒ no chmod
```
Worked cases (single chmod from one read of `actual`):
- Over-only, recorded `0444`, on disk `0666` → `0666 & 0444 = 0444` (strips `g+w`,`o+w`,`o+x`). ✓ AC3
- Over-only, recorded `0500`, on disk `0540` → `0500`. ✓ AC3
- Under-permissive, recorded `0500`, on disk `0400` → `0400 & 0500 = 0400`: **no excess, no chmod** (file unchanged). `validate` already passes — under is allowed. ✓ AC2/AC4/AC4b
- Both over+under, recorded `0500`, on disk `0640` → `0640 & 0500 = 0400`: excess (`0240`) stripped; owner-`x` not added. Result `0400` ≤ `0500`, so `validate` passes (no floor check to fail).

Every result is ≤ recorded, so after `fix-security` the tree validates clean under the ceiling-only check — without ever raising a bit. This is the literal "strip any permission bits outside the mask".

## Constraints
- Perl core only; POSIX `chmod`/`stat`; NUL-safe path handling already in callers.
- **Correctness ordering (implementation phase)**: the ceiling check and the dev-tree perm flip must land together. If the check lands first, this repo's 31 `0700` scripts fail `validate` immediately — turning the `prove` suite / AC7 red (the hard gate) and emitting a non-fatal warning on every subsequent `cwf-checkpoint-commit` (its post-commit `validate` only `warn`s, it does not block — but a noisy false warning is undesirable). Flip perms in the same commit as the check.
- Hash refresh for edited scripts in the same commit (hash-updates convention); the perm-only flip of the 31 scripts needs no sha refresh.
- No surface may silence a tampering signal: ceiling repair stays sha-gated (skip chmod on sha mismatch), `--dry-run` never mutates, chmod failure surfaces as unfixable.

## Decomposition Check
- [ ] **Time**: >1 week? No (~1 day).
- [ ] **Complexity**: 3+ concerns? Check + repair + dev-perm-flip + install/TC-5 verification — but all are bound by the single correctness-ordering constraint and one subsystem.
- [ ] **Risk**: Needs isolation? No — the perm flip and the check MUST land together, so they cannot be separate tasks.
- [ ] **Independence**: Separable? No.

**Verdict**: No decomposition (unchanged). The install.bash/TC-5 verification is contingent work inside this task, not a separate deliverable.

## Validation
- [ ] Design review completed (Step 8 plan review)
- [ ] Bit-math for ceiling check and clamp repair verified against ACs
- [ ] Correctness-ordering constraint (perm flip + check in one commit) carried into implementation plan

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
The three-surface design held: ceiling predicate in `Security.pm`, `clamp` mode in
`_apply_recorded_perms`, and the dev-tree perm flip. The only deviation was naming
— the design proposed keeping `additive`; in exec it became dead code once the
floor check was removed, so it was deleted (two modes: `exact`, `clamp`).

## Lessons Learned
The bit-math worked-cases table (over-only, under, both-over-and-under) earned its
keep — it pre-verified that clamp ≠ exact only for both-over-and-under files, which
is the entire justification for adding `clamp` rather than reusing `exact`.

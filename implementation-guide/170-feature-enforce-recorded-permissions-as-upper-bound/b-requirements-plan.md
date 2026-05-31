# Enforce recorded permissions as upper bound - Requirements
**Task**: 170 (feature)

## Task Reference
- **Task ID**: internal-170
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/170-enforce-recorded-permissions-as-upper-bound
- **Template Version**: 2.1

## Goal
Define what the integrity check and repair must do so that a tracked file can never be *more* permissive than its recorded permissions, and repair clears only the excess.

## Model (user-clarified): recorded perms are a CEILING ONLY
Recorded perms are an upper bound. **Less permissive than recorded is always allowed and never flagged**; more permissive is flagged. This *replaces* the existing under-permissive (floor) check — CWF no longer requires a file to carry its recorded bits, only that it not exceed them.

- **Recorded perms** — the `permissions` value of a manifest entry in `.cwf/security/script-hashes.json` (octal string, e.g. `"0500"`). Entries without this key (lib `.pm` modules) are excluded from all permission checks.
- **Excess bits** — `(actual_mode & ~recorded) & 07777`: mode bits present on disk that are not in the recorded value.
- **Ceiling check (new, replaces floor)** — violation iff excess bits are present. `actual <= recorded` (bitwise subset) passes.

## Existing Baseline (what already ships)
- `cwf-manage validate` (`CWF::Validate::Security` lines 113–125) checks the **floor** (`(actual & recorded) != recorded`) — it flags *under*-permissive files and ignores excess. This task **replaces** that with the ceiling check (inverts which direction is flagged).
- `cwf-manage fix-security` repairs in **`additive`** mode (`cwf-manage` line 733): raises missing bits, never clears excess. This task switches it to a clear-excess (clamp) repair.
- `cwf-manage update` (laydown) sets exact recorded perms via `apply_exact_perms_or_die` → `_apply_recorded_perms(... 'exact')` (`cwf-manage` ~line 500, 761–778). Exact ⊆ ceiling, so laydown stays compliant and is **unchanged**.

## Functional Requirements
### Core Features
- **FR1 — Ceiling validation in `validate` (replaces the floor check)**: `cwf-manage validate` (via `CWF::Validate::Security`) MUST report a permissions violation for any entry with recorded perms whose on-disk mode has excess bits (`excess != 0`), and MUST NOT flag a file that is less permissive than recorded. This *replaces* the existing floor check. The violation MUST name the path, actual mode (octal), recorded mode, and a ceiling-appropriate remediation hint (clear the excess bits / run `fix-security`).
  - **AC1**: A tracked file chmod-ed more permissive than recorded (e.g. recorded `0444`, on disk `0666`) causes `validate` to exit non-zero with a `permissions` violation.
  - **AC2 (under-permissive allowed)**: A file strictly less permissive than recorded (e.g. recorded `0500`, on disk `0400`) raises **no** violation — this is the behaviour change from the old floor check, which *would* have flagged it.
  - **AC1b**: Excess is computed over the full `& 07777` mode, so acquiring a setuid/setgid/sticky bit not present in recorded is flagged (e.g. recorded `0500`, on disk `04500`). Highest-severity exposure case; MUST be covered.
  - **AC1c**: The ceiling hint differs from the old floor hint at `Security.pm:122`; it does not instruct setting the exact recorded mode.
- **FR2 — Excess-bit (clamp) repair in `fix-security`**: `cwf-manage fix-security` MUST repair a ceiling violation by setting the mode to `actual & recorded` (stripping out-of-mask bits only), MUST NOT add bits the file lacks, MUST gate the chmod on a prior sha256 match, and MUST report before/after modes. `--dry-run` MUST report the would-be change without mutating. This replaces the previous additive repair.
  - **AC3**: recorded `0444`, on disk `0666` → repaired to `0444`; recorded `0500`, on disk `0540` → `0500`; recorded `0500`, on disk `0640` → `0400` (excess stripped, bits not raised; result ≤ recorded so `validate` then passes).
  - **AC4 (under-permissive: no-op)**: recorded `0500`, on disk `0400` → no excess, no chmod, file unchanged; `validate` already passes (under is allowed).
  - **AC5**: A file with a sha256 mismatch is reported unfixable and is NOT chmod-ed, even if it has excess bits.
  - **AC5b**: A chmod that fails (e.g. EPERM) is surfaced as unfixable with a non-zero exit, not swallowed.
- **FR2a — Floor repair intentionally dropped**: `fix-security` no longer raises under-permissive files to recorded (the old additive behaviour), because under-permissive is now allowed (FR1/AC2). This is a deliberate behaviour change, recorded here; existing tests that asserted raise-to-recorded are updated to the ceiling semantics.
  - **AC4b**: A test asserts the new under-permissive behaviour: `fix-security` leaves a `0400`/rec-`0500` file at `0400` and `validate` passes.
- **FR3 — Unrecorded files unaffected**: Entries without a `permissions` key MUST be excluded from both the ceiling check and the clamp repair.
  - **AC6**: A lib `.pm` module set to `0777` raises no permissions violation.
- **FR4 — Laydown unchanged, recorded values consistent**: `cmd_update`'s `apply_exact_perms_or_die` (`exact` mode) is unchanged; exact ⊆ ceiling so a freshly-laid-down tree validates clean. Recorded values keep a single meaning: the per-file ceiling.
  - **AC7**: On a freshly-laid-down install tree at recorded perms, `cwf-manage validate` reports OK; `prove t/validate-security*.t t/cwf-manage-fix-security.t` and the install/update end-to-end suite (including TC-5) are green.
  - **AC7b — working-edit cycle**: After the 31 dev scripts are flipped to `0500`, a maintainer can make a script writable to edit and restore it to its recorded perm, then `validate` passes (no ceiling false positive on the working tree).
- **FR5 — Documented semantics**: The security-model documentation MUST state that recorded `permissions` are a ceiling (less-permissive allowed; more-permissive flagged), and that recorded ceilings for scripts MUST NOT include group/other **write or execute** bits, nor setuid/setgid/sticky (the 9 data entries legitimately keep group/other **read** at `0444`).
  - **AC8**: The relevant convention/security doc describes the ceiling semantics and what a hash-refresh must record, including the group/other write-or-execute prohibition.

### User Stories
- **As a** CWF maintainer **I want** validation to flag a tracked file that has become group- or world-writable (or otherwise over-permissive) **so that** an over-exposed file is caught rather than silently accepted.
- **As a** CWF user running `fix-security` **I want** the repair to strip only the out-of-mask bits **so that** an over-open mode is tightened to the ceiling without touching a tampered file, and a file I deliberately set *less* permissive is left alone.

## Non-Functional Requirements
### Performance (NFR1)
- No extra filesystem reads beyond the `stat` already performed per entry; the ceiling test is a constant-time bitwise op. No measurable regression in `validate`/`fix-security` runtime.

### Usability (NFR2)
- The ceiling violation message and fix output follow the existing `_violation` / `fix-security` formats. The remediation hint is actionable (clearing excess bits / pointing at `fix-security`), not a recompute-and-silence instruction.

### Maintainability (NFR3)
- Ceiling logic lives beside the existing permission check in `CWF::Validate::Security`; the clear-only repair extends `_apply_recorded_perms` (which already has `additive` and `exact` modes) rather than adding a parallel code path — note the new `actual & recorded` behaviour is distinct from both existing modes, so design names it explicitly. All fix modes remain described in that function's comment block.

### Security (NFR4)
- This is a security-hardening change: it closes the gap where an over-permissive tracked file passes validation. The repair MUST never widen permissions and MUST never silence an existence or sha256 violation. No new surface may turn a tampering signal into a silent no-op (integrity-friction principle).

### Reliability (NFR5)
- Repair is gated on sha256 match (never chmod a tampered file). `--dry-run` never mutates. A failed `chmod` is surfaced as unfixable, not swallowed.

## Constraints
- Perl core modules only; POSIX-only environment.
- Hash/manifest refresh in the same task and commit as the file modification (hash-updates convention); this task edits hashed scripts and must disclose that at plan time.
- Must not introduce any mechanism that silences a tampering signal without surfacing it first.

## Resolved Decisions
- **D1 — Recorded-value meaning (RESOLVED, user choice "Strict, keep 0500")**: recorded perms are a per-file ceiling; recorded values unchanged (31×`0500`, 8×`0700`, 9×`0444`). The `0700` working-perms convention is retired in favour of "working perms match recorded": this repo's 31 scripts recorded `0500` are flipped on-disk `0700`→`0500`. **Hard security bound**: recorded ceilings for scripts MUST NOT include group/other write or execute bits, nor setuid/setgid/sticky, so a future hash-refresh cannot silently re-open the exposure.
- **D2 — Floor replaced, not kept (RESOLVED, user clarification)**: under-permissive is allowed; the floor check is removed and replaced by the ceiling check. `fix-security` clamps (strips excess), never raises.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? Coupled (check + fix + value reconciliation), one subsystem.
- [ ] **Risk**: Needs isolation? No — D1 governs the check and cannot be split from it.
- [ ] **Independence**: Separable parts? No.

**Verdict**: No decomposition (unchanged from planning).

## Acceptance Criteria
Roll-up of the per-FR criteria above:
- [ ] AC1, AC1b–AC1c: Ceiling check fires on excess bits (incl. setuid/setgid/sticky acquisition) with a ceiling-appropriate hint (FR1).
- [ ] AC2: Under-permissive files are NOT flagged — the deliberate inversion of the old floor check (FR1).
- [ ] AC3–AC5, AC5b: Clamp repair (`actual & recorded`) strips excess, never raises, gated on sha256, surfaces chmod failures (FR2).
- [ ] AC4b: `fix-security` leaves an under-permissive file unchanged and `validate` passes (FR2a).
- [ ] AC6: Unrecorded `.pm` entries unaffected (FR3).
- [ ] AC7, AC7b: Freshly-laid-down tree validates OK and the maintainer edit cycle survives; `validate-security*`, `cwf-manage-fix-security`, install/update e2e (incl. TC-5) all green (FR4).
- [ ] AC8: Security-model doc states ceiling semantics incl. the group/other write-or-execute prohibition (FR5).

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All FRs satisfied and every AC (AC1–AC8) maps to a passing test. The ceiling-only
model (FR1 replaces floor; FR2 clamp; FR2a floor-drop) was implemented exactly;
FR3 (unrecorded `.pm` excluded), FR4 (exact laydown unchanged), and FR5 (doc
states ceiling + g/o write-or-execute bound) all met.

## Lessons Learned
Writing FR2a ("floor repair intentionally dropped") as an explicit requirement,
not an implementation footnote, kept the deliberate behaviour change visible and
gave the test rewrites (raise-to-recorded → clamp) a requirement to point at.

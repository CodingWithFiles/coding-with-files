# Enforce recorded permissions as upper bound - Testing Plan
**Task**: 170 (feature)

## Task Reference
- **Task ID**: internal-170
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/170-enforce-recorded-permissions-as-upper-bound
- **Template Version**: 2.1

## Goal
Validate the ceiling-only permission model: `validate` flags over-permissive and allows under-permissive; `fix-security` strips excess (clamp) without raising; the dev tree and all harnesses stay green after the `0500` flip.

## Test Strategy
### Test Levels
- **Unit (Perl `Test::More`)**: ceiling predicate in `Security.pm` via `t/validate-security.t`; clamp repair via `t/cwf-manage-fix-security.t`.
- **Integration / e2e**: install + reinstall + update over a `0500` source tree (`t/install-bash-reinstall.t`, `t/cwf-manage-update-end-to-end.t`).
- **System (self-host)**: `.cwf/scripts/cwf-manage validate` on this repo's own tree after the flip → OK; output-level smoke against a deliberately over-permissive fixture.

### Coverage Targets
- Every AC (AC1–AC8) maps to ≥1 named test case below.
- Critical paths (ceiling predicate, clamp chmod, sha-gate) 100%.
- Regression: full `prove t/` green; no validator other than `Security.pm` perm-check changes behaviour.

## Test Cases
### A. Ceiling check — `t/validate-security.t` (new/added subtests)
- **TC-A1 (AC1 over-permissive flags)**: Given a recorded-`0444` file chmod-ed `0666`, When `validate`, Then exit≠0 with a `permissions` violation naming the file, actual `0666`, recorded `0444`.
- **TC-A2 (AC2 under-permissive allowed — the inversion)**: Given a recorded-`0500` file chmod-ed `0400`, When `validate`, Then **no** violation for it (the behaviour the old floor check would have failed).
- **TC-A3 (AC1b setuid acquisition)**: Given a recorded-`0500` file chmod-ed `04500`, When `validate`, Then a ceiling violation (high bit is excess). Repeat sticky `01500` / setgid `02500`.
- **TC-A4 (AC1/edge equal)**: Given a file exactly at recorded, When `validate`, Then no violation.
- **TC-A5 (AC6 unrecorded `.pm`)**: Given a lib `.pm` (no `permissions` key) chmod-ed `0777`, When `validate`, Then no permissions violation.
- **TC-A6 (AC1c hint)**: The ceiling violation's `fix` text says strip-excess / `fix-security`, not `chmod <recorded>`.

### B. Clamp repair — `t/cwf-manage-fix-security.t`
- **TC-B1 (AC3 over→stripped)**: recorded `0444` on disk `0666`, sha intact → `fix-security` chmods to `0444`; recorded `0500` on disk `0540` → `0500`. Exit 0; post-`validate` OK.
- **TC-B2 (AC3 both over+under)**: recorded `0500` on disk `0640` → `0400` (excess stripped, not raised); post-`validate` OK (`0400` ≤ `0500`).
- **TC-B3 (AC2/AC4 under→no-op)**: recorded `0500` on disk `0400` → no chmod, file stays `0400`; `fix-security` reports 0 repairs; `validate` already OK.
- **TC-B4 (AC5 sha mismatch)**: tampered file with excess bits → reported unfixable, **no chmod**, exit 1 (rework of existing TC-3).
- **TC-B5 (AC5b chmod failure)**: a fixable entry whose chmod fails (e.g. read-only parent dir) → surfaced unfixable, non-zero exit, not swallowed.
- **TC-B6 (dry-run)**: over-permissive entry under `--dry-run` → "would chmod" preview, file unchanged, exit 0, no false "validate: OK".
- **TC-B7 (idempotency)**: two runs over a stripped tree; second reports "repaired 0" (verify existing TC-7 still holds under clamp).
- **Rework existing**: TC-4 (`:226`) and TC-5 (`:246`) raise-to-recorded assertions → clamp results; TC-2 (`:165`) → assert on a non-bootstrap script + post-`validate` OK.

### C. Read-only-source harness robustness
- **TC-C1**: After the `0500` flip, the mutation helpers (`install-bash-reinstall.t::write_file`, `cwf-manage-fix-security.t::append_byte`, and any peer in the 5 tree-copying harnesses) succeed against a copied `0500` script (chmod u+w first). Pinned implicitly by those suites passing.

### D. Install / update e2e
- **TC-D1 (AC7 / TC-5 real)**: `t/install-bash-reinstall.t` full suite green with `0500` sources (the Task 162 break stays fixed).
- **TC-D2 (Security F1)**: after `cwf-manage update`, the laid-down tree (exact mode) `validate`s clean under the new ceiling.

### E. Self-host system test
- **TC-E1 (AC7)**: `.cwf/scripts/cwf-manage validate` on this repo after S5 flip → `validate: OK`.
- **TC-E2 (AC7b working-edit cycle)**: chmod a script u+w, edit, restore to recorded (`0500`), `validate` → OK (no ceiling false positive).
- **TC-E3 (output smoke)**: deliberately chmod a tracked file over-permissive, run `validate`, grep the output for the ceiling message; restore.

### Non-Functional
- **Performance**: ceiling test is one extra bitwise op per already-stat-ed entry; assert no new filesystem reads (inspection, not a benchmark).
- **Security**: TC-B4/TC-B5 prove clamp stays sha-gated and never raises; TC-A3 proves setuid acquisition is caught; doc bound (AC8) reviewed in g.
- **Reliability**: TC-B5/TC-B6 cover chmod-failure surfacing and dry-run non-mutation.

## Test Environment
- POSIX, Perl core only (`Test::More`, `File::Temp`); no network. Fixtures via `cp -rp` of `.cwf/` into tempdirs (existing harness pattern).
- AC → TC map: AC1→A1/A6, AC1b→A3, AC1c→A6, AC2→A2/B3, AC3→B1/B2, AC4/AC4b→B3, AC5→B4, AC5b→B5, AC6→A5, AC7→D1/E1, AC7b→E2, AC8→g doc review.

## Validation Criteria
- [ ] Every AC has a passing mapped test case
- [ ] Full `prove t/` green (incl. the 5 tree-copying harnesses after the flip)
- [ ] `.cwf/scripts/cwf-manage validate` → OK on this repo
- [ ] Output-level smoke confirms the ceiling message (TC-E3)
- [ ] No behaviour change in validators other than `Security.pm` perm-check

## Decomposition Check
- [ ] Unchanged — single subsystem; tests share the existing harness patterns. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Every planned test case executed and passed (see g-testing-exec.md). The AC→TC map
held; the ceiling subtests (TC-A1..A6) and clamp cases (TC-9/10) were added as
planned, and the breaking raise-to-recorded assertions (TC-4/TC-5) were rewritten
to clamp results. Full `prove t/`: 634 tests green.

## Lessons Learned
The plan's instruction to "verify, don't assume rewrite" for TC-7 idempotency was
correct — TC-7 passed unchanged under clamp (clamp is idempotent: a stripped tree
re-clamps to itself). Assuming it needed a rewrite would have wasted effort.

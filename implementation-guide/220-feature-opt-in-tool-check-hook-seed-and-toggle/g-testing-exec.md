# opt-in tool-check hook seed and toggle - Testing Execution
**Task**: 220 (feature)

## Task Reference
- **Task ID**: internal-220
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/220-opt-in-tool-check-hook-seed-and-toggle
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Environment
Perl core + `prove` (TAP), no network, no DB. Fixtures via `File::Temp`; hook/helper
tests build a hermetic git repo with `$HOME`/`$TMPDIR` pinned into the tempdir.
Runner: `prove t/tool-check.t t/pretooluse-bash-tool-check.t t/tool-check-seed.t`,
then full `prove t/`. All executed on this branch at commit `98f0f97`.

## Test Results — all PASS

### Unit — `t/tool-check.t` (13 subtests, all PASS)
| Test ID | Case | Result |
|---------|------|--------|
| TC-U1 | `resolve_active` default-true (no trusted layer defines it) | PASS |
| TC-U2 | boolean-only coercion (`"false"`/`0`/`null`/`[]` ignored; real `false`/`true` honoured) | PASS |
| TC-U3 | precedence high→low + undef/error-layer skip | PASS |
| TC-U3b | `trusted_layers` selects+orders `[project-local, user-global]`, checked-in excluded, undef dropped | PASS |
| TC-U4 | `merge_seed` no-clobber + `(added,skipped)` counts | PASS |
| TC-U5 | `merge_seed` baseline (empty existing) | PASS |

### Hook integration — `t/pretooluse-bash-tool-check.t` (17 subtests, all PASS)
| Test ID | Case | Result |
|---------|------|--------|
| TC-H1 | live toggle: `active:false` allows, flip to `true` denies (no restart) | PASS |
| TC-H2 | `active:true` + zero rules → allow | PASS |
| TC-H3 | fail-open with an `active` key present (`{}` / symlinked layer) | PASS |
| TC-H4 | trusted precedence: project-local `false` beats user-global `true` | PASS |
| TC-H5 | checked-in `active:false` IGNORED — user-global rule still denies (clone-suppression closed) | PASS |
| TC-H6 | F2 degradation: `active:false` project-local corrupted → falls through to deny (deny-safe) | PASS |
| TC-H7 | kill-switch short-circuits BEFORE compile (BEGIN-probe never runs when off; positive control when on) | PASS |
| TC-H8 | `--check` "Effective active" matches hot path; checked-in `active` shown + marked ignored | PASS |

### Helper integration — `t/tool-check-seed.t` (9 subtests, all PASS)
| Test ID | Case | Result |
|---------|------|--------|
| TC-S1 | seed idempotent (byte-identical checked-in file on re-seed) | PASS |
| TC-S2 | re-seed preserves a user-edited starter id; skip reported | PASS |
| TC-S3 | preserving RMW keeps an unrelated top-level key | PASS |
| TC-S4 | `off` touches only `settings.local.json`; `git check-ignore` confirms it ignored | PASS |
| TC-S5 | seed→off→on effective-active transitions | PASS |
| TC-S6 | symlink-safe: refuses a symlinked target (sentinel untouched); clean write is 0600 | PASS |
| TC-S7 | unknown subcommand → non-zero, usage to stderr, no write | PASS |
| TC-S8 | seed after a prior `off` clears it → effective on (F3 ordering) | PASS |
| TC-S9 | **regression (robustness finding)**: broken symlinked user-global → `off` still exits 0 and writes | PASS |

### Non-Functional
- **Performance (NFR1)**: TC-H7 proves the kill-switch short-circuits before any perl compile (a `die`/`mkdir`-BEGIN probe never fires when off). `load_merged` returns decoded layers from the single existing read pass — no second stat/read.
- **Security (NFR4)**: TC-H5 (clone-suppression closed), TC-S4 (`git check-ignore` control), TC-S6 (symlink-safe 0600 writes). Corroborated by the security changeset reviewer (no findings).
- **Reliability (NFR5)**: TC-H3/TC-H6 fail-open matrix; TC-S1/TC-S5 idempotency; TC-S9 non-fatal echo.

## AC → Test traceability
Every AC1–AC9 traced per e-testing-plan.md §"AC → Test traceability"; AC5 (cwf-init
decline inert) verified at the skill level (manual/system — the opt-in step defaults
to decline and writes nothing); AC9 (docs + validate + same-commit hash refresh)
verified by `cwf-manage validate: OK` with the three hashed files refreshed in the
f-phase commit.

## Coverage Report
- Targeted: `Files=3, Tests=39, Result: PASS`.
- Full regression: `Files=75, Tests=970, Result: PASS` — no Task-201 regression; the
  25 tool-check tests added this task all green.
- `cwf-manage validate`: **OK** (sha256 for `CWF::ToolCheck`, the hook, and the new
  `tool-check-seed` helper all match; recorded permissions clean).

## Test Failures
None. (During f-exec, one intermediate: TC-H7's first compile-probe used an ambiguous
`print($f …)` inside a JSON-embedded BEGIN; switched to an unambiguous `mkdir` probe
with a positive control. No production defect — a test-authoring fix.)

## Changeset Reviews

Two reviewers ran in parallel over the testing-exec changeset (anchor `ed72881`,
22 files, 2451 lines). Classified by `security-review-classify`. Verbatim outputs in
the per-task scratch dir (`*-review-output-testing-exec.out`).

### Security Review
**State**: no findings

Fail-closed helper writes (symlink-safe, `O_EXCL`, atomic 0600, every syscall
checked); boolean-only kill-switch defaulting active with the checked-in layer
excluded (clone-suppression closed) and `trusted_layers` single-sourced; hook
fail-open preserved (short-circuit before compile, proven by TC-H7). The only
observation — a test-only single-string `system()` interpolation — is safe at every
callsite (File::Temp paths, literal verbs) and matches the existing harness pattern;
not a finding.

### Best-Practice Review
**State**: no findings

Matched tags (`golang`, `postgres`) are domain-mismatched to a Perl/markdown
changeset. The transferable language-agnostic principles (return-early, explicit
error handling, DRY single-source, fail-safe defaults) are honoured — notably the
single-sourced `trusted_layers` and the fail-closed `die_err` syscall checks.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
The narrower 2-reviewer testing-exec MAP was clean, corroborating the f-phase security
posture rather than re-finding it. AC → test traceability made "all ACs met" a
checkable fact, not a claim.

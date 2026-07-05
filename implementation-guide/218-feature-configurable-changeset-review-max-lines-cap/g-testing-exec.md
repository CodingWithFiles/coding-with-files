# Configurable changeset-review max-lines cap - Testing Execution
**Task**: 218 (feature)

## Task Reference
- **Task ID**: internal-218
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/218-configurable-changeset-review-max-lines-cap
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready (Perl core + Test::More; synthetic git repos)
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document deviations from the plan
- [x] Status → Finished (all pass)

## Deviation from e-testing-plan (naming)
The plan named the new cases **TC-CAP7–16**, but `t/security-review-changeset.t`
**already** defines TC-CAP7/8/9 for unrelated purposes (outside-repo exclude-paths
pattern, unconfigured test path, deprecated `test-paths` key). Reusing those numbers
would collide. The cases were implemented under **TC-CONFIGCAP1–10** (same scenarios,
1:1 mapping below). A second plan slip was corrected: plan TC-CAP14 specified a
~600-line diff but a missing key degrades to 500, so 600 lines would exit 2 and
conflate the "silent default" signal — TC-CONFIGCAP8 uses a small (<500) diff to
isolate silence + default cleanly.

## Test Results

### Functional Tests
Suite: `prove t/security-review-changeset.t` → **59/59 subtests PASS** (49 pre-existing
+ 10 new). Full repo suite: `prove t/` → **74 files, 947 tests, all PASS**.

| Plan ID | Impl ID | Test Case | Expected | Actual | Status |
|---------|---------|-----------|----------|--------|--------|
| TC-CAP7  | TC-CONFIGCAP1  | config cap used, no CLI flag (cap 20, 30-line diff) | exit 2, `> 20` | exit 2, matched | PASS |
| TC-CAP8  | TC-CONFIGCAP2  | 600-line diff under config cap 1000 (FR4) | exit 0, no cap msg | exit 0 | PASS |
| TC-CAP9  | TC-CONFIGCAP3  | `--max-lines=10` beats config 1000 | exit 2, `> 10` | exit 2, matched | PASS |
| TC-CAP10 | TC-CONFIGCAP4  | explicit `--max-lines=500` beats config 1000 | exit 2, `> 500` | exit 2, matched | PASS |
| TC-CAP11 | TC-CONFIGCAP5  | `"abc"` → warn (key only) + degrade to 500 | exit 0, warn, no `abc` echo | exit 0, matched | PASS |
| TC-CAP12 | TC-CONFIGCAP6  | `true` and `[500]` (refs) → warn + degrade | exit 0, warn (both) | exit 0, matched | PASS |
| TC-CAP13 | TC-CONFIGCAP7  | `0`, `-5`, `"007"` → warn + degrade | exit 0, warn (all) | exit 0, matched | PASS |
| TC-CAP14 | TC-CONFIGCAP8  | missing key / `null` → silent default | exit 0, **no** warn | exit 0, silent | PASS |
| TC-CAP15 | TC-CONFIGCAP9  | numeric string `"20"` accepted | exit 2, `> 20`, no warn | exit 2, matched | PASS |
| TC-CAP16 | TC-CONFIGCAP10 | invalid `--max-lines` fatal despite valid config | exit 1, `invalid --max-lines` | exit 1, matched | PASS |

Regression: TC-CAP1–6, TC-DEFAULTCAP, and the full 49-subtest suite continue to pass
unchanged — the default→unset refactor is behaviour-neutral when no config key is set.

### Non-Functional Tests
- **Security (NFR4 / info-leak)**: TC-CONFIGCAP5 asserts the malformed-value warning
  names the key only and does **not** echo the offending value (`unlike($err, qr/abc/)`).
  No new exec/shell/env surface introduced.
- **Reliability (NFR5)**: TC-CONFIGCAP6/7/8 confirm every non-integer / ref / absent
  input class resolves without making the helper fatal (fail-safe degrade).
- **Integrity**: `cwf-manage validate` → no SECURITY or hash drift (only the expected
  non-terminal WORKFLOW status flags on the in-progress a–f files, which clear at
  retrospective). Test file `t/` is not hash-tracked; no hash refresh needed for it.

## Test Failures
One transient failure surfaced and was resolved during this phase:
`t/cwf-manage-fix-security.t` TC-8 failed because the f-phase fix-on-sight
`cwf-manage fix-security` clamped two Task-217 robustness agent files from `0600`
down to `0400`. fix-security only *clears* excess bits (it never *raises*
permissions), so it under-clamped past the recorded `0444` floor; `validate` accepts
under-permissive, but TC-8 pins those repo files at the 0444 floor and caught the
regression. **Resolution**: restored both to the recorded `0444` (`chmod 0444`, git
tracks only the exec bit so no commit content change). TC-8 and the full suite then
pass. Lesson for the retrospective: fix-on-sight for a recorded-floor file should
`chmod <recorded>`, not rely on `fix-security` (which only strips excess).

## Coverage Report
Precedence matrix (CLI / config / default): 100% — all three layers plus the explicit
`--max-lines=500`-vs-config edge. Invalid-config equivalence classes: non-integer
scalar, boolean, array, zero, negative, leading-zero, missing key, JSON null, numeric
string — all covered. CLI-fatal / config-degrade asymmetry covered (TC-CONFIGCAP10).

## FR4 manual smoke
The live `implementation-guide/cwf-project.json` cap is set to `1000`; the config-read
path is exercised on every real review run (the f-phase changeset build reported
`65 production` and read the config without error). The >500-≤1000 passes-at-1000
behaviour is authoritatively proven by TC-CONFIGCAP2 on a synthetic 600-line diff — a
manufactured >500-line diff on the real repo would add noise commits for no extra
signal.

## Changeset Reviews (Step 8)
Branch: `feature/218-...` (not main). Changeset helper: exit 0, 1572 lines / 65
production (the new `t/` test block is discounted by the `t/**` exclude glob).
Best-practice resolver: 2 matches. Both reviewers launched in parallel; classified by
`security-review-classify`. No stderr `warning:` lines from either prep helper.

### Security Review
**State**: no findings

Reviewed all five threat categories, weighting the new `TC-CONFIGCAP1–10` test block.
Tests drive git via existing list-form helpers (`git_in`, `run_helper`) — no shell
interpolation; `cfg_maxlines($raw)` only ever receives hardcoded literal tokens. No new
git-porcelain parsing, no untrusted-string flow into LLM context, no env-var surface.
The self-referential cap raise (1000 lives in the diff it governs, no upper bound) is a
documented, bounded posture (exit 2 blocks, does not bypass; ambiguity → stricter 500) —
noted for the reuse-audit trail, not actionable. TC-CONFIGCAP5/10 directly test the
no-info-leak warning and the CLI-fatal asymmetry. Verdict: `no findings`.

### Best-Practice Review
**State**: no findings

Both source dirs (golang, postgres) readable; postgres and Go-language-mechanics
sections inapplicable to a Perl/JSON/markdown change. Against the *transferable* Go
testing/error-handling principles the changeset **conforms**: requirements-driven +
table-driven tests (FR2/FR3/FR4; TC-CONFIGCAP6/7/8 iterate value tables), black-box
subprocess testing through the public interface, fakes (synthetic git repos) over mocks,
no error info-leak (TC-CONFIGCAP5), fail-safe defaulting, and Rule-of-Three restraint
(design D2). Genuine no-divergence result. Verdict: `no findings`.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Two carried forward: (1) a full-suite run is the real gate — the isolated helper test
was green while `t/cwf-manage-fix-security.t` TC-8 caught the permission under-clamp
from an unrelated fix-on-sight action; (2) a "silent default" test must use a fixture
under that default, or the cap's exit-2 boundary masks the signal (drove the
TC-CONFIGCAP8 diff-size correction).

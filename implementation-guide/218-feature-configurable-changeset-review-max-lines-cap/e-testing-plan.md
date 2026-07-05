# Configurable changeset-review max-lines cap - Testing Plan
**Task**: 218 (feature)

## Task Reference
- **Task ID**: internal-218
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/218-configurable-changeset-review-max-lines-cap
- **Template Version**: 2.1

## Goal
Verify `CLI // config // 500` cap resolution, fail-safe config degradation, and the
hash/config rollout, extending the existing cap suite in `t/security-review-changeset.t`.

## Test Strategy
### Test Levels
- **Integration (primary)**: New `subtest 'TC-CAP7..'` blocks in
  `t/security-review-changeset.t`, reusing `make_cap_repo(config_json => …)`,
  `write_script($path, $n)`, and `run_helper($repo, @args)` — the same
  subprocess-against-synthetic-repo pattern as TC-CAP1–6.
- **System / integrity**: `cwf-manage validate` clean after the hash refresh
  (run in g-testing-exec).
- **Manual smoke**: a >500-≤1000-line changeset passes on this repo once the live
  config is set to 1000 (rebrand-style output-level check).

### Test Coverage Targets
- **Critical paths**: 100% of the precedence matrix (CLI/config/default) and every
  invalid-config equivalence class.
- **Regression**: TC-CAP1–6 and TC-DEFAULTCAP continue to pass unchanged (the
  default→unset refactor must be behaviour-neutral when no config key is present).

## Test Cases
Fixture: `make_cap_repo(config_json => $CFG)` where `$CFG` embeds
`security.review.max-lines`. Diffs sized with `write_script`. "production lines"
= added+deleted of non-excluded files.

### Functional — precedence (FR2)
- **TC-CAP7**: config cap used when no CLI flag.
  - **Given**: config `max-lines: 20`; a ~30-production-line diff.
  - **When**: `run_helper($repo)` (no `--max-lines`).
  - **Then**: exit 2; stderr `cap exceeded: \d+ production lines > 20`.
- **TC-CAP8**: config cap allows a diff under it.
  - **Given**: config `max-lines: 1000`; a ~600-line diff.
  - **When**: `run_helper($repo)`.
  - **Then**: exit 0 (proves 501–1000 passes at cap 1000 — FR4).
- **TC-CAP9**: CLI overrides config (both directions).
  - **Given**: config `max-lines: 1000`; a ~30-line diff.
  - **When**: `run_helper($repo, '--max-lines=10')`.
  - **Then**: exit 2 (CLI 10 wins over config 1000).
- **TC-CAP10**: explicit `--max-lines=500` beats a higher config (the default→unset
  motivator).
  - **Given**: config `max-lines: 1000`; a ~600-line diff.
  - **When**: `run_helper($repo, '--max-lines=500')`.
  - **Then**: exit 2 (explicit 500 wins, not treated as "absent" → 1000).

### Functional — fail-safe degradation (FR3)
- **TC-CAP11**: malformed config value → warn + degrade to 500.
  - **Given**: config `max-lines: "abc"` (non-integer scalar); a ~30-line diff.
  - **When**: `run_helper($repo)`.
  - **Then**: exit 0 (under 500); stderr warns
    `'security.review.max-lines' is not a positive integer`, and does **not** echo
    the value `abc` or any file path.
- **TC-CAP12**: structured/boolean config value → warn + degrade (surface, F1).
  - **Given**: config `max-lines: true` (and a parametrised variant `[500]`); a
    ~30-line diff.
  - **When**: `run_helper($repo)`.
  - **Then**: exit 0; the same key-named warning is emitted (proves ref types warn,
    not silently degrade).
- **TC-CAP13**: non-positive integers (`0`, `-5`, `007`) → warn + degrade.
  - **Given**: config `max-lines: 0`; a small diff.
  - **When**: `run_helper($repo)`.
  - **Then**: warning emitted; cap resolves to 500 (not a `>0` always-fire gate) —
    confirms CLI/config parity on the `^[1-9]\d*$` contract.
- **TC-CAP14**: missing key / JSON `null` → **silent** default (no warning).
  - **Given**: config with `security.review` present but no `max-lines` (and a
    `null` variant); a ~600-line diff.
  - **When**: `run_helper($repo)`.
  - **Then**: exit 0; stderr carries **no** `max-lines` warning (absence ≠ typo).
- **TC-CAP15**: numeric string accepted (FR3 JSON-scalar AC).
  - **Given**: config `max-lines: "20"` (string); a ~30-line diff.
  - **When**: `run_helper($repo)`.
  - **Then**: exit 2 (`"20"` matches the regex, treated as 20) — no warning.

### Regression (FR3 / behaviour-neutral refactor)
- **TC-CAP16**: invalid `--max-lines` CLI value stays **fatal** (exit 1) even with a
  valid config present — the CLI-fatal / config-degrade asymmetry.
  - Guards against the miscited-precedent risk from the requirements review.
- **Existing TC-CAP1–6, TC-CAP5 (invalid CLI), TC-DEFAULTCAP**: rerun unchanged.

## Non-Functional Test Cases
- **Security**: TC-CAP11/12 assert the warning names the key only (no value/path
  leak — NFR4 / best-practice finding). No new exec/shell/env surface to test.
- **Reliability**: unreadable/malformed `cwf-project.json` (whole-file garbage) does
  not make the helper fatal — degrades to 500 (reuse an existing malformed-config
  fixture shape if present, else add a `$CFG_GARBAGE` case).

## Test Environment
### Setup Requirements
- Perl core + `Test::More` (already used by the suite). No new deps.
- Synthetic git repos via `tempdir(CLEANUP => 1)` — never touches the real repo or
  a real database (n/a here). Capture files kept out-of-tree (existing `$CAPTURE_DIR`).
### Automation
- `prove -v t/security-review-changeset.t` locally; runs with the existing suite.

## Validation Criteria
- [ ] TC-CAP7–16 pass.
- [ ] Full `t/security-review-changeset.t` green (no regression in TC-CAP1–6).
- [ ] `cwf-manage validate` clean after the same-commit hash refresh.
- [ ] Manual smoke: >500-≤1000-line changeset passes on this repo at cap 1000.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
The planned cases were implemented as TC-CONFIGCAP1–10 (renamed from the plan's
TC-CAP7–16 to avoid colliding with existing TC-CAP7/8/9) and all pass. Two plan slips
were corrected at exec time and recorded in g: the naming collision, and TC-CAP14's
600-line diff (which would have exited 2 under the 500 default and conflated the
silent-default signal) reduced to a <500-line diff.

## Lessons Learned
Plan test IDs must be checked against the existing suite before numbering — reusing a
sequential range (TC-CAP7+) silently collided with unrelated pre-existing cases. Also:
when a case asserts "silent default", the fixture size must stay under that default or
the exit-2 boundary masks the very signal under test.

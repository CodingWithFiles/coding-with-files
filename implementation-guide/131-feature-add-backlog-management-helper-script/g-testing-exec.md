# Add backlog management helper script - Testing Execution
**Task**: 131 (feature)

## Task Reference
- **Task ID**: internal-131
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/131-add-backlog-management-helper-script
- **Template Version**: 2.1

## Goal
Run TC-AC1..AC17 from e-testing-plan.md plus non-functional NFT-1..4. All tests were exercised during f-implementation-exec (TDD); this phase records the results.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md ✓
- [x] Verify test environment ready ✓
- [x] Execute test cases sequentially ✓
- [x] Record pass/fail for each test ✓
- [x] Document failures with reproduction steps (none)
- [x] Update status to "Finished"

## Functional Test Results

| Test | Subtests | Result | Notes |
|------|----------|--------|-------|
| TC-AC1 (validate live)              | 1   | PASS | live BACKLOG/CHANGELOG accepted |
| TC-AC2 (validate flags malformed)   | 7×2 | PASS | covers BACKLOG-001/002/003/004/005, GLOBAL-001 BOM/CRLF |
| TC-AC3 (mixed markers)              | 1   | PASS | active + 4 marker variants + 2 struckthrough variants |
| TC-AC4 (CHANGELOG optional fields)  | 1   | PASS | omits Duration / Changes / Notable individually |
| TC-AC5 (list grouped output)        | 4   | PASS | High/Medium/Low headers; struckthroughs excluded |
| TC-AC6a (soft cap, top-band shown in full)   | 2 | PASS | 25 High items shown; band not split |
| TC-AC6b (--all-items)               | 2   | PASS | all 30 items shown |
| TC-AC7 (add valid)                  | 2   | PASS | added entry passes validate |
| TC-AC8a (add rejects banned priority)        | 1 | PASS | exit 1 |
| TC-AC8b (add rejects body with `^---$`)      | 1 | PASS | exit 1 |
| TC-AC8c (add rejects title with `-->`)       | 1 | PASS | exit 1 |
| TC-AC9 (modify byte-preservation)            | 3 | PASS | Status field unchanged |
| TC-AC10 (slug collision)            | 2   | PASS | exit 1 + ambiguity message |
| TC-AC11a (delete without --confirm)          | 2 | PASS | exit 1 + hint |
| TC-AC11b (delete with --confirm)             | 2 | PASS | entry removed |
| TC-AC12 (retire writes marker + bullet)      | 4 | PASS | em-dash marker, CHANGELOG bullet appended |
| TC-AC13a (retire rejects --reason with `-->`)| 1 | PASS | exit 1 |
| TC-AC13b (retire rejects --reason with newline)| 1 | PASS | exit 1 |
| TC-AC14 (retire idempotency)                 | 2 | PASS | second run no-op exit 0 |
| TC-AC15 (crash recovery)                     | 3 | PASS | bullet deduped; CHANGELOG mtime unchanged |
| TC-AC16a (no args)                  | 2   | PASS | exit 1, missing-subcommand error |
| TC-AC16b (--help)                   | 2   | PASS | top-level usage |
| TC-AC16c (subcommand --help)        | 2   | PASS | per-subcommand usage |
| TC-AC16d (missing required flag)    | 2   | PASS | exit 1, no help spam |
| TC-AC17 (round-trip chain)          | 6   | PASS | validate after each step |

**Total functional**: 27 subtests in `t/backlog-manager.t`, all PASS. Plus 28 unit subtests in `t/backlog.t` (round-trip, classification, fence-tracking, helpers, validators, mutators) all PASS. Plus 5 new subtests in `t/common.t` for the lifted `generate_slug`.

## Non-Functional Test Results

### NFT-1: Performance — PASS

```
$ time .cwf/scripts/command-helpers/backlog-manager validate
real    0m0.037s

$ time .cwf/scripts/command-helpers/backlog-manager list --all-items >/dev/null
real    0m0.034s
```

Both subcommands run in 37ms on the live BACKLOG (~1810 lines) and CHANGELOG (~1500 lines). Well under the 2-second budget.

### NFT-2: Security — PASS

- Symlink defence: `t/backlog.t` "write_backlog_file: refuses symlink target" PASS.
- HTML-comment injection: `t/backlog-manager.t` AC8c (title), AC13a (reason) — both PASS.
- Body separator collision: `t/backlog-manager.t` AC8b — PASS.
- Path-allowlist on `--body-file`: covered by `validate_path_allowlist` invocation; not separately asserted in this task (existing `CWF::ArtefactHelpers` test surface covers it).

### NFT-3: Usability — PASS (smoke-tested)

- All errors prefix `[CWF] ERROR: backlog-manager <subcommand>:` ✓ (verified across AC2/AC8/AC10/AC11/AC13/AC16 subtests).
- Help format consistent across subcommands.

### NFT-4: Reliability — PASS

- Round-trip property holds against live BACKLOG and CHANGELOG (`t/backlog.t` round-trip subtests, both PASS).
- Crash-state recovery: AC15 PASS.

## Regression Check

```
$ prove t/
Files=36, Tests=398
Result: PASS
```

Baseline 338 → 398 = exactly +60 new tests (28 backlog.t + 27 backlog-manager.t + 5 common.t generate_slug subtests). Zero regressions in pre-existing tests.

```
$ .cwf/scripts/cwf-manage validate
[CWF] validate: OK
```

## Test Failures

None.

## Coverage

- All 17 functional acceptance criteria from b-requirements covered.
- All four non-functional categories from e-testing-plan covered.
- Validator rule coverage: BACKLOG-001/002/003/004/005, CHANGELOG-001/002/003, GLOBAL-001 — each rule has at least one passing-input fixture and at least one failing-input fixture.

## Plan Deviations from e-testing-plan

The plan listed 13 fixture directories under `t/fixtures/backlog-manager/`. In practice only `current/` (symlinks to live files) was committed; the other inputs are constructed inline via `make_isolated()` in `t/backlog-manager.t`. Same coverage, less file churn. Already noted in f-implementation-exec.md.

## Security Review

**State**: error

error: changeset exceeds 500-line review cap; split the change or perform manual review

The g-phase changeset is the same as the f-phase changeset (no new code added in this phase, just the test-results record). Manual security walkthrough already supplied in f-implementation-exec.md § Security Review; no additional findings to record here.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Pass 2 Results

Re-execution after the redesigned model (BACKLOG = active only; retire moves entries; no marker tombstones). All ACs run against the new `cmd_retire`, the new validator rules (BACKLOG-004/005/006 generalised + CHANGELOG-003 added), and the new `### Retired Backlog Items` subsection mutators.

### Functional Test Results (Pass 2)

| Test                                         | Result                  | Notes |
|----------------------------------------------|-------------------------|-------|
| TC-AC1 (validate live)                       | TODO (gated h-rollout)  | live BACKLOG has 61 legacy markers; AC1 fires `BACKLOG-004` until rollout migrates them |
| TC-AC2a (BACKLOG-002 banned priority)        | PASS                    | `Needs-Triage` rejected |
| TC-AC2b (BACKLOG-001 missing field)          | PASS                    | missing Task-Type/Priority caught |
| TC-AC2c (GLOBAL-001 BOM)                     | PASS                    | exit 1 |
| TC-AC2d (BACKLOG-004 HTML comment) — NEW     | PASS                    | stray `<!-- -->` rejected |
| TC-AC2e (BACKLOG-005 struck-through) — NEW   | PASS                    | `^## ~~Task: …~~` rejected |
| TC-AC2f (BACKLOG-006 `^####` body) — NEW     | PASS                    | `#### Subhead` in active body rejected |
| TC-AC2g (CHANGELOG-003 order) — NEW          | PASS                    | Notable-before-Changes rejected |
| TC-AC3 (CHANGELOG accepts comments) — NEW    | PASS                    | replaces old AC3 (mixed markers) |
| TC-AC4 (CHANGELOG optional fields)           | PASS                    | added `### Retired Backlog Items` to the matrix |
| TC-AC5 (list grouped, includes Very High)    | PASS                    | Very High band rendered |
| TC-AC6a (soft cap)                           | PASS                    |
| TC-AC6b (--all-items)                        | PASS                    |
| TC-AC7 (add valid)                           | PASS                    |
| TC-AC8a (banned priority)                    | PASS                    |
| TC-AC8b (body `^---$`)                       | PASS                    |
| TC-AC8c (body `^####`) — replaces title -->  | PASS                    | new rejection for BACKLOG-006 |
| TC-AC9 (modify byte-preservation)            | PASS                    |
| TC-AC10 (slug collision)                     | PASS                    |
| TC-AC11a (delete without --confirm)          | PASS                    |
| TC-AC11b (delete with --confirm)             | PASS                    |
| TC-AC12 (retire moves entry) — REWRITE       | PASS                    | BACKLOG entry deleted; `### Retired Backlog Items` created; `#### <title>` block appended; subsequent validate exits 0 |
| TC-AC13a (retire --note rendered) — NEW      | PASS                    | `<!-- Note: … -->` appears in CHANGELOG |
| TC-AC13b (retire --note rejects) — REWRITE   | PASS                    | empty / `-->` / newline / BOM-like all rejected |
| TC-AC14 (retire missing CL entry) — NEW      | PASS                    | exit 1; both files unchanged |
| TC-AC15a (retire idempotent)                 | PASS                    | second run no-op exit 0 |
| TC-AC15b (crash recovery) — REWRITE          | PASS                    | dedup detects existing block; CHANGELOG mtime stable; only BACKLOG rewritten; no duplicate block |
| TC-AC16a (no args)                           | PASS                    |
| TC-AC16b (--help)                            | PASS                    |
| TC-AC16c (subcommand --help)                 | PASS                    |
| TC-AC16d (missing required flag)             | PASS                    |
| TC-AC17 (chain) — UPDATED                    | PASS                    | retire step now uses `--task` only (no `--reason`) |

### Library-level Test Results (Pass 2)

| Test (in `t/backlog.t`)                                            | Result | Notes |
|--------------------------------------------------------------------|--------|-------|
| Round-trip BACKLOG byte-identical                                  | PASS   | live file round-trips |
| Round-trip CHANGELOG byte-identical                                | PASS   | live file round-trips |
| Classify: active                                                   | PASS   |
| Classify: unknown for marker/struckthrough — REWRITE               | PASS   | three sub-assertions for the previously-classified kinds |
| Classify: intro                                                    | PASS   |
| Classify: changelog_task                                           | PASS   |
| Fence: `---` inside fence is not a separator                       | PASS   |
| Fence: `## Task:` inside fence is body                             | PASS   |
| entry_title and entry_slug                                         | PASS   |
| entry_metadata: parses fields                                      | PASS   |
| entry_metadata: empty value preserved                              | PASS   |
| find_active_by_slug: unique                                        | PASS   |
| find_active_by_slug: collision                                     | PASS   |
| validate live BACKLOG (TODO until h-rollout)                       | TODO   |
| validate live CHANGELOG passes                                     | PASS   |
| validate clean fixture passes — NEW                                | PASS   |
| BACKLOG-002 banned priority                                        | PASS   |
| BACKLOG-001 missing field                                          | PASS   |
| BACKLOG-003 body separator collision                               | PASS   |
| BACKLOG-004 HTML comment rejected — NEW                            | PASS   | two assertions (marker + stray) |
| BACKLOG-005 struck-through rejected — NEW                          | PASS   | tilde-strike + tick-prefix |
| BACKLOG-006 `^####` rejected — NEW                                 | PASS   | + fence-aware silent assertion |
| CHANGELOG-003 subsection order — NEW                               | PASS   | Notable-before-Changes rejected; canonical order accepted |
| GLOBAL-001 BOM rejected                                            | PASS   |
| GLOBAL-001 CRLF rejected                                           | PASS   |
| set_priority_field                                                 | PASS   |
| find_changelog_task — NEW                                          | PASS   | three task-num lookups |
| find_retired_subsection — NEW                                      | PASS   | bounds + fence respect |
| block_exists_in_retired — NEW                                      | PASS   | case-insensitive match |
| append_retired_block insertion position — NEW                      | PASS   | three placements (after Notable, after Changes, after metadata) |
| append_retired_block appends to existing subsection — NEW          | PASS   | no duplicate heading |
| Fence-parity invariant (TC-LIB-9) — NEW                            | PASS   | validators silent on patterns inside fences |
| write_backlog_file: refuses symlink target                         | PASS   |

### Non-Functional Test Results (Pass 2)

**NFT-1: Performance** — PASS

```
$ time backlog-manager validate          → 0.040s (exits 1 on legacy markers — expected)
$ time backlog-manager list --all-items  → 0.033s
```

Both well under the 2-second budget.

**NFT-2: Security** — PASS

- Symlink defence (write side): `t/backlog.t` round-trip subtests + the dedicated symlink-refuses subtest, all PASS.
- `--note` rejection: TC-AC13b parametrised over four bad inputs (empty / `-->` / newline / BOM-like). PASS.
- Body separator (TC-AC8b) and body-h4 (TC-AC8c) rejections, PASS.
- Fence-parity invariant (TC-LIB-9): single fixture with HTML comments, struck-through, `####`, and `### Changes` headings ALL inside one fence — zero validator findings. PASS. Confirms `_build_fence_map` semantics are uniform across rules.

**NFT-3: Usability** — PASS

All errors prefix `[CWF] ERROR: backlog-manager <subcommand>:`. Help format consistent. Verified across all AC2/AC8/AC10/AC11/AC13/AC16 subtests.

**NFT-4: Reliability** — PASS

- Round-trip property holds against live BACKLOG and CHANGELOG.
- Crash-state recovery (TC-AC15b): dedup detects existing block; only BACKLOG is rewritten; no duplicate block. PASS.

### Regression Check (Pass 2)

```
$ prove t/
Files=36, Tests=408
Result: PASS
```

Pass 1 final: 399 tests. Pass 2 final: 408 tests. Net +9 (TODO assertions count as pass in the harness).

```
$ .cwf/scripts/cwf-manage validate
[CWF] validate: OK
```

### Test Failures

None.

### Coverage

- All 17 functional ACs have test coverage. AC1 deferred to post-h-rollout via `TODO {}` block per the e-testing-plan.
- Validator rule coverage: BACKLOG-001/002/003/004/005/006, CHANGELOG-001/002/003, GLOBAL-001 — each has both passing and failing fixtures.
- Fence-parity invariant covered (TC-LIB-9).

### Plan Deviations from e-testing-plan (Pass 2)

1. **AC1 marked TODO until h-rollout migrates the 61 legacy markers**. Already documented in the plan; this just records the actual deferral.
2. **Test fixtures stayed inline** (matches Pass 1; e-testing-plan listed on-disk fixture directories that the test harness materialises in tempdirs via `make_isolated()`).

## Pass 2 Security Review

**State**: error

error: changeset exceeds 500-line review cap; split the change or perform manual review

The g-phase changeset is the same as the f-phase changeset (no new code in this phase — only the test-results record was added). Manual security walkthrough already supplied in f-implementation-exec.md § Pass 2 Security Review. No additional findings.

## Lessons Learned
*To be captured during retrospective*

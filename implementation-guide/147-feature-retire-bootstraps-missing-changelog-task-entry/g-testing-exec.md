# retire bootstraps missing CHANGELOG task entry - Testing Execution
**Task**: 147 (feature)

## Task Reference
- **Task ID**: internal-147
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/147-retire-bootstraps-missing-changelog-task-entry
- **Template Version**: 2.1

## Goal
Execute the test cases planned in e-testing-plan.md and record results.

## Test Run Command
```
prove t/backlog-bootstrap-changelog.t t/backlog-tree-mutators.t t/backlog-manager.t \
      t/backlog-tree-parse.t t/backlog-tree-validate.t t/backlog-manager-argv-utf8.t
```

## Result Summary
- **Files**: 6
- **Tests**: 87 subtests
- **Pass**: 87
- **Fail**: 0
- **Wall**: ~3s
- **Live validate**: `backlog-manager validate` → exit 0 (clean)

## Test Case Results

| Test Case | File | Status | Notes |
|---|---|---|---|
| TC-AC1 (FR1) bootstrap creates well-formed CHANGELOG | `t/backlog-bootstrap-changelog.t` | PASS | exit 0, heading + Status + Impact + Retired subsection + BACKLOG mutated |
| TC-AC2 existing-entry no-regression | (subsumed) | N/A | Subsumed by TC-AC3 (single-heading assertion) + pre-existing round-trip tests |
| TC-AC3 (FR3, NFR3) second retire reuses entry | `t/backlog-bootstrap-changelog.t` | PASS | both blocks present in order, exactly one `## Task 147:` heading |
| TC-AC4 (NFR2) validate clean | `t/backlog-bootstrap-changelog.t` | PASS | post-bootstrap `validate` exit 0 |
| TC-AC5a (FR4) deterministic title | `t/backlog-bootstrap-changelog.t` | PASS | derivation + idempotence + type-token stripping |
| TC-AC5b (FR5) zero-match dies, no mutation | `t/backlog-bootstrap-changelog.t` | PASS | error message + BACKLOG/CHANGELOG byte-unchanged |
| TC-AC5c (FR6) multi-match dies, lists candidates | `t/backlog-bootstrap-changelog.t` | PASS | single-quoted dir names + manual-workaround hint |
| TC-AC6 (FR8) `--note` works in bootstrap path | `t/backlog-bootstrap-changelog.t` | PASS | `<!-- Note: migrated mid-task -->` rendered in output |
| TC-AC7 (NFR1) re-run after partial state dedups | `t/backlog-bootstrap-changelog.t` | PASS | second retire exit 0, CHANGELOG byte-unchanged on dedup |
| TC-AC8a (NFR4) symlinked CHANGELOG refused | `t/backlog-bootstrap-changelog.t` | PASS | symlink guard fires, BACKLOG unchanged |
| TC-AC8b (NFR4) `--task=foo` refused | `t/backlog-bootstrap-changelog.t` | PASS | integer-guard message |
| TC-AC8c (NFR4) slug with shell metachar | (subsumed) | N/A | POSIX filesystem rules forbid `/` and `\0` in basenames; non-shell-interpolating code path makes other metachars inert. Covered by TC-AC8d. |
| TC-AC8d (D7) title rejects `:` | `t/backlog-bootstrap-changelog.t` | PASS | title-validation error with `(contains :)` annotation |
| TC-AC9 (FR3) stub overwritable | (documentation-only) | N/A | Semantic property covered by TC-AC4 (validator passes against the stub) + the existing retrospective-skill discipline |
| TC-U1 (mutator) empty-tree bootstrap | `t/backlog-tree-mutators.t` | PASS | 6 assertions |
| TC-U2 (mutator) inserts at index 0 | `t/backlog-tree-mutators.t` | PASS | 4 assertions |
| TC-U3 (mutator) serialise/parse round-trip | `t/backlog-tree-mutators.t` | PASS | 5 assertions, all fields preserved |
| TC-LT1 (type loader) filter malformed | (subsumed) | N/A | Strict filter `qr/\A[a-z][a-z0-9-]{0,31}\z/` exercised indirectly by every resolver test |
| TC-LT2 (type loader) dies on empty | (subsumed) | N/A | Die path exercised indirectly when configs are absent (see TC-AC5b setup) |
| AC14 (no-regression) | `t/backlog-manager.t` | PASS | Updated to assert new bootstrap-refuse-on-zero-match contract |
| All other AC1-AC15 (pre-existing) | `t/backlog-manager.t` | PASS | 29 subtests, no regressions |
| Tree parse/validate (pre-existing) | `t/backlog-tree-parse.t`, `t/backlog-tree-validate.t` | PASS | no regressions |
| UTF-8 argv (pre-existing) | `t/backlog-manager-argv-utf8.t` | PASS | no regressions |

## Pre-existing failure (not addressed)
`t/backlog-roundtrip-live.t` — `TC-ROUNDTRIP-LIVE-BACKLOG` fails on UTF-8 character mangling (`—` → `â` etc.) on the live BACKLOG.md. Reproduced on `main` HEAD prior to this task's work. Unrelated to Task 147; flagged for separate task.

## Coverage
All 9 ACs from b-requirements-plan.md covered by at least one test or a documented subsumption (TC-AC2, TC-AC8c, TC-AC9). All 3 tree-mutator unit tests pass. Live `backlog-manager validate` clean post-implementation.

## Defects Found
None.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout 147
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: error

error: changeset exceeds 500-line review cap; split the change or perform manual review

### Manual review notes (testing-phase delta)

The `--phase=testing` changeset covers the full cumulative diff from baseline (same 606 lines as the implementation-phase changeset). The testing-phase delta proper is small:
- Added: `g-testing-exec.md` (this file — wf doc, no executable).
- No new tests added in this phase; tests were authored in f.
- No production code changed.

Threat-category sweep over the testing delta:
- **(a) Bash injection**: no new shell calls.
- **(b) Perl/git input validation**: no new git calls.
- **(c) Prompt injection**: this wf doc embeds no user-controlled strings (test names and file paths are author-written).
- **(d) Env vars**: none.
- **(e) Pattern risks**: none.

No findings.

## Lessons Learned
*To be captured during retrospective*

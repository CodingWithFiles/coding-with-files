# review all changed files not just cwf-internal - Testing Execution
**Task**: 174 (bugfix)

## Task Reference
- **Task ID**: internal-174
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/174-review-all-changed-files-not-just-cwf-internal
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready (`prove`, core Perl modules)
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps (none after reconciliation)
- [x] Update status

## Test Results

Run: `prove t/security-review-changeset.t` (25 subtests) and `prove t/` (full suite).
All green.

### D5 reconciliation map — verified
| e-plan bucket | Subtest(s) | Result |
|---------------|-----------|--------|
| INVERT (now-false exclusion → inclusion) | TC-F5, TC-F6, TC-NF5 | PASS — non-CWF/non-script files now asserted *present* in the changeset |
| DELETE/REPLACE (deleted-guard behaviour) | TC-GUARD1a (was TC-NF3), TC-GUARD1b (was TC-NF4) | PASS — symlink reviewed + link-target emitted (not dereferenced); FIFO does not hang |
| RE-JUSTIFY (assertion holds, rationale updated) | TC-F1, TC-F2, TC-F4, TC-CAP2 | PASS — inclusion no longer attributed to shebang/CWF-internal |
| UNCHANGED (anchor/cap/CLI) | TC-F3, TC-F7, TC-F8, TC-NF1, TC-NF2, TC-Task141, TC-CAP1/3/4/5/6/7 | PASS |

### New test cases — verified
| Test ID | Asserts | Status |
|---------|---------|--------|
| TC-WIDEN1 | non-script consumer `src/app.js` is reviewed **and** counts as production | PASS |
| TC-CAP8 | unconfigured exclude-paths → test file counts as production (cap fires earlier) | PASS |
| TC-EMPTY1 | empty diff → exit 0, `reviewed 0 files`, empty stdout (no whole-tree leak) | PASS |
| TC-GUARD1a | symlink reviewed; diff body is the link **target** string (git did not dereference) | PASS |
| TC-GUARD1b | FIFO present → helper completes < bound (no hang) | PASS |
| TC-CAP9 | deprecated `test-paths` key still discounts + emits deprecation warning | PASS |

### Cross-file reconciliation (the plan-missed coupling) — verified
| File | Subtest | Result |
|------|---------|--------|
| `t/cwf-check-tree-symlinks.t` | TC-7 (ledger + tamper; prefix-coverage part removed) | PASS |
| `t/install-bash-reinstall.t` | (obsolete prefix-sync TC-7 removed) | PASS — suite green without it |

### Validation criteria (e-plan) — met
- [x] All reconciled + new subtests pass; full `t/` suite green (**Files=54, Tests=643**).
- [x] TC-WIDEN1 proves a non-script consumer file is reviewed **and** counted.
- [x] TC-GUARD1 (mandatory) passes with falsifiable symlink/FIFO observables.
- [x] No subtest still asserts a non-CWF / non-script file is *excluded*.
- [x] Empty-diff path yields exit 0 / `reviewed 0 files` (TC-EMPTY1).
- [x] `cwf-manage validate` reports no new violations after the hash refresh.

## Test Failures
None. (During exec, 5 failures surfaced from the fixture's a-task-plan.md
entering the now-wider diff window, and 4 from the pre-existing Task-173 perm
drift + the cross-file `@CWF_INTERNAL_PREFIXES` coupling — all resolved in f:
fixtures reworked to merge-base anchoring, perm drift clamped, two extra test
files reconciled. Detailed in f-implementation-exec.md.)

## Coverage Report
Every behavioural claim in c-design D1–D2 has an asserting subtest: all-files-
included (TC-F1/F2/F4/F5/F6/NF5/WIDEN1), test-reviewed-but-discounted
(TC-CAP2/CAP4), empty-diff guard (TC-EMPTY1), cap on production count
(TC-CAP1/8), guard-removal safety (TC-GUARD1a/b), back-compat key (TC-CAP9).

## Security Review

**State**: no findings

Testing-phase helper run: `reviewed 15 files, 1664 lines (208 production),
anchor=c886856` → **exit 0** (no deprecation warning — `cwf-project.json` uses
the new `max-lines-exclude-paths` key). The 6 production code files are
byte-identical to the implementation-phase review; the testing phase added the
reconciled `t/` suite + results doc. The `cwf-security-reviewer-changeset`
subagent reviewed against FR4(a–e); `security-review-classify` returned
**`no findings`**. Verbatim output captured at the task scratch dir; verdict:

```cwf-review
state: no findings
summary: Testing-phase diff (reconciled t/ suite, config key rename, doc sweep) introduces no new attack surface; classifier removal strictly widens review coverage and all helper fail-safes (NUL reject, exit-1 on malformed pattern, unconfigured=production, empty-diff guard) are preserved and now test-asserted. Deprecation fallback re-validates via the shared loop.
```

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None — 643 tests pass; testing-phase security review `no findings`.

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Full suite Files=54, Tests=643, all green; `cwf-manage validate: OK`; testing-phase
security review `no findings`. All reconciled and new subtests pass with falsifiable
observables (symlink link-target text, FIFO no-hang, widened-coverage inclusion+count).

## Lessons Learned
The genuine test signal was initially masked by 12 spurious failures (5 from the
fixture's own a-task-plan.md in the wider diff window; 4 from pre-existing Task-173
perm drift; cross-file coupling). Merge-base anchoring in `make_cap_repo` isolated the
fixture's own files from the cap count — a reusable pattern for tests that assert on
production-line counts. See j-retrospective.md.

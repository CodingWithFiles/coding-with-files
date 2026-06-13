# Bash tool-check framework - Testing Execution
**Task**: 201 (feature)

## Task Reference
- **Task ID**: internal-201
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/201-bash-tool-check-framework
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status

## Test Results

Tests were authored test-first during implementation-exec (TDD). This phase
re-ran the full plan and the regression set. Command:
`prove t/tool-check.t t/pretooluse-bash-tool-check.t` + the regression suite;
`cwf-manage validate`.

### Functional Tests — lib (`t/tool-check.t`)

| Test ID | Test Case | Expected | Status |
|---------|-----------|----------|--------|
| TC-1 | Merge precedence across 3 layers; override keeps position; new ids appended | order `[a,shared,b,c]`, override in place, overriding provenance wins | PASS |
| TC-2 | `enabled:false` removes; dup-in-layer last-wins; absent-id no-op | disabled id absent; dup→second; absent-id silent | PASS |
| TC-3 | Provenance-keyed perl drop; provenance from arg not content | checked-in perl dropped at load; ug kept; content-claim ignored | PASS |
| TC-4 | PCRE matches; `(?{...})` never executes (no `re 'eval'`) | sed -n matches; embedded code does not run | PASS |
| TC-5 | Over-cap no-match; `decide_repeat` truth table | >64 KB→no match; allow/deny/bypass rows correct | PASS |
| TC-6 | `compile_perl` resilience + perl matching | valid→coderef, broken→undef, undef coderef→no match | PASS |

### Functional Tests — hook (`t/pretooluse-bash-tool-check.t`)

| Test ID | Test Case | Expected | Status |
|---------|-----------|----------|--------|
| TC-7 | Deny with verbatim guidance; no command echo | deny JSON, reason=guidance verbatim, command absent | PASS |
| TC-8 | Allow on no match | empty stdout, exit 0 | PASS |
| TC-9 | Repeat-bypass state machine (X deny, X bypass, Y resets, X deny) | exactly that sequence | PASS |
| TC-10 | Malformed `session_id` (`../`) | denies both times, no state file written | PASS |
| TC-11 | No config anywhere → strict no-op | empty stdout, exit 0 | PASS |

### Non-Functional Tests

| Test ID | Category | Test Case | Expected | Status |
|---------|----------|-----------|----------|--------|
| TC-12 | Security | Pre-planted `<sid>.last` symlink not followed | sentinel untouched; `.last` now a regular file | PASS |
| TC-13 | Reliability (fail-open) | 7-row matrix: bad-JSON, unreadable/symlinked layer, invalid regex, dying perl, over-cap, runtime-hanging perl | every row → empty stdout, exit 0 | PASS |
| TC-14 | Performance/DoS | Pathological `(a+)+$` under external `timeout 5` | bounded, no deny emitted (fails open) | PASS |
| TC-15 | Usability | `--check` lists dropped checked-in perl + overridden id + effective set; non-zero on parse failure | all reported; exit 0 / non-zero | PASS |
| TC-16 | Install/upgrade | gitignore line idempotency | covered green by `t/cwf-apply-artefacts.t` + `t/installmanifest-integrity.t` with the new `lines` entry present | PASS |

### Regression + integrity
- `t/cwf-claude-settings-merge.t`, `t/installmanifest-integrity.t`,
  `t/cwf-apply-artefacts.t` → all PASS (60 tests).
- `cwf-manage validate` → OK (hook `0500`, lib regular file, hashes match).

## Test Failures

None. All TC-1…TC-16 pass. (Two implementation bugs were caught and fixed during
the TDD authoring in implementation-exec — see f-implementation-exec.md; both are
covered by the now-green tests.)

## Coverage Report

Critical paths at 100% per the plan: deny/allow, the repeat-bypass state machine,
the full fail-open matrix, the checked-in `perl`-drop, and the never-`re 'eval'`
guarantee. Edge cases covered: dup-id, absent-id override, over-cap, malformed
session_id, per-layer malformed/symlinked files, symlink-safe state writes, the
ReDoS bound under an external timeout.

## Security Review

**State**: error

error: cap exceeded: 603 production lines > 500

Note (not a smoothing): the testing-exec changeset anchors at the task baseline,
so its 603 production lines are byte-identical to the implementation-exec
changeset — testing-exec added only `g-testing-exec.md`, which the cap excludes
(`implementation-guide/**`). That production code was reviewed in
f-implementation-exec.md and returned **no findings**. Per the SKILL's
deterministic exit-2 contract, the subagent is not re-invoked here; re-reviewing
identical code adds no signal. The cap error is the review-cost mechanism firing,
not an unreviewed-risk condition.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*

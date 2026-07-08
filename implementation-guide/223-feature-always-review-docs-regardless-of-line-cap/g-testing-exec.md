# Always review docs regardless of line cap - Testing Execution
**Task**: 223 (feature)

## Task Reference
- **Task ID**: internal-223
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/223-always-review-docs-regardless-of-line-cap
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [ ] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [ ] Verify test environment ready
- [ ] Execute test cases sequentially
- [ ] Record pass/fail for each test
- [ ] Document failures with reproduction steps
- [ ] Update status to "Testing" when in progress, "Finished" when all pass

## Test Results

Command: `prove t/security-review-changeset.t t/exec-changeset-reviewers.t` →
**85 subtests, all PASS**. Full-suite regression `prove t/` → **76 files, 1008
tests, PASS**. `cwf-manage validate` → **OK**.

### Functional Tests

Each e-plan TC maps to the implementing subtest(s). All PASS.

| e-plan TC | Implementing subtest(s) | Result | Notes |
|-----------|-------------------------|--------|-------|
| TC-1 base-path markdown discounted | `TC-223-1` | PASS | 300 prose lines discounted, code under cap → exit 0; markdown still in the .out |
| TC-2 code under base-path still counts | `TC-223-2` | PASS | `docs-tree/tool.pl` trips cap → exit 2 (markdown-scoped, not tree) |
| TC-3 `.cwf/**/*.md` never discounted (HARD) | `TC-223-3` | PASS | base-path=.cwf rejected; `.cwf` markdown counts → exit 2 + diagnostic |
| TC-4 adversarial base-path fail-safe | `TC-223-4` | PASS | 10 malformed (incl. `content\n` proving `\A..\z`) + absent/empty silent |
| TC-5 deferred artefact on over-cap | `TC-223-5` | PASS | `-docs.out` docs-only, `wrote <D> doc lines` D>0, 0600, `cap exceeded:` on stderr |
| TC-6 configured-no-docs vs unconfigured | `TC-223-6` | PASS | present-0 (`wrote 0 doc lines`) ≠ absent (no doc line) |
| TC-7 cap boundary | `TC-CAPBOUNDARY` (existing) | PASS | 1000 passes, 1001 exits 2 — not duplicated |
| TC-8 deferred State recorded, agents on docs | `TC-223-A`, `TC-223-B` | PASS | both exec skills emit `## Changeset Review — Code (Deferred)` / `**State**: deferred`; bp gate treats docs as usable; live 5-reviewer MAP ran on the f-exec changeset (211 production) |
| TC-9 no stale wording | `TC-223-D` (+ `TC-223-C`) | PASS | no "one/exactly-one confirmation line" on helper/skills/doc; security-review.md owns the shared contract |

### Non-Functional Tests

| Axis | Coverage | Result |
|------|----------|--------|
| Security guardrail | `TC-223-3` (.cwf never discounted, HARD), `TC-223-4` (charset/anchor, fail-safe toward counting), `TC-SEED-GUARDRAIL` (live tree) | PASS |
| Reliability — exit-2→exit-1 safe collapse | `TC-CAP7` exercises the git-fatal→`capture_git` exit-1 mechanism the deferred doc-diff shares (surface, don't rescue); confirmed by robustness reviewer inspection | PASS |
| No world-read widening | `-docs.out` mode 0600 asserted in `TC-223-5` | PASS |
| Maintainability | `cwf-manage validate` OK after same-commit sha256 refresh | PASS |

## Test Failures

None.

## Coverage Report

Every KD5 guard branch exercised (charset, `.`/`./`, leading `./`, trailing `/`,
`//`, `..`, absolute, `.cwf`, absent, empty). All three doc-line outcomes covered
(present>0 / present-0 / absent). The `.cwf`-never-discounted control is a hard
assertion. No new uncovered paths; existing helper/skill/validate suites unbroken.

## Changeset Reviews

Testing-exec changeset: 19 files, 2185 lines, **211 production**, anchor `3f7bbed`.
Exit 0 → 2-reviewer MAP (security + best-practice) launched in parallel.

## Security Review

**State**: no findings

Only new command construction is list-form `capture_git` (no shell); doc-line count is
`tr/\n//` (no path-split); over-cap doc review widens coverage without a new injection
surface; the `doc_pathspec` guard is fail-safe toward counting. Tests cover the
adversarial base-path boundary.

```cwf-review
state: no findings
summary: Task 223 testing-exec — doc_pathspec base-path guard is defensively coded; all git via list-form; over-cap doc review widens coverage without new injection surface; tests cover the adversarial base-path boundary.
```

## Best-Practice Review

**State**: no findings

The Perl test files exemplify the applicable Perl testing guidance (failure-first,
boundary-rich TC-223-4 incl. `content\n` proving `\A…\z`, core `Test::More` +
`done_testing()`); the helper honours the regex-anchoring and ASCII-class guidance.
golang/postgres sources inapplicable (no Go/SQL in the diff).

```cwf-review
state: no findings
summary: testing-exec changeset (Perl tests + helper) is consistent with the applicable Perl best practices; golang/postgres sources not applicable.
```

## Status
**Status**: Finished
**Next Action**: /cwf-rollout 223
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See the Test Results and Changeset Reviews sections above — all TCs PASS, both
reviewers no findings.

## Lessons Learned
Proving an anchor is a security property (`\A…\z` vs `^…$`) is best asserted via the
diagnostic it fires, not via a coincidentally-unchanged exit code.

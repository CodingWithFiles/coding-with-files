# Fix normalise wrapped-field stranding - Testing Execution
**Task**: 208 (bugfix)

## Task Reference
- **Task ID**: internal-208
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/208-fix-normalise-wrapped-field-stranding
- **Template Version**: 2.1

## Goal
Execute the e-testing-plan.md cases (TC-1..TC-7) and confirm no regressions across the
full suite.

## Test Results

### Functional Tests
All TCs realised as the AC18d/e/f subtests in `t/backlog-manager.t` (see e-plan §
"Functional Test Cases"). Driven end-to-end via `run_bm` on `make_isolated` fixtures.

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | wrap → next field | Scope value folded to one `### Scope:`; `### Priority:` intact; no stranded fragment | as expected | PASS |
| TC-2 | wrap → blank + body prose | full `### Rationale:`; prose survives; nothing stranded | as expected | PASS |
| TC-3 | wrap → `---` separator | `### Detail:` folded; `---` dropped | as expected | PASS |
| TC-4 | wrap → end-of-file | `### Final:` folded; no trailing artefact | as expected | PASS |
| TC-5 | seed-empty field | `### Notes: …` single space after colon, no double | as expected | PASS |
| TC-6 | idempotency (extends AC18c) | second `normalise` byte-identical | as expected | PASS |
| TC-7 | single-line regression | `$LEGACY_BACKLOG` output unchanged; inner `while` no-ops | as expected | PASS |

Subtest roll-up:
- `AC18d (TC-1..TC-5)` — PASS (14 assertions)
- `AC18e (TC-6)` — PASS (3 assertions)
- `AC18f (TC-7)` — PASS (6 assertions)

### Non-Functional Tests
- **Out-of-scope items confirmed** (per e-plan): no CRLF round-trip fixture added
  (deliberate — `normalise` makes no CRLF byte-preservation promise); whitespace-only
  continuation unreachable (it is a blank-line terminator); no performance/security
  surface (deterministic in-memory fold).

## Test Run Summary
- `prove -lr t/backlog-manager.t`: **PASS** — 48 tests.
- `prove -lr t/`: **PASS** — 869 tests, 72 files, 0 failures.
- `cwf-manage validate`: **OK**.

## Validation Criteria (from e-testing-plan.md)
- [x] TC-1..TC-7 all pass
- [x] Full `prove -lr t/` green (no regressions)
- [x] Idempotent re-run byte-identical (TC-6)
- [x] `cwf-manage validate` OK after hash refresh

## Test Failures
None.

## Coverage Report
The fold's four terminators (next field / blank / `---` / EOF) plus the seed-empty edge
each have a dedicated fixture row and assertion (KD3 matrix). The single-line legacy path
is regression-guarded by AC18f and the pre-existing AC18a/b/c.

## Changeset Reviews (Step 8)
Both reviewers launched in parallel against the testing-exec changeset
(`security-review-changeset`: 11 files, 1069 lines, 61 production, anchor `c12b6c9`).
No `warning:` lines from either prep helper.

### Security Review
**State**: no findings

> Reviewed all five FR4 categories against the full changeset (helper edit, hash
> refresh, BACKLOG entry, wf docs, test fixture). **(a)** no shell invocation — pure
> in-memory string work; test harness reuses `run_bm`/`make_isolated`. **(b)** no new
> git/porcelain parsing; the three new regexes are line-anchored, bounded, single-pass
> (no catastrophic backtracking). **(c)** folded text is project-authored `BACKLOG.md`,
> rewritten to inert headings, never into LLM context or tool selection; wf files are
> documentation. **(d)** no `$ENV` reads; the `chmod 0444` repair is a narrative
> fix-on-sight note, not shipped code. **(e)** safe-here pattern recorded: the fold
> trims but does not escape the assembled value — safe because the sink is an inert
> `### Field: value` heading; the "inert display text" invariant is load-bearing for any
> future shell/path/exec/tool-selection sink.
> `summary: Pure in-memory text fold … no shell/git/env/LLM-context surface introduced; hash refresh accompanies the edit per convention. One safe-here pattern (unescaped single-line fold) recorded for future-sink audit.`

### Best-Practice Review
**State**: no findings

> Matched sources (`golang`, `postgres`) read cleanly but are language/DB-specific; the
> changeset is Perl + Markdown + JSON only, with no Go or SQL surface, so neither corpus
> applies and there are no divergences to report. The out-of-domain match is a standing
> `active-tags` artefact (the f-exec process note already flags it as a backlog
> candidate).
> `summary: Matched sources are Go and PostgreSQL best-practice corpora (both read cleanly); the testing-exec changeset is Perl/Markdown/JSON only with no Go or SQL surface, so neither corpus is applicable and there are no divergences.`

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Byte-budget gates conserve total bytes and are blind to misplace-not-delete corruption;
structural fixtures (one per fold terminator) catch it where byte accounting cannot. See
j-retrospective.md.

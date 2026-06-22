# exec-changeset reviewer agents - Testing Execution
**Task**: 210 (feature)

## Task Reference
- **Task ID**: internal-210
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/210-exec-changeset-reviewer-agents
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

### Automated — `t/exec-changeset-reviewers.t` (new, 11 subtests, all PASS)

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | Three lens agents exist, Bash-free | No `Bash` in frontmatter; `tools:` = precedent (`Read, Grep, Glob, LSP`); `effort: high`; name matches; shared-rules pointer | As expected for all three | PASS |
| TC-2 | Verdict block present, bp-input absent | `cwf-review` block + "Bash withheld" para present; no `{bp_context_file}` | As expected for all three | PASS |
| TC-3 | impl-exec Step 8 names five reviewers | Five `subagent_type`s; no stale "Two…reviewers"/"(0,1,or 2 calls)"; "(0 to 5 calls)" present (region-scoped) | As expected | PASS |
| TC-4 | testing-exec stays exactly two | Names security + best-practice; none of the three lens names anywhere | As expected | PASS |
| TC-5 | Guard matcher unchanged | Matcher directive = `cwf-security-reviewer-changeset` only; no lens names in guard | As expected | PASS |
| TC-6 | On-main wires all five sections | On-main clause names all five `## … Review` headings + "no findings: on main" | As expected | PASS |
| TC-7 | Empty-changeset wires all five | Security + 3 lens "empty changeset"; bp "no changeset to review" | As expected | PASS |
| TC-8 | New-agent verdict parses clean | Well-formed block → matching token via `security-review-classify` | `no findings`/`findings` as expected | PASS |
| TC-9 | Error isolation across five | One malformed of five → `error`; other four unaffected | `[no findings, no findings, error, findings, no findings]` | PASS |
| TC-10 | `cwf-manage validate` clean | Exit 0; no violation names the three new agents | As expected | PASS |

**Suite**: `t/exec-changeset-reviewers.t` 11/11. Full `prove t/` → **882 tests green**
(was 871; +11). `cwf-manage validate` → OK. `validate-agents.t`,
`validate-security.t`, `validate-security-coverage.t` all pass with the three new
`0444` agent entries present.

### Manual — output-level smoke (TC-11 / TC-12)

The live 5-reviewer MAP cannot run in this session: agent definitions and the
rewritten Step 8 are session-cached (load at session start), so the three new
reviewers and the five-reviewer flow are not yet active here. The deterministic
substrate the live MAP depends on is fully covered by TC-1…TC-10 above
(headings/`.out` wiring, classifier behaviour, error isolation, the on-main and
empty-changeset degradation branches). TC-11/TC-12 (a real exec run recording
five live `##` sections, and live error isolation) are deferred to the **next
session**, where the new agents are loaded — recorded here as the one residual
manual check, not a failure.

## Test Failures

None.

## Coverage Report

New behaviour covered by `t/exec-changeset-reviewers.t` (11 subtests) plus the
existing `t/security-review-classify.t` (classifier) and `t/validate-*.t`
(integrity/agent-frontmatter) suites. Live-MAP wiring is exercised end-to-end by
the next session's exec run (TC-11/12, manual).

## Security Review

**State**: no findings

Changeset: 17 files, 1822 lines (247 production), anchor 9972522, includes
uncommitted. The reviewer confirmed the only new executable code
(`t/exec-changeset-reviewers.t`) reuses the accepted single-quoted
`'$CLASSIFY' < '$path'` backtick idiom (byte-identical to
`t/security-review-classify.t`) with tool-internal, non-user-controlled
operands, and list-form spawn for `cwf-manage validate`. The three new agents
are read-only (no Bash/Edit/Write) — strictly narrower than the security
reviewer. No new injection/env/git-parsing/state-mutation surface. The hand-
authored hash entries are deterministically caught by `validate` (TC-10, exit 0)
— surfaced not smoothed.

## Best-Practice Review

**State**: no findings

Matched corpora: `golang`, `postgres` (2 entries), both read successfully (not
an error). The changeset is CWF Markdown/JSON + one core-Perl test — no Go or
SQL — so neither corpus contains applicable conventions. Project-level tag
false-positive for this diff (already logged: Task 209 backlog item).

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*

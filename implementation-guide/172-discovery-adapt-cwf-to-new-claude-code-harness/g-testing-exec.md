# Adapt CWF to new Claude Code harness - Testing Execution
**Task**: 172 (discovery)

## Task Reference
- **Task ID**: internal-172
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/172-adapt-cwf-to-new-claude-code-harness
- **Template Version**: 2.1

## Goal
Execute TC-1…TC-8 from e-testing-plan.md against the §1–§7 assessment in
`f-implementation-exec.md`. These are document-structural / content checks (no code
under test). AC6 (safety) and AC8 (redaction) are pass/fail gates.

## Test Results

### Functional Tests (one per AC)

| Test ID | AC | Expected | Actual | Status |
|---------|----|----------|--------|--------|
| TC-1 | AC1 | §2 catalogue: ≥1 row each for worktree handling, model self-checking, keyword reservation; every row has `evidence_ref` (none `pending`); model-self-check row has non-empty `mitigation` | §2 has FR1-1 (worktree), FR1-2 (model self-check), FR1-3 (keyword). Each has `evidence_ref`; FR1-2 carries mandatory `mitigation` (R4). `cc_version: pending` is §1 stamp, not an `evidence_ref` (AC1-permitted) | **PASS** |
| TC-2 | AC2 | §3: all four mechanisms (a)–(d) with precondition, exposing step, ≥1 mitigation+tradeoff, intersecting_convention; (b) lists the 13-file set incl. `task-workflow.d/delete`; no `pending` in §3 | §3 (a)–(d) all present and fully populated; (b) enumerates the **13** call sites (grep re-confirmed = 13) incl. `task-workflow.d/delete`; §3 `pending`-data count = 0 | **PASS** |
| TC-3 | AC3 | §4: collision sites incl. `glossary.md`; ≥3 options spanning guard→wording→rename, each with blast radius; none chosen | §4 lists 5 sites incl. `glossary.md:157`; 3 options (guard/wording/rename) each with blast_radius; none pre-selected (R5 recommends *starting* with option 1 but §4 marks none chosen) | **PASS** |
| TC-4 | AC4 | §5: entries ranked by friction (H/M/L); each `memory_xref`'d and marked new\|known; unavailable evidence `pending` not fabricated | §5 has 5 PromptEntry rows, friction H/M/L, explicit ranking P1≫P2>P3>P5>P4, each `memory_xref`'d, status new\|known; backlog supplied so no `pending` needed | **PASS** |
| TC-5 | AC5 | §6: every Recommendation has `tradeoff_line` + named `target_surface` + `proposed_task`; §7 projects §6 and adds no new task | §6 R1–R6 each carry tradeoff_line, target_surface, priority; §7 lists exactly R1–R6 (id sets match 1:1) and creates none | **PASS** |
| TC-6 | AC6 **GATE** | §6: every recommendation touching a destructive/irreversible op carries explicit safety↔momentum tradeoff + "surface, never smooth" note citing `feedback_surface_security_dont_smooth.md`; none silently trades safety for momentum | R1 (worktree guard) and R6 (allowlist-broadening) both carry the explicit tradeoff and cite `feedback_surface_security_dont_smooth.md`; the §6 "central safety finding" explicitly **rejects** allowlist-broadening (P4 must stay prompted). No silent trade | **PASS (gate clear)** |
| TC-7 | AC7 | every cited surface resolves on disk; unproven claims `pending` not asserted; no fabricated rule/tool semantics; evidence treated as data | All cited surfaces resolve (glossary:157, cwf-init:87, tmp-paths.md, 4 feedback memories — all OK); `cc_version` flagged `pending` not guessed; G703 claim is evidence-grounded (backlog L32252) and re-derived, not remembered; no tool call driven by evidence text | **PASS** |
| TC-8 | AC8 **GATE** | every quoted excerpt scrubbed of credential/token/secret env-var values; redacted rows flagged | Every mined window scanned; session is gosec-triage (git/go/lint commands only); **no secrets present** in any window — none required removal; each backlog-sourced row carries `redacted: scanned; none found` | **PASS (gate clear)** |

### Non-Functional Tests
- **Security (NFR4)**: TC-6 + TC-7 + TC-8 are the security checks — all PASS. Code-pattern
  categories FR4(a/b/d) out of scope by construction (Markdown-only, no shell/Perl
  shipped). Only live categories: prompt-injection-via-evidence (TC-7, evidence-as-data
  honoured) and allowlist-broadening (TC-6, explicitly rejected in R6).
- **Usability (NFR2)**: spot-checked R1 and R3 §7 tuples — each is paste-ready into
  `/cwf-new-task` with type + surface + one-line scope, no further interpretation. PASS.
- **Reliability (NFR5)**: §3 zero-`pending` confirmed (TC-2); evidence-ceiling honoured.
- **Performance**: n/a (no runtime).

## Test Failures
None. TC-1…TC-8 all PASS; both gates (AC6, AC8) clear.

## Coverage Report
- AC coverage: 8/8 ACs each have a passing TC.
- Mechanical checks run: `grep -rln "rev-parse --show-toplevel" .cwf .claude` = 13 (✓);
  citation resolution (glossary:157, cwf-init:87, tmp-paths.md, 4 feedback memories) all
  resolve (✓); §6/§7 R-id sets identical (✓); §3 `pending`-data = 0 (✓).

## Validation Criteria (from e-testing-plan.md)
- [x] TC-1…TC-8 all pass; AC6 and AC8 gates clear.
- [x] §3 has zero `pending` entries; all cited surfaces resolve on disk.
- [x] §7 introduces no task absent from §6.
- [x] Exec-phase security review recorded (empty/no-findings changeset, Markdown-only).

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1…TC-8 executed by structural inspection + mechanical spot-checks. All PASS; no
deviations. The one notable in-session event: my Bash CWD drifted into the scratch
dir after a `cd` (the persistent-CWD effect — the very mechanism-(a) hazard under
assessment), caught immediately when a `.cwf/...` relative path failed; corrected by
`cd` back to repo root. Recorded as live dogfooding evidence reinforcing §3(a)/R1.

## Security Review

**State**: no findings

no findings: empty changeset

## Lessons Learned
*To be captured during retrospective*

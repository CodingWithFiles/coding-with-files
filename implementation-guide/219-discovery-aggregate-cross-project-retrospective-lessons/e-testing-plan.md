# Aggregate cross-project retrospective lessons - Testing Plan
**Task**: 219 (discovery)

## Task Reference
- **Task ID**: internal-219
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/219-aggregate-cross-project-retrospective-lessons
- **Template Version**: 2.1

## Goal
Validate the deliverable (`f-implementation-exec.md`) and its scratch artefacts
against the six ACs and the injection-containment / no-silent-truncation guarantees.

## Test Strategy
### Test Levels
This is an assessment-only discovery: there is no shipped code to unit-test. "Tests"
are **deterministic assertion checks** over the produced artefacts (`SCRATCH/survey.json`,
`SCRATCH/digests/*.json`, `SCRATCH/friction-overlay.json`, `f-implementation-exec.md`),
run manually in g-testing-exec. Each maps to an AC or a stated guarantee.

### Test Coverage Targets
- **Every AC (AC1–AC6)** has ≥1 passing assertion check — 100% AC coverage required.
- **Every stated guarantee** (reduce-stage untrusted-string handling, no silent
  truncation, partial-failure gap-logging) has a check.
- No numeric %-coverage target applies (no code paths).

## Test Cases
### Functional Test Cases
- **TC-1 (AC1 — coverage reconciliation)**
  - **Given**: `survey.json` with the live denominator D (counting **both**
    `h-` and `j-retrospective.md`).
  - **When**: computing `sum(retros_scanned + retros_stubbed)` over merged digests
    `+ sum(surveyed retro_count of each gap project)`.
  - **Then**: the total equals D exactly; any delta and every survey-level/coverage
    gap is logged in §1. The h-convention corpus is included, not dropped.
- **TC-2 (AC2 — friction overlay + attribution)**
  - **Given**: `friction-overlay.json` + §1/§2 of the deliverable.
  - **When**: inspecting each session-log and LMM signal.
  - **Then**: each carries a source attribution; any unavailable/empty source appears
    in `gaps[]` and is surfaced, not omitted.
- **TC-3 (AC3 — axis coverage)**
  - **Given**: all findings.
  - **When**: checking axis tags.
  - **Then**: no finding is untagged; a per-axis rollup exists for all three axes
    (token, permission, sdlc).
- **TC-4 (AC4 — corroboration rule)**
  - **Given**: findings labelled "general".
  - **When**: checking corroboration.
  - **Then**: each lists ≥2 **external** corroborating projects; this-repo counts as
    ≤1; single-project findings are visibly flagged.
- **TC-5 (AC5 — novelty classification)**
  - **Given**: each candidate recommendation.
  - **When**: checking its novelty label against the baseline (`MEMORY.md`, feedback
    memories, `error-patterns.md`, `docs/conventions/`, `.cwf/docs/conventions/`).
  - **Then**: each is net-new / under-enforced / already-codified; every
    "under-enforced" cites ≥1 corpus violation; no recommendation restates a codified
    rule without the enforcement-gap label; already-codified-and-enforced are dropped.
- **TC-6 (AC6 — ranking + shape)**
  - **Given**: the final recommendation set.
  - **When**: checking order and fields.
  - **Then**: ordered impact-desc, effort-asc; each carries axis, impact, effort,
    safety↔momentum tradeoff, a one-line follow-up task title, and source attribution.

### Non-Functional Test Cases
- **TC-7 (Security — injection containment)**: No corpus-derived string is acted on as
  an instruction; spot-check that `followup_task_title`s are descriptive (not injected
  imperatives) and that every `SCRATCH/digests/*.json` filename derives from the
  dispatch key (no `../`-escaped or out-of-set file exists).
- **TC-8 (Reliability — no silent truncation)**: For every digest where
  `lessons_total_found > len(lessons)`, the dropped count is recorded; any capped or
  gapped coverage is logged in §1.
- **TC-9 (Reliability — partial-failure tolerance)**: Any failed extraction/absent
  source is present as a logged gap and the run completed (not aborted). Observational
  if no failure occurred — then assert "0 gaps" is itself stated.

## Test Environment
### Setup Requirements
- Read-only access to the 11 project roots' retrospectives and `~/.claude/projects/*`
  session logs; LMM scoped to `github@mattkeenan.net`. No test database (assessment is
  read-only; the corpus is never mutated).
- The scratch artefacts produced by the exec phase are the inputs under test.

### Automation
- Manual assertion checks in g-testing-exec (jq/grep over the JSON artefacts + a read of
  the deliverable). No CI integration — one-shot discovery.

## Validation Criteria
- [ ] TC-1…TC-6 pass (all six ACs)
- [ ] TC-7 pass (injection containment)
- [ ] TC-8, TC-9 pass (no silent truncation; partial-failure gaps logged)
- [ ] Every guarantee traced to a passing check

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

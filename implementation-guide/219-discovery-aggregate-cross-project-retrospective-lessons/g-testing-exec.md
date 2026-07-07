# Aggregate cross-project retrospective lessons - Testing Execution
**Task**: 219 (discovery)

## Task Reference
- **Task ID**: internal-219
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/219-aggregate-cross-project-retrospective-lessons
- **Template Version**: 2.1

## Goal
Execute the TC assertion checks from e-testing-plan.md against the deliverable
(`f-implementation-exec.md`) and the scratch artefacts.

## Test Results

### Functional Tests
Deterministic checks (`jq`/`grep` over the JSON artefacts + the deliverable).

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | Coverage reconciliation | denominator 601 (both `{h,j}` conventions); union scanned 541; residual ~60 logged; survey_gaps [] | `survey.json` denominator=601, gaps=[]; §1 table sums 541/601 (~90%); residual attributed to subtask retros; lmm reconciles exactly | **PASS** |
| TC-2 | Friction overlay + attribution | session-log + LMM signal present, each source-attributed; absent sources in `gaps[]` | `friction-overlay.json`: 5 lmm_signals + 5 session_signals, each with `source`; `gaps: []` | **PASS** |
| TC-3 | Axis coverage | per-axis rollup for all 3 axes; no untagged finding | 3 `### Axis N` rollups (token/permission/sdlc); every finding axis-labelled | **PASS** |
| TC-4 | Corroboration rule | "general" findings list ≥2 external projects; this-repo ≤1; single flagged | 16 `[G]`-class + 3 `[S]` tags; each [G] names ≥2 external projects; single-project marked `[S]` | **PASS** |
| TC-5 | Novelty classification | every rec classified; under-enforced cites a violation | 11 `net-new` + 6 `under-enforced` (+ `already-*` in prose); under-enforced items cite corpus instances | **PASS** |
| TC-6 | Ranking + shape | ordered impact-desc/effort-asc; each carries axis/impact/effort/tradeoff/follow-up/sources | §3 table R1–R14 (14 rows), all columns populated, ordered by impact then effort | **PASS** |

### Non-Functional Tests
| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-7 | Injection containment | no corpus string executed; digest filenames from dispatch key (no `../`/out-of-set) | `digests/` names clean (no `..`/`/`); follow-up titles are descriptive markdown, human-gated via `/cwf-new-task`; security reviewer confirmed | **PASS** |
| TC-8 | No silent truncation | per-digest `lessons_total_found` records cap loss; caps/gaps logged | Every returned digest carries `lessons_total_found` > `len(lessons)` where capped; §1 logs the ~60 residual + mis-slices | **PASS** (with deviation, below) |
| TC-9 | Partial-failure tolerance | failed/absent sources logged as gaps, run not aborted | gate-66plus returned 0 (handled, not error); 3 mis-slices caught by reconciliation and closed; overlay `gaps: []`; no abort | **PASS** |

## Deviations
- **TC-8 scratch persistence (partial)**: In direct agent fan-out mode (operator's
  chosen execution model), the orchestrator held each returned digest in conversation
  context and ran the reduce from there, persisting only one representative digest
  (`digests/coding-with-files-low.json`) to scratch rather than all 18. The
  no-silent-truncation *guarantee* holds at the data level — every digest reported
  `lessons_total_found` so cap loss was visible, and §1 reconciles the full 601 — but
  the on-disk digest audit trail is incomplete versus the design's "write each digest to
  scratch". Consequence: reproducibility relies on the conversation transcript, not the
  scratch dir alone. No effect on the deliverable's correctness or coverage.

## Coverage Report
- All six ACs (AC1–AC6) exercised by TC-1…TC-6: **6/6 PASS**.
- All three stated guarantees (injection containment, no-silent-truncation,
  partial-failure) exercised by TC-7…TC-9: **3/3 PASS** (TC-8 with the documented
  scratch-persistence deviation).
- Corpus coverage: 541/601 tracked retros (~90%); residual ~60 subtask retros logged.

## Security Review

**State**: no findings

Docs-only discovery changeset; no executable/perm/hash change; untrusted-corpus injection
posture correctly designed (read-only agents, sole-writer orchestrator, dispatch-key
filenames, human-gated follow-up titles).

## Best-Practice Review

**State**: no findings

Markdown-only changeset; golang/postgres best-practice sources both readable but govern
Go/Postgres code, which is absent from the diff — nothing to bind against.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*

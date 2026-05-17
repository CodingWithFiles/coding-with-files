# Document Dead Code Audit Methodology - Testing Execution
**Task**: 148 (chore)

## Task Reference
- **Task ID**: internal-148
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/148-document-dead-code-audit-methodology
- **Template Version**: 2.1

## Goal
Execute TC-1 through TC-10 from e-testing-plan.md; record results, surface refinement bound if any direction fails.

## Fixture Record (from f-exec Step 1)

- **Fixture A (false-positive direction, TC-1)**: `workflow_file_mappings()`. Pre-removal definition was in TaskContextInference.pm-era library; live caller was the script `context-inheritance-v2.0`. Source of evidence: `implementation-guide/51-bugfix-dead-code-removal/j-retrospective.md:69-71`.
- **Fixture B (false-positive direction, TC-2)**: `format_error()`. Pre-removal definition in `Common.pm` era; live caller was internal to the same file (and the function had POD documentation per retrospective line 89). Source: `j-retrospective.md:70`.
- **Fixture C (positive control, TC-3)**: `_format_uncorrelated()`. Removed in commit `6ad9ce3` (Task 51, 2026-02-10). Appearance sites: `CHANGELOG.md:2320,:2955`; `implementation-guide/32-feature-task-tracking-using-inference-scoring/c-design-plan.md:192,202` and `f-implementation-exec.md:89`; `implementation-guide/37-bugfix-fix-inconclusive-inference-output-format/d-implementation-plan.md:19,30,49,50,149,153,175` and `c-design-plan.md:46,53`. All historical-doc mentions (CHANGELOG removal/deprecation records + pre-removal planning snapshots).

## Test Results

### Functional Tests — Methodology Self-Test (TC-1 to TC-3)

| Test ID | Fixture | Walk of 6 Categories | Verdict | Status |
|---------|---------|----------------------|---------|--------|
| TC-1 | `workflow_file_mappings()` | (1) no same-package direct caller documented; (2) **HIT** — `context-inheritance-v2.0` is a script consuming the library, Category 2's explicit "script-to-library" example in `.cwf/docs/dead-code-audit.md:55-69`; (3) no; (4) no; (5) no; (6) not advertised | ALIVE — kept alive by Category 2 | PASS |
| TC-2 | `format_error()` | (1) — / (3) **HIT** — used internally within `Common.pm` per Category 3's exact pattern (`.cwf/docs/dead-code-audit.md:71-79`); (6) **HIT** — POD documentation per retrospective:89 makes this Category 6 advertised surface, *never dead even with no internal callers*; (2),(4),(5) no | ALIVE — kept alive by Categories 3 AND 6 | PASS |
| TC-3 | `_format_uncorrelated()` (currently removed) | (1) `grep -rn '_format_uncorrelated' .cwf/ --include='*.pm' --include='*.pl'` → 0 hits; (2) 0 hits; (3) N/A (definition gone); (4) `grep -rn '"_format_uncorrelated"' .` finds historical-doc mentions only, no dispatch tables; (5) no tests; (6) Category 6 carve-out distinguishes *advertisement* (current shipping API) from *historical mention* (CHANGELOG removal entry + pre-removal planning snapshots) per `.cwf/docs/dead-code-audit.md:107-110` — appearances correctly classified as historical | DEAD — all 6 categories return no live caller; appearance/caller distinction works | PASS |

**False-positive direction (TC-1, TC-2)**: methodology surfaces ≥1 real caller in both cases. Applied honestly, would have stopped Task 51's removal.

**Positive-control direction (TC-3)**: methodology distinguishes appearance from caller-ness. The Category 6 carve-out wording ("Historical mentions are appearance, not advertisement") is the load-bearing sentence; without it, a naïve walker could mis-flag CHANGELOG/planning-doc mentions as advertised surface.

**Refinement attempts**: 0. Both directions passed first walk; D6's 3-strikes bound not consumed.

### Plan-deviation note (TC-1, TC-2 categories)

e-testing-plan.md TC-1 predicted Category 3 catching `workflow_file_mappings()` and TC-2 predicted Category 2 catching `format_error()`. Actual catches are the reverse — TC-1 caught by Category 2, TC-2 caught by Category 3 (plus Category 6 from POD). The pass condition in each TC is "at least one category surfaces a real caller", which is satisfied; only the *predicted* category was wrong. No retest needed.

### Functional Tests — Integration Points

| Test ID | Command | Expected | Actual | Status |
|---------|---------|----------|--------|--------|
| TC-4 | `grep -F '.cwf/docs/dead-code-audit.md' .claude/agents/cwf-plan-reviewer-misalignment.md` | ≥1 line, target exists, declarative phrasing | 1 match (line 22: "consult `.cwf/docs/dead-code-audit.md` § Plan-time heuristics"); target exists; phrasing is criteria-shaped not imperative | PASS |
| TC-5 | `grep -F '.cwf/docs/dead-code-audit.md' .cwf/templates/pool/i-maintenance.md.template` | ≥1 line, last bullet of `### Preventive Maintenance`, target exists | 1 match; located at end of Preventive Maintenance list (line 42); target exists | PASS |

### Functional Tests — Document Integrity

| Test ID | Check | Expected | Actual | Status |
|---------|-------|----------|--------|--------|
| TC-6 | In-doc anchor resolution | All `(#...)` resolve to `## `/`### ` headings | 3 unique anchor targets (`#plan-time-heuristics`, `#maintenance-time-audit`, `#caller-categories`) — all match `## Plan-time heuristics` (line 112), `## Maintenance-time audit` (line 140), `## Caller categories` (line 42) | PASS |
| TC-7 | Cross-file `.md` references | All paths exist | Canonical refs `docs/dead-code-audit-perl.md`, `.claude/agents/cwf-plan-reviewer-misalignment.md`, `.cwf/templates/pool/i-maintenance.md.template`. Recipes refs `.cwf/docs/dead-code-audit.md`. All exist | PASS |

### Non-Functional Tests

| Test ID | Check | Expected | Actual | Status |
|---------|-------|----------|--------|--------|
| TC-8 | `wc -l .claude/agents/cwf-plan-reviewer-misalignment.md` | < 55 | 41 | PASS |
| TC-9 | `wc -l docs/dead-code-audit-perl.md` | ≤ 40 (D1 anti-bloat) | 30 | PASS |
| TC-10 | `.cwf/scripts/cwf-manage validate` | Exits 0 | `[CWF] validate: OK` | PASS |

## Test Failures

None.

## Coverage Report

- Methodology coverage: both directions tested (TC-1, TC-2 = false-positive; TC-3 = positive control). 100% per e-plan §Test Coverage Targets.
- Reference integrity: both integration points greppable + target exists (TC-4, TC-5).
- Document integrity: 100% of in-doc anchors resolve; 100% of cross-file `.md` references exist (TC-6, TC-7).

## Security Review

**State**: no findings

no findings
Testing-phase changeset contains only two doc additions (an agent-procedure pointer and a maintenance-template bullet) referencing `.cwf/docs/dead-code-audit.md`; no executable surface, no input handling, no auth/permission/secret/injection vectors introduced.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 148
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*

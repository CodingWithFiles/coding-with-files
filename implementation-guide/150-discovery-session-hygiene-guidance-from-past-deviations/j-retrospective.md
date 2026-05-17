# Session hygiene guidance from past deviations - Retrospective
**Task**: 150 (discovery)

## Task Reference
- **Task ID**: internal-150
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/150-session-hygiene-guidance-from-past-deviations
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-17

## Executive Summary
- **Duration**: single session, ~2–3 hours wall-clock active work spread across one calendar day (estimate: 2–4 hours — within range)
- **Scope**: Discovery task — evidence-based audit of session-hygiene deviations + production of installed CWF guidance doc. Scope held: one canonical doc, one CLAUDE.md `## Conventions` consumer, one BACKLOG retirement. No scope creep.
- **Outcome**: Success. All 16 test cases pass; BACKLOG entry retired; guidance doc (59/60 lines) wired into the always-reloaded preamble surface.

## Variance Analysis
### Time and Effort
- **Estimated** (a-task-plan §"Original Estimate"): 2–4 hours total, complexity Medium (signal density in audit was the main variable).
- **Actual**: Within range. Audit took less time than budgeted because the sparse-signal contingency was triggered cleanly (4 + 1 patterns from 3 sources, LMM unavailable but threshold met without it). Plan-review map/reduce added several minutes per b/c/d phase but caught load-bearing defects.
- **Variance**: No notable variance.

### Scope Changes
- **Additions**: None. The 5-pattern audit (P1–P5) and 4-section doc shape were both fixed by the plan phases and held.
- **Removals**: LMM corpus search dropped from the audit (Risk H1 mitigation invoked — `mcp__lmm__search_semantic` returned `User not found`). Recorded as R-LMM follow-up in b-requirements §Recommendations; not deferred work, just out-of-scope tracking.
- **Impact**: None on deliverable quality — sparse-signal threshold still met from retrospectives + memory files. R-LMM is a separate-task quantitative re-audit, not a gap in this task's guidance.

### Quality Metrics
- **Test Coverage**: 100% — every FR1–FR4 sub-AC, every NFR (NFR2.1, NFR4.1–NFR4.3), and every d-plan validation gate has at least one passing TC.
- **Defect Rate**: 0 test failures. One plan-text defect (d-plan referenced `.cwf/scripts/command-helpers/cwf-manage`; actual path `.cwf/scripts/cwf-manage`) — corrected at exec time with no behaviour impact.
- **Performance**: N/A (documentation only).

## What Went Well
- **Plan-review map/reduce earned its keep across all three plan phases.** Caught: M1 wiki-link misalignment in a-task-plan (fixed in b-phase commit), the structural-mechanism reframe of D2 (CLAUDE.md is reloaded per turn — not "compaction preserves the bullet"), the workflow-state authoritativeness FR (Security F3 → FR3.AC3.3), the inline-principle requirement (Security F1 → NFR4.1, because the principle's prior residence is operator-private memory), and the load-bearing self-application risk (F5 on c-design — the guidance documents a failure mode that affects itself, motivating AC4.6).
- **Sparse-signal contingency was actually invoked and behaved correctly.** LMM corpus unavailable → fall back to retrospectives + memory files → still meet ≥3-pattern threshold (4 clear + 1 named residue). The a-plan threshold was real, not theatre.
- **Defender-framing first-filter regex auto-passed** because of natural prose adjacency (backticks, hyphens) around `/clear`. The doc didn't need to contort to evade the filter — defender-framed phrasing produced filter-clean output by construction.
- **Test cases specified partial-match vs exact-line semantics throughout**, carrying forward the Task 149 retrospective lesson cleanly. Made g-exec mechanical rather than interpretive.

## What Could Be Improved
- **d-plan helper-path defect**: referenced `.cwf/scripts/command-helpers/cwf-manage`; actual path is `.cwf/scripts/cwf-manage`. The plan-review subagents didn't catch it because they reviewed the *plan logic*, not whether referenced helper paths exist. A cheap improvement: a plan-review check that greps any referenced `.cwf/scripts/...` path against the filesystem at plan-time, as a separate dimension.
- **Two `; echo "exit=$?"` slips during exec.** The no-echo-EXIT feedback memory exists; the bash-habit leak still happened twice in this session. Surfacing on every Bash call (not just review) would help.

## Key Learnings
### Technical Insights
- **CLAUDE.md `## Conventions` is the right surface for cross-`/compact` durability**, not because compaction preserves it, but because the harness reloads CLAUDE.md fresh on every turn. The mechanism is structural; the consumer's persistence is incidental to the reload, not to compaction logic.
- **Anti-pattern enumeration belongs in-doc, not by-omission.** §3 explicitly lists `recompute-hashes`, `validate --fix`, `validate --ignore`, `/clear`-as-gate-bypass under "Do not propose". Future readers see the boundary; the write-time grep verifies anti-pattern strings appear only in defender-framed context.

### Process Learnings
- **Discovery-task workflow (all 8 of a/b/c/d/e/f/g/j) is well-shaped for evidence-based work.** The b-phase audit feeds c-design's section-count decision, which feeds d-plan's line-budget allocation, which feeds e-testing's per-TC pass conditions. Each phase consumes a concrete output of the previous one; no phase is filler.
- **Plan-review's value scales with the load-bearing-ness of the artefact.** For a 59-line doc with hard security constraints (NFR4.1–4.3 + AC4.6 self-application), 4 subagents catching 5 distinct defects across 3 phases is a clear positive.

### Risk Mitigation Strategies
- **Risk H1 (sparse evidence) mitigation worked**: explicit "≥3 distinct patterns or pivot to principle-based" threshold + triangulation across 3 sources. When LMM dropped out, the other two sources covered the gap.
- **Risk H2 (orphan doc) mitigation forced the AC4.2 design choice**: requiring ≥1 advertised consumer up-front prevented producing a doc that no skill or convention pointed to.

## Recommendations
### Process Improvements
- **Plan-time helper-path verification**: add a plan-review pass (or a helper) that resolves any `.cwf/scripts/...` path referenced in d-plan against the filesystem. Cheap; catches the class of defect this task hit.
- **Echo-EXIT detection in the harness layer (or a hook)**: the feedback memory exists but the habit leak still happens. Mechanical detection (post-bash-call grep for `echo.*EXIT|echo.*\$\?`) would close the gap.

### Tool and Technique Recommendations
- **`backlog-manager retire` is the right shape.** Atomic BACKLOG removal + CHANGELOG append in one operation, idempotent-ish, returns clean exit. No hand-editing required, no two-step inconsistency window.
- **Pre-extracting target sections to /tmp via a small Perl helper** (used in g-exec) was lower-friction than per-section greps with backtick-laden headings in shell quoting. Reusable pattern for any TC suite that targets specific sections of a doc.

### Future Work
- **R-LMM follow-up**: re-audit when LMM access is restored. Separate BACKLOG entry "Research Compaction Failure Frequency via LMM Memory Analysis" exists; if picked up, fold quantitative findings back into session-hygiene.md.
- **Hash drift on `.claude/agents/cwf-plan-reviewer-misalignment.md`** (permissions 0600 vs expected 0444) is a Task 149 carry-over still present in the validate baseline. A separate BACKLOG entry covers it ("Make `.claude/agents/cwf-plan-reviewer-misalignment.md` enforced-permission survive git checkout"). Not absorbed into this task per the hash-update rule.
- **Helper-path verification gate**: file as Low-priority chore if the harness-level fix is not pursued.

## Status
**Status**: Finished
**Next Action**: Task complete; suggest merge to main (human decision).
**Blockers**: None identified
**Completion Date**: 2026-05-17
**Sign-off**: Task 150 retrospective complete

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`, `b-requirements-plan.md`, `c-design-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md`
- Execution: `f-implementation-exec.md`, `g-testing-exec.md`
- Commits on task branch: `1dd97ff` (a) → `6dc793d` (b) → `dec44d0` (c) → `19b0deb` (d) → `dfe3de9` (e) → `dcc1222` (f) → `a150c81` (g) → this commit (j)
- Produced artefact: `.cwf/docs/conventions/session-hygiene.md`
- Wiring: `CLAUDE.md` `## Conventions` `**Session Hygiene**` bullet (after `**Hash Updates**`)
- BACKLOG → CHANGELOG move: "Add Session Hygiene Guidance to CWF Documentation" retired under Task 150

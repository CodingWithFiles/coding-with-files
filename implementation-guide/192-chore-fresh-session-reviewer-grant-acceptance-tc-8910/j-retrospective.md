# Fresh-session reviewer grant acceptance (TC-8/9/10) - Retrospective
**Task**: 192 (chore)

## Task Reference
- **Task ID**: internal-192
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/192-fresh-session-reviewer-grant-acceptance-tc-8910
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-11

## Executive Summary
- **Duration**: <0.5 day (estimated <0.5 day; on estimate).
- **Scope**: Run Task 186's three deferred fresh-session acceptance checks (TC-8/9/10) and
  retire the backlog item. No scope change; verification only, no production code.
- **Outcome**: Success. PG (freshness) + TC-8 + TC-9 + TC-10 + TC-REG all PASS. The Task 186
  reviewer-agent grant (`tools: Read, Grep, Glob, LSP, Bash`) is confirmed live in the registry
  and the reviewers function. Backlog item retired against Task 192; CWF's review gate is
  verified intact.

## Variance Analysis
### Time and Effort
- **Estimated**: planning + d/e plans + f/g exec + j, all under half a day combined.
- **Actual**: on estimate. The only unplanned work was fixing the self-inflicted invalid-status
  validation failure (minutes).
- **Variance**: negligible.

### Scope Changes
- **Additions**: none to the verification target. One incidental fix: corrected
  `**Status**: Planning` → `Finished` in the a/d/e plan files after TC-REG flagged it.
- **Removals**: none.
- **Impact**: none on outcome; the fix kept `cwf-manage validate` clean.

### Quality Metrics
- **Test Coverage**: PG + TC-8/9/10 + TC-REG = 4/4 functional + gate PASS; critical path
  (grant live on all five reviewers) 100% via TC-8.
- **Defect Rate**: one self-inflicted validation failure (invalid status value), caught by
  TC-REG before commit and fixed in-phase. Zero defects in the verification target.
- **Performance**: N/A.

## What Went Well
- **The freshness gate's discriminating signal worked.** Rather than a naive `registry ==
  on-disk` equality, the plan keyed on "restricted set vs pre-change all-tools inheritance" —
  which actually distinguishes a fresh session from a stale one. The registry showed the
  restricted set, giving a sound in-session pass.
- **Dog-fooding produced free evidence.** The d-phase Step 8 plan review *is* a live exercise
  of the four plan reviewers, so TC-9 was satisfied by real work already done rather than a
  contrived second run. Likewise the f/g security reviews *are* TC-10.
- **Plan review caught a real defect pre-exec.** The robustness reviewer flagged that TC-9's
  original "reaches markdown-reader" signal is not caller-observable; reframing to "completes
  with no tool-denied error" made the criterion testable.
- **TC-REG did its job.** A regression guard on a verification-only task still caught a
  validity error introduced by the task's own doc edits.

## What Could Be Improved
- **Skill templates steer toward an invalid status value.** Setting `**Status**: Planning`
  felt natural for a plan phase, but `Planning` is not in `cwf-project.json:status-values`, so
  validate failed. This is a known, already-filed backlog item — but it bit again here,
  confirming it is worth fixing rather than leaving as a watch-item.

## Key Learnings
### Technical Insights
- A subagent's internal tool-call trace is **not** observable to the caller — only its final
  text is. Any acceptance criterion phrased as "the agent used tool X" is untestable from the
  parent; phrase it as an observable outcome (completes, returns well-formed output, no
  tool-denied error) instead.
- A diff-embedded `cwf-review` block cannot pollute `security-review-classify`: the classifier
  reads the *subagent's stdout*, never the changeset. The g-phase reviewer confirmed this when
  the changeset carried the f-phase verdict block as file content.

### Process Learnings
- For verification-only tasks, the CWF f/d/g phases map cleanly onto evidence-gather / assert /
  record — and the mandatory plan-review and security-review steps double as the live exercises
  the verification needs. Lean on them rather than staging separate isolated runs.

### Risk Mitigation Strategies
- Recording the freshness *residual* (strictest guarantee = brand-new session) while accepting
  the in-session run kept the decision honest and surfaced rather than smoothed.

## Recommendations
### Process Improvements
- None new. The "Planning status mismatch" backlog item should be prioritised: it has now
  caused a validate failure in a live task, not just a theoretical mismatch.

### Tool and Technique Recommendations
- When authoring acceptance criteria for agent behaviour, default to caller-observable signals.

### Future Work
- The closely-related **"Lint `.claude/agents/*.md` for the silently-ignored `allowed-tools:`
  key"** (Medium) is the natural successor — it productionises the insight this task verified,
  guarding the grant against silent regression. No follow-up task created here; left in the
  backlog for separate scheduling.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-11
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Links to planning documents and artefacts
- Links to implementation PRs and commits
- Links to test results and quality reports
- Links to deployment and monitoring dashboards

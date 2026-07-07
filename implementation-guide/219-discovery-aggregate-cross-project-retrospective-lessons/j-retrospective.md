# Aggregate cross-project retrospective lessons - Retrospective
**Task**: 219 (discovery)

## Task Reference
- **Task ID**: internal-219
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/219-aggregate-cross-project-retrospective-lessons
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-07

## Executive Summary
- **Duration**: ~1 session (estimate: 1–2 days; within estimate).
- **Scope**: Mine the lessons-learnt signal across all CwF-using projects (plus session
  logs and LMM) → corroborated, novelty-filtered, per-axis improvement recommendations.
  Final scope matched plan; corpus turned out larger than the initial snapshot (601 vs
  the j-only ~558, once the `h-retrospective.md` convention was included).
- **Outcome**: Success. 541/601 tracked retros digested (~90%), 3 friction axes, 14
  ranked recommendations, 14 seeded follow-up tasks. Assessment-only (no CwF code
  changed), all five exec reviewers and both testing reviewers `no findings`.

## Variance Analysis
### Time and Effort
- **Estimated**: 1–2 days (assessment + write-up).
- **Actual**: ~1 session, agent-paced. The map-reduce fan-out (19 agents total: 15 shard
  extractors + session miner + 3 gap-fillers) compressed wall-clock; the reduce and
  write-up dominated.
- **Variance**: within estimate. Per the study's own S7 finding, calendar estimates are
  noise for agent-paced work — complexity was High, which held.

### Scope Changes
- **Additions**: 3 gap-fill extractors added mid-exec after reconciliation caught shard
  mis-slicing (gate 66–101, lmm 1–52, cwf 196+). Not a scope change so much as the
  no-silent-truncation guarantee doing its job.
- **Removals**: None. Residual ~60 subtask retros consciously logged rather than chased
  (diminishing returns; findings already saturated at 3–8 project corroboration).
- **Impact**: Coverage rose from a first-pass 518 to 541/601; no timeline impact.

### Quality Metrics
- **Test Coverage**: 6/6 ACs + 3/3 guarantees via TC-1…TC-9, all PASS (TC-8 with a
  documented scratch-persistence deviation).
- **Defect Rate**: 0 findings across 7 reviewer passes (5 exec + 2 testing).
- **Corpus Coverage**: 541/601 (~90%); residual logged.

## What Went Well
- **The reconciliation step earned its place.** It caught two shard mis-slices and a
  range gap that would otherwise have silently dropped ~140 retros; the design's
  survey-authoritative denominator made the hole visible and quantifiable.
- **Map-reduce held under real scale.** Read-only extractors returning bounded digests
  kept injection contained and context bounded; the two-stage reduce absorbed ~19
  digests without overflow.
- **Plan-review paid off repeatedly.** The misalignment reviewer caught the
  `h-retrospective.md` second-convention undercount at plan time — the single most
  important correction, which changed the denominator from ~558 to 601.
- **Strong cross-project convergence.** The top findings (security-review cap on
  test/generated code; command-decoration permission prompts; status-field hygiene;
  CwF-upgrade friction) each corroborated across 5–8 projects.

## What Could Be Improved
- **Shard slicing by task-number range was fragile.** Two of three large projects were
  mis-sliced (agents converged on the same range, or assumed dense numbering). A
  subtask-aware enumeration (glob + explicit file-list handed to each agent) would have
  avoided the gap-fill round. This is itself a mild instance of the study's own S5/plan-
  time-verification theme.
- **Scratch persistence was partial (TC-8 deviation).** In direct fan-out mode digests
  were held in context and only one was written to scratch; the audit trail leans on the
  transcript. A tiny "write each returned digest to scratch as it lands" discipline would
  have matched the design.
- **A persistent `cd` into the scratch dir broke a later relative-helper call** (the
  exact CWD hazard in `feedback_worktree_cwd_dataloss` / the no-`cd` rule). Recovered by
  `cd`-ing back to the repo root; reinforces "don't leave the shell CWD elsewhere".

## Key Learnings
### Technical Insights
- The corpus has **two retro filename conventions** (`h-retrospective.md` pre-v2.1,
  `j-retrospective.md` v2.1); any cross-project corpus tool must match both or undercount
  older projects.
- **Tracked vs on-disk** retro counts differ slightly (untracked in-flight stubs); the
  git-tracked count is the reproducible denominator.
- The session-log miner surfaced quantified harness-level signal the retrospectives
  under-report — e.g. shell operators defeat the allowlist ~45–55% of the time, and a
  **tool-check hook fails open from a subdirectory** (a real, previously-uncaptured bug).

### Process Learnings
- **Reconciliation-as-a-named-step is a keeper pattern** for any map over a large corpus:
  compute an authoritative denominator first, then reconcile the union and log the delta.
- **Corroboration ≥2 external projects** cleanly separated general CwF findings from
  single-project noise, and the novelty diff against both convention dirs stopped the
  output restating already-codified rules.
- The `best-practice-resolve` golang/postgres tags fired on an unrelated meta-task every
  phase — the 5th reviewer was vacuous each time. A tag-applicability check would save it.

### Risk Mitigation Strategies
- The plan's High risk (corpus blows context) never materialised — bounded per-agent
  digests + two-stage reduce held.
- Prompt-injection containment (read-only agents, sole-writer orchestrator, dispatch-key
  filenames) was validated by the security reviewers as correctly designed.

## Recommendations
### Process Improvements
- For future corpus-mining tasks, hand each extractor an explicit file list (subtask-aware
  glob) rather than a task-number range; keep the reconciliation step.
- Persist each digest to scratch as it returns, even in direct fan-out mode.

### Tool and Technique Recommendations
- The map-reduce + reconcile + two-stage-reduce shape is reusable for any "read across
  many files, keep the conclusion" task.

### Future Work
The deliverable (`f-implementation-exec.md` §4) seeds **14 follow-up tasks** across the
three axes. Highest-leverage: **R1** default security-review exclusions for
test/generated/doc at `cwf-init`; **R2** planning/exec skills set terminal Status at their
own checkpoint; **R3** ship a consolidated shell-hygiene convention + allowlist seed;
**R7** bugfix the tool-check-hook fail-open-from-subdir; and the incidental
`ArtefactHelpers.pm` UTF-8 `Wide character` bugfix. See §4 for the full list. These are
added to the backlog as a consolidated Task-219 follow-up group.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-07-07
**Sign-off**: CwF maintainer (Task 219)

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md` … `e-testing-plan.md` (this task directory).
- Deliverable: `f-implementation-exec.md` (§1 method+reconciliation, §2 findings, §3
  ranked recommendations, §4 seeded tasks).
- Validation: `g-testing-exec.md` (TC-1…TC-9).
- Scratch artefacts: `survey.json`, `friction-overlay.json`, `reconciliation.md`,
  `digests/` (per-task scratch leaf).

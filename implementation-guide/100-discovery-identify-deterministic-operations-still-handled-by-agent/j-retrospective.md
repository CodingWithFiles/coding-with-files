# Identify deterministic operations still handled by agent - Retrospective
**Task**: 100 (discovery)

## Task Reference
- **Task ID**: internal-100
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/100-identify-deterministic-ops-handled-by-agent
- **Template Version**: 2.1
- **Retrospective Date**: 2026-04-17

## Executive Summary
- **Duration**: 1 session (estimated: 1 session, variance: 0%)
- **Scope**: Delivered as planned — all 18 skills audited, 24 candidates found, 5 backlog items drafted
- **Outcome**: Comprehensive inventory of deterministic operations with actionable extraction plan

## Variance Analysis
### Time and Effort
- **Estimated**: 1 session, low complexity
- **Actual**: 1 session (~30 minutes active), low complexity
- **Variance**: On target. Parallel agent auditing was efficient.

### Scope Changes
- **Additions**: Also audited shared docs (checkpoint-commit.md, retrospective-extras.md, re-execution.md) — these turned out to contain the highest-value candidates
- **Removals**: None
- **Impact**: Positive — shared docs are where the most frequently executed deterministic operations live

### Quality Metrics
- **Test Coverage**: 7/7 test cases pass (100%)
- **Defect Rate**: 0 — no classification errors found during testing
- **Audit Coverage**: 18/18 skills, plus 3 shared docs

## What Went Well
- Parallel agent auditing (2 agents, 9 skills each) completed the read phase efficiently
- The classification test ("same inputs → same output? zero judgement? script could do it?") was clear and easy to apply consistently
- The categorisation taxonomy from the design phase covered all found operations without needing new categories
- The ranking formula (frequency × error-proneness / extraction complexity) produced a sensible priority ordering

## What Could Be Improved
- The existing "Add Status Update Helper Script" backlog item (from Task 60) has been in the backlog since February — this audit confirms it should have been higher priority all along
- The audit could have been done earlier — the architectural principle "deterministic in code, probabilistic in models" has been a founding principle since Task 8 but was never systematically audited

## Key Learnings
### Technical Insights
- The shared preamble and checkpoint commit procedure are the highest-leverage extraction targets — they affect every single workflow skill invocation (~10 skills × every task)
- cwf-extract is the only skill that is entirely deterministic end-to-end — all other skills have a mix of deterministic and judgemental steps
- JSON manipulation (settings.json merging in cwf-init) is the most error-prone deterministic operation — the agent has to read, parse, merge, and write JSON by hand

### Process Learnings
- Auditing with a clear classification test prevents subjective judgements about what "should" be scripted
- The edge cases (partially deterministic operations) are real and important — a script can handle the deterministic part and accept the judgemental part as a parameter

## Recommendations
### Future Work
1. **cwf-set-status**: Highest rank — extract status field update to a script (already in backlog, confirm priority)
2. **cwf-checkpoint-commit**: Second highest — bundle status update + stage + commit + validate into one script
3. **cwf-slug**: Eliminate duplication between cwf-new-task and cwf-subtask
4. **cwf-settings-merge**: Reduce error-proneness of JSON manipulation in cwf-init
5. **cwf-extract replacement**: Replace the entire skill with a helper script

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None
**Completion Date**: 2026-04-17

## Archived Materials
- Task branch: `discovery/100-identify-deterministic-ops-handled-by-agent`
- Key deliverable: `f-implementation-exec.md` — findings table with 24 candidates and 5 backlog items

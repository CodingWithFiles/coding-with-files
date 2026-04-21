# Discover best gotchas for skills via LMM memory analysis - Design
**Task**: 107 (discovery)

## Task Reference
- **Task ID**: internal-107
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/107-discover-best-gotchas-for-skills-via-lmm-mem
- **Template Version**: 2.1

## Goal
Design the research methodology: what to query, how to analyse, and what output format to produce.

## Research Methodology

### Phase 1: LMM Queries (broad then targeted)

Start with 2-3 broad queries to surface which skills have problems, then follow up on the top hits:
1. **Broad failure query**: `"cwf skill mistake OR error OR wrong OR rework OR correction"`
2. **Broad frustration query**: `"cwf workflow frustration OR repeated OR rework"`
3. **Targeted follow-ups**: For the 3-5 skills that surface most, query `"cwf-{skill}"` specifically

This avoids 38 individual queries (2 per skill x 19 skills) — most utility skills will have no failure data.

### Phase 2: Secondary Sources

Cross-reference LMM findings with:
- MEMORY.md "Recurring Process Errors" section (already documented patterns)
- `j-retrospective.md` files across all tasks (grep for "What Could Be Improved", "Lessons Learned", "Recommendations")

### Phase 3: Analysis

For each skill with findings:
- Count distinct occurrences (2+ required to classify as pattern)
- Assess impact: low (minor inconvenience), medium (rework needed), high (task derailed or data lost)
- Draft gotcha text: specific scenario + what goes wrong + how to avoid

### Phase 4: Output

For each skill with actionable gotchas, produce a BACKLOG.md entry:
```markdown
## Task: Add Gotchas to cwf-{skill} Skill

**Task-Type**: chore
**Priority**: {based on impact}
**Status**: Follow-up from Task 107

Gotchas to add near top of SKILL.md:
1. **{scenario}**: {what goes wrong}. {how to avoid}.
2. ...

**Identified in**: Task 107 (LMM memory analysis)
```

## Skill Prioritisation

Not all 19 skills are equal. Focus analysis effort on skills most likely to have gotchas:
- **High effort**: Workflow step skills (10) — these are used every task, most opportunity for error
- **Medium effort**: cwf-new-task, cwf-new-subtask, cwf-init — used at task creation, common source of misclassification
- **Low effort**: cwf-status, cwf-extract, cwf-config, cwf-current-task, cwf-security-check, test-cwf-skill — simple utilities, unlikely to have recurring failure patterns

## Constraints
- LMM query results are bounded by ingested data — skills used in early tasks may have fewer records
- Discovery output only — gotchas are written as backlog items, not applied to SKILL.md files

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 107
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

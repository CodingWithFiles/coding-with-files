# Create CWF terminology glossary - Plan
**Task**: 87 (hotfix)

## Task Reference
- **Task ID**: internal-87
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/87-create-cwf-terminology-glossary
- **Template Version**: 2.1

## Goal
Create `.cwf/docs/glossary.md` — a machine-searchable canonical term reference that
covers gaps not already defined in existing docs, and wire it into `workflow-preamble.md`
so every model encounters it on every skill invocation.

## Success Criteria
- [ ] `glossary.md` created with one entry per term, structured for grep/Read tool access
- [ ] Covers all terms not authoritatively defined in existing docs (WF abbreviation,
  git workflow vocabulary, meta vocabulary)
- [ ] Does not duplicate content already defined in `workflow-overview.md`,
  `workflow-steps.md`, or `workflow-preamble.md`
- [ ] `workflow-preamble.md` references glossary so every skill invocation surfaces it
- [ ] `cwf-manage validate` passes

## Original Estimate
**Effort**: <1 hour
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. Audit existing docs for already-defined terms (scope the gaps)
2. Draft `glossary.md` with grep-friendly structure
3. Add reference line to `workflow-preamble.md`

## Risk Assessment
### Low Priority Risks
- **Duplication with existing docs**: Glossary re-defines terms already covered elsewhere,
  creating two sources of truth
  - **Mitigation**: Audit existing docs first; cross-reference rather than redefine where
    a term is already authoritative

## Dependencies
- None

## Constraints
- Do not redefine terms already authoritatively defined in `workflow-overview.md`,
  `workflow-steps.md`, or `workflow-preamble.md` — link to them instead
- Glossary structure must be searchable by grep (one term per heading) and by Read
  tool with offset/limit (predictable, consistent entry format)

## Decomposition Check
- [x] **Time**: No — <1 hour
- [x] **People**: No
- [x] **Complexity**: No — one new file, one line in preamble
- [x] **Risk**: No
- [x] **Independence**: N/A

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 87
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

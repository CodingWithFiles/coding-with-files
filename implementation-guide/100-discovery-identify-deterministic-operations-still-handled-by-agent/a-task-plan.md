# Identify deterministic operations still handled by agent - Plan
**Task**: 100 (discovery)

## Task Reference
- **Task ID**: internal-100
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/100-identify-deterministic-ops-handled-by-agent
- **Template Version**: 2.1

## Goal
Audit CWF skills and workflows to identify deterministic operations currently performed by the agent that should be extracted into helper scripts, enforcing the architectural principle: "deterministic operations in code, probabilistic/stochastic operations in models."

## Success Criteria
- [ ] All CWF skills (SKILL.md files) audited for deterministic operations
- [ ] Each candidate operation categorised by type (file I/O, JSON manipulation, validation, git operations, etc.)
- [ ] Priority ranking based on frequency, error-proneness, and complexity of extraction
- [ ] Findings documented with specific file/line references
- [ ] Backlog items created for the highest-value extractions

## Original Estimate
**Effort**: 1 session
**Complexity**: Low (read-only audit, no code changes)
**Dependencies**: None — all source material is in the repo

## Major Milestones
1. **Skill audit complete**: All SKILL.md files reviewed, deterministic operations identified
2. **Categorisation complete**: Operations grouped by type and ranked by extraction value
3. **Backlog items drafted**: Top candidates written up as actionable backlog items

## Risk Assessment
### Medium Priority Risks
- **False positives**: Some operations that appear deterministic may actually require LLM judgement (e.g., deciding whether to skip a step)
  - **Mitigation**: Apply a strict test — "could a bash/perl script do this with zero ambiguity?" If no, it stays with the agent.
- **Scope creep**: Discovery could expand into redesigning the entire skill system
  - **Mitigation**: Output is a ranked list and backlog items, not implementations

## Dependencies
- Current SKILL.md files and helper scripts in `.cwf/scripts/command-helpers/`

## Constraints
- Discovery only — no code changes in this task
- Focus on operations the agent currently does inside skill workflows, not on the skills framework itself
- The architectural boundary is: if the output is fully determined by the input (no judgement, no creativity, no interpretation), it belongs in code

## Decomposition Check
- [ ] **Time**: Will this take >1 week? No — single session
- [ ] **People**: Does this need >2 people? No
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — one audit across one file type
- [ ] **Risk**: Are there high-risk components? No — read-only
- [ ] **Independence**: Can parts be worked on separately? No

0/5 signals triggered — no decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 100
**Blockers**: None

## Actual Results
Scope confirmed: audited 18 SKILL.md files + 3 shared docs. 24 candidate operations found, 10 skills had zero unique candidates.

## Lessons Learned
Discovery tasks benefit from a structured scoring matrix early — it prevented scope creep and kept the audit focused on actionable candidates.

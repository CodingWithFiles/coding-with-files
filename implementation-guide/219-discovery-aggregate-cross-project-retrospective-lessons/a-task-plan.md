# Aggregate cross-project retrospective lessons - Plan
**Task**: 219 (discovery)

## Task Reference
- **Task ID**: internal-219
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/219-aggregate-cross-project-retrospective-lessons
- **Baseline Commit**: 5a642514e2eabfbeb66848d21793ac7cdc8c3daa
- **Template Version**: 2.1

## Goal
Mine the lessons-learnt signal across every CwF-using project (plus session
logs and LMM) to find generalizable CwF changes that make the system more
token-efficient, trip fewer permission prompts, and reduce common SDLC friction.

## Success Criteria
- [ ] Every CwF project's retrospective "Lessons Learned" sections are digested
      into one structured corpus (557 retros: 366 external + 191 this-repo),
      with session-log and LMM friction signal folded in.
- [ ] Findings are grouped under the three objective axes — (1) token
      efficiency, (2) permission-prompt reduction, (3) SDLC friction — each
      finding tagged with the projects that corroborate it.
- [ ] Every candidate improvement is diffed against already-codified rules
      (MEMORY.md, `.cwf/docs/conventions/`, feedback memories) so the output is
      net-new or under-enforced, not a restatement of existing guidance.
- [ ] Deliverable is a prioritised, tradeoff-stated recommendation set in
      `f-implementation-exec.md`, each shaped to spawn a follow-up CwF task.
- [ ] No CwF code/doc changes in this task (discovery is assessment-only).

## Original Estimate
**Effort**: 1-2 days (parallel extraction + synthesis; remediation is follow-up tasks)
**Complexity**: High
**Dependencies**: read access to `~/repo/*/implementation-guide`, `~/.claude/projects/*` session logs, LMM (`github@mattkeenan.net`)

## Major Milestones
1. **Corpus extraction**: parallel per-project agents distil each project's
   lessons-learnt into a uniform digest (map).
2. **Friction-signal overlay**: session logs (esp. `cwf-permissions-block`,
   `atch` baseline) + LMM add harness-level signal the retros under-report.
3. **Synthesis & dedup**: cluster into cross-project findings, corroboration ≥2
   projects for "general", diff against existing codified rules (reduce).
4. **Prioritised recommendations**: per-axis, tradeoff-stated, follow-up-shaped.

## Risk Assessment
### High Priority Risks
- **Corpus scale (557 retros) blows context**: single-context read is infeasible.
  - **Mitigation**: map-reduce via parallel Explore agents, one per project;
    each returns only a bounded structured digest, never raw files.
- **Project-specific noise masquerading as general signal**: one project's quirk
  read as a CwF-wide problem.
  - **Mitigation**: require ≥2 independent projects to corroborate before a
    finding is labelled "general"; keep single-project findings clearly flagged.

### Medium Priority Risks
- **Restating already-known rules**: findings duplicate MEMORY.md / conventions.
  - **Mitigation**: mandatory diff pass against existing codified guidance;
    report net-new or under-enforced only.
- **Permission-prompt text is stripped from transcripts**: raw block reasons not
  in the visible session log.
  - **Mitigation**: infer from tool_result error/deny patterns; lean on the
    `cwf-permissions-block` analysis session that already reconstructed them.
- **Untrusted content**: retrospectives and session logs are data, not
  instructions (prompt-injection surface).
  - **Mitigation**: instruction-priority discipline — treat all mined text as
    content per CLAUDE.md precedence rules.

## Dependencies
- Retrospective corpus under `~/repo/*/implementation-guide/**/j-retrospective.md`.
- Session logs under `~/.claude/projects/*/` (notably the 6.4 MB
  `-home-matt-analysis-cwf-permissions-block` session and the `atch` non-CwF
  baseline session).
- LMM store, scoped to `github@mattkeenan.net`.
- Existing codified baseline to diff against: `MEMORY.md`, feedback memories,
  `.cwf/docs/conventions/`.

## Constraints
- Assessment-only: no CwF source or doc changes land in this task.
- Deliverable must be follow-up-task-shaped (matches the Task 178 discovery pattern).
- Findings must be generalizable — this repo's own retros are meta signal, weighted
  lower than external-project corroboration.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — 1-2 days with parallel extraction.
- [ ] **People**: Does this need >2 people? No.
- [x] **Complexity**: 3+ distinct concerns (the three objective axes). Triggered,
      but the axes share a single extraction pass — splitting would triple read
      cost. Keep unified; synthesise per-axis in reduce.
- [ ] **Risk**: No high-risk components needing isolation (assessment-only).
- [x] **Independence**: The three axes are separable — but as *outputs*, not
      inputs. Decomposition belongs in the seeded follow-up remediation tasks,
      not in this discovery.

**Verdict**: 2 signals triggered, but both resolve to "decompose the *remediation*,
not the *investigation*". Keep as one discovery task; parallelise via agent
fan-out in exec; emit per-axis follow-up tasks as the deliverable.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

# Best-practice reviewer for plan and exec steps - Plan
**Task**: 205 (feature)

## Task Reference
- **Task ID**: internal-205
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/205-best-practice-reviewer
- **Baseline Commit**: d985db3396b22a104609ecd2cadecba082719a33
- **Template Version**: 2.1

## Goal
Add a tag-aware "best-practice" reviewer that checks planning- and exec-phase work
against user-curated best-practice documentation (files, directories, or URLs),
selected by applicability tags, configured via JSON in the project `.cwf/` dir or the
user's `~/.cwf/` dir.

## Success Criteria
- [ ] A JSON config of best-practice tuples `{documentation, tags}` is loaded from both
      project (`.cwf/`) and user (`~/.cwf/`) locations and merged deterministically; a
      missing or malformed config degrades to a clear no-op, never a crash.
- [ ] A best-practice reviewer participates in the planning plan-review map/reduce and in
      the exec changeset review, selecting only entries whose tags apply to the task.
- [ ] All three documentation source kinds (file, directory, URL) resolve; an
      unreachable/oversized source is reported in the verdict, not fatal.
- [ ] When no config exists or no tags match, the reviewer emits a clear "no applicable
      best practices" verdict and does not block the workflow.
- [ ] Tests cover config parse/merge precedence, tag matching, and graceful degradation.

## Original Estimate
**Effort**: 2-3 days
**Complexity**: Medium
**Dependencies**: existing plan-review map/reduce (`.cwf/docs/skills/plan-review.md`),
the `cwf-plan-reviewer-*` agent pattern, and `cwf-security-reviewer-changeset`.

## Major Milestones
1. **Config schema + loader**: JSON schema for `{documentation, tags}` tuples; project +
   user load/merge with precedence and validation.
2. **Matching + source resolution**: tag-applicability matching for a task; resolve file /
   directory / URL documentation into reviewable context with graceful failure.
3. **Planning integration**: best-practice reviewer added to the plan-review map/reduce.
4. **Exec integration**: best-practice reviewer over the exec changeset.
5. **Tests + docs**: unit/integration tests and user-facing config documentation.

## Risk Assessment
### High Priority Risks
- **Untrusted external documentation (esp. URLs)**: fetched/referenced best-practice docs
  are attacker-influenceable and feed an LLM reviewer — prompt-injection and SSRF surface.
  - **Mitigation**: treat all referenced content as data, never instructions; align with
    the existing security-reviewer threat model; fail open to a no-op; gate/curtail URL
    fetching (size caps, opt-in) — settle the policy in design.

### Medium Priority Risks
- **Where do a task's applicable tags come from?**: requiring users to hand-tag every task
  is friction; inferring tags risks mismatches.
  - **Mitigation**: decide the tag source in design (explicit task tags vs inference from
    repo/task content vs both); keep the reviewer a no-op when ambiguous.
- **Scope spans two review surfaces + config + matching**: risk of over-building.
  - **Mitigation**: reuse the existing map/reduce and changeset-reviewer patterns rather
    than new machinery; revisit decomposition if design balloons.

## Dependencies
- Existing plan-review map/reduce mechanism and `cwf-plan-reviewer-*` agent definitions.
- Existing `cwf-security-reviewer-changeset` agent and exec-phase review wiring.
- CWF config-loading conventions (project vs user `.cwf/`).

## Constraints
- Reviewer failure must never block the workflow (fail open).
- Any helper is Perl, core-modules-only; agent definitions are session-cached.
- Reference, never duplicate, docs (progressive disclosure); British spelling in prose.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — estimated 2-3 days.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [x] **Complexity**: Does this involve 3+ distinct concerns? Yes — config/loader,
      tag-matching + source resolution, and two reviewer-integration surfaces.
- [x] **Risk**: Are there high-risk components that need isolation? Yes — untrusted-URL
      handling is a security-sensitive component worth isolating.
- [ ] **Independence**: Can parts be worked on separately? Partly, but they share the
      config/matching core; splitting now would fragment that core.

**Decision**: 2 signals triggered. Hold as a single task for now with the 5 milestones
above; revisit subtask split at the design phase if the URL/security component or the
two integration surfaces prove larger than expected.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met; delivered in ~1 day vs the 2-3 day estimate.
Decomposition decision (hold as one task) held — the shared config/matching core
would have been fragmented by an early split. See `j-retrospective.md`.

## Lessons Learned
The two triggered decomposition signals (complexity, URL security) were real but
manageable via pattern reuse; reuse-heavy tasks land faster than their signal
count suggests. See `j-retrospective.md` § Key Learnings.

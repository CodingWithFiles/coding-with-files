# Document Dead Code Audit Methodology - Plan
**Task**: 148 (chore)

## Task Reference
- **Task ID**: internal-148
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/148-document-dead-code-audit-methodology
- **Baseline Commit**: 246e6c49a1f4f67b212c0e3277b1d24251cb4f57
- **Template Version**: 2.1

## Goal
Document a dead-code analysis methodology that simultaneously serves CWF-dev internal cleanup (Perl/POSIX recipes), ships language-agnostic heuristics to CWF consumers, and wires into CWF's plan-review (shift-left, via `cwf-plan-reviewer-misalignment`) and maintenance (shift-right, via `i-maintenance`) surfaces.

## Success Criteria
- [ ] A CWF-dev-internal recipe doc exists at repo-root `docs/` covering Perl/POSIX-specific grep/POD/symlink-target patterns. Not shipped to consumers.
- [ ] A language-agnostic methodology doc exists under `.cwf/docs/maintenance/` (so it ships to consumers' `.cwf/` trees). Covers caller categories that any language exhibits: static, same-file, reflective/runtime, generated, tests-only, public-API, plugin/hook surfaces.
- [ ] `.cwf/agents/cwf-plan-reviewer-misalignment.md` Procedure references the methodology, giving the reviewer a concrete checklist for its existing "unused abstractions" / "overlap with existing functionality" focus. Agent stays under ~55 lines.
- [ ] The `i-maintenance` template references the consumer-facing doc as the canonical input for any maintenance-phase dead-code sweep.
- [ ] Methodology self-test: applying the documented recipes to Task 51's false-positive functions (`workflow_file_mappings()` and `format_error()`) classifies them as **not dead** — i.e. the methodology, had it existed, would have caught the original error before removal.

## Original Estimate
**Effort**: 1 session (~half-day). Docs-only, no scripts, no code.
**Complexity**: Low
**Dependencies**: None upstream. Downstream: the "Comprehensive Dead Code Audit for CWF Library Modules" backlog entry explicitly depends on this task (BACKLOG.md, line 255).

## Major Milestones
1. **Implementation plan (d)**: Decide doc split — one shared file with audience addenda, or two siblings cross-referencing a shared "principles" section. Decide the exact shape of the misalignment-agent reference (inline checklist vs link-only). Enumerate the caller categories the methodology must cover.
2. **Testing plan (e)**: Define the Task 51 self-test concretely — what input the recipes consume, what verdict they must reach for each function, and how to record the test outcome inside this task's `g-testing-exec.md`.
3. **Implementation (f)**: Write both docs, wire references into the misalignment agent and `i-maintenance` template, run the self-test.

## Risk Assessment
### High Priority Risks
- **Risk: scope creep into doing the audit, not just the methodology.** Backlog has a follow-up "Comprehensive Dead Code Audit for CWF Library Modules" that depends on this task; conflating them turns a half-day docs task into a multi-day audit.
  - **Mitigation**: The only audit-style work permitted by this task is success criterion 5 (the Task 51 self-test on two known functions). Anything broader is explicitly the follow-up task's job.
- **Risk: drift between CWF-dev recipes and the shipped methodology.** If the two docs evolve separately they will contradict each other and the misalignment-reviewer reference will rot.
  - **Mitigation**: Design phase decides on a shared-source structure — either one doc with an audience-specific addendum, or two docs with one declared canonical and the other a thin applied-recipe sibling. No two free-standing parallel docs.

### Medium Priority Risks
- **Risk: language-agnostic doc becoming so abstract it has no actionable content.** "Look for callers" without category examples is vacuous.
  - **Mitigation**: Requirements phase (folded into implementation plan since chore skips b/c) must enumerate the caller categories — at minimum: static-call, same-file, reflective/runtime, tests-only, public-API/export, generated-code, plugin/hook surface, build-time/CI reference. The doc must give a cross-language example per category, not just name it.
- **Risk: heuristics overfit to the Task 51 case and pass the self-test trivially.** A methodology that correctly classifies two known incidents tells us little about its generality.
  - **Mitigation**: Either include a second historical case from the repo's task history (find another flagged-but-not-dead incident), or invert the self-test by feeding it code that the methodology *should* flag as dead and confirm the verdict matches reality. Decision deferred to implementation plan.
- **Risk: misalignment-agent file bloats past its current tight footprint** (currently 37 lines, including frontmatter). Reviewer agents are kept small deliberately.
  - **Mitigation**: Reference the heuristics as a 4-6 item numbered checklist with a link to the full doc; do not inline the methodology.

## Dependencies
- None external. Internal: the misalignment-agent file and the `i-maintenance` template must already exist (they do — `.claude/agents/cwf-plan-reviewer-misalignment.md` and the chore/feature templates).

## Constraints
- POSIX-only, core Perl only ([[feedback_perl_core_only]]) — relevant if any examples become executable; for now they are illustrative.
- Doc files only. No new helper scripts, no code changes outside the misalignment-agent and `i-maintenance` template references.
- The consumer-facing doc lives under `.cwf/docs/` so it ships; the CWF-dev recipe doc lives under repo-root `docs/` so it does not. This split is load-bearing for the audience separation and must be preserved.

## Decomposition Check
- [ ] **Time**: >1 week? No — half-day.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one concern (methodology) with three delivery surfaces.
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Separable parts? No — the misalignment-agent and `i-maintenance` references depend on the docs they point at; the two docs depend on a shared core.

No decomposition signals triggered → proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 148
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

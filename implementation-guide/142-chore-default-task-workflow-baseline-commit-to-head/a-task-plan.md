# default task-workflow baseline-commit to HEAD - Plan
**Task**: 142 (chore)

## Task Reference
- **Task ID**: internal-142
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/142-default-task-workflow-baseline-commit-to-head
- **Baseline Commit**: b074b4b8b4c5f0eb84726d903ecc45248cb2d634
- **Template Version**: 2.1

## Goal
Eliminate the per-invocation permission prompt caused by `$(git rev-parse HEAD)` in the `/cwf-new-task` and `/cwf-new-subtask` SKILL examples by making `--baseline-commit` resolve HEAD without requiring shell substitution.

## Success Criteria
- [ ] `/cwf-new-task` and `/cwf-new-subtask` can be invoked end-to-end with no shell-substitution permission prompt
- [ ] `task-workflow create` resolves HEAD internally (no caller-side `$(...)` required) — exact shape (omit flag vs HEAD sentinel) decided in design
- [ ] Existing explicit-SHA invocations of `task-workflow create` continue to work unchanged (rare expert path not broken)
- [ ] `grep -rn 'git rev-parse HEAD' .claude/skills/cwf-new-task .claude/skills/cwf-new-subtask` returns no matches after the change
- [ ] Script hash in `.cwf/security/script-hashes.json` updated for the modified helper (Task-135 hand-update path)

## Original Estimate
**Effort**: ~0.5 days
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Design decision**: Choose between option 1 (omit flag, default HEAD) and option 2 (literal `HEAD` sentinel). UX call captured in d-implementation-plan rationale (chore has no c-design-plan).
2. **Helper change + hash regen**: Update `task-workflow create` (template-copier-v2.1), regenerate `.cwf/security/script-hashes.json` via the Task-135 hand-update path.
3. **SKILL.md updates**: Strip the `BASELINE_COMMIT=$(...)` capture from both `.claude/skills/cwf-new-task/SKILL.md` § 3 and `.claude/skills/cwf-new-subtask/SKILL.md` § 3.

## Risk Assessment
### High Priority Risks
- **Breaking the explicit-SHA path**: A caller passing `--baseline-commit=<40-char-SHA>` for the rare expert workflow (branching off a non-HEAD commit) must keep working unchanged.
  - **Mitigation**: Test matrix covers all three shapes — explicit SHA, literal `HEAD`/omitted, garbage value. Existing test that pins a specific SHA (if any) stays green.

### Medium Priority Risks
- **Hash regen drift**: Forgetting to regenerate the script hash leaves `cwf-security-check` failing for downstream users on next pull.
  - **Mitigation**: Hash regen is an explicit milestone-2 deliverable, not a fix-on-failure step.
- **Option 1 vs 2 reversal**: If the design picks option 1 (omit flag) and users have shell aliases or scripts hard-coding `--baseline-commit="$(git rev-parse HEAD)"`, those keep working but stop being the documented shape.
  - **Mitigation**: Both shapes must remain valid. The skill examples change; the CLI contract loosens, doesn't tighten.

## Dependencies
- None. Self-contained change to one helper script and two SKILL.md files.

## Constraints
- POSIX-only Perl, core modules only (`feedback_perl_core_only`).
- Must not introduce a parallel "convenience" path that silently changes recorded baselines; the resolved SHA written into `a-task-plan.md` must remain a literal 40-char SHA, not the string `HEAD`.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — half-day estimate.
- [ ] **People**: Does this need >2 people working on different parts? No — single-concern change.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — one helper + two SKILL.md files, single concern (resolve HEAD without caller substitution).
- [ ] **Risk**: Are there high-risk components that need isolation? No — small surface, easily reversible.
- [ ] **Independence**: Can parts be worked on separately? No — design decision drives both helper and SKILL.md edits.

Zero signals triggered. No decomposition needed.

## Out of Scope
- Generalising "resolve symbolic refs" to other helper flags (e.g. `security-review-changeset` anchor). Separate refactor; see backlog.
- The `--destination` parameter ambiguity surfaced while creating this task (SKILL.md example reads as parent path; helper wants full task-dir path). File as separate backlog entry — different defect, different fix.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 142
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

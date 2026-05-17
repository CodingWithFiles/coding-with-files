# update cwf skills to use namespaced tmp paths - Plan
**Task**: 145 (chore)

## Task Reference
- **Task ID**: internal-145
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/145-update-cwf-skills-to-use-namespaced-tmp-paths
- **Baseline Commit**: e435162c06856f5e84b774905584035adad72768
- **Template Version**: 2.1

## Goal
Codify a project-namespaced `/tmp/` scratch-path convention so concurrent agents working in different repositories do not collide on shared task numbers (e.g. two repos both reaching task 145).

## Success Criteria
- [ ] A convention doc at `.cwf/docs/conventions/tmp-paths.md` defines the canonical namespaced scratch-path pattern, documents the collision-avoidance rationale, and includes a threat-model section (single-user dev host scope, `mkdir -m 0700` first-use guard). Located under `.cwf/` because the convention is content-applicable to adopters too (their agents will encounter the same collision risk in their own repos).
- [ ] `docs/conventions/design-alignment.md` § Scope (lines 7-8) is updated to acknowledge that conventions which need to ship to adopters live under `.cwf/docs/conventions/`, regardless of dev-repo origin.
- [ ] `CLAUDE.md § Conventions` lists the new convention per `design-alignment.md:116-122`, pointing at the `.cwf/docs/conventions/tmp-paths.md` location.
- [ ] `.cwf/docs/skills/security-review.md:98` carries an inline annotation marking the existing `/tmp/cwf-update` example as illustrative-only, so the convention and the anti-pattern don't fight each other.
- [ ] Agent-memory files (`feedback_no_heredocs.md`, `feedback_no_tee_permissions.md`, `MEMORY.md`) reference the canonical form; a grep verification gate is passed before the task is marked Finished.
- [ ] A smoke test demonstrates two simulated repo roots with the same task number produce non-colliding scratch paths via the documented derivation snippet.
- [ ] `.claude/agents/cwf-security-reviewer-changeset.md` permissions restored to `0444` (matches `script-hashes.json:26`). Validation warning that surfaced on every checkpoint commit in this task is resolved; the validation *mechanism* is preserved unchanged.

### Descoped during d-plan review (rationale)
- `template-copier-v2.1` example strings: out of scope. Plan-review confirmed these are illustrative argument strings, not runtime paths CWF writes to.

### Amended after user review (rationale)
- Originally planned to live at `docs/conventions/tmp-paths.md` with no `.cwf/` mirror, to avoid duplication. User correctly pointed out this strands adopters (they install only `.cwf/`, so a dev-repo-only convention would never reach them). Resolved by inverting: file lives at `.cwf/docs/conventions/tmp-paths.md` (the install-shipped location), with no `docs/conventions/` copy. Single source of truth, ships to adopters, no symlink machinery. `design-alignment.md` gets a one-line update so the new location placement is documented, not surprising.
- Folded in `.claude/agents/cwf-security-reviewer-changeset.md` permission restoration (0600 → 0444). Strictly orthogonal to the namespaced-tmp-paths goal, but it surfaces on every `cwf-manage validate` run during this task's checkpoint commits — leaving it would let the warning bleed into a follow-up task with the same noise. SHA verified unchanged against `script-hashes.json:27`, so this is restoration to recorded state, not new content.

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None — documentation and convention change; no behavioural change to running CWF code.

## Major Milestones
1. **Convention defined**: `docs/conventions/tmp-paths.md` (or similarly-named) written, naming format chosen, rationale captured.
2. **Skills and docs aligned**: All in-repo references to `/tmp/...` reviewed; updated or pointed at the convention.
3. **Smoke test + sync to installed copy**: Verify the convention holds; `.cwf/docs/conventions/` mirrors `docs/conventions/`.

## Risk Assessment
### High Priority Risks
- **Bikeshedding the format**: The dashified-path form (`/tmp/-home-matt-repo-coding-with-files-task-145/`) is unambiguous but ugly; the repo-basename form (`/tmp/coding-with-files-task-145/`) is readable but collides across worktrees of the same repo. Risk: time spent debating without a forcing function.
  - **Mitigation**: Design phase picks one and documents *why*; later tasks can adjust if a concrete collision proves the choice wrong.

### Medium Priority Risks
- **Scope creep into helper-script territory**: Tempting to add a `.cwf/scripts/.../tmp-dir` helper that returns the canonical path. That's a code change with hash-tracking implications, not a docs change.
  - **Mitigation**: Defer helper-script proposal to a follow-up task unless the convention proves unusable without one.
- **Stale `/tmp/task-NNN/` allowlist entries in `.claude/settings.local.json`**: Existing per-task allowlist lines (e.g. `Bash(/tmp/task-132/...)`) embed the old un-namespaced format. Risk: future agents see these as precedent and copy the pattern.
  - **Mitigation**: Note in convention doc that historical allowlist entries predate the rule and should not be propagated; do not retroactively rewrite settings.local.json (it's a user file).

## Dependencies
- None. Self-contained docs/convention change.

## Constraints
- Must not introduce new helper scripts (defer to follow-up task per risk above).
- Must not retroactively rewrite `.claude/settings.local.json` allowlist entries.
- Must preserve existing agent-memory guidance (already updated in `feedback_no_tee_permissions.md`).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** — <1 day of documentation work.
- [ ] **People**: Does this need >2 people working on different parts? **No** — single author.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** — single concern (path-namespacing convention).
- [ ] **Risk**: Are there high-risk components that need isolation? **No** — docs-only.
- [ ] **Independence**: Can parts be worked on separately? **No** — convention + references must land together to be coherent.

No decomposition signals triggered. Proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

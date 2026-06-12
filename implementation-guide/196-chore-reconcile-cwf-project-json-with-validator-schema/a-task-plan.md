# Reconcile cwf-project.json with validator schema - Plan
**Task**: 196 (chore)

## Task Reference
- **Task ID**: internal-196
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/196-reconcile-cwf-project-json-with-validator-schema
- **Baseline Commit**: e0f66f778a61a96ee327514859ba46fe5a29cbf4
- **Template Version**: 2.1

## Goal
Make a fresh `/cwf-init` produce a `cwf-project.json` whose shape matches the documented schema (`CWF-PROJECT-SPEC.md`) and the dog-fooded live config: drop vestigial keys the system ignores and align pass-through key names — without altering the live config (that is the sibling "Prune vestigial blocks" task).

## Context (findings from planning)
- The template's two **required** validated keys (`supported-task-types`, `source-management.branch-naming-convention`) are already present and well-formed, and its `sandbox` block already matches the spec. So a template-derived config **already passes** `cwf-manage validate` — the gap is *shape*, not *validity*.
- Divergences in `.cwf/templates/cwf-project.json.template` vs `CWF-PROJECT-SPEC.md` / live config:
  - Vestigial keys the system never reads: `cwf-version` + `_cwf-version-note`, `title`, `team`, and a `templates` block in an options shape (`task-reference-format`/`branch-name-max-length`/…) unrelated to the live legacy filename-map `templates`.
  - Divergent key names for documented pass-through concepts: `project` (name/description) vs live `project-name` + `description`; `task-management` vs documented `task-tracking`.
- `CWF-PROJECT-SPEC.md` (Task 189) is already authoritative and does **not** list `cwf-version`, `title`, `team`, or `task-management` — so removing them aligns the template *to the current spec*, no spec change needed for those.

## Decided (confirmed with user at plan time)
1. **Optional blocks** (`versioning`, `wf_step_config`): **omit** from the template. They encode CWF's own dev-versioning; consumers add them if wanted. Both are optional-validated, so absence is spec-clean.
2. **Task-tracking key**: **align** the template to the documented `task-tracking` shape (`system`/`base-url`/`id-format`/`fallback`), replacing the template-only `task-management` block.

## Scope Fence
- **In scope**: `.cwf/templates/cwf-project.json.template`; the `cwf-init` SKILL.md step-2 prose that describes the produced config; `t/cwf-project-template.t` (extend to assert spec-conformance).
- **Out of scope**: the live `implementation-guide/cwf-project.json` (sibling task "Prune vestigial blocks…"); retiring `cwf-version`/`security.version-tracking` from the *live* config (Low item "Retire remaining vestigial version fields"); any migration of existing installs (init runs once on a fresh repo).

## Success Criteria
- [ ] The shipped template, parsed and run through `CWF::Validate::Config::validate_config_hash`, returns **zero** violations.
- [ ] The template contains none of the vestigial keys: `cwf-version`, `_cwf-version-note`, `title`, `team` (and no top-level `version`, preserving Task 188).
- [ ] The template uses the documented pass-through key names (`project-name`, `task-tracking`) rather than `project`/`task-management`.
- [ ] `cwf-init` SKILL.md step 2 prose matches the produced shape (no reference to "task management" block names that no longer exist).
- [ ] `t/cwf-project-template.t` asserts the above mechanically and passes; full `prove t/` is green.

## Original Estimate
**Effort**: ~0.5 day
**Complexity**: Low (mechanical template rewrite; the two shape decisions are settled above)
**Dependencies**: None blocking. Adjacent (not blocking): sibling "Prune vestigial blocks from the live config" and "Retire vestigial version fields" — kept strictly out of scope to avoid overlap.

## Major Milestones
1. **Template rewritten** to spec shape (vestigial keys removed, pass-through names aligned, required + sandbox blocks retained).
2. **Init prose synced** — `cwf-init` SKILL.md step 2 describes the new shape.
3. **Guard test extended** — `t/cwf-project-template.t` validates the template against `CWF::Validate::Config` and pins the absent vestigial keys; suite green.

## Risk Assessment
### Medium Priority Risks
- **Scope bleed into sibling tasks**: editing the live config or retiring live version fields belongs to other backlog items.
  - **Mitigation**: Scope Fence above; touch only template + init skill + template test.

### Low Priority Risks
- **A helper silently reads a "vestigial" template key on fresh installs**: removing it could break a first-run code path.
  - **Mitigation**: grep the `.cwf/` + `.claude/` tree for each removed key name before deletion (symbol-deletion reference sweep) and record results in d-plan.
- **Template is not hash-tracked but the init skill is**: a SKILL.md edit pulls a sha256 refresh.
  - **Mitigation**: confirm at d-plan whether `.cwf/templates/cwf-project.json.template` and `cwf-init/SKILL.md` are in `script-hashes.json`; if so, refresh hashes in the same commit per `hash-updates.md`.

## Dependencies
- None blocking. Authoritative reference: `CWF-PROJECT-SPEC.md`; contract: `.cwf/lib/CWF/Validate/Config.pm`.

## Constraints
- Must not change the dog-fooded live config or any existing install (init is first-run only).
- British prose, no superlatives, POSIX/core-Perl test only (existing `t/cwf-project-template.t` conventions).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: <1 week (≈0.5 day). No decomposition.
- [x] **People**: Single contributor. No decomposition.
- [x] **Complexity**: One concern (config-shape reconciliation). No decomposition.
- [x] **Risk**: No high-risk component needing isolation. No decomposition.
- [x] **Independence**: Three artefacts move together as one change. No decomposition.

**Conclusion**: 0 signals triggered — proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met. The template was rewritten to the documented shape, `cwf-init` step-2 prose synced, and `t/cwf-project-template.t` extended to assert validator-clean + vestigial-absent + documented-names-present mechanically (13 assertions). Full `prove t/` green at 63 files / 759 tests. Scope Fence held — live config and version-field retirement untouched. Effort matched the ~0.5 day estimate (variance ≈ 0%).

## Lessons Learned
Settling the two shape decisions (omit optional blocks; adopt `task-tracking`) at plan time made the implementation genuinely mechanical, with no mid-flight user round-trips. See `j-retrospective.md` for full analysis.

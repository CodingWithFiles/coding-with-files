# Permission-drift repair and agent guidance - Plan
**Task**: 183 (feature)

## Task Reference
- **Task ID**: internal-183
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/183-permission-drift-repair-and-agent-guidance
- **Baseline Commit**: 32b3c4c85d703cb1fa04c462d9d1dab59c1b1a92
- **Template Version**: 2.1

## Goal
Make permission drift against recorded ceilings something CWF repairs promptly — clear the
current drift across every affected file and give agents a standing "fix-on-sight, never
defer" rule — while preserving the "surface, never smooth" guarantee for sha256/content
tampering signals.

## Success Criteria
- [ ] **SC1 (drift cleared)**: `cwf-manage validate` reports no permission violation across
  the whole tree at task end; the three Task-173 scripts are among the repaired set (the
  general sweep subsumes the file-specific backlog item).
- [ ] **SC2 (standing rule)**: A discoverable fix-on-sight rule exists in a standing location
  (CLAUDE.md `## Critical Rules` and a convention doc) instructing agents to repair
  permission drift the moment they observe it — via the existing `cwf-manage fix-security`
  (clamp to recorded) — rather than deferring it as "out of scope", with ≥1 concrete
  "don't do this" example drawn from the real failure mode.
- [ ] **SC3 (safe/unsafe boundary explicit)**: The guidance draws the line unambiguously —
  permission clamping is auto-repairable; sha256/content drift is NOT and MUST be surfaced
  per `hash-updates.md` "what NOT to build". No new tool/flag/mode that silences `validate`.
- [ ] **SC4 (backlog subsumed)**: The "Restore Task-173 permission drift on three helper
  scripts" backlog item is retired as superseded on completion.
- [ ] **SC5 (demonstrated)**: A documented, repeatable check shows the rule works in practice
  — drift introduced, prescribed fix applied, `validate` returns to OK.

## Original Estimate
**Effort**: ~1 day
**Complexity**: Low–Medium (mechanical repair is small; the care is in the guidance boundary)
**Dependencies**: existing `cwf-manage validate` / `fix-security`; the hash-updates,
surface-don't-smooth, session-hygiene, and cross-doc-references conventions

## Major Milestones
1. **Inventory**: enumerate current permission drift across the tree
   (`cwf-manage fix-security --dry-run`) and confirm the clamp repair is non-destructive.
2. **Repair sweep**: clear all current permission drift (Task-173's three scripts included).
3. **Codify guidance**: add the fix-on-sight rule + the perm-vs-sha256 safe/unsafe boundary
   to standing locations, single-sourced and cross-referenced (no duplication).
4. **Close out**: retire the superseded backlog item; verify `validate` clean; demonstrate SC5.

## Risk Assessment
### High Priority Risks
- **R1 (tamper-silencing confusion)**: An over-broad "make validate pass" rule could be read
  as licence to recompute sha256 / absorb content drift — the exact anti-pattern
  `hash-updates.md` forbids.
  - **Mitigation**: scope auto-repair strictly to permission clamping; reaffirm and
    cross-reference "what NOT to build" for content/sha; require an explicit safe/unsafe
    statement (SC3).

### Medium Priority Risks
- **R2 (working-tree-only nature)**: git records only `100755`/`100644`, so the `0500`-vs-`0700`
  distinction is invisible to `git status` and a perm repair is not committable as a diff —
  risk of promising a git-persisted fix that does not exist, or of drift recurring on checkout.
  - **Mitigation**: requirements/design must state plainly what persists (guidance, and any
    install/laydown-time enforcement) vs what is a working-tree action; do not promise a
    committable fix where none exists.
- **R3 (guidance sprawl/duplication)**: perm guidance could duplicate existing
  hash-updates / session-hygiene / surface-don't-smooth text and drift out of sync.
  - **Mitigation**: single source of truth; cross-reference per `cross-doc-references.md`
    rather than copy.

### Low Priority Risks
- **R4 (scope creep into new automation)**: temptation to build a hook/auto-fixer.
  - **Mitigation**: prefer guidance + the existing `fix-security` tool; admit new automation
    only if requirements justify it and it respects the surface-don't-smooth boundary.

## Dependencies
- Existing `cwf-manage validate` (detects more-permissive-than-recorded) and
  `cwf-manage fix-security` (clamps to recorded ceiling) — no new repair engine needed.
- Conventions: `hash-updates.md` (recorded perms are a ceiling; what NOT to build),
  `surface-don't-smooth`, `session-hygiene`, `cross-doc-references.md`.

## Constraints
- MUST NOT introduce any surface that silences `cwf-manage validate` without first surfacing
  it to a human (hash-updates "what NOT to build").
- Recorded `permissions` are an upper bound; repair clamps, never raises.
- CWF self-hosted workflow (this task eats its own dogfood); British spelling; no superlatives.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No (~1 day).
- [ ] **People**: >2 people on different parts? No.
- [ ] **Complexity**: 3+ distinct concerns? No — two coupled strands (repair sweep + guidance),
  the guidance referencing the repair. Not independent enough to split.
- [ ] **Risk**: high-risk components needing isolation? No — the one sharp risk (R1) is a
  wording/boundary concern handled in-place, not an isolable component.
- [ ] **Independence**: parts separable? Partially, but splitting would scatter a single
  coherent rule across two tasks for no gain.

**Decision**: 0–1 signals → no decomposition. Single feature task.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

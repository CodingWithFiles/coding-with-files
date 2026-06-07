# changelog header brand name - Plan
**Task**: 184 (bugfix)

## Task Reference
- **Task ID**: internal-184
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/184-changelog-header-brand-name
- **Baseline Commit**: faf92479fac564f241ce10afb8ec00c986ad37f1
- **Template Version**: 2.1

## Goal
Replace the stale "Code Implementation Guide (CIG)" name in the `CHANGELOG.md` intro header with the current "Coding with Files (CwF)" name — both in this repo and, on upgrade, for existing CwF installs — and align changelog tooling so the canonical brand is asserted, not silently re-introduced.

## Success Criteria
- [ ] `CHANGELOG.md:3` reads "Coding with Files (CwF)" (no "Code Implementation Guide"/"CIG" remains in the intro)
- [ ] Changelog tooling (`CWF/Backlog.pm`, `backlog-manager`) does not generate or re-introduce the stale brand string; the canonical brand is documented/asserted so future drift is caught (mechanism decided in design)
- [ ] An upgrade path rewrites the stale intro line in an existing install's `CHANGELOG.md`, is idempotent (re-run is a no-op), targets only the brand string, and does not clobber a user-customised intro
- [ ] No stale "Code Implementation Guide" / "CIG" references remain in production artefacts in scope (glossary checked; historical `implementation-guide/` task docs excluded as immutable history)
- [ ] All existing backlog/changelog tests pass; new coverage exists for the brand assertion and the migration's idempotency + non-clobber behaviour

## Original Estimate
**Effort**: ~0.5 day
**Complexity**: Low–Medium (the header edit is trivial; the upgrade-hook wiring carries the only real design risk)
**Dependencies**: Existing migration framework (`.cwf/scripts/migrations/`) and the `cwf-manage update` / `cwf-apply-artefacts` artefact-application path.

## Major Milestones
1. **Header fix**: `CHANGELOG.md` intro line corrected in this repo (completes the Task 59 rebrand).
2. **Tooling alignment**: Confirm no generator emits the old string; add/locate the canonical-brand assertion so drift is surfaced.
3. **Upgrade migration**: Idempotent, brand-targeted header-rewrite artefact, wired into the upgrade path decided in design, with non-clobber safety for customised intros.

## Risk Assessment
### High Priority Risks
- **Risk 1 — No existing auto-migration hook on `cwf-manage update`.** `migrations/migrate-v2.1-file-order` is a manual one-off; `cwf-manage` only runs `run_apply_artefacts`, never the `migrations/` dir. Where to hook an automatic header rewrite is an open design decision and the main source of scope.
  - **Mitigation**: Resolve in design phase (c). Candidate options: extend `cwf-apply-artefacts`, add a migration-runner step to update, or ship as a documented + optionally-invoked migration. Prefer reusing the existing artefact path over inventing a new runner.

### Medium Priority Risks
- **Risk 2 — Clobbering a user-customised intro.** A blunt header overwrite could destroy intros that consuming repos have legitimately edited.
  - **Mitigation**: Target the exact stale brand substring only; leave any non-matching intro untouched; make re-runs no-ops. Cover with a non-clobber test.
- **Risk 3 — Tooling silently re-introduces the old string.** If any bootstrap/normalise path were to emit the intro, the fix would regress.
  - **Mitigation**: Verified in planning that bootstrap only writes `## Task N` nodes and validation only checks `# Changelog`; design will add a positive canonical-brand assertion so any future regression is caught.

## Dependencies
- Migration framework under `.cwf/scripts/migrations/` and the `cwf-manage update` → `cwf-apply-artefacts` path.
- `CWF/Backlog.pm` changelog parse/validate functions; `backlog-manager` helper.

## Constraints
- `CHANGELOG.md` is consumer-owned (each install has its own) — the migration must operate per-install, not assume CwF's own file.
- Perl core-modules-only; existing CWF conventions (UTF-8, hash-update-in-same-commit if a hashed script changes, exact-recorded perms).
- Historical `implementation-guide/*` task docs are immutable history and out of scope for brand rewriting.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — hours, not days.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [x] **Complexity**: Does this involve 3+ distinct concerns? Marginally — header / tooling / migration. Each concern is small and tightly cohesive around one brand string.
- [ ] **Risk**: Are there high-risk components that need isolation? No — the one real risk (upgrade hook) is a design choice, not an isolatable build.
- [ ] **Independence**: Can parts be worked on separately? Technically yes, but they share one trivial root cause; splitting adds overhead without benefit.

**Verdict**: 1 marginal signal triggered (< 2). Keep as a single task; do not decompose.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered as a two-part task, not three: the upgrade migration (Milestone 3, the
plan's main risk and cost driver) was dropped in design after confirming no CWF
tooling seeds the stale intro into consumer installs. Header fixed at
`CHANGELOG.md:3`; `CHANGELOG-005` validation warning added as the regression
guard (Milestone 2). Brand casing held at canonical `CWF`; `CwF` rebrand deferred
to a backlog item. All success criteria met except #3 (migration), which was
descoped with user approval. Full suite green (698 tests); security review clean.

## Lessons Learned
The "High Priority Risk" around where to hook a `cwf-manage update` migration was
moot — there was nothing to migrate. Validate the propagation path (which code
writes the artefact into a user install?) before treating a migration as required
scope. See j-retrospective.md.

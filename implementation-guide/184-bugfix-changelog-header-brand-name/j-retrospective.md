# changelog header brand name - Retrospective
**Task**: 184 (bugfix)

## Task Reference
- **Task ID**: internal-184
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/184-changelog-header-brand-name
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-07

## Executive Summary
- **Duration**: Single session (estimated ~0.5 day; came in well under, the migration descope removed the only real cost driver).
- **Scope**: Planned as three parts (header fix + tooling assertion + upgrade migration). Delivered as two — the migration was dropped after investigation, and brand casing was held at canonical `CWF` with the `CwF` rebrand deferred to a backlog item.
- **Outcome**: Success. CWF's own CHANGELOG intro is corrected, a regression guard (`CHANGELOG-005`) is in place, full suite green (698 tests), security review clean.

## Variance Analysis
### Time and Effort
- **Estimated**: ~0.5 day total; the a-plan flagged the upgrade-hook wiring as the main cost/risk.
- **Actual**: Substantially less. The header fix and validation rule were small; the projected design risk (where to hook the migration) evaporated once the migration was dropped.
- **Variance**: Under estimate, driven entirely by the scope reduction below.

### Scope Changes
- **Removals**:
  - **Upgrade migration (part 3) dropped.** Investigation in design showed no CWF tooling ever seeds the "All notable changes…" intro into a consumer `CHANGELOG.md`: no CHANGELOG template, neither `install.bash` nor `/cwf-init` create the file, and `backlog-manager` bootstrap writes only `# Changelog` + `## Task N` nodes (`t/backlog-bootstrap-changelog.t:109`). The stale string therefore exists only in CWF's own hand-authored file — a migration would be a no-op in the wild. Confirmed with the user ("Drop migration; fix + guard"). "The best part is no part."
- **Modifications**:
  - **Brand casing held at `CWF`, not the originally-stated `CwF`.** The repo-wide canonical is all-caps `CWF` (glossary, README, Task 59 entry). Introducing the only `(CwF)` mid-rebrand would create new inconsistency. Filed the project-wide `CWF`→`CwF` rebrand as a Low backlog item instead (`51494d2`).
- **Additions**:
  - **TC-5 added to `t/backlog-manager.t`** (not the planned `t/backlog-tree-validate.t`) — the CLI `--strict` escalation test needs the `make_isolated`/`run_bm` scaffolding that lives there; duplicating it would violate DRY. One extra file vs the d-plan list.
- **Impact**: Net simplification — from helper + `cwf-manage` wiring + 4 files down to 2 production files + hash refresh + tests. Lower risk, same user-facing benefit.

### Quality Metrics
- **Test Coverage**: Every `CHANGELOG-005` branch exercised (fires / silent-canonical / silent-body-only / severity / strict-escalation). No new uncovered code.
- **Defect Rate**: Zero defects in the task's own changes. One pre-existing environmental working-tree permission drift surfaced and fixed-on-sight (see below).
- **Performance**: N/A — read-only in-memory scan.

## What Went Well
- **Investigation-driven descoping.** Validating the migration premise against the actual code (templates, install, bootstrap) before building it saved the most expensive and risky part of the task.
- **Intro-scoping caught the real failure mode.** Binding the scan to `$tree->{intro}` (mirroring CHANGELOG-001) means historical body `(CIG)` fragments (lines 2245, 2854) never trip the rule — proven by TC-3 and confirmed against the live file.
- **TDD.** Wrote `TC-VAL-CHANGELOG-005` first, watched it fail, then implemented — clean red→green.
- **Plan-review gate.** The 4-agent design review caught the `CWF`/`CwF` casing error and the intro-scoping requirement before implementation.

## What Could Be Improved
- **The migration premise should have been validated before it reached the a-plan as a milestone + dependency.** It was listed as a "High Priority Risk" with the migration framework as a hard dependency, then dropped wholesale in design. Earlier propagation-path checking would have scoped the task to two parts from the outset.
- **Brand-casing drift (`CWF` vs intended `CwF`) was latent until this task.** Task 59's rebrand left it ambiguous; surfaced now and filed, but it is pre-existing debt.

## Key Learnings
### Technical Insights
- **Verify the propagation path before designing a migration.** "We must migrate users" is only true if some code actually writes the stale artefact into user installs. Here nothing did.
- **Git tracks only the exec bit.** The `0400` vs recorded `0444` read-bit drift on `.claude/agents/cwf-security-reviewer-changeset.md` is non-committable and purely local — fixable on sight with `chmod`, never part of a changeset. `cwf-manage validate` (ceiling model) accepted `0400`, but the fix-security TC-8 test asserts the recorded value as a floor.
- **Intro-vs-body scoping is the right boundary for brand assertions** in append-only changelogs where the body legitimately preserves historical names.

### Process Learnings
- A "Low–Medium" bugfix can still warrant the full design phase: the value here was almost entirely in the design-phase investigation that removed two-thirds of the planned work.

### Risk Mitigation Strategies
- The a-plan's Risk 3 mitigation (positive canonical-brand assertion) is exactly what shipped as `CHANGELOG-005` — a planned regression guard that proved its worth.

## Recommendations
### Process Improvements
- When a task plan names a "migration"/"upgrade path", add an explicit early check: *which code path writes this artefact into a consumer install?* If none, the migration is likely a no-op.

### Tool and Technique Recommendations
- Reuse the intro-scoped literal-`index` assertion idiom for future brand/string-drift guards; keep it bound to a specific tree sub-array, never the serialized whole file.

### Future Work
- **`CWF`→`CwF` TLA rebrand across the project** — filed as a Low backlog item (`BACKLOG.md`, identified in Task 184).

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-07
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`, `c-design-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md`
- Execution: `f-implementation-exec.md` (commit `1980881`), `g-testing-exec.md` (commit `f466435`)
- Backlog item: `CWF`→`CwF` rebrand (commit `51494d2`)

# Comprehensive Perl Test Suite for CWF Library Modules - Plan
**Task**: 77 (feature)

## Task Reference
- **Task ID**: internal-77
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/77-comprehensive-perl-test-suite-for-cwf-library-mo
- **Template Version**: 2.1

## Goal
Establish a reusable, runnable Perl test suite (`prove t/`) covering all CWF library
modules so that regressions are caught automatically rather than through manual inspection.

## Success Criteria
- [ ] All 17 `.pm` files in `.cwf/lib/` have corresponding `.t` files runnable via `prove`
- [ ] `t/task-state.t` migrated from stale `.cig/lib` path to `.cwf/lib`
- [ ] `prove t/` passes with zero failures on a clean checkout
- [ ] Coverage target defined and documented (public subs as minimum baseline)
- [ ] Test strategy document (fixture approach, module categories) written in design phase

## Original Estimate
**Effort**: 3–5 days
**Complexity**: High — 17 modules, varying testability (some need git repo fixtures)
**Dependencies**: `Test::More` (core), `File::Temp` (core), possibly `Test2::Suite` (CPAN)

## Major Milestones
1. **Infrastructure**: Fix `t/task-state.t` path; agree on test patterns and fixture strategy (design)
2. **Isolatable modules**: Tests for modules with no filesystem/git dependencies
3. **Filesystem modules**: Tests for modules that need temp dirs but not a git repo
4. **Git-dependent modules**: Tests for modules requiring a real git repo fixture
5. **Prove integration**: `prove t/` runs clean; add to validation docs

## Risk Assessment
### High Priority Risks
- **Git-dependent modules hard to isolate**: `TaskContextInference`, `VersionRouter`, `WorkflowFiles`
  require a populated git repo. Mocking may be complex.
  - **Mitigation**: Create a minimal in-repo git fixture (bare or temp) in a `t/fixtures/` directory;
    skip if fixture setup fails rather than failing the suite
- **`Implemented` status value removed**: `t/task-state.t` references the now-obsolete `Implemented`
  status; migrating the file may require updating these tests too.
  - **Mitigation**: Check status values against `workflow-steps.md` during migration

### Medium Priority Risks
- **`Test2::Suite` not installed**: If we choose it over `Test::More`, CI/dev envs need the CPAN dep.
  - **Mitigation**: Default to `Test::More` (core) unless clear benefit; decide in design phase
- **Coverage target debates**: "All public subs" is vague for modules with complex internals.
  - **Mitigation**: Define coverage target in requirements; use statement coverage as a stretch goal only

## Dependencies
- All 17 `.pm` files in `.cwf/lib/` (source of truth for what needs testing)
- Existing `t/task-state.t` (migrate and update)
- `prove` available in the environment (standard Perl tooling)

## Constraints
- Tests must run from the repo root (`prove t/`) without special setup
- No new runtime deps added to CWF scripts themselves — test deps only
- Must not break existing `cwf-manage validate` behaviour

## Decomposition Check
- [x] **Time**: 17 modules × meaningful test coverage ≈ substantial effort (>1 week realistic)
- [ ] **People**: Single-agent task
- [x] **Complexity**: 3 distinct concerns — test infrastructure, unit tests, git-fixture tests
- [ ] **Risk**: Risks are manageable within one task
- [x] **Independence**: Module groups (isolatable / filesystem / git-dependent) are independent

**Result**: 3 signals. Decomposition recommended but not required — module groups can be
milestoned within a single task. User to decide before execution.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 77
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered ahead of the high-end estimate. All 5 success criteria met:
- 17 `.t` files created (16 new + 1 migrated), one per `.pm` module
- `t/task-state.t` migrated from `.cig/lib` to `.cwf/lib`, Implemented status removed, Blocked expectations corrected
- `prove t/` exits 0, 157 tests, 0 failures, ~0.9s runtime
- Coverage target documented in c-design-plan.md and enforced: ≥1 subtest per exported/public sub
- Three-tier strategy (A/B/C) documented and implemented with SKIP guards for Tier C

## Lessons Learned
- `grep BLOCK LIST` inside `ok()` passes the message string into the list — always use extra parens: `ok((grep { ... } @list), $msg)`
- `qw()` cannot express multi-word strings like 'In Progress' — use quoted lists instead
- Functions not in `@EXPORT_OK` must be called fully qualified; check exports before writing tests
- Blocked status is 15% in CWF::TaskState (not 0%), affecting dormant formula — verify expected values against actual module logic

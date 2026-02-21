# Comprehensive Perl Test Suite for CWF Library Modules - Requirements
**Task**: 77 (feature)

## Task Reference
- **Task ID**: internal-77
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/77-comprehensive-perl-test-suite-for-cwf-library-mo
- **Template Version**: 2.1

## Goal
Define what "covered" means for the CWF Perl library and what the test suite must
satisfy for it to be considered complete and maintainable.

## Functional Requirements

### FR1: All library modules have a corresponding test file
Every `.pm` file under `.cwf/lib/` must have a counterpart `.t` file under `t/`.
- **Acceptance**: `prove t/` loads and exercises every module; no module is silently skipped
- **Scope**: 17 modules at time of writing (see milestone list in a-task-plan.md)

### FR2: Existing test migrated to current library path
`t/task-state.t` currently hard-codes `use lib "$FindBin::Bin/../.cig/lib"` — the old
path. It must be updated to `.cwf/lib` and any obsolete status values corrected.
- **Acceptance**: `prove t/task-state.t` passes with zero failures after migration

### FR3: Tests runnable with a single command from repo root
`prove t/` (no flags, no environment setup, no sudo) must execute the full suite.
- **Acceptance**: A developer with `perl` and CPAN core modules can run the suite
  immediately after cloning

### FR4: Coverage baseline defined and documented
The minimum coverage bar must be stated explicitly so future contributors know what
is expected.
- **Acceptance**: Design phase document states the coverage target (public subs as minimum)
  and it is enforced by the tests themselves (i.e., every listed public sub has ≥1 test)

### FR5: Test failures are informative
A failing test must indicate which module, which sub/behaviour, and what was expected
vs. actual — without requiring the developer to read the source.
- **Acceptance**: `Test::More` TAP output or equivalent gives actionable failure messages

### FR6: Git-dependent modules tested without flakiness
Modules that require a git repository (e.g., `TaskContextInference`, `VersionRouter`)
must be tested using a controlled fixture, not the live repo state.
- **Acceptance**: Tests pass on a clean checkout with no in-progress work; tests skip
  gracefully (not fail) if fixture creation fails

### User Stories
- **As a** CWF developer **I want** `prove t/` to catch regressions **so that** I can
  refactor library code with confidence
- **As a** new contributor **I want** one command to validate my changes **so that** I
  do not need to understand the full CWF script surface to verify correctness
- **As a** maintainer **I want** each test to explain its failure **so that** debugging
  does not require reading source and tests simultaneously

## Non-Functional Requirements

### Performance (NFR1)
- Full suite (`prove t/`) completes in <30 seconds on a standard dev machine
- Individual `.t` files complete in <5 seconds each
- No test creates persistent state (temp dirs cleaned up via `File::Temp CLEANUP=>1`)

### Usability (NFR2)
- `prove t/` is the only invocation needed — no wrapper scripts, no env vars
- Test file names mirror module names (e.g., `CWF/TaskPath.pm` → `t/taskpath.t`)
- Skipped tests emit a `SKIP` reason, not a silent pass

### Maintainability (NFR3)
- Each `.t` file tests exactly one module (single responsibility)
- Shared fixture helpers extracted to `t/lib/` if used by ≥3 test files
- New modules added to `.cwf/lib/` require a corresponding `.t` file (documented convention)

### Security (NFR4)
- Tests must not write outside temp dirs or the repo
- Tests must not make network calls
- Git fixture uses a temp bare repo, not the live origin

### Reliability (NFR5)
- Suite is deterministic: same result on every run, regardless of git working tree state
- Tests that cannot run without unavailable deps use `SKIP`, never hard `die`
- `prove t/` exit code is non-zero on any failure (standard TAP behaviour)

## Constraints
- Test deps limited to CPAN core (`Test::More`, `File::Temp`, `File::Path`, `FindBin`)
  unless design phase justifies a CPAN-only dep with explicit rationale
- No changes to `.cwf/lib/` modules themselves — this task is tests only
- `cwf-manage validate` must continue to pass after all test files are added

## Decomposition Check
- [x] **Time**: 17 modules is substantial — >1 week realistic
- [ ] **People**: Single-agent task
- [x] **Complexity**: 3 distinct concerns — infrastructure/migration, isolatable modules, git-fixture modules
- [ ] **Risk**: Risks manageable within one task
- [x] **Independence**: Three module groups (isolatable / filesystem / git-dependent) are independent

**Result**: 3 signals. Milestoned within a single task; user may choose to decompose
into subtasks (77.1 infra + migrate, 77.2 unit tests, 77.3 git-fixture tests).

## Acceptance Criteria
- [ ] AC1: `prove t/` exits 0 with all tests passing on a clean checkout
- [ ] AC2: Every `.pm` under `.cwf/lib/` has a counterpart `.t` file
- [ ] AC3: `t/task-state.t` passes after migration to `.cwf/lib` path
- [ ] AC4: No test requires env vars or manual setup beyond `perl` + core CPAN
- [ ] AC5: Coverage target (≥1 test per exported/public sub) documented and met
- [ ] AC6: Git-fixture tests skip cleanly when fixture setup fails, never hard-fail
- [ ] AC7: `cwf-manage validate` continues to pass after all changes

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 77
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
7 functional requirements, 5 NFR dimensions, 7 acceptance criteria defined.
Coverage target (≥1 test per public sub) and git-fixture skip behaviour are the
two requirements most likely to drive design decisions.

## Lessons Learned
FR4 (SKIP guards for git-dependent tests) was more nuanced than expected — the guard
must wrap both the git availability check AND the repo creation step. See taskpath.t
and validate-consistency.t for the correct two-level skip pattern.

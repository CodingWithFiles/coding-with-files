# Comprehensive Perl Test Suite for CWF Library Modules - Design
**Task**: 77 (feature)

## Task Reference
- **Task ID**: internal-77
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/77-comprehensive-perl-test-suite-for-cwf-library-mo
- **Template Version**: 2.1

## Goal
Define the structure, conventions, and fixture strategy for the CWF Perl test suite
so that implementation follows a consistent pattern across all 17 modules.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### Decision 1: Test framework — `Test::More` (core only)
- **Decision**: Use `Test::More` with `subtest`, no CPAN-only deps
- **Rationale**: `Test::More` is distributed with Perl; no install step needed; TAP
  output is readable by `prove` and any CI system. `Test2::Suite` adds features
  (better diffs, async) that are not needed for this codebase.
- **Trade-offs**: Less expressive diff output on hash/array failures — acceptable
  because CWF modules return scalars and plain hashes, not deep structures

### Decision 2: Module categorisation into three test tiers
Modules are divided by the resources they require at test time:

| Tier | Description | Fixture needed |
|------|-------------|----------------|
| A — Pure | No filesystem, no git | None |
| B — Filesystem | Reads/writes temp dirs | `File::Temp::tempdir` |
| C — Git | Reads git branch/worktree/log | Temp bare git repo |

**Tier A** (pure string/logic — test in isolation):
- `CWF::Common` — `check_perl5opt`, `format_error`
- `CWF::Options` — `parse`
- `CWF::MarkdownParser` — `extract_status`
- `CWF::TaskPath` — `normalize`, `validate`, `build_glob`, `get_parent`, `get_depth`,
  `detect_format`, `format_dirname`, `parse_dirname`, `format_branch`, `parse_branch`,
  `version_compare`

**Tier B** (filesystem — need temp dirs):
- `CWF::TaskState` — `state_done`, `state_achievable`, `status_percent`, `status_extract`
- `CWF::WorkflowFiles` — `workflow_file_mappings`, `list`, `get_template_version`,
  `status_to_percent`, `load_config`
- `CWF::WorkflowFiles::V20` — `get_workflow_files`
- `CWF::WorkflowFiles::V21` — `get_workflow_files`
- `CWF::ContextInheritance::Core` — `extract_headers`, `calculate_boundaries`,
  `count_lines`, `generate_context`
- `CWF::TemplateCopier::Core` — `discover_templates`, `compute_variables`,
  `substitute_variables`, `copy_templates`
- `CWF::StatusAggregator::Core` — `aggregate`, `get_workflow_status`
- `CWF::Validate::Config` — `validate`, `validate_config_hash`
- `CWF::Validate::Security` — `validate` (reads files + SHA256; no git call needed)
- `CWF::Validate::Workflow` — `validate`

**Tier C** (git-dependent — need controlled git repo):
- `CWF::TaskPath` (filesystem subs only) — `find_base_dir`, `resolve_num`,
  `resolve_branch`, `resolve_path`, `resolve`, `find_parent`, `find_children`,
  `find_siblings`, `find_ancestors`, `find_descendants`, `task_exists`,
  `branch_exists`, `find_first_free`
- `CWF::TaskContextInference` — `infer_task_context`, `get_all_signals`,
  `correlate_signals`, `format_output`
- `CWF::VersionRouter` — `detect_version`, `route_to_version`, `get_script_dir`
- `CWF::Validate::Consistency` — `validate` (calls `git branch --show-current`)

Note: `CWF::TaskPath` spans tiers A and C — a single `t/taskpath.t` covers both,
using fixtures only for the C-tier subs.

### Decision 3: Shared helper module threshold — ≥3 consumers
- `t/lib/CWFTest/Fixtures.pm` is created if helpers are used by ≥3 test files
- `create_task_dir($tmpdir, $type, @statuses)` will be used by ≥5 Tier B files
  (TaskState, WorkflowFiles, StatusAggregator, Validate::Workflow, ContextInheritance)
  → qualifies for extraction
- `create_git_repo($tmpdir)` used by ≥3 Tier C files → qualifies

### Decision 4: Git fixture strategy — temp init + minimal commit
Tier C tests use a temp dir with:
1. `git init` + `git config user.email/name` (local only)
2. One initial commit (empty or README) to have a valid HEAD
3. Task dirs created under `implementation-guide/` inside the temp repo
4. Tests `chdir` into the temp repo for the duration; restore via `local $ENV{...}`
   or `chdir` cleanup in `END {}` block

If `git` is not available, Tier C tests skip with `SKIP: git not available`.

### Decision 5: Naming convention — lowercase hyphenated
Module path → test file: strip `CWF/` prefix, lowercase, `::` → `-`, no extension suffix.

| Module | Test file |
|--------|-----------|
| `CWF::Common` | `t/common.t` |
| `CWF::TaskPath` | `t/taskpath.t` |
| `CWF::WorkflowFiles` | `t/workflowfiles.t` |
| `CWF::WorkflowFiles::V20` | `t/workflowfiles-v20.t` |
| `CWF::Validate::Config` | `t/validate-config.t` |
| `CWF::StatusAggregator::Core` | `t/statusaggregator.t` |
| `CWF::ContextInheritance::Core` | `t/contextinheritance.t` |
| `CWF::TemplateCopier::Core` | `t/templatecopier.t` |
| `CWF::TaskContextInference` | `t/taskcontextinference.t` |
| `CWF::VersionRouter` | `t/versionrouter.t` |

### Decision 6: Library path — `FindBin` relative
All `.t` files use:
```perl
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";   # for t/lib/ helpers
```
This works from any working directory because `FindBin` resolves to the `.t` file's
own directory, not `cwd`.

### Decision 7: Coverage contract — ≥1 subtest per exported/public sub
- For modules with `@EXPORT_OK`: every listed sub has ≥1 named `subtest`
- For `::Core` modules without `@EXPORT_OK`: every sub not prefixed `_` has ≥1 subtest
- Private (`_`-prefixed) subs are tested indirectly through the public interface

## Directory Structure

```
t/
  lib/
    CWFTest/
      Fixtures.pm       # create_task_dir(), create_git_repo(), create_config()
  task-state.t          # Tier B (migrate from .cig/lib; update obsolete statuses)
  taskpath.t            # Tier A + C
  common.t              # Tier A
  options.t             # Tier A
  markdownparser.t      # Tier A
  workflowfiles.t       # Tier B
  workflowfiles-v20.t   # Tier B
  workflowfiles-v21.t   # Tier B
  contextinheritance.t  # Tier B
  templatecopier.t      # Tier B
  statusaggregator.t    # Tier B
  validate-config.t     # Tier B
  validate-security.t   # Tier B
  validate-workflow.t   # Tier B
  validate-consistency.t # Tier C
  versionrouter.t       # Tier C
  taskcontextinference.t # Tier C
```

Total: 17 test files (one per module) + 1 shared helper module = 18 files added/modified.

## Constraints
- `Test::More`, `File::Temp`, `File::Path`, `FindBin` — all core; no CPAN installs
- `t/` root chosen over `.cwf/t/` for discoverability (`prove t/` is standard)
- No modifications to `.cwf/lib/` modules (tests only)
- `prove t/` must pass in a clean checkout without any in-progress work on the live repo

## Decomposition Check
- [x] **Time**: Substantial but milestoned (3 tiers = 3 milestones)
- [ ] **People**: Single-agent
- [x] **Complexity**: 3 tiers with different fixture strategies
- [ ] **Risk**: Managed by skip guards
- [x] **Independence**: Tiers are independent; Tier A can be done without Tier C

**Result**: Unchanged from planning — 3 signals. Proceeding as single task with
milestoned implementation.

## Validation
- [x] All 17 modules categorised into tiers
- [x] Naming convention covers all edge cases (namespaced `::Core` modules)
- [x] Fixture strategy satisfies FR6 (skip on failure, not hard die)
- [x] `Test::More`-only approach satisfies NFR1 (no CPAN dep constraint)
- [x] `t/lib/` helper threshold rule satisfies NFR3 (shared helpers extracted at ≥3)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 77
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Three-tier categorisation (pure / filesystem / git) gives a clear implementation
roadmap. The `t/lib/CWFTest/Fixtures.pm` shared helper is the key design decision
— without it, 5+ test files would duplicate the same `create_task_dir()` setup code.

## Lessons Learned
The tier classification (A/B/C) was the most valuable design decision. It prevented
over-engineering git fixtures for modules that didn't need them. Most "risky" modules
(VersionRouter, TaskContextInference) turned out to be partially Tier A once their
pure functions were identified.

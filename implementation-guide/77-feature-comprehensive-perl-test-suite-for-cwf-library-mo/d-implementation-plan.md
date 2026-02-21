# Comprehensive Perl Test Suite for CWF Library Modules - Implementation Plan
**Task**: 77 (feature)

## Task Reference
- **Task ID**: internal-77
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/77-comprehensive-perl-test-suite-for-cwf-library-mo
- **Template Version**: 2.1

## Goal
Create 16 new `.t` files, migrate 1 existing `.t` file, and add 1 shared helper
module so that `prove t/` passes with zero failures covering all 17 CWF library
modules.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Create / Modify

### New files
| File | Tier | Modules covered |
|------|------|-----------------|
| `t/lib/CWFTest/Fixtures.pm` | — | Shared helpers for all tiers |
| `t/common.t` | A | `CWF::Common` |
| `t/options.t` | A | `CWF::Options` |
| `t/markdownparser.t` | A | `CWF::MarkdownParser` |
| `t/taskpath.t` | A+C | `CWF::TaskPath` (pure subs + git subs) |
| `t/workflowfiles.t` | B | `CWF::WorkflowFiles` |
| `t/workflowfiles-v20.t` | B | `CWF::WorkflowFiles::V20` |
| `t/workflowfiles-v21.t` | B | `CWF::WorkflowFiles::V21` |
| `t/contextinheritance.t` | B | `CWF::ContextInheritance::Core` |
| `t/templatecopier.t` | B | `CWF::TemplateCopier::Core` |
| `t/statusaggregator.t` | B | `CWF::StatusAggregator::Core` |
| `t/validate-config.t` | B | `CWF::Validate::Config` |
| `t/validate-security.t` | B | `CWF::Validate::Security` |
| `t/validate-workflow.t` | B | `CWF::Validate::Workflow` |
| `t/validate-consistency.t` | C | `CWF::Validate::Consistency` |
| `t/versionrouter.t` | C | `CWF::VersionRouter` |
| `t/taskcontextinference.t` | C | `CWF::TaskContextInference` |

### Modified files
| File | Change |
|------|--------|
| `t/task-state.t` | Update `use lib` from `.cig/lib` → `.cwf/lib`; remove `Implemented` status; add `use lib` for `t/lib/` |

## Implementation Steps

### Step 1: Create shared helper module `t/lib/CWFTest/Fixtures.pm`
- [ ] Create `t/lib/CWFTest/` directory
- [ ] Write `Fixtures.pm` exporting three helpers:
  - `create_task_dir($base, $type, @statuses)` — creates a v2.1 task dir with workflow
    files; each file has a `## Status / **Status**: <value>` block
  - `create_git_repo($tmpdir)` — runs `git init`, sets local user config, writes and
    commits a README; returns the repo root path; skips (not dies) if `git` absent
  - `create_config($base)` — writes a minimal `implementation-guide/cwf-project.json`
    with required keys (`project-name`, `supported-task-types`,
    `source-management.branch-naming-convention`, `task-tracking.system`)
- [ ] Verify module loads cleanly: `perl -I.cwf/lib -It/lib -MCWFTest::Fixtures -e1`

### Step 2: Migrate `t/task-state.t`
- [ ] Change `use lib "$FindBin::Bin/../.cig/lib"` → `use lib "$FindBin::Bin/../.cwf/lib"`
- [ ] Add `use lib "$FindBin::Bin/lib"` (for future `CWFTest::Fixtures` use)
- [ ] Change `BEGIN { use_ok('TaskState', ...) }` → `use_ok('CWF::TaskState', ...)`
- [ ] Remove the `Implemented` status test case (status no longer valid in v2.1)
- [ ] Update `status_percent` subtest: remove `is(status_percent('Implemented'), 50, ...)`
- [ ] Verify: `prove t/task-state.t`

### Step 3: Tier A — pure module tests

#### `t/common.t`
- [ ] `use_ok('CWF::Common', qw(check_perl5opt format_error))`
- [ ] Subtest `check_perl5opt()`: test with `$ENV{PERL5OPT}` set and unset
- [ ] Subtest `format_error()`: test with message, with/without context hashref

#### `t/options.t`
- [ ] `use_ok('CWF::Options', 'parse')`
- [ ] Subtest `parse() — valid flags`: pass known flags, check returned hashref
- [ ] Subtest `parse() — unknown flag`: expect `die` or error return
- [ ] Subtest `parse() — missing required arg`: expect appropriate error behaviour

#### `t/markdownparser.t`
- [ ] `use_ok('CWF::MarkdownParser', 'extract_status')`
- [ ] Subtest `extract_status() — found`: markdown string with `**Status**: Finished`
- [ ] Subtest `extract_status() — missing section`: no Status section → returns undef/empty
- [ ] Subtest `extract_status() — multiple statuses`: first match wins

#### `t/taskpath.t` (Tier A subs only in this step — Tier C added in Step 6)
- [ ] `use_ok('CWF::TaskPath', qw(normalize validate build_glob get_parent get_depth
  detect_format format_dirname parse_dirname format_branch parse_branch version_compare))`
- [ ] Subtest `normalize()`: strips whitespace, handles edge cases
- [ ] Subtest `validate()`: valid numbers pass, invalid strings fail
- [ ] Subtest `get_parent()`: `"1.2.3"` → `"1.2"`, `"1"` → undef
- [ ] Subtest `get_depth()`: `"1"` → 1, `"1.2.3"` → 3
- [ ] Subtest `detect_format()`: on a temp dir with v2.1 files
- [ ] Subtest `format_dirname()` / `parse_dirname()`: round-trip test
- [ ] Subtest `format_branch()` / `parse_branch()`: round-trip test
- [ ] Subtest `version_compare()`: ordering of version strings

### Step 4: Tier B — filesystem module tests

#### `t/workflowfiles.t`
- [ ] Subtests for `workflow_file_mappings()`, `status_to_percent()`, `load_config()`,
  `get_template_version()`, `list()` — use `File::Temp` + `create_config()`

#### `t/workflowfiles-v20.t`
- [ ] Create a temp dir with v2.0 workflow file names (`a-plan.md`, etc.)
- [ ] Subtest `get_workflow_files()` returns correct file list for each task type

#### `t/workflowfiles-v21.t`
- [ ] Create a temp dir with v2.1 workflow file names (`a-task-plan.md`, etc.)
- [ ] Subtest `get_workflow_files()` returns correct file list for each task type
- [ ] Verify v2.0 and v2.1 return different file lists for the same task type

#### `t/contextinheritance.t`
- [ ] Write a temp markdown file with known headings
- [ ] Subtest `extract_headers()`: returns correct heading/line pairs
- [ ] Subtest `calculate_boundaries()`: line ranges are correct
- [ ] Subtest `count_lines()`: counts lines accurately
- [ ] Subtest `generate_context()`: output contains headings and line numbers

#### `t/templatecopier.t`
- [ ] Create a temp template pool with two minimal template files
- [ ] Subtest `discover_templates()`: finds templates by task type
- [ ] Subtest `compute_variables()`: substitutes task-num, description, branch
- [ ] Subtest `substitute_variables()`: replaces `{task-num}` etc. in content
- [ ] Subtest `copy_templates()`: files created in destination with substitutions applied

#### `t/statusaggregator.t`
- [ ] Use `create_task_dir()` to create tasks at various completion states
- [ ] Subtest `aggregate()`: returns correct percent for all-Finished, all-Backlog, mixed
- [ ] Subtest `get_workflow_status()`: returns per-file status hash

#### `t/validate-config.t`
- [ ] Subtest `validate_config_hash()` — valid minimal config: no violations
- [ ] Subtest `validate_config_hash()` — missing required key: violation returned
- [ ] Subtest `validate_config_hash()` — wrong type: violation returned
- [ ] Subtest `validate()` — with temp dir containing `implementation-guide/cwf-project.json`
- [ ] Subtest `validate()` — missing config file: violation returned

#### `t/validate-security.t`
- [ ] Create temp dir with a known file and its correct SHA256 in a hash JSON
- [ ] Subtest `validate()` — hashes match: no violations
- [ ] Subtest `validate()` — hash mismatch: violation returned
- [ ] Subtest `validate()` — missing file: violation returned

#### `t/validate-workflow.t`
- [ ] Use `create_task_dir()` to create a task with valid status values
- [ ] Subtest `validate()` — valid task: no violations
- [ ] Subtest `validate()` — invalid status value in a file: violation returned
- [ ] Subtest `validate()` — missing Status section: violation returned

### Step 5: Verify Tier A + B
- [ ] `prove t/task-state.t t/common.t t/options.t t/markdownparser.t t/taskpath.t`
- [ ] `prove t/workflowfiles.t t/workflowfiles-v20.t t/workflowfiles-v21.t`
- [ ] `prove t/contextinheritance.t t/templatecopier.t t/statusaggregator.t`
- [ ] `prove t/validate-config.t t/validate-security.t t/validate-workflow.t`
- [ ] All pass with zero failures before proceeding to Tier C

### Step 6: Tier C — git-dependent tests

#### Add Tier C subs to `t/taskpath.t`
- [ ] `SKIP` block: `unless system("git --version >/dev/null 2>&1") == 0`
- [ ] Use `create_git_repo()` + create minimal `implementation-guide/` structure
- [ ] Subtest `find_base_dir()`: locates `implementation-guide/` from within task dir
- [ ] Subtest `resolve_num()` / `task_exists()` / `branch_exists()`: use temp repo
- [ ] Subtest `find_children()` / `find_parent()` / `find_descendants()`: temp hierarchy

#### `t/validate-consistency.t`
- [ ] Use `create_git_repo()` with a branch named to match a task's Branch field
- [ ] Subtest `validate()` — branch matches doc: no violations
- [ ] Subtest `validate()` — branch mismatch: violation returned

#### `t/versionrouter.t`
- [ ] Use `create_git_repo()` with version tags on commits
- [ ] Subtest `detect_version()`: returns correct version string
- [ ] Subtest `route_to_version()`: returns correct routing for detected version
- [ ] Subtest `get_script_dir()`: returns correct path

#### `t/taskcontextinference.t`
- [ ] Use `create_git_repo()` with a branch `feature/1-test-task` checked out
- [ ] Create `implementation-guide/1-feature-test-task/` with workflow files
- [ ] Subtest `get_all_signals()`: all signal keys present in result
- [ ] Subtest `correlate_signals()`: conclusive result when branch + dir match
- [ ] Subtest `format_output()`: output contains `task_num:`, `confidence:`, `current:`
- [ ] Subtest `infer_task_context()`: end-to-end; returns correct task_num

### Step 7: Full suite verification
- [ ] `prove t/` — all 17 `.t` files pass, zero failures
- [ ] `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` — no regressions
- [ ] Run from a subdirectory to confirm `FindBin` path resolution works

## Code Changes

### `t/task-state.t` — lib path migration (before → after)
```perl
# Before
use lib "$FindBin::Bin/../.cig/lib";
BEGIN { use_ok('TaskState', qw(...)) }
is(status_percent('Implemented'), 50, 'Implemented = 50%');

# After
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";
BEGIN { use_ok('CWF::TaskState', qw(...)) }
# Implemented test case removed — status no longer valid
```

### `t/lib/CWFTest/Fixtures.pm` — canonical header
```perl
package CWFTest::Fixtures;
use strict;
use warnings;
use Exporter 'import';
use File::Temp qw(tempdir);
use File::Path qw(make_path);
our @EXPORT_OK = qw(create_task_dir create_git_repo create_config);
```

### Canonical per-test-file header (all `.t` files)
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";
```

## Test Coverage
**See e-testing-plan.md for full test plan**

Coverage contract: ≥1 named `subtest` per exported/public sub per module.

## Validation Criteria
- [ ] `prove t/` exits 0 on a clean checkout
- [ ] 17 `.t` files present (16 new + 1 migrated)
- [ ] `prove t/task-state.t` passes with updated lib path
- [ ] Tier C tests skip (not fail) when `git` is unavailable
- [ ] `cwf-manage validate` continues to pass

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

If work must be deferred: get user approval, update success criteria, create
follow-up task immediately, document deferral in Actual Results.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 77
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 7 steps executed. 19 files created or modified (18 test files + Fixtures helper).
Four systematic bugs found and fixed during implementation (see f-implementation-exec.md
deviations section). Final suite: 17 files, 157 tests, ~0.9s runtime.

## Lessons Learned
The deviations in Step 5 (Tier B) were all the same class of error — Perl parsing
subtleties (`grep` list scope, `qw` multi-word). Reading the Test::More source or
running a minimal test before writing suites would catch these faster.

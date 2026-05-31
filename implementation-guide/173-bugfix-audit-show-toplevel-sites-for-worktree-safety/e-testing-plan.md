# Audit show-toplevel sites for worktree-safety - Testing Plan
**Task**: 173 (bugfix)

## Task Reference
- **Task ID**: internal-173
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/173-audit-show-toplevel-sites-for-worktree-safety
- **Template Version**: 2.1

## Goal
Define the test strategy proving the repointed `find_git_root` (and `cwf-manage`'s independent resolver) return the **main** worktree root from inside a linked worktree, while the main-tree and outside-repo paths are unchanged — and that no routed/transitive caller regresses.

## Test Strategy
### Harness
- Standard CWF harness: `prove`-runnable `.t` files under `t/`, `Test::More`, `FindBin` + `use lib "$FindBin::Bin/../.cwf/lib"` (pattern from `t/common.t`, `t/template-copier-baseline-default.t`).
- **Isolation rule**: every git-touching test builds a throwaway repo under `File::Temp::tempdir(CLEANUP=>1)` and `git init`s it — **never** the live repo (the test-database-never-production rule applies to the working tree). Resolver behaviour is CWD-sensitive, so tests `chdir` into the temp repo/worktree and restore CWD (or run the resolver in a forked subprocess) deterministically.
- Core-Perl only: `File::Temp`, `File::Spec`, `Cwd`, `POSIX` — no non-core modules.

### Test Levels
- **Unit** (`t/common.t`, extended): `find_git_root` return-value across the three contexts (main tree / linked worktree / outside repo) + the `/.git`-parent derivation and fallback branch.
- **Integration**: the routed helpers and `cwf-manage`'s resolver exercised as subprocesses from inside a worktree.
- **Regression**: full existing suite (`prove t/`) green; `cwf-manage validate` clean (hash/perms integrity).

### Coverage Targets
- **Critical path (the resolver) 100%**: all three context branches + the documented `--show-toplevel` fallback are each asserted (no untested branch).
- **Every routed site** has at least one assertion that it resolves the main tree from a worktree (directly or via a representative caller).
- **Regression**: zero failures across the pre-existing suite.

## Test Cases
### Functional — resolver (unit)
- **TC-1 — worktree returns MAIN root (the bug)**:
  - **Given** a temp repo with a committed file and a linked worktree (`git worktree add`).
  - **When** `find_git_root()` runs with CWD inside the linked worktree.
  - **Then** it returns the **main** repo root, NOT the worktree path. (This test fails against today's code — TDD anchor.)
- **TC-2 — main tree unchanged**:
  - **Given** the temp repo's main working tree.
  - **When** `find_git_root()` runs there.
  - **Then** it returns a value equal to `git rev-parse --show-toplevel` (no behavioural change outside worktrees).
- **TC-3 — outside a repo returns undef**:
  - **Given** CWD in a non-repo tempdir.
  - **When** `find_git_root()` runs.
  - **Then** it returns `undef` (contract preserved for `//`/`length` callers).
- **TC-4 — flag ordering / derivation guard**:
  - **Given** the linked worktree of TC-1.
  - **When** the resolver derives the root.
  - **Then** an absolute path is produced (asserts `--path-format=absolute` precedes `--git-common-dir`; the relative-`.git` regression would make the path relative and fail) and the result has no trailing `/.git`.
- **TC-5 — fallback branch**:
  - **Given** a context where `--git-common-dir` does not yield a `.../.git` (documented fallback).
  - **When** the resolver runs.
  - **Then** it falls back to `--show-toplevel` and returns a valid root (branch is executed, not dead).

### Functional — callers & sites (integration)
- **TC-6 — transitive callers**: from inside a worktree, `CWF::Versioning::config_path` and `CWF::Backlog::_scan_task_dirs` build paths under the **main** tree (proves the choke-point fix propagates without editing them).
- **TC-7 — routed helper**: a representative routed helper (e.g. `template-copier`) invoked from inside a worktree anchors to the main tree; and behaves identically to today when run from the main tree.
- **TC-8 — cwf-manage resolver (independent path)**: from inside a worktree, `cwf-manage`'s own resolver returns the main tree and preserves its `die`-on-no-repo contract (self-masking-validator risk — must be asserted directly, not assumed via `Common`).
- **TC-9 — Class C guard untouched**: the existing `task-workflow.d/delete` self-worktree guard still detects "branch checked out in another worktree" and still self-excludes the current worktree (no semantic regression). Reuse/extend existing delete tests.
- **TC-10 — Class A shell snippet**: the canonical snippet resolves the main tree from inside a worktree and **aborts** (non-zero) outside a repo (deliberate divergence from the Perl `undef` contract); verify `update-cwf-skill-docs.sh` no longer leaves the shell `cd`'d into a transient tree.

### Non-Functional
- **Integrity**: `cwf-manage validate` passes — every edited hashed artefact has a same-commit hash refresh; edited scripts at **recorded** perms; `.pm` remain `100644`.
- **Portability**: tests pass under macOS system-perl (core-only modules; no GNU-specific git flags beyond `--path-format`/`--git-common-dir`, both verified on git 2.43).
- **Reliability**: outside-repo and fallback paths degrade predictably (undef / abort), no silent wrong-root.

## Test Environment
### Setup Requirements
- `git` on PATH; `PERL5OPT=-CDSLA` (CWF convention).
- Throwaway temp repos via `File::Temp` (`CLEANUP=>1`); linked worktrees via `git worktree add` into a second tempdir.
- No network, no live-repo mutation, no fixtures outside `t/`.

### Automation
- `prove t/common.t` for unit; `prove t/<new-worktree-resolver>.t` for integration; `prove t/` for the full regression pass.
- `.cwf/scripts/cwf-manage validate` as the integrity gate (run in g-testing-exec).

## Validation Criteria
- [ ] TC-1..TC-10 implemented and passing (TC-1 demonstrably failed against pre-fix code)
- [ ] Resolver's three context branches + fallback each covered (critical-path 100%)
- [ ] Full pre-existing `prove t/` suite green (no regression)
- [ ] `cwf-manage validate` clean (hashes + perms)
- [ ] Class C delete guard behaviour unchanged (TC-9)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 173
**Blockers**: OQ-1..OQ-4 (c-design-plan) to confirm before exec; TC-8/TC-10 depend on OQ-4/OQ-3 outcomes

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

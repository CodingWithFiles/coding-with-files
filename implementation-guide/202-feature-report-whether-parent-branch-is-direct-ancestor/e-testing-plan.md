# report whether parent branch is direct ancestor - Testing Plan
**Task**: 202 (feature)

## Task Reference
- **Task ID**: internal-202
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/202-report-whether-parent-branch-is-direct-ancestor
- **Template Version**: 2.1

## Goal
Define the test strategy for `parent_branch_ancestry`, the additive `hierarchy`
output, and the `run_quiet` hoist — proving the tri-state contract and no
regression in `delete`.

## Test Strategy
### Test Levels
- **Unit** (`Test::More`, run via `prove`): `parent_branch_ancestry` against
  synthetic git repos exercising every row of the design edge-case table. This is
  the core of the coverage (FR6: the function is the single testable enforcement
  point).
- **Integration**: `context-manager hierarchy <task> --format=json|markdown`
  invoked end-to-end against a synthetic repo, asserting the new JSON field /
  markdown line.
- **Regression**: full `t/` suite, with explicit attention to `delete`'s tests
  (the `run_quiet` hoist + `POSIX::_exit` change) and `taskpath.t`/`common.t`.

### Test Coverage Targets
- **Critical path**: 100% of the tri-state branches (`1` / `0` / `undef`) in
  `parent_branch_ancestry`.
- **Edge cases**: every row of the c-design edge-case table has a case.
- **Regression**: existing suite stays green; no existing `hierarchy` field/exit
  code changes.

### Environment / fixtures
- Synthetic git repos via `CWFTest::Fixtures::create_git_repo` (one commit, local
  config). The current fixture has **no branch/parent-child helpers**, so the
  implementation extends the harness: build an `implementation-guide/` with a
  parent dir (`1-feature-parent`) + child dir (`1.1-bugfix-child`), create the
  parent branch `feature/1-parent` with `git checkout -b`, and shape ancestry by
  adding commits. Prefer adding a small reusable helper to
  `t/lib/CWFTest/Fixtures.pm` over inline duplication if >1 test file needs it.
- All git in fixtures stays list-form / `git -C <repo>`; tests `chdir` into the
  repo where the function resolves `HEAD` (restore cwd after, per `taskpath.t`).

## Test Cases
### Functional (map to ACs)
- **TC-1 (AC1, ancestor)**: *Given* child `1.1` whose parent branch
  `feature/1-parent` is an ancestor of HEAD; *When* `parent_branch_ancestry('1.1')`;
  *Then* returns `1`.
- **TC-2 (AC1, same tip)**: *Given* HEAD is exactly the parent branch tip; *When*
  called; *Then* `1` (a branch is its own ancestor).
- **TC-3 (AC2, diverged)**: *Given* `feature/1-parent` has a commit not reachable
  from HEAD (HEAD on a sibling line); *When* called; *Then* `0`.
- **TC-4 (AC3, no parent)**: *Given* top-level task `1`; *When*
  `parent_branch_ancestry('1')`; *Then* `undef`.
- **TC-5 (AC3, branch absent)**: *Given* child `1.1` but `feature/1-parent` does
  not exist; *When* called; *Then* `undef` (distinct from TC-3's `0`).
- **TC-6 (prefix-collision, FR4)**: *Given* `feature/1-foo` exists and the queried
  parent branch would be `feature/1-foobar` (absent); *When* called; *Then*
  `undef` — proves `rev-parse --verify refs/heads/...` exact-matches where a
  `git branch --list` glob would false-positive.
- **TC-7 (unborn HEAD)**: *Given* a repo with no commits (or `merge-base` errors);
  *When* called; *Then* `undef` (rc ∉ {0,1} ⇒ null).

### Integration (hierarchy output)
- **TC-8 (JSON validity, AC4)**: `hierarchy 1.1 --format=json` parsed by a **real
  JSON parser** (`JSON::PP`, not a regex) → object contains
  `parent_branch_is_ancestor` as a JSON boolean/`null`, and every pre-existing
  field (`full_path`, `format`, `task_num`, `task_type`, `task_slug`,
  `parent_path`, `depth`) is present and unchanged. Hard requirement — guards the
  hand-rolled serialiser's trailing-comma edit.
- **TC-9 (markdown)**: `hierarchy 1.1` (default) prints
  `Parent branch ancestor of HEAD: yes|no|unknown`; `hierarchy 1` (top-level)
  prints **no** such line.

### Non-Functional Test Cases
- **Security (NFR3)**: the existence + ancestry calls are list-form `run_quiet`;
  asserted behaviourally via a parent task whose slug contains a hyphen (normal)
  — no shell evaluation occurs. (No metacharacter slug is reachable: `generate_slug`
  bounds the charset; documented as safe-here, not separately fuzzed.)
- **Reliability (NFR4)**: existing `hierarchy` exit code stays `0`; undecidable
  inputs never produce a non-zero exit or a stack trace.

## Validation Criteria
- [ ] TC-1…TC-9 passing.
- [ ] Tri-state branches 100% covered; every edge-case-table row has a case.
- [ ] Full `t/` suite green (esp. `delete` tests, incl. failed-exec/cleanup path).
- [ ] `cwf-manage validate` clean after the hash refresh.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1…TC-9 all PASS (see g-testing-exec.md); every row of the c-design edge-case
table has a case, tri-state branches 100% covered. The fixture helper was kept
**local** to `t/taskpath-parent-branch-ancestry.t` rather than added to
`Fixtures.pm` — only one test file needs it, so per this plan's own ">1 file"
guidance and the brevity principle it stayed local. Full suite green at 67 files /
807 tests; `cwf-manage validate` clean after the hash refresh.

## Lessons Learned
*Consolidated in j-retrospective.md.*

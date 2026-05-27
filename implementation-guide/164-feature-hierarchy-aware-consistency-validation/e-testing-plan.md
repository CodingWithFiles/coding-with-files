# hierarchy-aware consistency validation - Testing Plan
**Task**: 164 (feature)

## Task Reference
- **Task ID**: internal-164
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/164-hierarchy-aware-consistency-validation
- **Template Version**: 2.1

## Goal
Prove the five FRs (full-depth coverage, directional branch rule, off-chain/fail-closed,
completeness invariant, no flat-repo regression) and the plan-review guards, against
synthetic **nested** task trees in `t/validate-consistency.t`.

## Test Strategy
### Test Levels
- **Integration** (primary): `t/validate-consistency.t` extends the existing Tier-C harness
  — build a throwaway git repo (`CWFTest::Fixtures::create_git_repo`), lay down nested task
  dirs with `make_path` + `write_md`, set HEAD with `system("git -C <repo> checkout -q -b
  <branch>")`, call `CWF::Validate::Consistency::validate($repo)`, and assert on the
  returned violation list (`category`/`field`/`file`).
- **Behavioural unit**: the private `_is_ancestor` and the leaf/completeness logic are
  exercised through `validate`'s public output (not called directly), so tests bind to the
  contract, not internals.
- **Regression**: full `prove t/`; the three existing subtests must pass unchanged.

### Fixture conventions
- **Nested layout** (canonical): a child dir is physically created inside its parent, e.g.
  `implementation-guide/1-feature-p/1.1-bugfix-c/`. The repo has no real subtask dirs, so
  every hierarchy assertion relies on these synthetic fixtures.
- A node's files carry `## Task Reference` (`**Task**`, `**Branch**`) and `## Status`
  (`**Status**`), matching `_extract_fields`/`status_get` parsing.

### Coverage Targets
- Five ACs (AC1–AC5) each asserted; the new branch/completeness logic covered at every
  decision point (leaf found / absent / ambiguous; ancestor / sibling / unrelated;
  complete-with-active-descendant / inverse / missing-status / no-descendant).
- Edge/near-miss cases (`1.1` vs `1.10`, grandparent depth) asserted explicitly.

## Test Cases

### Regression — existing behaviour preserved (FR5 / AC5)
- **TC-R1**: missing `implementation-guide` → empty list (existing subtest, unchanged).
- **TC-R2**: matching `**Task**` num → no `**Task**` violation (existing).
- **TC-R3**: mismatched `**Task**` num → `**Task**` violation (existing).
- **TC-R4**: Finished task, branch mismatch → no `**Branch**` violation (existing —
  terminal ⇒ not active ⇒ branch unchecked).
- **TC-R5 (new flat fixture)**: a repo with **two** top-level tasks (one active on a
  non-current branch, one Finished) → the violation **set and ordering** match the
  pre-change behaviour (locks AC5's "identical", not merely "tests pass").

### FR1 — full-depth coverage (AC1)
- **TC-1**: nested child `1-feature-p/1.1-bugfix-c/` whose file says `**Task**: 1` (wrong;
  dir is `1.1`).
  - **Then**: a `**Task**` violation is reported whose `file` is inside the nested dir
    (proves recursion descends and field-checks subtasks — silent today).

### FR2 — directional branch consistency (AC2)
- **TC-2 (ancestor satisfied)**: parent `1` (active, `**Branch**: feature/1`) + nested child
  `1.1` (active, `feature/1.1`); HEAD on `feature/1.1`.
  - **Then**: no `**Branch**` violation for `1` (ancestor of leaf) nor `1.1` (leaf, matches).
- **TC-2b (grandparent / multi-level)**: chain `1` → `1.1` → `1.1.1`, all active, branches
  `feature/1`, `feature/1.1`, `feature/1.1.1`; HEAD on `feature/1.1.1`.
  - **Then**: zero `**Branch**` violations (both `1` and `1.1` are transitive ancestors).
- **TC-2c (numeric near-miss + sibling)**: parent `1` (active, `feature/1`) with nested
  children `1.1` (active, `feature/1.1`) and `1.10` (active, `feature/1.10`); HEAD on
  `feature/1.10`.
  - **Then**: `1` not flagged (ancestor); `1.10` not flagged (leaf); **`1.1` flagged**
    (sibling, not an ancestor of `1.10` — confirms `1.1` is not mis-read as an ancestor of
    `1.10`).

### FR3 — off-chain flagged, fail-closed (AC3)
- **TC-3a (unrelated active task)**: leaf chain as TC-2 plus an unrelated active top-level
  task `2` (`feature/2`); HEAD on `feature/1.1`.
  - **Then**: `2` is flagged (off-chain), while `1`/`1.1` are not.
- **TC-3b (fail closed on duplicate branch)**: two unrelated top-level tasks `1` and `2`
  both active and both recording `**Branch**: feature/shared`; a third active task `3`
  (`feature/3`); HEAD on `feature/shared`.
  - **Then**: no crash; `1`/`2` not flagged (on `feature/shared` = current); **`3` flagged**
    — the ambiguous (≥2) leaf match disables suppression (flat equality), so nothing is
    silenced. Contrast with TC-2 (exactly one match ⇒ ancestor suppressed) pins the
    0/1/≥2-match contract.

### FR4 — completeness invariant (AC4)
- **TC-4a (Finished parent, active child)**: parent `1` all files Finished (complete) +
  nested child `1.1` Backlog (active).
  - **Then**: a `**Status**` completeness violation whose `file` is `1`'s dir and whose fix
    names `1.1`.
- **TC-4b (Cancelled parent)**: parent `1` all files Cancelled (complete) + active child
  `1.1`.
  - **Then**: completeness violation (confirms `Cancelled` is treated as terminal, named
    explicitly).
- **TC-4c (inverse — permitted)**: parent `1` active (some Backlog) + nested child `1.1`
  all Finished.
  - **Then**: no completeness violation (terminal descendant under active ancestor is fine).
- **TC-4d (missing-status child)**: parent `1` complete + nested child `1.1` with no
  recognised status.
  - **Then**: no completeness violation (`1.1` not "active" ⇒ does not count for FR4).
- **TC-4e (complete leaf, no descendants)**: single complete top-level task `1`, no
  children.
  - **Then**: zero completeness violations (self-match structurally excluded).
- **TC-4f (nearest descendant deterministic)**: complete parent `1` with active children
  `1.1` and `1.2` and active grandchild `1.1.1`.
  - **Then**: exactly one completeness violation for `1`, naming the **nearest** active
    descendant (shallowest; `1.1` before `1.2` by `version_compare`) — locks the tiebreak.

### Non-Functional Test Cases
- **NFR4 / TC-S1 (symlink not followed)**: parent `1` containing a **symlinked** dir
  `1.9-feature-evil` → a dir outside `implementation-guide/` holding a task-shaped `.md`.
  - **Then**: no node/violation references the external dir (the `-l` skip prevents
    descent); validate completes normally.
- **NFR5 / TC-W (no warnings)**: wrap a `validate` call (fixture including a top-level node
  `1` whose `get_parent` is immediately `undef`) in a `$SIG{__WARN__}` trap.
  - **Then**: zero warnings captured (module runs under `use warnings`; confirms the
    `_is_ancestor` loop never calls `get_parent(undef)`).
- **NFR1 (performance)**: implicit — a single recursive pass; no dedicated perf test
  (advisory tool, tree bounded by task-dir count).
- **Security**: dir names / field values never reach a shell — covered structurally by the
  exec-phase security review of the diff (no new `system`/backtick); the only git call is
  the unchanged `_current_branch`.

## Test Environment
### Setup Requirements
- Perl `prove`; core modules only (`Test::More`, `File::Temp`, `File::Path`, `FindBin`);
  `CWFTest::Fixtures` for repo/dir scaffolding. Tier C (git): branch-dependent cases skip
  cleanly when git is unavailable, mirroring the existing `SKIP` guard.
- Each subtest builds an isolated `tempdir(CLEANUP => 1)` repo; no production config or the
  live `implementation-guide/` is touched.

### Automation
- Runs under the standard `prove t/` suite; no CI changes.

## Validation Criteria
- [ ] TC-R1..R5 pass (regression + flat ordering identical) — AC5.
- [ ] TC-1 passes — AC1 (nested field check).
- [ ] TC-2, TC-2b, TC-2c pass — AC2 (ancestor/grandparent/near-miss).
- [ ] TC-3a, TC-3b pass — AC3 (off-chain + fail-closed).
- [ ] TC-4a..TC-4f pass — AC4 (completeness, both polarities, tiebreak).
- [ ] TC-S1, TC-W pass — symlink skip + no warnings.
- [ ] Full `prove t/` green; `cwf-manage validate` clean for the touched files.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned cases (TC-R1–R5, TC-1, TC-2/2b/2c, TC-3a/3b, TC-4a–4f, TC-S1, TC-W)
implemented and passing in `t/validate-consistency.t` (20/20); full suite 600/600.

## Lessons Learned
Cases that don't need a current branch were made git-independent (plain tempdir →
`_current_branch` undef → branch pass skipped), running more coverage in minimal
environments than the all-git-gated plan had assumed.

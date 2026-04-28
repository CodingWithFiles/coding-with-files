# Make cwf-manage update handle a dirty working tree - Testing Plan
**Task**: 116 (bugfix)

## Task Reference
- **Task ID**: internal-116
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/116-make-cwf-manage-update-handle-a-dirty-working-tree
- **Template Version**: 2.1

## Goal
Verify that `check_clean_tree` correctly detects working-tree dirtiness scoped to `.cwf/`/`.cwf-skills/` and that `cmd_update` aborts with the documented recipe before any destructive operation runs. Confirm `cmd_rollback` is automatically covered. Confirm no regression to the existing 235-test baseline.

## Test Strategy

### Test Levels
- **Unit (subtests in `t/cwf-manage-check-clean-tree.t`)**: Exercise the helper directly via the Task 115 `do $SCRIPT` + symbol-table pattern. Each subtest builds an isolated `tempdir` git repo via `make_baseline_repo`. **Load-bearing for the helper's contract**: clean-tree path, dirty-tracked path, untracked-files-included path, cap-overflow formatting, status-failure path.
- **Integration (manual smokes from a tempdir fixture)**: Invoke `cwf-manage update` end-to-end against a synthetic `.cwf/version` to verify the call-site `eval` wrapper, the recipe wording, and that the dirty check runs **before** clone/copy.
- **Regression (full `prove t/`)**: Confirm no existing test breaks. Baseline 235/235; expected post-change ≥240 (5 new subtests).
- **Validation (`cwf-manage validate`)**: Confirm the script-hash bump in `.cwf/security/script-hashes.json` is correct.

### Test Coverage Targets
- **`check_clean_tree` helper**: 100% branch coverage (clean / dirty / status-fail). Spawn-fail is hard to trigger reliably in a sandbox; covered by code review.
- **`cmd_update` call site**: Smoke-tested end-to-end (Scenario B — load-bearing). The call site is one line; no separate unit test.
- **`cmd_rollback`**: Inherited via delegation. Verified by code review of lines 257–263 — no separate runtime test.
- **Regression**: full suite must remain green.

## Test Cases

### Functional Tests — Unit (`t/cwf-manage-check-clean-tree.t`)

| Test ID | Setup | Action | Expected |
|---------|-------|--------|----------|
| TC-1 | `make_baseline_repo` (tracked `.cwf/version`, committed clean) | `main::check_clean_tree($dir)` | Returns without dying; `$@` is empty |
| TC-2 | Baseline + append to `.cwf/version` AND create untracked `.cwf/notes.md` | Same call | Dies; `$@` matches `qr{Working tree has uncommitted changes}` AND mentions both paths AND contains `qr{git stash}` (recipe present) |
| TC-3 | No setup — call against `/nonexistent/path` | `main::check_clean_tree('/nonexistent/path')` | Dies; `$@` matches `qr{Failed to check working tree status}` |

**Given/When/Then** for each:

- **TC-1 (clean tree)**
  - *Given*: A git repo with a single committed snapshot containing `.cwf/version` and no other changes.
  - *When*: `check_clean_tree` is called.
  - *Then*: Returns silently. No exception. No output.

- **TC-2 (dirty: tracked + untracked combined)**
  - *Given*: Clean baseline; `.cwf/version` is appended; a new `.cwf/notes.md` is created.
  - *When*: Helper called.
  - *Then*: Helper dies with the documented header text. The offending tracked path AND the untracked path are both in the file list (verifies `--untracked-files=all`). The recipe (`git stash` etc.) is present in the message — confirms the helper emits the full message itself, no call-site wrapper required.

- **TC-3 (status command fails)**
  - *Given*: A non-git path (`/nonexistent/path`).
  - *When*: Helper called.
  - *Then*: Helper dies with `Failed to check working tree status`. Verifies the `$? != 0` defensive branch from c-design Decision 7 — closes the silent-failure window.

### Functional Tests — End-to-End Smokes

Run from a tempdir fixture: `mktemp -d` + `git init -q` + `git config` + `mkdir .cwf` + populated `.cwf/version` + `git add` + `git commit`. Pattern reused from Task 115's TC-10 smoke.

| Test ID | Scenario | Expected |
|---------|----------|----------|
| TC-4 | **Clean tree, env override** — `CWF_SOURCE=file:///tmp/cwf-nonexistent cwf-manage update` against the fixture | Logs `Cloning CWF source from file:///tmp/cwf-nonexistent (from: CWF_SOURCE env var)...` (Task 115 behaviour preserved) and fails on the clone. **No** dirty error appears. Exit code: non-zero (clone failure). |
| TC-5 | **Dirty `.cwf/`, env override** (load-bearing — the bug being fixed) — `echo dirt > $tmpdir/.cwf/foo.txt && CWF_SOURCE=file:///tmp/cwf-nonexistent cwf-manage update` | Output: `[CWF] ERROR: Working tree has uncommitted changes under .cwf, .cwf-skills:` then `?? .cwf/foo.txt` then the recipe (`Stash or commit them, then re-run:` / `git stash` / `cwf-manage update [ref]` / `git stash pop`). **No** clone attempted. Exit code: 1. |
| TC-6 | **Dirty file outside scope** — `echo dirt >> $tmpdir/README.md && cwf-manage update` | **No** dirty error. Update proceeds to `Cloning CWF source...` (and fails downstream for unrelated reasons). Confirms scope is `.cwf/.cwf-skills` only. |

(Rollback delegation is verified by reading `cmd_rollback` lines 257–263; no separate runtime smoke needed.)

### Non-Functional Tests

| Aspect | Test | Expected |
|--------|------|----------|
| **Usability — error wording** | TC-5 output | Recipe is exactly: `git stash` / `cwf-manage update [ref]` / `git stash pop`. Includes which paths are dirty. |
| **Usability — help text** | `cwf-manage help` after change | Output includes a `Notes:` section mentioning the dirty-tree pre-check. Same heredoc style as the existing `Environment:` section. |
| **Reliability — no destructive op on dirty** | TC-5 | No `Cloning CWF source...` log appears. Check happens **before** `tempdir`/`git clone`. |
| **Reliability — defensive on git failure** | TC-3 (unit) | Non-zero `$?` from `git status` does **not** silently proceed. |
| **Backwards compatibility** | TC-4 + full `prove t/` | Clean-tree update path unchanged from Task 115; existing 235 tests still pass. |
| **Convention** | Modified `cwf-manage` after re-hash | `cwf-manage validate` exits 0. |

Performance and security testing not relevant: the helper is one `git status` call (pre-existing infrastructure) and a list comparison; there is no new network or auth surface.

## Test Environment

### Setup Requirements
- Working tree: `bugfix/116-make-cwf-manage-update-handle-a-dirty-working-tree` at f-impl-exec checkpoint.
- Perl: system Perl with `PERL5OPT=-CDSL` (preserves Task 115 boy-scout fix).
- Git: any modern version (>= 2.7 for `--porcelain -z --untracked-files=all` semantics — universally available).
- Test fixtures: `make_baseline_repo()` per subtest in `t/cwf-manage-check-clean-tree.t`; `mktemp -d` shell fixtures for end-to-end smokes.
- No external services, no network, no privileged operations.

### Automation
- Unit subtests: `prove t/cwf-manage-check-clean-tree.t` and full-suite `prove t/`.
- End-to-end smokes: manual shell sessions captured in g-testing-exec.md (the no-CI convention used in Task 115).

## Validation Criteria
- [ ] **TC-1..TC-3** all pass via `prove t/cwf-manage-check-clean-tree.t`.
- [ ] **TC-4** clean-tree+env smoke shows preserved Task 115 logging and no dirty error.
- [ ] **TC-5** (load-bearing) dirty-tree+env smoke shows the exact recipe and **no** clone attempt; exit code 1.
- [ ] **TC-6** dirty-outside-scope smoke shows no dirty error.
- [ ] Full `prove t/` passes — baseline 235/235 → expected 238/238.
- [ ] `cwf-manage validate` exits 0 after `.cwf/security/script-hashes.json` re-hash.
- [ ] `cwf-manage help` output contains the new `Notes:` block.
- [ ] `cmd_rollback` delegation confirmed by reading lines 257–263 — no runtime smoke needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 116
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

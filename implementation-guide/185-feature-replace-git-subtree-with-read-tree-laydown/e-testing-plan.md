# Replace git-subtree with read-tree laydown - Testing Plan
**Task**: 185 (feature)

## Task Reference
- **Task ID**: internal-185
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/185-replace-git-subtree-with-read-tree-laydown
- **Template Version**: 2.1

## Goal
Define the test strategy that proves AC1–AC10 (b-requirements) plus the two failure modes
surfaced in plan review, with no regression to the existing `t/` suite.

## Test Strategy
### Test Levels
- **Unit**: `cwf-detect-merges` classification (fingerprint, under-claim, counts-only) over
  crafted commit fixtures.
- **Integration**: `install.bash` read-tree laydown into a throwaway consumer repo; subtree
  refusal; copy fallback; reinstall determinism; symlink-escape refusal.
- **System / E2E**: `cwf-manage update` subtree→read-tree migration (positive + negative
  fail-closed); `cwf-manage check-merges`; post-migration `validate` clean.
- **Acceptance**: AC1–AC10 demonstrated.

Framework: Perl `prove` / `Test::More` (core only), matching existing `t/`; throwaway git
repos via `t/lib/CWFTest/Fixtures.pm`. New files: `t/install-bash-read-tree.t`,
`t/cwf-detect-merges.t`, `t/cwf-manage-update-migrate.t`. Extend `t/install-bash-reinstall.t`.

### Test Coverage Targets
- **Critical paths** (laydown, migration, refusal, detection): every AC has an automated test.
- **Edge/error**: symlink-escape, reinstall-with-stale-file, mid-laydown failure, detection
  ambiguity, detection-helper failure.
- **Regression**: full `t/` suite green — especially `install-bash-reinstall`,
  `cwf-manage-update*`, `cwf-check-tree-symlinks`, `installmanifest-integrity`.

## Test Cases
### Functional Test Cases
- **TC-1 (AC1) read-tree laydown is merge-free + tree-exact**
  - **Given**: a throwaway consumer repo (one commit) and a CWF source clone.
  - **When**: `install.bash` runs with `CWF_METHOD` unset (default `read-tree`).
  - **Then**: `git rev-list --merges <base>..HEAD` empty; each dest prefix tree SHA equals
    its mapped source subtree SHA; exec (`100755`) + symlink (`120000`) modes preserved;
    laydown is staged, not committed by CWF.
- **TC-2 (AC3) subtree refused**
  - **Given**: `CWF_METHOD=subtree`.
  - **When**: `install.bash` runs.
  - **Then**: exits non-zero; message names read-tree (primary), copy (fallback), reason; no
    `git subtree add` runs; no partial laydown remains.
- **TC-3 (AC2) copy fallback still installs**
  - **Given**: `CWF_METHOD=copy`. **When**: install. **Then**: succeeds; `.cwf/version`
    records `cwf_method=copy`.
- **TC-4 (AC9) reinstall determinism**
  - **Given**: an existing read-tree install with a stale extra file under a prefix.
  - **When**: forced reinstall (`CWF_FORCE=1`, read-tree).
  - **Then**: laid-down tree is byte/mode-identical to a clean install (stale file gone); no
    merge commit.
- **TC-5 (AC8) symlink-escape refusal on the read-tree path**
  - **Given**: a source tree with an out-of-tree symlink under a prefix.
  - **When**: `install_read_tree`. **Then**: refuses non-zero **before** materialising;
    nothing laid into the consumer tree (fail-closed).
- **TC-6 (AC4 positive) migrate-on-update**
  - **Given**: a consumer recording `cwf_method=subtree` with a subtree-style install.
  - **When**: `cwf-manage update`.
  - **Then**: completes; `.cwf/version` now `cwf_method=read-tree`; no new merge commit;
    `validate` clean.
- **TC-7 (AC4 negative / fail-closed) failed laydown keeps subtree**
  - **Given**: a subtree install with laydown/artefacts/perms forced to fail mid-migration.
  - **When**: `cwf-manage update`.
  - **Then**: `.cwf/version` still `cwf_method=subtree` (never `read-tree`); no half-migrated
    install validates clean under a method it did not reach.
- **TC-8 (AC5) detection total / subset / under-claim**
  - **Given**: a repo with N fingerprinted CWF subtree merges + 1 unrelated merge + 1
    ambiguous (`Add CWF core …` subject but NO subtree marker).
  - **When**: `cwf-detect-merges`.
  - **Then**: total counts all; CWF subset counts only the N fingerprinted; the unrelated and
    ambiguous merges are in the total but NOT the subset.
- **TC-9 (AC6) advisory only**
  - **Given**: the detection surface. **Then**: no code path rewrites history; no
    silence/acknowledge flag; output is counts-only (no raw commit subjects echoed); message
    names re-linearisation as optional and points to the maintainer; helper `exit 0`.
- **TC-10 (AC7) reachable at migration and on demand**
  - **Given**: an installed repo. **When**: `cwf-manage check-merges`. **Then**: read-only
    report, repo unchanged (no index/worktree/ref mutation). The TC-6 migration also emits
    the warning.
- **TC-11 (extra-a) mid-laydown failure is recoverable + idempotent**
  - **Given**: a read-tree laydown interrupted after clearing some prefixes (or a `read-tree`
    failure).
  - **When**: re-run. **Then**: completes cleanly (the unconditional clear makes re-laydown
    idempotent); final tree equals a clean install.
- **TC-12 (extra-b) detection failure does not abort migration**
  - **Given**: `cwf-detect-merges` forced to fail (non-zero / die).
  - **When**: subtree→read-tree migration `update`.
  - **Then**: migration still completes successfully (`.cwf/version` `read-tree`); the helper
    rc is ignored.
- **TC-13 (AC10) docs + default flipped**
  - **Given**: the repo. **Then**: `install.bash` default is `read-tree`; INSTALL.md names
    read-tree default + copy fallback + subtree deprecated, and no longer calls all methods
    "first-class" (grep smoke).

### Non-Functional Test Cases
- **Security**: TC-5 (symlink-escape fail-closed); TC-9 (display-only / no injection, no
  silencing); list-form spawn + NUL-safe reads verified at exec-phase
  `security-review-changeset`. No raw attacker-controlled subject reaches stdout.
- **Performance**: `cwf-detect-merges` single-pass; sub-second on a typical-size fixture
  (informal timing assertion, not a hard benchmark).
- **Reliability**: TC-7 (fail-closed migration), TC-11 (idempotent re-run), TC-12
  (detection-failure-tolerant).
- **Usability**: TC-2 and TC-9 assert message content (alternative method named; maintainer
  + optional re-linearisation).

## Test Environment
### Setup Requirements
- Throwaway git repos in tempdirs via `t/lib/CWFTest/Fixtures.pm`; a CWF source clone
  fixture. The subtree-fixture (TC-6/7/12) is built by laying a mini source down with the
  legacy `git subtree add --squash` path (or crafting equivalent merge commits) so a
  `cwf_method=subtree` starting state exists.
- **Constraint** (per project memory): `cwf-manage validate` uses `find_git_root()` and
  cannot target a tempdir — `validate`-asserting cases (TC-6) write to the actual repo
  config and restore after, following `t/cwf-manage-update-end-to-end.t`.
- No production data; all git state is throwaway. No network (fetch is from the local clone).

### Automation
- `prove t/` (and CI if present); new `.t` files self-contained and core-only.

## Validation Criteria
- [ ] TC-1…TC-13 implemented and passing
- [ ] AC1–AC10 each covered by ≥1 automated test
- [ ] Full `t/` suite green (no regression)
- [ ] `cwf-manage validate` clean after a read-tree install and after a migration
- [ ] Exec-phase `security-review-changeset` raises no FR4 issue

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

# Fix install.bash reinstall and settings-merge - Testing Plan
**Task**: 158 (bugfix)

## Task Reference
- **Task ID**: internal-158
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/158-fix-install-bash-reinstall-and-settings-merge
- **Template Version**: 2.1

## Goal
Validate the three Option-B fixes: item 1 (force-reinstall commit), item 2
(settings-merge in post_install), item 3 (security-review.md doc). Both the
happy path and the failure paths the fixes turn on (which the old `|| true`
swallowed) must be exercised.

## Test Strategy
### Test Levels
- **End-to-end (item 1, item 2)**: drive real `bash install.bash` with `CWF_FORCE=1` against a scratch git repo + fixture source, reusing the Task-155 fixture-server pattern in `t/cwf-manage-update-end-to-end.t`. This is the only level that reproduces the dirty-index and missing-settings symptoms.
- **Static/doc (item 3)**: assert the doc enumeration matches the helper's `@CWF_INTERNAL_PREFIXES`.
- **Regression**: full Perl suite + `cwf-manage validate` unchanged-green.

### Test Coverage Targets
- Item 1: the missing-dir reinstall (the reported bug), plus the two failure/edge cases the new logic introduces (tracked-dir `git rm` failure; mixed tracked/untracked pre-state).
- Item 2: settings-merge applied on success; install aborts (no version file) on merge failure.
- Item 3: exact-string presence + helper-parity.

## Test Cases
### Functional Test Cases
- **TC-1 (item 1, the reported bug) — reinstall with a CWF dir absent in the pre-state**
  - **Given**: a scratch repo with a copy-style pre-state containing tracked `.cwf`, `.cwf-skills`, `.cwf-rules` but **no** `.cwf-agents`
  - **When**: `CWF_FORCE=1 CWF_METHOD=subtree bash install.bash` runs against the fixture source
  - **Then**: the removal commit succeeds with only the present dirs; every `git subtree add` runs against a clean index; install exits 0; `.cwf .cwf-skills .cwf-rules .cwf-agents` all present afterwards

- **TC-2 (item 1, failure path) — tracked dir whose `git rm` fails aborts**
  - **Given**: a pre-state where a tracked CWF dir cannot be cleanly `git rm`'d (simulate a `git rm` failure)
  - **When**: the force-removal block runs
  - **Then**: install **aborts via `die`** (non-zero exit, `[CWF] ERROR:` message) rather than proceeding with a dirty index — verifies the removed `|| true` no longer hides the failure

- **TC-3 (item 1, edge) — mixed tracked/untracked pre-state**
  - **Given**: a CWF dir containing both tracked and untracked files
  - **When**: the force-removal block runs
  - **Then**: the dir is removed from both index and worktree, the commit covers the tracked deletions, and the index is clean for subtree add (no leftover staged/untracked CWF paths)

- **TC-4 (item 2, happy path) — settings-merge applied on fresh install**
  - **Given**: a scratch repo with no prior `.claude/settings.json` CWF entries
  - **When**: `bash install.bash` completes (either method)
  - **Then**: `.claude/settings.json` contains `env.PERL5OPT == "-CDSLA"` and the Bash allowlist entries the helper derives — confirming the merge ran without `/cwf-init`

- **TC-5 (item 2, failure path) — merge failure aborts before version write**
  - **Given**: `cwf-claude-settings-merge` made to exit non-zero (e.g. a malformed pre-existing `.claude/settings.json`)
  - **When**: `post_install` reaches the merge call
  - **Then**: install **aborts** with `die`; `.cwf/version` is **not** written and success is **not** logged — mirrors `cwf-manage`'s abort-before-version-write invariant

- **TC-6 (item 2, guard) — missing helper tolerated**
  - **Given**: the `cwf-claude-settings-merge` helper absent/non-executable
  - **When**: `post_install` runs
  - **Then**: the `-x` guard skips the call, install completes (mirrors `run_settings_merge`'s `return unless -x`)

- **TC-7 (item 3) — doc lists `.claude/agents/` and matches the helper**
  - **Given**: `.cwf/docs/skills/security-review.md` §Pathspec coverage and `security-review-changeset`'s `@CWF_INTERNAL_PREFIXES`
  - **When**: the prefixes named in the doc prose are compared to the helper list
  - **Then**: every helper prefix (including `.claude/agents/`) appears in the doc; no drift

### Non-Functional Test Cases
- **Reliability**: TC-1 reinstall is deterministic and idempotent (a second `CWF_FORCE` reinstall also succeeds).
- **Regression (integrity)**: `cwf-manage validate` stays green (neither edited file is hash-tracked, so no `script-hashes.json` change is expected); full Perl suite passes unchanged.
- **Sanity (no regression on rules-inject)**: after TC-1, `.cwf/rules-inject.txt` is non-empty (it ships in the subtree) — guards against any accidental emptying.
- **Security**: exec-phase security-review changeset over the two edited files; expected `no findings` (no user-input interpolation; helpers reused unchanged).

## Test Environment
### Setup Requirements
- Reuse `t/cwf-manage-update-end-to-end.t`'s fixture-server + scratch-repo helpers; new test file `t/install-bash-reinstall.t` (or similar — final name at exec).
- Fixture source must carry the four subtree prefixes so `subtree split` works; pre-states are constructed per TC.
- Core Perl only; no new non-core deps (test harness conventions).

### Automation
- New `.t` file runs under the existing `prove`-based suite; no CI change beyond adding the file.

## Validation Criteria
- [ ] TC-1: missing-dir reinstall completes with a clean index (the reported bug fixed)
- [ ] TC-2 + TC-3: item-1 failure/edge paths behave (abort on tracked-rm failure; clean on mixed pre-state)
- [ ] TC-4: settings-merge applied without `/cwf-init`
- [ ] TC-5 + TC-6: merge failure aborts before version write; missing helper tolerated
- [ ] TC-7: doc matches helper `@CWF_INTERNAL_PREFIXES`
- [ ] Regression: full suite + `cwf-manage validate` green; `.cwf/rules-inject.txt` still populated

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1..TC-7 implemented in `t/install-bash-reinstall.t`; all green. The Task-155
fixture-server pattern was reused as planned (helpers copied locally rather than
extracting a shared test lib — scope-appropriate for a bugfix).

## Lessons Learned
The fake-git PATH shim (planned as "simulate a git rm failure") proved both
deterministic and root-independent — a reusable technique for install/update
failure-path tests.

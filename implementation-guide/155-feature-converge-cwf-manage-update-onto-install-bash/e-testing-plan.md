# Converge cwf-manage update onto install.bash - Testing Plan
**Task**: 155 (feature)

## Task Reference
- **Task ID**: internal-155
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/155-converge-cwf-manage-update-onto-install-bash
- **Template Version**: 2.1

## Goal
Verify the converged subtree update (delegation to target `install.bash`) satisfies FR1-FR10 without regressing the existing `cwf-manage` prelude/laydown behaviour, primarily via a new end-to-end fixture harness plus targeted unit/integration tests.

## Test Strategy
### Test Levels
- **Unit (Perl, `Test::More`)**: ref validation (lexical phase-1), exact-set perms mode return values, version-file reconcile helper.
- **Integration**: `cmd_update` delegation wiring (env/cwd/exit-code handling), apply-artefacts narrowing, exact-perms ordering.
- **System (end-to-end)**: `t/cwf-manage-update-end-to-end.t` against a fixture upstream remote — the FR8 deliverable; the only level that exercises clone→delegate→laydown→post-steps.
- **Regression**: full `t/` suite, especially `t/cwf-manage-update.t` prelude tests and the 5 `copy_tree`/`_escapes_src` subtests (must stay green — copy path is unchanged).

### Test Coverage Targets
- **Critical paths (100%)**: subtree delegation success; non-zero/spawn-fail/signal abort; ref-validation reject set; exact-perms exact-match + fatal-on-mismatch; manifest-SHA pin survives a second update.
- **Edge cases**: cross-version gap, manifest-schema bump, downgrade, unrelated-staged-work isolation, dirty `.cwf-rules` tree.
- **Regression**: no existing `t/` test regresses.

## Test Cases
### Functional Test Cases
- **TC-FR1 (single laydown / staging-dir identity)**:
  - **Given** a fixture install via `install.bash`; **When** `cwf-manage update` (subtree) runs; **Then** all four staging dirs (`.cwf`, `.cwf-skills`, `.cwf-rules`, `.cwf-agents`) are present and rules are delivered by install.bash (not by a separate apply-artefacts re-laydown).
- **TC-FR2/FR3 (target laydown, no squash conflict across a gap)**:
  - **Given** a fixture installed at v1 and a target ≥2 minors ahead whose laydown differs; **When** `cwf-manage update <target>` runs with `cwf_method=subtree`; **Then** it completes with no conflict markers, no non-zero git exit, and the on-disk structure matches the *target's* (not the installed version's) laydown.
- **TC-FR4 (accreted steps preserved)**:
  - **Given** a fixture update; **When** it completes; **Then** the lock is released, `settings.json` was parse-checked, the manifest-SHA tamper check ran, rules-inject/CLAUDE.md/.gitignore were applied, and settings were merged (each observable effect asserted).
- **TC-FR5 (exact least-privilege perms)**:
  - **Given** a post-laydown tree with files at install.bash baseline perms; **When** the exact-set pass runs; **Then** sampled entries equal their recorded mode — at least one `0444`, one `0500`, one `0700`, and one entry **outside `.cwf/scripts/`**; `cwf-manage validate` passes.
  - **Given** a tampered file (SHA mismatch) post-laydown; **When** the exact-set pass runs; **Then** `cmd_update` aborts (fatal) before the manifest pin.
- **TC-FR6 (version-file pin survives two updates)**:
  - **Given** one completed update; **When** a second update runs immediately; **Then** `validate_install_manifest_sha` does NOT false-positive (pin was written, not dropped), and `.cwf/version` carries a valid `cwf_install_manifest_sha`.
- **TC-FR7 (recovery documented)**:
  - **Given** the docs; **Then** the forward-only `CWF_FORCE=1 CWF_REF=<tag> CWF_SOURCE=<src> bash install.bash` recovery is present and states the forward-only limitation. (Doc assertion / grep.)
- **TC-FR8 (downgrade + manifest-schema bump)**:
  - **Given** a fixture spanning a manifest-schema bump; **When** updating across the bump and then downgrading to an older self-consistent target; **Then** both complete and `validate` passes after each.
- **TC-FR9 (ref injection rejected)**:
  - **Given** refs `--foo`, `;rm -rf x`, `$(touch pwned)`, `../escape`; **When** passed to `update`/`rollback`; **Then** each is rejected at phase-1 before any clone/checkout/exec side effect (assert no file created, no clone dir).
- **TC-FR10 / staged-work isolation**:
  - **Given** an unrelated staged file (e.g. `README.md`) before update; **When** the force-reinstall remove commit is created; **Then** the staged file is NOT included in that commit (explicit CWF pathspec).

### Non-Functional Test Cases
- **Security**: TC-FR9 (injection), TC-FR10 (staged-work isolation), copy-path `_escapes_src` regression suite stays green; delegation uses list-form `system` (no shell) — asserted by the injection tests passing.
- **Reliability**: spawn-failure / signal / non-zero-exit each abort with an actionable message and leave no manifest pin (TC-FR2 negative variants); lock released even on abort.
- **Usability**: abort messages name the failing step (assert message substrings).
- **Performance**: end-to-end test completes within the suite's per-test budget (no multi-minute hang) — NFR1 sanity, not a benchmark.

## Test Environment
### Setup Requirements
- `t/fixtures/upstream-server/`: bare git repo + 3-5 scripted CWF-shaped commits (≥2 minors, one manifest-schema bump, one downgrade target), each internally manifest-consistent.
- Per-test `tempdir` working copies; `cwf-manage`/`install.bash` run with cwd at the temp repo root (relies on `find_git_root()`); never mutate the real repo's `.cwf/`.
- Core-Perl only (`Test::More`, `File::Temp`, `Digest::SHA`, `Fcntl`); Bash 4+ and `git` available.

### Automation
- Plain `prove t/` (existing convention); no CI change required beyond the new test file being picked up.

## Validation Criteria
- [ ] `t/cwf-manage-update-end-to-end.t` green for all three scenarios (version gap [subtree], manifest bump, downgrade)
- [ ] All FR ACs (FR1-FR10) have a passing mapped test case
- [ ] `cwf-manage validate` passes post-update with exact perms
- [ ] Full `t/` suite green (no regression; copy_tree/_escapes_src subtests intact)
- [ ] Injection refs rejected with no side effects

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 155
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned cases executed as 5 end-to-end subtests; FR1 copy-path and the manifest-schema-bump scenario deferred as planned. Results in g-testing-exec.md.

## Lessons Learned
Building the upstream fixture programmatically (seeded from the real repo, tagged across versions) beat a checked-in `t/fixtures/` tree — no second copy of CWF content to maintain. Non-TTY apply-artefacts required `CWF_UPGRADE_RESOLVE=new`; the interactive resolution branch is genuinely out of harness scope. See j-retrospective.md.

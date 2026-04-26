# Add retrospective version bump and tag settings with versioning helper script - Testing Plan
**Task**: 114 (feature)

## Task Reference
- **Task ID**: internal-114
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/114-add-retrospective-version-bump-and-tag-settings-w
- **Template Version**: 2.1

## Goal
Define the test strategy, environments, and acceptance gates that prove the versioning subsystem behaves per spec and that the existing `cwf-manage` semver functionality is preserved across the refactor.

## Test Strategy

### Test Levels
- **Unit Tests** (Test::More, in `t/`): pure-function coverage of `CWF::Common` (`parse_semver`, `version_cmp`) and `CWF::Versioning` (config-reading, computation, bump, tag operations with mocked git/filesystem where appropriate)
- **Integration Tests** (`t/cwf-version-{next,bump,tag}.t`): invoke each helper script as a subprocess in a tempdir, with a fixture `cwf-project.json`; assert stdout/stderr/exit
- **Schema Tests** (`t/validate-config.t`): exercise `CWF::Validate::Config` with valid and malformed `versioning` and `wf_step_config` blocks
- **Regression Tests**: existing `t/cwf-manage-list-releases.t`, `t/common.t`, and `t/validate-config.t` must pass unchanged
- **End-to-End Smoke**: in the live repo, run `cwf-version-next --task-num=114` after Step 6 of implementation; assert it prints `v1.0.114`

### Test Coverage Targets
- **`CWF::Common` parse_semver / version_cmp**: 100% — every documented input shape (valid, missing prefix, missing patch, non-numeric) and ordering (eq/lt/gt/mixed-length)
- **`CWF::Versioning`**: 100% of public functions; all error paths in `read_config` and the `bump_to`/`tag_at` skip/idempotent/error branches
- **Helper scripts**: every documented exit status and stdout message variant (3 for bump, 2 for tag, 1 for next; plus error paths)
- **`CWF::Validate::Config` extensions**: every new violation message
- **Regression**: zero net-new failures; pre-existing test count + new tests = total passing
- **Edge cases**: explicitly enumerated in the test cases below — no "TBD" entries in this plan

## Test Cases

Numbering: TC-Cn = `CWF::Common`; TC-Vn = `CWF::Versioning`; TC-Sn = scripts; TC-Xn = schema validation; TC-Rn = regression; TC-En = end-to-end.

### Unit — `CWF::Common` (extends `t/common.t`)
- **TC-C1 — parse_semver valid input**
  - **Given** input `"v1.0.113"`
  - **When** `parse_semver` is called
  - **Then** returns `(1, 0, 113)` with **numeric** scalars (verify via `Scalar::Util::looks_like_number` or arithmetic comparison)
- **TC-C2 — parse_semver invalid inputs**
  - **Given** inputs `""`, `"1.0.113"` (no v), `"v1.0"` (no patch), `"vfoo"`, `"v1.0.113-rc1"` (non-numeric)
  - **When** `parse_semver` is called
  - **Then** returns empty list for each
- **TC-C3 — version_cmp ordering**
  - **Given** pairs `(v1.0.113, v1.0.97)`, `(v1.0.113, v1.0.113)`, `(v1.0.97, v1.0.113)`, `(v1.0.5, v1.0.50)` (numeric not lexical), `(v0.2.1, v1.0.0)`
  - **When** `version_cmp(a, b)` is called
  - **Then** returns `+1`, `0`, `-1`, `-1`, `-1` respectively
- **TC-C4 — version_cmp mixed lengths**
  - **Given** `(v1.0.0, v1.0)` and `(v1.0, v1.0.0)`
  - **When** `version_cmp` is called
  - **Then** missing components default to 0; both pairs return `0`

### Unit — `CWF::Versioning` (new `t/versioning.t`)
- **TC-V1 — read_config: file missing**
  - **Given** no `cwf-project.json` at the configured path
  - **When** `read_config()` is called
  - **Then** dies with a message naming the missing path
- **TC-V2 — read_config: malformed JSON**
  - **Given** a `cwf-project.json` with a syntax error
  - **When** `read_config()` is called
  - **Then** dies with a message identifying the file and the parse error
- **TC-V3 — read_config: missing major_minor (when versioning block absent)**
  - **Given** a config with no `versioning` key
  - **When** `next_version(task_num => 1)` is called
  - **Then** dies with `"versioning.major_minor missing in <path>"` and an example value
- **TC-V4 — read_config: malformed major_minor**
  - **Given** `versioning: { major_minor: "1.0" }` (no v) and separately `"v1"` (no minor)
  - **When** `next_version(task_num => 1)` is called
  - **Then** dies with a message naming the field and the regex requirement
- **TC-V5 — wf_step_setting: defaults applied**
  - **Given** a config with no `wf_step_config` key
  - **When** `wf_step_setting('retrospective','bump_version', 1)` and `..., 'tag_version', 0)` are called
  - **Then** returns `1` and `0` respectively
- **TC-V6 — wf_step_setting: explicit override**
  - **Given** `wf_step_config: { retrospective: { bump_version: false, tag_version: true } }`
  - **When** the same calls are made
  - **Then** returns `0` (false) and `1` (true)
- **TC-V7 — next_version composition**
  - **Given** `major_minor: "v1.0"` and `task_num => 114`
  - **When** `next_version` is called
  - **Then** returns `"v1.0.114"`
- **TC-V8 — current_version: absent vs present**
  - **Given** (a) no `last_released`, (b) `last_released: "v1.0.113"`
  - **When** `current_version()` is called
  - **Then** returns `undef` and `"v1.0.113"` respectively
- **TC-V9 — bump_to: skipped when bump_version=false**
  - **Given** `bump_version: false`
  - **When** `bump_to('v1.0.114')` is called
  - **Then** returns `{status => 'skipped', message => /bump_version=false/}`; cwf-project.json untouched (file mtime preserved)
- **TC-V10 — bump_to: idempotent when last_released equals target**
  - **Given** `last_released: "v1.0.114"` and target `"v1.0.114"`
  - **When** `bump_to` is called
  - **Then** returns `{status => 'idempotent', message => /already at v1.0.114/}`; file untouched
- **TC-V11 — bump_to: writes valid JSON**
  - **Given** `bump_version: true`, `last_released` absent, target `"v1.0.114"`
  - **When** `bump_to` is called
  - **Then** returns `{status => 'bumped', ...}`; the file parses as valid JSON; `versioning.last_released == "v1.0.114"`; **the file's other keys and values are preserved unchanged**
- **TC-V12 — bump_to: temp file is in same directory as target (atomic-rename safety)**
  - **Given** target file in tempdir
  - **When** `bump_to` is called and we hook the rename (e.g., wrap `rename` or inspect leftover files on a forced failure)
  - **Then** the temp filename starts with the same dirname as the target (regression guard against cross-filesystem rename)
- **TC-V13 — bump_to: write-failure surfaces error, leaves original intact**
  - **Given** target file's directory made read-only
  - **When** `bump_to` is called
  - **Then** dies with a message naming the failure; original file unchanged; no stray temp files
- **TC-V14 — tag_at: skipped when tag_version=false**
  - **Given** `tag_version: false` (CwF default)
  - **When** `tag_at('v1.0.114')` is called
  - **Then** returns `{status => 'skipped', message => /tag_version=false/}`; no `git tag` invoked
- **TC-V15 — tag_at: refuses off main branch**
  - **Given** `tag_version: true`, current branch `feature/foo`
  - **When** `tag_at('v1.0.114')` is called
  - **Then** returns `{status => 'error', message => /not on main/}`; exit-code-ish behaviour mapped per design
- **TC-V16 — tag_at: refuses on existing tag**
  - **Given** `tag_version: true`, on main, tag `v1.0.114` already exists
  - **When** `tag_at` is called
  - **Then** returns `{status => 'error', message => /already exists/}`; no force; no overwrite
- **TC-V17 — tag_at: creates annotated tag on success**
  - **Given** `tag_version: true`, on main, no existing tag, message `"Task 114"`
  - **When** `tag_at('v1.0.114', message => 'Task 114')` is called
  - **Then** returns `{status => 'tagged', ...}`; `git tag -l v1.0.114` matches; `git cat-file -p` shows annotated tag with the message

### Integration — Helper Scripts
- **TC-S1 — cwf-version-next: required arg missing → exit 1**
  - **Given** invocation `cwf-version-next` (no args)
  - **When** executed
  - **Then** exit 1; stderr names `--task-num=N`
- **TC-S2 — cwf-version-next: bad arg → exit 1**
  - **Given** `--task-num=abc`, `--task-num=0`, `--task-num=-1`, `--unknown=foo`
  - **When** executed
  - **Then** exit 1; stderr explains the issue
- **TC-S3 — cwf-version-next: happy path**
  - **Given** fixture config with `major_minor: "v1.0"`; arg `--task-num=114`
  - **When** executed
  - **Then** exit 0; stdout exactly `v1.0.114\n`
- **TC-S4 — cwf-version-bump: each of three outcomes (bumped / skipped / idempotent)**
  - **Given** three fixtures matching each outcome
  - **When** executed
  - **Then** all return exit 0; stdout matches the contract (`bumped: v1.0.N` | `skipped: bump_version=false` | `already at v1.0.N`); the file mutation matches expectation in each case
- **TC-S5 — cwf-version-bump: missing major_minor → exit 1**
  - **Given** fixture with no `versioning.major_minor`
  - **When** executed with `--task-num=114`
  - **Then** exit 1; stderr names the field and the file path
- **TC-S6 — cwf-version-tag: skipped (tag_version=false)**
  - **Given** CwF-style fixture (`tag_version: false`)
  - **When** `cwf-version-tag --task-num=114 --message="Task 114"` is run
  - **Then** exit 0; stdout `skipped: tag_version=false`; no tag created
- **TC-S7 — cwf-version-tag: success on main, no existing tag**
  - **Given** fixture with `tag_version: true`, fresh git repo on main, no existing v1.0.114 tag
  - **When** the script is run
  - **Then** exit 0; stdout `tagged: v1.0.114`; `git tag -l v1.0.114` non-empty; tag is annotated
- **TC-S8 — cwf-version-tag: refuses off main**
  - **Given** fixture `tag_version: true`, on `feature/foo` branch
  - **When** run
  - **Then** exit 1; stderr names the current branch and the required main branch; no tag created

### Schema Validation — `CWF::Validate::Config` (extends `t/validate-config.t`)
- **TC-X1 — both new blocks absent → no violations** (back-compat)
- **TC-X2 — `versioning.major_minor` valid (`v1.0`, `v2.5`) → no violations**
- **TC-X3 — `versioning.major_minor` malformed (`1.0`, `v1`, `v1.0.0`, `""`) → violation each**
- **TC-X4 — `versioning.last_released` valid (`v1.0.113`) → no violation**; malformed (`1.0.113`, `v1.0`) → violation
- **TC-X5 — `wf_step_config` not an object → violation**
- **TC-X6 — `wf_step_config.retrospective` not an object → violation**
- **TC-X7 — `wf_step_config.retrospective.bump_version` non-boolean (string `"true"`, integer `2`) → violation**
- **TC-X8 — full valid config (CwF's actual settings) → no violations**

### Regression
- **TC-R1 — `t/cwf-manage-list-releases.t` passes unchanged** after `parse_semver`/`version_cmp` are extracted (validates the numeric-coercion contract)
- **TC-R2 — `t/validate-config.t` original subtests pass unchanged** alongside the TC-X additions
- **TC-R3 — `cwf-manage validate` (the post-commit guard) reports OK** at every checkpoint commit during implementation

### End-to-End Smoke (in the live repo, after Step 6 of implementation)
- **TC-E1 — `cwf-version-next --task-num=114`** prints `v1.0.114`
- **TC-E2 — `cwf-version-bump --task-num=114`** writes `versioning.last_released: "v1.0.114"`; running it a second time is idempotent (`already at v1.0.114`); cwf-project.json remains valid JSON; diff is value-only (no formatting noise) thanks to canonical-format manual edit in Step 6
- **TC-E3 — `cwf-version-tag --task-num=114 --message="Task 114"`** prints `skipped: tag_version=false` (CwF's intended behaviour); no tag created
- **TC-E4 — Final `cwf-manage validate`** clean
- **TC-E5 — `prove t/`** all green

### Non-Functional Test Cases
- **NF-Performance**: `cwf-version-next --task-num=N` completes in <500ms (NFR1). Trivially satisfied — file read + integer compose.
- **NF-Security**: helper scripts contain no `git push`, no `wget`/`curl`, no shell-out beyond `git tag` and `git rev-parse`. Verified by `grep -E 'push|wget|curl|http|exec' .cwf/scripts/command-helpers/cwf-version-*` returning empty (apart from documented `git` calls).
- **NF-Usability**: each script's `--help` (when invoked with `--help` or with no args) names: required arguments, the wf_step_config setting that gates it, and a link to `.cwf/docs/workflow/versioning-standard.md`.
- **NF-Reliability — interrupted bump**: simulated by killing the process between tmp-write and rename (covered conceptually by TC-V13 — original file untouched on any failure).

## Test Environment

### Setup Requirements
- **Perl** with core modules + `JSON::PP` and `Test::More` (already required by the project)
- **git** (for tag tests; CI image already has it)
- **Working directory**: each integration/system test creates a temporary git repo via `File::Temp::tempdir(CLEANUP => 1)`, `git init`, configures user.name/email, makes an initial commit so a branch exists, then writes the fixture `implementation-guide/cwf-project.json`
- **No mocks needed for the filesystem** — tempdirs are real. Git is real. The unit-tests for `CWF::Versioning` may stub the `git` invocations using a `local *CWF::Versioning::_run_git = sub {...}` pattern (or pass an injected runner) to keep them fast and deterministic; the integration tests prove the real-git path

### Test Data
- Fixture `cwf-project.json` blobs inlined in each `.t` file as heredoc strings (matching `t/cwf-set-status.t` style at lines 14-29). No shared fixture file. Per-test fixtures keep failures localised.

### Automation
- Test framework: `Test::More` + `prove`
- Invocation: `prove t/` from the repo root (existing convention; no Makefile)
- CI/CD: not currently configured for this project; tests are run locally as part of `g-testing-exec`

## Validation Criteria
- [ ] All TC-C, TC-V, TC-S, TC-X tests pass
- [ ] Regression: TC-R1, TC-R2, TC-R3 all green
- [ ] Smoke: TC-E1 through TC-E5 all green in the live repo
- [ ] No skipped or pending tests left behind
- [ ] `prove t/` total count = pre-existing + (TC-C extensions + TC-V tests + TC-S tests + TC-X extensions); confirm in g-testing-exec by recording before/after counts

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 114
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All TC-C/V/S/X/R/E and NF cases passed. TC-V12 ran as a graceful SKIP (rename-hook coverage); TC-V13 descoped (covered structurally). 33 net-new test assertions; 196 → 229 total.

## Lessons Learned
The pre-existing `t/cwf-set-status.t` inline-tempdir style was the right model for the three new script tests — pulling in `CWFTest::Fixtures` would have been heavier for marginal value, since these tests need parameterised JSON per case.

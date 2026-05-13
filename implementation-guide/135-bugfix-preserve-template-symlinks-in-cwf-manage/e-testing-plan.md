# Preserve template symlinks in cwf-manage - Testing Plan
**Task**: 135 (bugfix)

## Task Reference
- **Task ID**: internal-135
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/135-preserve-template-symlinks-in-cwf-manage
- **Template Version**: 2.1

## Goal
Verify both bug fixes via automated tests at the level the project already uses (`prove -rv t/`): a unit-test file for the new validator (`t/validate-templates.t`) and extended subtests in `t/cwf-manage-update.t` for the `copy_tree` symlink branch. No new test frameworks introduced; all assertions go through `Test::More` (Perl core).

## Test Strategy

### Test Levels
- **Unit** (`t/validate-templates.t`, NEW): isolated tests for `CWF::Validate::Templates::validate` against `File::Temp::tempdir(CLEANUP => 1)` fixtures. Validator is pure (no I/O outside the file system it is handed), so unit testing is the natural fit.
- **Integration** (`t/cwf-manage-update.t`, EXTENDED): subtests that exercise `copy_tree` directly through its public function — relative-symlink preservation, absolute-target rejection, escape-target rejection. Same `File::Temp::tempdir` fixture pattern as the rest of `t/cwf-manage-*.t`.
- **End-to-end smoke** (manual, recorded in `g-testing-exec.md`): one round-trip in this actual repo — break a template symlink → `cwf-manage validate` reports the violation → restore the symlink → `validate` is green. Restore before commit.

**Not in scope** (existing convention; no need to invent):
- Performance / load testing — the change is in install-time code, not hot path.
- Acceptance / user-story testing — internal tool, no end-user surface change.
- Mock services — there are none; everything is local file system.

### Test Coverage Targets
- **`CWF::Validate::Templates::validate`**: every branch reachable. Five test inputs cover all four exit branches (no violation, `type` violation, `target` violation, `pool-name` violation) plus the `pool/` ignored case. No branch should be untested.
- **`copy_tree` symlink branch**: three inputs cover the happy path and the two refusal paths.
- **`_escapes_src`**: exercised indirectly through `copy_tree` tests; no separate unit tests needed — the helper has no observable behaviour outside `copy_tree`'s decision.
- **Regression**: full `prove -rv t/` must pass — including all existing tests (currently ~30 files) — before merge. No coverage target for the rest of the codebase; baseline must not drop.

## Test Cases

### Functional Test Cases — `t/validate-templates.t`

- **TC-V1: Happy path produces no violations**
  - **Given**: a fixture tempdir with `<git_root>/.cwf/templates/pool/a-task-plan.md.template` (regular file) and `<git_root>/.cwf/templates/feature/a-task-plan.md.template -> ../pool/a-task-plan.md.template` (symlink). `cwf-project.json` minimal stub providing `supported-task-types: [feature]`.
  - **When**: `CWF::Validate::Templates::validate($fixture_root)` is called.
  - **Then**: returns the empty list.

- **TC-V2: Regular file in place of symlink → `type` violation**
  - **Given**: fixture as TC-V1 but with `feature/a-task-plan.md.template` as a regular file (any content).
  - **When**: validate.
  - **Then**: returns exactly one violation with `category => 'TEMPLATES'`, `file =>` the relative path, `field => 'type'`, `actual => 'regular file'`, `expected => 'symlink to ../pool/a-task-plan.md.template'`. `fix` contains the literal substring `cwf-manage update` and the literal `ln -sfn ../pool/a-task-plan.md.template`.

- **TC-V3: Directory in place of symlink → `type` violation with `actual => 'directory'`**
  - **Given**: fixture as TC-V1 but with `feature/a-task-plan.md.template/` as an empty directory.
  - **When**: validate.
  - **Then**: one violation, `field => 'type'`, `actual => 'directory'`. Confirms the `-d _ ? 'directory' : 'regular file'` branch in `_v`.

- **TC-V4: Dangling symlink → `target` violation**
  - **Given**: fixture as TC-V1 but `feature/a-task-plan.md.template -> ../pool/does-not-exist`.
  - **When**: validate.
  - **Then**: one violation, `field => 'target'`, `actual => '../pool/does-not-exist'`, `expected => '../pool/a-task-plan.md.template'`.

- **TC-V5: Symlink to existing-but-wrong pool entry → `pool-name` violation**
  - **Given**: fixture has both `pool/a-task-plan.md.template` and `pool/c-design-plan.md.template`; `feature/a-task-plan.md.template -> ../pool/c-design-plan.md.template`.
  - **When**: validate.
  - **Then**: one violation, `field => 'pool-name'`, `actual => '../pool/c-design-plan.md.template'`, `expected => '../pool/a-task-plan.md.template'`.

- **TC-V6: Absolute symlink target → caught by exact-pattern check**
  - **Given**: `feature/a-task-plan.md.template -> /etc/passwd`.
  - **When**: validate.
  - **Then**: one violation. `field` depends on `-e $resolved`: if the absolute target exists on the test host, `field => 'pool-name'`; otherwise `field => 'target'`. In both cases `actual => '/etc/passwd'`. Test asserts `field` is one of the two acceptable values and `actual` is exactly `/etc/passwd` — does not assert which, since `/etc/passwd` existence varies by host.

- **TC-V7: Escaping relative symlink → caught by exact-pattern check**
  - **Given**: `feature/a-task-plan.md.template -> ../../etc/passwd`.
  - **When**: validate.
  - **Then**: same shape as TC-V6 (`pool-name` if resolved path happens to exist, `target` otherwise), `actual => '../../etc/passwd'`. Comment in the test notes that the symlink is never followed by the validator — `-e` performs the existence check but does not read content.

- **TC-V8: Multiple violations in one run**
  - **Given**: fixture with three task-type dirs, each containing a different violation (type, target, pool-name).
  - **When**: validate.
  - **Then**: three violations returned in deterministic order (sorted by type then by file name, matching the validator's `sort readdir` and `for my $type (supported_types())` loop ordering).

- **TC-V9: `pool/` itself is ignored**
  - **Given**: fixture has `.cwf/templates/pool/some-extra-file.txt` (regular file, not a symlink).
  - **When**: validate.
  - **Then**: empty list. Confirms the validator iterates only `supported_types()`, not every directory under `templates/`.

- **TC-V10: Missing task-type directory is not an error**
  - **Given**: `cwf-project.json` lists `feature` and `chore`, but the fixture only has `feature/`.
  - **When**: validate.
  - **Then**: validator inspects `feature/` (any violations there are reported) and silently skips `chore/` (the `next unless -d $dir` early-exit).

### Functional Test Cases — `t/cwf-manage-update.t` (extended subtests)

- **TC-C1: Relative symlink is preserved by `copy_tree`**
  - **Given**: source tempdir with `src/a.txt` (regular) and `src/b -> a.txt` (relative symlink); empty dest tempdir.
  - **When**: `copy_tree($src, $dst)`.
  - **Then**: `$dst/b` is a symlink (`-l`) whose `readlink` equals `a.txt`. `$dst/a.txt` is a regular file with the original content.

- **TC-C2: Subdir-spanning relative symlink is preserved**
  - **Given**: source contains `src/pool/x` (regular) and `src/feature/x -> ../pool/x`.
  - **When**: `copy_tree`.
  - **Then**: `$dst/feature/x` is a symlink, `readlink($dst/feature/x) eq '../pool/x'`, `$dst/pool/x` is a regular file. This is the bug-at-hand scenario.

- **TC-C3: Absolute symlink target → die**
  - **Given**: source contains `src/leak -> /etc/passwd`.
  - **When**: `copy_tree`.
  - **Then**: dies. Captured error message matches the regex `/refusing escaping symlink target.*\/etc\/passwd/`. Dest dir does not contain `leak`.

- **TC-C4: Escaping relative symlink target → die**
  - **Given**: source contains `src/escape -> ../../etc/passwd`.
  - **When**: `copy_tree`.
  - **Then**: dies. Error matches `/refusing escaping symlink target.*\.\.\/\.\.\/etc\/passwd/`. Dest dir does not contain `escape`.

- **TC-C5: In-tree but non-pool relative symlink is allowed (regression guard)**
  - **Given**: source contains `src/a/x.txt` (regular) and `src/b/link -> ../a/x.txt` (in-tree, relative, non-escaping).
  - **When**: `copy_tree`.
  - **Then**: `$dst/b/link` is a symlink with `readlink eq '../a/x.txt'`. This guards against `_escapes_src` being overly strict.

### Non-Functional Test Cases

- **Security (TC-S1)**: TC-C3 and TC-C4 ARE the security tests for the copy_tree gate; no additional security tests needed for that change. For the validator, TC-V6 and TC-V7 confirm the same inputs are flagged post-write.
- **Reliability (TC-R1)**: `prove -rv t/` after the change must report the same pass count as before, plus the new tests passing. No flakes (re-run twice in `g-testing-exec`).
- **Usability (TC-U1)**: a manual `cwf-manage validate` run on a deliberately broken templates dir produces a message containing both the literal `cwf-manage update` and the literal `ln -sfn ../pool/<name>` so the user has both an automated and a manual recovery path. Captured in `g-testing-exec.md`.
- **Performance**: not measured — both changes are install-time, run once per update.

## Test Environment

### Setup Requirements
- **Perl**: system Perl on the dev machine (no version-specific feature used; all modules are core).
- **Modules** (all core, no CPAN — per project rule): `Test::More`, `File::Temp`, `File::Spec`, `File::Basename`, `File::Path`, `File::Find`, `File::Copy`.
- **Fixtures**: `File::Temp::tempdir(CLEANUP => 1)` for every test. No test touches the real `.cwf/` tree. Reference pattern: `t/validate-security.t` and `t/cwf-manage-update.t`.
- **CWF helpers under test**: source the script directly into the test process where possible (`do '.cwf/scripts/cwf-manage'` then call `copy_tree`/`_escapes_src` by package); existing `t/cwf-manage-*.t` files demonstrate this pattern.

### Mock Services
None. All operations are local file system.

### Automation
- **Test runner**: `prove -rv t/` (existing convention; no new tooling).
- **CI integration**: none currently in this repo — `prove` is run manually by the maintainer. No change.
- **Test execution schedule**: before any checkpoint commit, before merge.

## Validation Criteria
- [ ] `prove -rv t/validate-templates.t` is green (all 10 TCs above pass).
- [ ] `prove -rv t/cwf-manage-update.t` is green (existing + 5 new TCs).
- [ ] Full `prove -rv t/` is green — no regression in any other test file.
- [ ] `cwf-manage validate` passes on the live repo.
- [ ] Manual smoke (Step 7 of `d-implementation-plan.md`) confirmed and recorded in `g-testing-exec.md`. Live repo restored to clean state before commit.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 135
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

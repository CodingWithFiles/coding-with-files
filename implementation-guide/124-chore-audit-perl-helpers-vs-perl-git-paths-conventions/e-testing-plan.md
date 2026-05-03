# audit perl helpers vs perl-git-paths conventions - Testing Plan
**Task**: 124 (chore)

## Task Reference
- **Task ID**: internal-124
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/124-audit-perl-helpers-vs-perl-git-paths-conventions
- **Template Version**: 2.1

## Goal
Validate that `CWF::Validate::PerlConventions` correctly flags non-conformant Perl files, that the 9 identified files become conformant, and that the source-encoding changes (`use utf8;`) don't regress any existing runtime path.

## Test Strategy

### Test Levels
- **Unit**: `t/validate-perl-conventions.t` — fixture-driven Test::More against `CWF::Validate::PerlConventions::validate($fixture_root)`. Each fixture is a temporary directory built per-subtest so cases are isolated and don't depend on real repo state.
- **Integration**: `cwf-manage validate` against the real repo — confirms wiring (Step 3 of d-plan) and that the 9 identified files reach `OK` after Step 4 fixes.
- **Regression (negative)**: planted-breakage smoke — temporarily revert `use utf8;` in one module and confirm `cwf-manage validate` fails with a clear `PerlConventions` violation citing the file.
- **Runtime smoke**: manual exercise of the modified scripts/modules to confirm `use utf8;` doesn't change observable behaviour.

### Test Coverage Targets
- **PerlConventions module**: every assertion (source-pragma, git-z, shebang) covered by both a passing and a failing fixture; allowlist behaviour covered by one fixture.
- **Modified files**: every one of the 9 must show `OK` under `cwf-manage validate` post-fix.
- **Existing suite**: `prove -r t/` remains 100% green — no test count change, no skipped/failed cases attributable to this task.

## Test Cases

### Functional — `t/validate-perl-conventions.t` (unit)

- **TC-U1**: Module with non-ASCII source and `use utf8;` passes.
  - **Given**: fixture module containing an em-dash literal and `use utf8;` after the `package` line.
  - **When**: `validate($fixture_root)`.
  - **Then**: returned violations array contains no entry for this file.

- **TC-U2**: Module with non-ASCII source and **no** `use utf8;` fails source-pragma.
  - **Given**: same fixture as TC-U1 minus `use utf8;`.
  - **When**: `validate($fixture_root)`.
  - **Then**: violations contains one record `{ rel => ..., field => 'use_utf8', expected => 'use utf8;' }`.

- **TC-U3**: Script capturing `git status` without `-z` fails git-z.
  - **Given**: fixture script with shebang `#!/usr/bin/perl -CDSL`, body uses `qx{git status --porcelain}`.
  - **When**: `validate($fixture_root)`.
  - **Then**: violations contains a record `{ field => 'git_z' }` for the script.

- **TC-U4**: Script capturing `git status` with `-z` and conformant shebang passes.
  - **Given**: fixture script with shebang `#!/usr/bin/perl -CDSL`, body uses `qx{git status --porcelain -z}`.
  - **When**: `validate($fixture_root)`.
  - **Then**: no violations for this file.

- **TC-U5**: Script with the offending pattern only inside POD passes.
  - **Given**: fixture script whose POD block contains a literal `git status` example without `-z`, but no actual git invocation in code.
  - **When**: `validate($fixture_root)`.
  - **Then**: no violations for this file. Confirms POD/comment exclusion.

- **TC-U6**: Script with `git log -- $path` (path as **argument**, output not captured) passes.
  - **Given**: fixture script with `system('git', 'log', '--', $path)` and no captured git path output.
  - **When**: `validate($fixture_root)`.
  - **Then**: no violations. Confirms the rule scopes to path *output*, not argument paths.

- **TC-U7**: Script consuming git paths but in `@GRANDFATHERED` skips git-z and shebang assertions.
  - **Given**: fixture script with relative path matching the allowlist entry, env shebang, captures `git diff --name-only`, contains an em-dash but **no** `use utf8;`.
  - **When**: `validate($fixture_root)` with `@GRANDFATHERED` set to include the fixture path.
  - **Then**: violations contains the `use_utf8` record only — git-z and shebang are skipped, source-pragma is not.

- **TC-U8**: Module that does not match `^package CWF::` and is not a perl script is ignored.
  - **Given**: fixture file `.cwf/scripts/notes.txt` with non-ASCII content.
  - **When**: `validate($fixture_root)`.
  - **Then**: no violations — discovery filter excludes non-Perl files.

### Functional — `cwf-manage validate` (integration)

- **TC-I1**: Pre-fix integration baseline — validate flags the 9 identified files.
  - **Given**: `CWF::Validate::PerlConventions` wired into `cmd_validate` (Step 3 done), but the 9 source edits not yet applied (between Steps 3 and 4).
  - **When**: `.cwf/scripts/cwf-manage validate`.
  - **Then**: exit non-zero; output names exactly the 9 expected files with `field=use_utf8` (8 modules + `migrate-v2.1-file-order`).

- **TC-I2**: Post-fix integration — validate clean.
  - **Given**: All Step 4 edits applied; `script-hashes.json` regenerated for modified files and the new `PerlConventions.pm` entry added.
  - **When**: `.cwf/scripts/cwf-manage validate`.
  - **Then**: exit 0, `[CWF] validate: OK`. No PerlConventions violations, no sha256 violations.

- **TC-I3**: Negative regression — planted breakage detected.
  - **Given**: Post-fix repo. Temporarily delete `use utf8;` from `.cwf/lib/CWF/TaskState.pm` (do not stage).
  - **When**: `.cwf/scripts/cwf-manage validate`.
  - **Then**: exit non-zero; output cites `TaskState.pm` with `field=use_utf8`. Restore the line; re-run; expect `OK`. Demonstrates the check actually catches drift.

- **TC-I4**: Grandfathered file does not regress.
  - **Given**: `.cwf/scripts/hooks/stop-stale-status-detector` unchanged from current state (env shebang, `git diff` without `-z`).
  - **When**: `.cwf/scripts/cwf-manage validate`.
  - **Then**: no PerlConventions violation for this file (allowlist hit). Documents that the grandfathered exception remains honoured.

### Non-Functional

- **TC-NF1 (Reliability — runtime smoke)**: source-encoding change doesn't break observable behaviour.
  - **Given**: All Step 4 edits applied.
  - **When**: Exercise each affected runtime path:
    - `.cwf/scripts/migrations/migrate-v2.1-file-order --help` (or its dry-run if `--help` absent) — touches the migration script.
    - `.cwf/scripts/cwf-manage status` — touches `Versioning.pm`.
    - `cwf-status 124` — touches `TaskState.pm`, `MarkdownParser.pm`, `TaskContextInference.pm`, `TaskPath.pm`, `WorkflowFiles/V21.pm`.
    - Exercise the `stop-uncommitted-changes-warning` and `stop-stale-status-detector` hook flows by triggering uncommitted/stale conditions in a scratch branch.
    - `.cwf/scripts/cwf-manage validate` — touches `Validate/Security.pm`, `Validate/Config.pm`.
  - **Then**: each invocation produces output identical (modulo timestamps) to a pre-task baseline captured before any edits. No new warnings, no encoding-mojibake, no exception traces.

- **TC-NF2 (Security)**: allowlist cannot be bypassed by source comment.
  - **Given**: A fresh fixture script that consumes `git diff` without `-z` and includes a leading comment `# perl-git-paths-skip: pretending`.
  - **When**: `validate($fixture_root)` (the file path is **not** in `@GRANDFATHERED`).
  - **Then**: violation is still raised (`field=git_z`). Confirms the bypass requires editing the module's allowlist constant, not a source comment.

- **TC-NF3 (Security)**: hash-tampering detection still works.
  - **Given**: Post-fix repo. Manually corrupt one byte in `.cwf/lib/CWF/TaskState.pm` without updating `script-hashes.json`.
  - **When**: `.cwf/scripts/cwf-manage validate`.
  - **Then**: exit non-zero with a `sha256` violation on `TaskState.pm`. Restore the byte. Confirms the integrity model is undamaged by the source edits.

## Test Environment

### Setup Requirements
- Standard CWF dev checkout (perl 5.32+, Test::More, Digest::SHA — already present).
- No external services, mocks, or test doubles.
- Unit tests build their own fixture trees in `File::Temp` directories; integration tests run against the working tree on the task branch.
- Negative tests (TC-I3, TC-NF3) modify tracked files temporarily — must run with a clean working tree so reverts are obvious; never commit the planted breakage.

### Automation
- `prove -r t/` runs the unit suite (CI/`/cwf-testing-exec` invocation).
- `cwf-manage validate` runs as part of every checkpoint commit (`cwf-checkpoint-commit:53`), so integration coverage is automatic from this task forward.
- No new CI configuration needed — the new `.t` is picked up by `prove -r t/`.

## Validation Criteria
- [ ] `prove -r t/` is fully green, including all TC-U* in `t/validate-perl-conventions.t`.
- [ ] `cwf-manage validate` reports `OK` on the post-fix working tree (TC-I2).
- [ ] Planted-breakage smoke (TC-I3) confirms the check fires and the file is named in the violation output.
- [ ] All TC-NF1 runtime invocations match pre-task baseline output (no encoding regressions).
- [ ] Allowlist bypass attempt (TC-NF2) is rejected.
- [ ] Hash-tamper detection (TC-NF3) still fires.
- [ ] BACKLOG entry removed; `docs/conventions/perl-git-paths.md` updated.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

# re-align Perl-script conventions to Task-27 form - Testing Plan
**Task**: 139 (bugfix)

## Task Reference
- **Task ID**: internal-139
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/139-re-align-perl-script-conventions-to-task-27-form
- **Template Version**: 2.1

## Goal
Specify the test cases that verify the validator amendment, doc-split, shebang reverts, hash regen, and inbound-reference audit each work, and that no previously-passing test or end-to-end behaviour regresses.

## Test Strategy

### Test Levels
- **Unit**: `t/validate-perl-conventions.t` exercises the validator in isolation against synthetic fixtures (the standard CWF pattern — temp-dir trees, no real `.cwf/` walk). This is where the polarity flip + 2 new subtests live.
- **Integration**: `cwf-manage validate` run against the actual `.cwf/` tree at three checkpoints (between shebang revert and hash regen; after hash regen; after the inbound-reference audit) verifies the validator and hash registry agree on the live state.
- **System / smoke**: `backlog-manager list` and a UTF-8 `add`+`delete` round-trip verify the reverted scripts still work under `PERL5OPT=-CDSLA` + `env perl`.
- **Acceptance**: `git grep` for `perl-git-paths` and `-CDSL\b` across the live (non-historical) surfaces returns zero hits.

### Test Coverage Targets
- **Validator unit tests**: every rule branch (shebang, `use utf8;`, `git_z`, grandfather) exercised by at least one positive and one negative subtest.
- **Critical paths**: 100% — the new shebang rule is exercised by both TC-U9 (positive) and TC-U10 (negative).
- **Edge cases**: TC-U3c uses the post-Task-137 form `-CDSLA` (not just the older `-CDSL`) so the test is meaningful against the current convention drift.
- **Regression**: full `prove t/` passes; `cwf-manage validate` reports OK; smoke tests succeed; no inbound reference to the deleted doc remains.

## Test Cases

### Functional Test Cases

- **TC-1: Validator rejects hardcoded `-C` shebang on a non-capturing script** (new TC-U10 in `t/validate-perl-conventions.t`)
  - **Given**: A fixture script with `#!/usr/bin/perl -CDSLA`, `use utf8;`, and a `qx{git status -z}` capture that includes `-z`.
  - **When**: The validator runs on the fixture tree.
  - **Then**: Exactly one violation with `field = 'shebang'`, `actual = '#!/usr/bin/perl -CDSLA'`, `expected = '#!/usr/bin/env perl'`. The presence of `-z` does not save it.

- **TC-2: Validator accepts `env perl` shebang on a capturing script** (new TC-U9)
  - **Given**: A fixture script with `#!/usr/bin/env perl`, `use utf8;`, and `qx{git status -z}`.
  - **When**: The validator runs.
  - **Then**: Zero violations.

- **TC-3: Validator still flags missing `-z` regardless of shebang form** (existing TC-U3 / TC-U3b, retargeted)
  - **Given**: A fixture script with `#!/usr/bin/env perl` capturing `git status` without `-z`.
  - **When**: The validator runs.
  - **Then**: Exactly one violation with `field = 'git_z'`. Shebang violation is absent.

- **TC-4: Validator still flags missing `use utf8;`** (existing TC-U2 / U2b, unchanged)
  - **Given**: A fixture module without `use utf8;`.
  - **When**: The validator runs.
  - **Then**: Violation with `field = 'use_utf8'` regardless of any other rule state.

- **TC-5: Grandfathered file bypasses `-z` rule but still subject to shebang rule** (existing TC-U7, semantics clarified)
  - **Given**: A fixture file at the grandfathered path with `#!/usr/bin/env perl` + missing `-z`.
  - **When**: The validator runs with the grandfather list active.
  - **Then**: Zero violations. (`env perl` passes the new shebang rule; grandfather list covers `-z` exemption.)

- **TC-6: `cwf-manage validate` reports exactly the expected 12 hash mismatches mid-implementation** (manual integration test, Step 4 of d-implementation-plan.md)
  - **Given**: All 11 shebangs reverted in place; validator amended in `PerlConventions.pm`; hashes in `script-hashes.json` not yet updated.
  - **When**: `.cwf/scripts/cwf-manage validate` runs.
  - **Then**: Exactly 12 `sha256` field violations (11 scripts + `PerlConventions.pm`). No `shebang`, `use_utf8`, or `git_z` violations. No missing-file or permission violations.

- **TC-7: `cwf-manage validate` reports OK after hash regen** (manual integration test, end of Step 5)
  - **Given**: 12 new hashes spliced into `script-hashes.json`; `last_updated` bumped.
  - **When**: `cwf-manage validate` runs.
  - **Then**: Exit 0; output ends with `[CWF] validate: OK`.

- **TC-8: `backlog-manager list` smoke test** (manual, Step 7)
  - **Given**: Shebangs reverted; user's `PERL5OPT=-CDSLA`.
  - **When**: `.cwf/scripts/command-helpers/backlog-manager list` runs.
  - **Then**: Exit 0; output formatted as priority-grouped headings (matching pre-revert behaviour).

- **TC-9: Task-137 mojibake non-regression** (manual UTF-8 round-trip, Step 7)
  - **Given**: Shebangs reverted; `PERL5OPT=-CDSLA`; UTF-8 locale.
  - **When**: `backlog-manager add --title='Test → arrow' --task-type=chore --priority=Low --body='smoke'` followed by `backlog-manager delete --exact-title='Test → arrow' --confirm`.
  - **Then**: Both commands exit 0. `BACKLOG.md` shows the literal `→` arrow during the brief window between add and delete (no `â†'` mojibake).

- **TC-10: Final repo-wide grep is clean** (acceptance gate)
  - **Given**: All inbound-reference audit edits complete.
  - **When**: `git grep -n perl-git-paths` and `git grep -n -- '-CDSL\b'` run from repo root.
  - **Then**: Outside `implementation-guide/` and `### Retired Backlog Items` sections, both return zero hits.

### Non-Functional Test Cases
- **Reliability**: Hash regen is one-shot atomic via the Edit tool; partial-splice failure mode covered by the pre-splice diff review in Step 5.
- **Security**: Validator inversion tightens the surface (one more rule, no rule relaxation). `cwf-manage validate` runs at every checkpoint and at retrospective, so any drift surfaces immediately. FR4(b) coverage preserved (per design Decision 3).
- **Portability**: `env perl` shebang is the POSIX-portable form by construction. No kernel-shebang-argv parsing dependency.
- **Usability**: Validator error messages cite specific doc paths (`perl.md` or `git-path-output.md`) so a reader can find the rule that fired.
- **Performance**: No measurable change. Validator runs in the same time bound (one extra regex per file is negligible against File::Find traversal cost).

## Test Environment

### Setup Requirements
- Repo on branch `bugfix/139-…`, working tree clean before testing.
- Shell environment: `PERL5OPT=-CDSLA`, `LANG=en_US.UTF-8` (or any UTF-8 locale).
- Perl core modules only (already satisfied by project policy).
- No test database or external service dependencies.

### Automation
- `prove t/` runs the unit tests (no CI runner specific to this project; the developer runs locally).
- `cwf-manage validate` runs at every checkpoint commit via the existing post-commit guard.
- Smoke tests are manual one-liners run during Step 7.

## Validation Criteria
- [ ] `prove t/` passes with all subtests, including the 10 flipped fixtures and the 2 new TCs.
- [ ] `cwf-manage validate` reports OK after hash regen (TC-7).
- [ ] Smoke tests TC-8 and TC-9 pass.
- [ ] Final repo-wide grep (TC-10) returns zero live hits.
- [ ] All 6 success criteria from `a-task-plan.md` are met.

## Decomposition Check
- [ ] Time: well under 1 day for testing alone.
- [ ] People: 1.
- [ ] Complexity: single test file flipped + manual smoke tests; standard scope.
- [ ] Risk: low — all tests are deterministic.
- [ ] Independence: tests are sequenced inside the implementation steps, not run independently.

**Decision**: No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

# backlog-manager double-encodes non-ASCII @ARGV - Testing Plan
**Task**: 137 (bugfix)

## Task Reference
- **Task ID**: internal-137
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/137-backlog-manager-double-encodes-non-ascii-argv
- **Template Version**: 2.1

## Goal
Define the test strategy that proves the bug is fixed and the convention is enforced.

## Test Strategy
### Test Levels
- **Unit / Integration**: One new Perl test under `t/` exercises `backlog-manager add` with a non-ASCII argv, parses the resulting markdown bytes, and asserts UTF-8 round-trip (no double-encoding).
- **Validator regression**: Existing `t/validate-perl-conventions.t` is updated to expect `-CDSLA` (7 fixture sites). A new subtest asserts the validator now rejects `-CDSL` and accepts `-CDSLA`.
- **System / Smoke**: `cwf-manage validate` exits 0 on the post-patch tree; `prove -r t/` is fully green.

### Test Coverage Targets
- **Functional**: Every `-C*` flag transition we made is asserted by at least one test (validator accept-`-CDSLA`, validator reject-`-CDSL`, argv-decoded-by-`-CDSLA`).
- **Regression**: All existing `prove -r t/` tests pass with no skips or new TODOs.

## Additional Implementation Surface Discovered During Test Planning
The test fixtures in `t/validate-perl-conventions.t` embed `#!/usr/bin/perl -CDSL` shebangs at 7 sites (lines 88, 103, 117, 132, 147, 163, 184). These must move to `-CDSLA` in lockstep with the validator change. This file was missed in `d-implementation-plan.md` (caught here in test planning); add to the implementation-exec checklist.

## Test Cases

### Functional

#### TC-F1: `backlog-manager add` UTF-8 argv round-trip (the reported bug)
- **Given**: A scratch fixture directory created via `File::Temp` containing a minimal valid `BACKLOG.md` (under `prove`'s isolation, not the live file). The current process invokes `backlog-manager add` with `--title='Smoke 137: → § —'`, body containing the same three non-ASCII codepoints, and other fields ASCII.
- **When**: The helper writes its entry to the scratch BACKLOG.md.
- **Then**: Reading the scratch file `<:raw`, the byte sequence for `→` is `0xE2 0x86 0x92` (3 bytes), `§` is `0xC2 0xA7` (2 bytes), and `—` is `0xE2 0x80 0x94` (3 bytes). Specifically NOT the 6-byte / 4-byte / 6-byte double-encoded sequences.
- **Failure on baseline**: This test must FAIL on commit `e8d1b8f` (current main) and PASS on the fix.

#### TC-F2: `backlog-manager normalise` is unaffected (regression guard)
- **Given**: A scratch BACKLOG.md containing legacy `**Field**:` metadata AND non-ASCII bytes in body content (e.g. an existing `→`).
- **When**: `backlog-manager normalise` runs on it.
- **Then**: The non-ASCII bytes are preserved bit-for-bit (the `normalise` codepath reads/writes file bytes; it should never have been broken and must not regress).

#### TC-F3: Validator accepts `-CDSLA`
- **Given**: A fresh fixture Perl script under `File::Temp` with shebang `#!/usr/bin/perl -CDSLA`, source pragma `use utf8;`, and a `git ls-files -z` capture.
- **When**: `CWF::Validate::PerlConventions::validate` is invoked.
- **Then**: No violation returned for the shebang field.

#### TC-F4: Validator rejects `-CDSL` (the old shebang, post-migration)
- **Given**: A fresh fixture with the now-stale `#!/usr/bin/perl -CDSL` shebang and a git capture that exercises the rule.
- **When**: The validator runs.
- **Then**: A violation is returned with `field => 'shebang'`, `expected => '#!/usr/bin/perl -CDSLA'`. This is the symmetric inverse of TC-F3; together they prove the rule actually changed.

#### TC-F5: All 11 affected scripts have the new shebang
- **Given**: The post-patch working tree.
- **When**: Each of the 11 listed scripts is opened.
- **Then**: First line is exactly `#!/usr/bin/perl -CDSLA` (no whitespace, no flag re-order).

#### TC-F6: No `-CDSL$` shebang remains anywhere under `.cwf/`
- **Given**: Post-patch working tree.
- **When**: Anchor-grep `grep -rln '^#!/usr/bin/perl -CDSL$' .cwf/`.
- **Then**: Zero matches. This is the regression alarm against future agents partially reverting the migration.

#### TC-F7: Integrity surface is consistent
- **Given**: Post-patch working tree.
- **When**: `cwf-manage validate` runs.
- **Then**: Exit code 0; no `category=SECURITY` or `category=PERL_CONVENTIONS` violations.

#### TC-F8: Convention doc no longer carries the false `-CDSL` claim
- **Given**: Post-patch `docs/conventions/perl-git-paths.md`.
- **When**: The Shebang bullet is read.
- **Then**: The text explicitly names `A` as the flag that decodes `@ARGV`; the previous claim "makes Perl decode … `@ARGV` as UTF-8" attached to `-CDSL` is gone.
- **Verification**: Grep for `-CDSL[^A]` outside of historical context (comments referring to Task 115 or prior commits are allowed; convention statements are not).

### Non-Functional

#### TC-NF1: `prove -r t/` exit 0
- Existing suite unaffected by the change.

#### TC-NF2: `cwf-manage validate` exit 0
- Already covered in TC-F7; restated as a release-gate non-functional check.

## Test Environment
- POSIX (Linux + macOS); core-Perl modules only (`File::Temp`, `Encode`, `Digest::SHA` all core).
- All filesystem state confined to `File::Temp`-managed directories. Never touch the live `BACKLOG.md` or `CHANGELOG.md` from a test.
- Tests run under `prove -r t/`; no manual scratch-file pattern.

## Implementation Notes for `g-testing-exec.md`
- TC-F1 / TC-F2 belong in a new file `t/backlog-manager-argv-utf8.t` (or as new subtests inside `t/backlog-manager.t` if the existing scaffolding suits). Decision deferred to exec phase based on cost of fixture setup.
- TC-F3 / TC-F4 belong as new subtests inside `t/validate-perl-conventions.t`.
- TC-F5 / TC-F6 are simple Perl one-liners or `Test::More` `is`/`cmp_ok` assertions; can live in `t/validate-perl-conventions.t` alongside the existing structural assertions.

## Failure Modes Considered
- **FM-T1**: Test depends on the user having `PERL5OPT=-CDSLA` set. **Mitigation**: tests explicitly invoke `backlog-manager` via list-form `system()` with an explicit environment block, NOT via PERL5OPT inheritance. The shebang is the contract being tested.
- **FM-T2**: Test pollutes live BACKLOG.md if the fixture path is misconfigured. **Mitigation**: every test uses `File::Temp::tempdir(CLEANUP => 1)`; `find_git_root` is overridden via `chdir` to the temp dir before invocation. Same pattern as `t/cwf-manage-update.t`.
- **FM-T3**: TC-F1 passes by accident under `-CA`-enabled environments even on the unfixed code. **Mitigation**: TC-F1 runs the helper as a child process with `env -i PATH=$PATH` plus only the strictly necessary env vars; PERL5OPT is explicitly unset for the child so the shebang is the sole source of truth.

## Decomposition Check
Single test deliverable; no decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
- 8 functional + 2 non-functional cases planned; 7 functional + 2 non-functional executed and passed (TC-F8 explicitly deferred — see `g-testing-exec.md`).
- Sensitivity check on TC-F1: shebang transient revert to `-CDSL` made TC-F1 fail with mojibake; restore made it pass. Confirms test is not a vacuous pass.

## Lessons Learned
- Catching the 7-fixture shebang-coupling in `t/validate-perl-conventions.t` was the most valuable contribution of the test-planning phase — d-plan missed it. Worth treating "what fixtures must change when the production literal changes?" as a standing question for any test-plan that touches a validator.
- TC-F8 (convention-doc assertion) survives as a deferral marker: even though it didn't run in this task, having it on record makes the convention re-alignment follow-up's acceptance criterion explicit. Useful pattern for deliberate-deferral situations.

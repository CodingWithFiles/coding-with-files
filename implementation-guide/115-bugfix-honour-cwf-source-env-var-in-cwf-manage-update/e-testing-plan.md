# Honour CWF_SOURCE env var in cwf-manage update - Testing Plan
**Task**: 115 (bugfix)

## Task Reference
- **Task ID**: internal-115
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/115-honour-cwf-source-env-var-in-cwf-manage-update
- **Template Version**: 2.1

## Goal
Verify that `resolve_source` returns the correct source/origin pair across all env-var/file-value combinations, that `cmd_update` and `cmd_list_releases` route through it correctly, and that an env-driven update never persists `CWF_SOURCE` into `.cwf/version`.

## Test Strategy
### Test Levels
- **Unit Tests** (automated): `resolve_source` is a pure function over `(\%v, %ENV)`. Six subtests in a new `t/cwf-manage-resolve-source.t`, following the `do $SCRIPT` + `main::sub_name` harness from `t/cwf-manage-list-releases.t`. Failure paths use a `*main::die_msg` symbol-table override to convert `exit 1` into a catchable `die`.
- **Regression** (automated): Existing `prove t/` suite must pass unchanged. `t/cwf-manage-list-releases.t` exercises pure functions in `cwf-manage` and is unaffected by the new helper.
- **Manual smoke tests**: Three short shell invocations cover end-to-end behaviour that's impractical to mock — the `(from: ...)` log line in real `git clone` / `git ls-remote` paths, and the no-persistence assertion. Run during `g-testing-exec`; results recorded there.

### Test Coverage Targets
- **`resolve_source`**: 100% — six subtests covering every combination of env state (set/empty/unset) × file state (present/empty/missing).
- **Critical paths**: every code path in `resolve_source` is exercised, including both `defined && ne ''` short-circuits and the `die_msg` fallthrough.
- **Regression**: full `prove t/` suite passes after the change.
- **End-to-end**: one manual smoke test per call site (`update`, `list-releases`) plus one for the no-persistence invariant.

## Test Cases

### Functional test cases — `resolve_source` (automated, `t/cwf-manage-resolve-source.t`)

- **TC-1**: env set + file present → env wins
  - **Given**: `$ENV{CWF_SOURCE} = 'file:///env/path'`; `\%v = ( cwf_source => 'file:///file/path' )`
  - **When**: `my ($src, $origin) = main::resolve_source(\%v)`
  - **Then**: `$src eq 'file:///env/path'` and `$origin eq 'CWF_SOURCE env var'`

- **TC-2**: env unset + file present → file wins
  - **Given**: `delete $ENV{CWF_SOURCE}`; `\%v = ( cwf_source => 'file:///file/path' )`
  - **When**: same call
  - **Then**: `$src eq 'file:///file/path'` and `$origin eq '.cwf/version'`

- **TC-3**: env empty + file present → file wins (defined-but-empty env does not override)
  - **Given**: `$ENV{CWF_SOURCE} = ''`; `\%v = ( cwf_source => 'file:///file/path' )`
  - **When**: same call
  - **Then**: `$src eq 'file:///file/path'` and `$origin eq '.cwf/version'`

- **TC-4**: env set + file missing key → env still wins
  - **Given**: `$ENV{CWF_SOURCE} = 'file:///env/path'`; `\%v = ()`
  - **When**: same call
  - **Then**: `$src eq 'file:///env/path'` and `$origin eq 'CWF_SOURCE env var'`

- **TC-5**: env unset + file missing key → dies with documented message
  - **Given**: `delete $ENV{CWF_SOURCE}`; `\%v = ()`
  - **When**: `eval { main::resolve_source(\%v) }; my $err = $@`
  - **Then**: `$err` matches `qr/No CWF source: CWF_SOURCE unset and cwf_source missing\/empty in \.cwf\/version/`

- **TC-6**: env empty + file empty → dies
  - **Given**: `$ENV{CWF_SOURCE} = ''`; `\%v = ( cwf_source => '' )`
  - **When**: same `eval` block
  - **Then**: same error pattern as TC-5

### Functional test cases — call-site routing (verified via existing tests + smoke)

- **TC-7**: `cmd_list_releases` reads via `resolve_source`
  - **Given**: existing `t/cwf-manage-list-releases.t` continues to pass without modification
  - **When**: `prove t/cwf-manage-list-releases.t`
  - **Then**: all subtests pass — confirms the line-124 substitution did not break parsing of pure helpers (`parse_semver`, `filter_releases`)

- **TC-8**: `cmd_update` reads via `resolve_source` (manual smoke)
  - **Given**: `CWF_SOURCE=file:///nonexistent/repo` in shell environment
  - **When**: `.cwf/scripts/cwf-manage update 2>&1 | head -3`
  - **Then**: first log line includes `(from: CWF_SOURCE env var)`; clone fails next line on the bogus path. (The clone failure is expected and is the *signal* that the env var was honoured.)

- **TC-9**: `cmd_list_releases` honours env override end-to-end (manual smoke)
  - **Given**: `unset CWF_SOURCE`
  - **When**: `.cwf/scripts/cwf-manage list-releases 2>&1 | head -1`
  - **Then**: log line includes `(from: .cwf/version)` and lists tags from the file-pinned source

- **TC-10**: env-driven update does not persist (manual smoke)
  - **Given**: `.cwf/version` has `cwf_source=https://github.com/CodingWithFiles/coding-with-files.git`; an alternative working repo exists at `/tmp/cwf-test-clone` with a tagged release
  - **When**: `CWF_SOURCE=file:///tmp/cwf-test-clone .cwf/scripts/cwf-manage update <some-tag>`
  - **Then**: update succeeds; `grep ^cwf_source= .cwf/version` still shows the original `https://github.com/...` URL — env value was **not** written back

### Non-Functional Test Cases
- **Usability**: `cwf-manage help` output includes the new `Environment:` block listing `CWF_SOURCE`. Verified by `cwf-manage help | grep -A2 Environment` returning the expected three lines.
- **Reliability**: TC-5 / TC-6 confirm the helper dies with a clear, single-line message rather than producing undefined behaviour when both source candidates are absent.
- **Backwards compatibility**: TC-2 (env unset + file present) is the existing-user steady-state. It must produce identical effective behaviour to today, with the addition of the `(from: .cwf/version)` log suffix. Asserted by TC-9.
- **No persistence regression**: TC-10 is the load-bearing check for Decision 2 of the design. If this fails, the bug-fix has introduced a worse bug (silent re-pin).

Performance and security are not relevant for this change — the helper is a few defined-and-non-empty checks; there is no network surface change beyond honouring an extra env var that `install.bash` already accepts.

## Test Environment

### Setup Requirements
- **Automated tests**: Perl 5 with `Test::More`, `FindBin`, `File::Spec` (already used in `t/cwf-manage-list-releases.t`). No external dependencies.
- **Manual smoke tests**:
  - A throwaway local clone of the CWF repo at e.g. `/tmp/cwf-test-clone` for TC-8 and TC-10
  - The actual `.cwf/version` of this checkout (the task branch itself) for TC-9 and TC-10
  - A shell that allows `export CWF_SOURCE=...` and `unset CWF_SOURCE` between cases
- **No mocks**: `resolve_source` is pure. The existing `cwf-manage` test pattern uses `do $SCRIPT` to load the file with `@ARGV = ('help')` so `main()` is side-effect-free; no further mocking required.

### Automation
- **Framework**: Test::More via `prove`, consistent with the rest of `t/`.
- **CI/CD**: covered by the same `prove t/` invocation that runs in existing CWF testing.
- **Schedule**: tests run on every commit on this task branch (Step 7 of `d-implementation-plan` runs them as part of smoke testing); recorded as final state in `g-testing-exec.md`.

## Decomposition Check
- [x] **Time**: Six unit subtests + three manual smokes — minutes, not days. **No** decomposition.
- [x] **People**: Single contributor. **No** decomposition.
- [x] **Complexity**: One pure helper, three call sites. **No** decomposition.
- [x] **Risk**: Low — TC-10 explicitly guards the highest-impact failure mode. **No** decomposition.
- [x] **Independence**: Tightly coupled. **No** decomposition.

**Conclusion**: Confirmed — single top-level task.

## Validation Criteria
- [ ] `prove t/cwf-manage-resolve-source.t` — all six subtests pass
- [ ] `prove t/` — full suite passes with no regressions
- [ ] `cwf-manage validate` — passes on the modified script
- [ ] TC-8: env-override log line observed in `cmd_update` smoke
- [ ] TC-9: file-default log line observed in `cmd_list_releases` smoke
- [ ] TC-10: `cwf_source` field unchanged in `.cwf/version` after env-driven update
- [ ] `cwf-manage help` output includes the `Environment: CWF_SOURCE` block

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 115
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

# fix outstanding cwf-manage issues - Testing Plan
**Task**: 159 (feature)

## Task Reference
- **Task ID**: internal-159
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/159-fix-outstanding-cwf-manage-issues
- **Template Version**: 2.1

## Goal
Define the test cases that verify FR1/FR2/FR4 and guard against regression. Each acceptance criterion from b-requirements (AC1-AC4, AC7-AC10) maps to ≥1 test case. AC5/AC6 belong to the deferred FR3 and are out of scope.

## Test Strategy
### Test Levels
- **Unit**: `git_capture` and `git_describe_version` contracts, loaded via `do $SCRIPT` with `@ARGV=('help')` (the established pattern in `t/cwf-manage-list-releases.t`), exercising `main::` subs directly.
- **Integration (subprocess)**: run the real `cwf-manage` binary against a tempdir fixture — `fix-security` (mirrors `t/cwf-manage-fix-security.t`: copy `.cwf/` into tempdir, mutate, run `perl -I$tmp/.cwf/lib $tmp/.cwf/scripts/cwf-manage <cmd>`, assert exit/output/fs state) and `update` end-to-end (mirrors `t/cwf-manage-update-end-to-end.t`: build a local git source repo, install, update, inspect `.cwf/version`).
- **Static**: `perlcritic` single-policy check for the backtick policy.
- **Regression**: the full `t/cwf-manage-*.t` suite.

### Test Coverage Targets
- Every in-scope AC (AC1-AC4, AC7-AC10) covered by ≥1 named TC below.
- FR1, FR2, FR4 code paths each exercised by at least one test that fails before the change and passes after.
- No regression: all existing `t/cwf-manage-*.t` pass unchanged.

## Test Cases
### FR1 — `cwf_version` semver derivation / `cwf_ref` preservation (`cmd_update`)
Environment: a throwaway local git source repo (file:// source, no network) with at least one `v*` tag.

- **TC-1 (AC1, `latest`)**
  - **Given**: a source repo whose highest semver tag is `vX.Y.Z`.
  - **When**: install/update with ref `latest` (or no ref).
  - **Then**: `.cwf/version` has `cwf_version=vX.Y.Z` and `cwf_ref=latest`.
- **TC-2 (AC1, SHA on a tag)**
  - **Given**: the SHA that the tag `vX.Y.Z` points at.
  - **When**: update pinned to that SHA.
  - **Then**: `cwf_version=vX.Y.Z`; `cwf_ref=<the SHA>` (the requested ref, not the resolved tag).
- **TC-3 (AC2, ref not on a tag)**
  - **Given**: a branch/commit N commits past `vX.Y.Z`.
  - **When**: update pinned to that branch name.
  - **Then**: `cwf_version` matches `^vX\.Y\.Z-\d+-g[0-9a-f]+$` (describe long form); `cwf_ref=<branch name>`. Assert `cwf_version` is **never** the literal `HEAD` or a bare branch name.
- **TC-4 (AC2, degrade — no tags reachable)**
  - **Given**: a source repo with **no** `v*` tags, updated by SHA/branch (note: `latest` legitimately dies "No version tags found" — that path is unchanged and not under test here).
  - **When**: update by SHA.
  - **Then**: `cwf_version` is the abbreviated SHA (`^[0-9a-f]{7,}$`), update exits 0 (no crash); `cwf_ref` = the requested ref.

### FR2 — `fix-security --dry-run` + unknown-arg (subprocess, fix-security fixture)
- **TC-5 (AC3, no-mutation preview)**
  - **Given**: a fixture where one tracked file has a perms violation but matching sha256 (fixable).
  - **When**: `cwf-manage fix-security --dry-run`.
  - **Then**: the file's mode is **unchanged** (assert `stat` before == after); stdout contains a `[dry-run]` would-repair line naming the file; exit code **0**; summary line does **not** say `validate: OK`.
- **TC-6 (AC3, unfixable surfaced under dry-run)**
  - **Given**: a fixture where a tracked file's content is altered (sha256 mismatch).
  - **When**: `cwf-manage fix-security --dry-run`.
  - **Then**: the entry is reported unfixable (sha256), exit code **1**, and the file is **not** mutated. (Confirms the pre-`chmod` gates run identically in dry-run.)
- **TC-7 (AC4, unknown-arg fail-closed)**
  - **Given**: a clean fixture.
  - **When**: (a) `cwf-manage fix-security bogus`; (b) `cwf-manage fix-security --dry-run extra`.
  - **Then**: both exit non-zero with `unknown argument` naming the offending token (`bogus` / `extra`); `--dry-run` itself is accepted in (b) (i.e. it is stripped before the leftover check).
- **TC-8 (regression, live path unchanged)**
  - **Given**: a fixture with a fixable perms violation.
  - **When**: `cwf-manage fix-security` (no flag).
  - **Then**: the file **is** chmod-ed to the recorded perms, exit 0, `validate: OK` summary — identical to pre-change behaviour. (Existing `t/cwf-manage-fix-security.t` cases must also still pass.)

### FR4 — backtick→`open '-|'` conversion / `git_capture`
- **TC-9 (AC7, perlcritic)**
  - **When**: `perlcritic --single-policy InputOutput::ProhibitBacktickOperators .cwf/scripts/cwf-manage`.
  - **Then**: no violations (the two `:67`/`:309` sites are gone; no new backticks introduced).
- **TC-10 (AC8, `git_capture` contract)** — unit, `do`-load
  - **Given**: `cwf-manage` loaded so `main::git_capture` is callable.
  - **When/Then**: (a) `git_capture('rev-parse','--show-toplevel')` from inside the repo → returns `(\@lines, 0)` with the repo root as the single line; (b) a deliberately-failing call (e.g. `git_capture('rev-parse','--verify','zzz-no-such-ref')`) → non-zero exit, and the captured stdout does **not** contain git's `fatal:` text (stderr was redirected to `/dev/null`, proving the merge-trap is avoided).
- **TC-11 (AC8, `find_git_root` equivalence)**
  - **Given/When/Then**: `find_git_root` from within the repo returns the same toplevel path as `git rev-parse --show-toplevel`; invoking `cwf-manage` from a non-repo directory dies with `Not inside a git repository` and emits **no** git `fatal:` noise on stderr (behaviour-equivalent to the old `2>/dev/null`).

### Regression / knock-on
- **TC-12 (AC10 + no-regression)**: run the full `t/cwf-manage-*.t` suite → all green; `t/cwf-manage-list-releases.t` (which guards `parse_semver`/`filter_releases` and the `(installed)` marker) passes unchanged after FR1 changes `cwf_version` to a real semver.

## Non-Functional Test Cases
- **Security**: TC-7 (fail-closed on unknown args); TC-5/TC-6 (dry-run cannot mutate the filesystem); FR4's removal of the `$source` shell interpolation is verified by inspection + TC-9 (no backticks) — `cmd_list_releases`'s network `git ls-remote` path is not unit-exercised (no network in tests), so the `git_capture` contract test (TC-10) stands in for it.
- **Reliability**: TC-4 (degrade-to-SHA never crashes); TC-11 (stderr suppression preserved).
- **Usability**: TC-5 `[dry-run]` prefix is present and the summary is dry-run-distinct; `cmd_help` documents `--dry-run` (assert `cwf-manage help` output mentions it).
- **Performance**: n/a (one extra `git describe` per update; not separately benchmarked, NFR1).

## Test Environment
### Setup Requirements
- Perl core only (`Test::More`, `File::Temp`, `Cwd`, `Fcntl`, `JSON::PP`) — matches existing tests.
- FR1 tests build a **local** git source repo with tags (no network); FR2 tests copy `.cwf/` into a tempdir fixture; all DB-free.
- No production/network resources touched.

### Automation
- Tests live under `t/` and run via the project's existing `prove`/`perl` harness alongside the current `cwf-manage-*.t` files.

## Validation Criteria
- [ ] TC-1..TC-12 all pass.
- [ ] AC1-AC4, AC7-AC10 each demonstrated by their mapped TC.
- [ ] Full `t/cwf-manage-*.t` suite green (regression).
- [ ] `perlcritic --single-policy InputOutput::ProhibitBacktickOperators` clean on `cwf-manage`.
- [ ] `cwf-manage validate` OK with the refreshed `script-hashes.json`.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned TCs (TC-1..TC-12) executed and PASS; results in g-testing-exec.md. TC-5/TC-6 AC-mapping note holds (AC5/AC6 belong to deferred FR3, out of scope). Full suite 48 files / 527 tests green.

## Lessons Learned
Unit-testing `git_capture`/`git_describe_version` against throwaway tagged repos (exact-tag / long-form / no-tags / bad-committish) covered FR1's derivation logic without needing a full install→update cycle for every case; the end-to-end harness then verified only the wiring. See j-retrospective.md.

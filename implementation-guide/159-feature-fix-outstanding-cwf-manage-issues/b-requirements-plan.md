# fix outstanding cwf-manage issues - Requirements
**Task**: 159 (feature)

## Task Reference
- **Task ID**: internal-159
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/159-fix-outstanding-cwf-manage-issues
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for resolving the four outstanding `cwf-manage` backlog items.

## Scope Note (source-grounding correction)
The backlog item for item 4 (from Task 61) claims "5 backtick usages" across `find_git_root`, `resolve_ref`, `resolve_sha`, `cmd_list_releases`. Reading the current source: `resolve_ref` (`.cwf/scripts/cwf-manage:159`) and `resolve_sha` (`:187`) **already** use list-form `open my $fh, '-|', 'git', ...` and contain no backticks. Only **two** backtick command executions remain: `find_git_root` (`:67`) and `cmd_list_releases` (`:309`). FR4 is scoped to those two sites.

## Functional Requirements

### FR1 — `cwf_version` records resolved semver, not the requested ref (item 1, bugfix, Very High)
`cmd_update` (`:477-478`) currently assigns the same `$resolved` string to **both** `cwf_version` and `cwf_ref`. For `latest`, `$resolved` is the semver (good); for any other ref (`HEAD`, a branch, a SHA), `resolve_ref` (`:159`, returns verbatim at `:184`) returns the ref string unchanged, so `cwf_version` records a ref rather than a version.

- `cwf_version` MUST hold a version derived from the resolved SHA, not the requested ref string.
- `cwf_ref` MUST hold the originally-requested ref (`latest`, `HEAD`, a branch, a SHA) and MUST NOT be overwritten with the resolved value.
- For an install whose resolved SHA sits exactly on a version tag, `cwf-manage status` MUST show that semver in the Version field (e.g. a SHA that is exactly `v1.1.155` → `v1.1.155`).
- For `latest`, `cwf_version` stays the semver and `cwf_ref` records `latest`.
- **Knock-on**: `cwf_version` has a second consumer — `cmd_list_releases` (`:305`) reads it to mark the `(installed)` release. Deriving a real semver makes that marker match a `v*` tag for tagged installs (today it never matches a bare ref); this is an improvement, but FR4/AC8 MUST confirm no regression in `t/cwf-manage-list-releases.t`.
- **Acceptance**: `cwf-manage status` Version field is never a bare branch name or the literal `HEAD`; an install pinned to a tagged commit reports that tag's semver; `cwf_ref` shows the requested ref.

### FR2 — `fix-security --dry-run` preview (item 2, feature)
`cmd_fix_security` (`:861`) currently always mutates via `_apply_recorded_perms(..., 'additive')`, which calls `chmod` (`:842`).

- `cwf-manage fix-security --dry-run` MUST report the `chmod` actions it *would* take, **without mutating the filesystem** (no `chmod` call).
- Dry-run MUST share the same pre-`chmod` gates as the live path (`_apply_recorded_perms`): existence (`:806`) and sha256-match (`:823`) are evaluated **before** any `chmod`, so dry-run MUST surface those would-be-unfixable entries (missing file, sha256 mismatch) exactly as the live run does. It MUST NOT attempt to predict the chmod-failure unfixable case (`:848`), which is only knowable by attempting the mutation — dry-run reports the entry as a would-be repair, matching what the live run would try.
- Dry-run output lines that represent a would-be repair MUST be visually distinguished (e.g. prefixed `[dry-run]`).
- **Added hardening (not in the backlog item; in scope because introducing the first `fix-security` flag forces an argument-parsing decision)**: an unrecognised argument to `fix-security` MUST be rejected with a non-zero exit and a clear message (today extra args are silently ignored). Reuse the `list-releases` flag-inspection shape (`grep { $_ eq ... } @ARGV`, `:950`) rather than a new parser.
- **Acceptance**: a regression test asserts that filesystem permissions are unchanged after a `--dry-run` invocation against a fixture with a fixable perms violation; the dry-run still prints the would-be `[dry-run]` repair line, and a sha256-mismatch fixture is still surfaced as unfixable under dry-run.

### FR3 — Copy update method lays down via `install.bash` (item 3, feature)
`cmd_update` (`:452-458`) takes a `copy`-method branch that retains `cwf-manage`'s own laydown (`update_copy` → `copy_tree` with the `_escapes_src` symlink-escape guard), while the `subtree` branch already delegates to `install.bash`.

- The copy update method MUST lay files down through `install.bash` (single laydown path; backlog FR1 "single laydown").
- The upstream-symlink-escape protection currently enforced by `_escapes_src`/`_collapse_dotdot` MUST be preserved at equivalent strength after convergence (`install.bash install_copy` uses `cp -r` at `scripts/install.bash:226-243`, which today has no such guard).
- The guard MUST be evaluated over the **upstream clone contents before/while files are copied** — not deferred to `install.bash`'s post-laydown `find ... chmod` (`install.bash:246`). `cp -r` copies an escaping symlink verbatim, so a guard that fires after the copy is too late.
- The copy method MUST NOT leave a duplicate laydown path in `cwf-manage`. Any helper rendered dead by the chosen approach MUST be removed. (Which of `update_copy`/`copy_tree`/`_escapes_src`/`_collapse_dotdot` die depends on the design decision — port-into-`install.bash` vs shared-checker shell-out — so the requirement is "no dead/duplicate laydown code remains", not a fixed delete list.)
- **Acceptance**: a copy-method update of a source tree containing an out-of-tree (absolute or `..`-escaping) symlink is refused, exactly as it is today; no duplicate copy-laydown path remains in `cwf-manage` and any sub left unreferenced by the chosen design is deleted.
- **Note**: this is the highest-risk item. If preserving the guard via `install.bash` proves disproportionate (design phase decides port-into-`install.bash` vs shared-checker shell-out), the design MAY recommend deferring FR3 back to the backlog rather than weakening or dropping the guard. Weakening the symlink-escape protection is out of scope under any option.

### FR4 — Replace remaining backtick `git` calls with `IPC::Open3` (item 4, chore)
Two backtick command executions remain (see Scope Note): `find_git_root` (`:67`, `git rev-parse --show-toplevel`) and `cmd_list_releases` (`:309`, `git ls-remote --tags "$source" 'v*'`).

- Both MUST be converted to list-form invocation (`IPC::Open3`, or list-form `open '-|'` consistent with `resolve_ref`) so `perlcritic` severity 3 reports no `ProhibitBacktickOperators` violation in `cwf-manage`.
- The conversion MUST be behaviour-equivalent: existing exit-status handling is preserved (`find_git_root` tolerates the not-in-a-repo case; `cmd_list_releases` dies on a non-zero remote query).
- Without a shell there is no `2>/dev/null`, so the implementation MUST explicitly discard child stderr (e.g. redirect to `/dev/null` in the child) to keep git's "fatal: not a git repository" noise off the user's terminal in the `find_git_root` not-in-a-repo case.
- `find_git_root` MUST resolve the **same git-root path** as the current backtick form for the same cwd (its return value feeds every later `chmod`/`open`/path operation); the conversion MUST NOT introduce a `-C`/`chdir` or otherwise change which root is resolved.
- The `cmd_list_releases` conversion MUST pass `$source` as a list argument (removing the current interpolation of `"$source"` into a shell string).
- **Acceptance**: `perlcritic --severity 3` on `cwf-manage` reports no `ProhibitBacktickOperators`; the full `cwf-manage` test suite passes unchanged.

### FR5 — Integrity refresh (cross-cutting)
`cwf-manage` is hash-tracked (`.cwf/security/script-hashes.json:204`).

- Each commit that modifies `cwf-manage` MUST refresh that file's recorded sha256 in the **same commit** (hash-updates convention).
- `cwf-manage validate` MUST pass after every phase commit.

### User Stories
- **As a maintainer** I want `cwf-manage status` to show a real version **so that** I can tell which release an install corresponds to, even when it was pinned to a branch or SHA.
- **As a security-conscious operator** I want `fix-security --dry-run` **so that** I can audit what a repair would change before letting it mutate the install.
- **As a CWF developer** I want one laydown path and perlcritic-clean source **so that** the copy/subtree methods cannot drift and the script passes the project's lint bar.

## Non-Functional Requirements

### Performance (NFR1)
- No measurable added latency. FR1 adds a single `git describe` call per update; FR4 swaps process-spawn mechanism without adding spawns.

### Usability (NFR2)
- `fix-security --dry-run` documented in `cmd_help` text and the relevant SKILL/docs.
- Dry-run repair lines clearly marked (`[dry-run]`).
- Version field human-meaningful (semver or `git describe` form, never a bare ref).

### Maintainability (NFR3)
- FR3 removes four dead subs and collapses two laydown paths to one.
- FR4 conversions follow the existing list-form `open '-|'` idiom already used by `resolve_ref`/`resolve_sha` for consistency.

### Security (NFR4)
- FR3 MUST NOT weaken upstream-symlink-escape protection (no out-of-tree symlink may be written into the installed `.cwf/`).
- FR4's `cmd_list_releases` conversion removes a shell-string interpolation of `$source` (which can originate from the `CWF_SOURCE` env var via `resolve_source`), narrowing the metacharacter surface.
- (Integrity / hash-refresh is captured once as FR5; not restated here.)

### Reliability (NFR5)
- FR1 version derivation MUST degrade gracefully when the resolved SHA is not exactly on a tag (e.g. `git describe --tags` long form `v1.1.155-3-gabcdef`) and MUST NOT crash an update when no tags are reachable.
- FR4 conversions preserve existing error/exit-status handling (graceful "not in a repo" for `find_git_root`; fatal on remote-query failure for `cmd_list_releases`).

## Constraints
- Dog-food repo — all changes go through the CWF workflow; no direct-to-main commits.
- Perl **core modules only** (`IPC::Open3` is core since 5.000 — compliant).
- POSIX-only; macOS system-Perl portability.
- Hash refresh in the same commit as the underlying edit (hash-updates convention).

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? **Yes** — four independent FRs.
- [ ] **Risk**: High-risk components needing isolation? Borderline — FR3 only; isolated to its own phase commit.
- [x] **Independence**: Parts separable? **Yes**.

**Decision**: unchanged from a-task-plan — maintainer's informed bundle; each FR handled separately within one flat task and one phase commit per item.

## Acceptance Criteria
- [ ] AC1 (FR1): install pinned to a SHA on `v1.1.155` reports `Version: v1.1.155`; `cwf_ref` retains the requested ref; `latest` install reports semver + `Ref: latest`.
- [ ] AC2 (FR1): Version field is never a bare branch name or `HEAD` after an update; untagged-commit case yields a `git describe` value, not a crash.
- [ ] AC3 (FR2): `fix-security --dry-run` against a perms-violation fixture leaves file modes unchanged (asserted) and prints a `[dry-run]` would-repair line; a sha256-mismatch fixture is still surfaced as unfixable under dry-run.
- [ ] AC4 (FR2): an unknown `fix-security` argument exits non-zero with a clear message.
- [ ] AC10 (FR1 knock-on): `t/cwf-manage-list-releases.t` passes unchanged — the `(installed)` marker now keys off the resolved semver with no regression.
- [ ] AC5 (FR3): copy-method update refuses an out-of-tree/absolute upstream symlink (parity with current `_escapes_src` behaviour).
- [ ] AC6 (FR3): `update_copy`, `copy_tree`, `_escapes_src`, `_collapse_dotdot` removed from `cwf-manage`; copy method delegates to `install.bash`.
- [ ] AC7 (FR4): `perlcritic --severity 3` on `cwf-manage` reports no `ProhibitBacktickOperators`.
- [ ] AC8 (FR4): full `cwf-manage` test suite green; `find_git_root`/`cmd_list_releases` behaviour unchanged.
- [ ] AC9 (FR5): `.cwf/security/script-hashes.json` refreshed in the same commit as each `cwf-manage` edit; `cwf-manage validate` passes at every phase commit.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
FR1, FR2, FR4, FR5 delivered and covered by tests; FR3 deferred at design (copy convergence stays on backlog). All in-scope acceptance criteria (AC1, AC2, AC3, AC4, AC7, AC8, AC9, AC10) demonstrated by ≥1 passing TC; AC5/AC6 belong to deferred FR3.

## Lessons Learned
The FR4 backlog item's "5 backticks" claim was two releases stale — only 2 remained after Task 155. Re-deriving the count from the current tree at requirements time, rather than trusting backlog text, avoided over-scoping. See j-retrospective.md.

# retire bootstraps missing CHANGELOG task entry - Testing Plan
**Task**: 147 (feature)

## Task Reference
- **Task ID**: internal-147
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/147-retire-bootstraps-missing-changelog-task-entry
- **Template Version**: 2.1

## Goal
Specify the test cases that exercise the bootstrap path end-to-end, the title-derivation contract, the regression invariants on the existing-entry path, and the security guards from c-design D7 / NFR4. One test case per AC plus targeted edge coverage; no aspirational coverage targets.

## Test Strategy

### Test Levels
- **Unit (tree)** — `t/backlog-tree-mutators.t`: `bootstrap_changelog_entry` against synthetic trees. No filesystem.
- **Unit (resolver)** — `t/backlog-bootstrap-changelog.t`: `resolve_task_title_from_dir` against tmpdir fixtures (`File::Temp::tempdir` with the project-namespaced template `-home-matt-repo-coding-with-files-task-147-XXXXXX`, `DIR=>'/tmp'`, `CLEANUP=>1`; `git init` so `find_git_root` resolves; minimal `cwf-project.json`).
- **Integration (end-to-end)** — same file: invoke the `backlog-manager retire` script via `system()` against a fully-set-up tmp project. Exercises imports, the script's `repo_paths()` chain, the helpers, and the file writes.
- **Regression** — `prove t/backlog-*.t` and `cwf-manage validate` post-commit.

### Coverage
- One test per AC (AC1–AC9 from b-requirements). Targeted negative cases for each `die_user` path in the resolver.
- No numeric coverage target. A failing test trumps an "X% covered" claim.

## Test Cases

### Bootstrap happy path
- **TC-AC1 (FR1)**: bootstrap path produces well-formed CHANGELOG.
  - **Given**: tmp project with `implementation-guide/147-feature-foo-bar/`, `BACKLOG.md` containing `## Task: Old Item` with slug `old-item`, empty `CHANGELOG.md` (only `# Changelog\n\n`).
  - **When**: `backlog-manager retire --id=old-item --task=147` via `system()`.
  - **Then**: exit 0. CHANGELOG contains `## Task 147: foo bar` followed by `### Status: In Progress`, `### Impact: Task in progress.`, `### Retired Backlog Items` containing the migrated `Old Item` block. BACKLOG no longer contains `Old Item`.

### Existing-entry no-regression
- **TC-AC2 (no-regression)**: existing-entry path byte-equivalent to today.
  - **Given**: tmp project as TC-AC1, but `CHANGELOG.md` pre-populated with a full retrospective-style `## Task 147: <title>` entry (full Status / Duration / Impact / Notable / Changes / Retired Backlog Items subsections).
  - **When**: `retire --id=old-item --task=147`.
  - **Then**: exit 0. Diff of CHANGELOG touches only inside `### Retired Backlog Items` (the appended block). Title, metadata, Notable, Changes all byte-identical. No reordering. Assert via `Test::More::is` on the full file contents pre/post outside the subsection.

### Re-run + round-trip
- **TC-AC3 (FR3, NFR3)**: second retire takes existing-entry path; round-trip is byte-identical.
  - **Given**: post-TC-AC1 state.
  - **When**: add a second BACKLOG entry `Other Item` (slug `other-item`), then `retire --id=other-item --task=147`. Parse the resulting CHANGELOG, serialise, compare.
  - **Then**: exit 0. Second block appears under the same `### Retired Backlog Items` (no second `## Task 147` header). `parse(serialise($tree))` byte-equals the on-disk CHANGELOG.

### Validator clean
- **TC-AC4 (NFR2)**: bootstrap output passes `backlog-manager validate`.
  - **Given**: post-TC-AC3 CHANGELOG.
  - **When**: `system('backlog-manager', 'validate')`.
  - **Then**: exit 0. STDERR clean.

### Title derivation / directory matching
- **TC-AC5a (FR4)**: deterministic title from unique-match directory.
  - **Given**: tmp project with `implementation-guide/200-chore-do-the-thing/`.
  - **When**: call `resolve_task_title_from_dir(200)` twice in the same process.
  - **Then**: both calls return `'do the thing'`. Type token (`chore`) absent from the title.
- **TC-AC5b (FR5)**: zero-match → die, no file mutation.
  - **Given**: tmp project with empty `implementation-guide/`.
  - **When**: call `resolve_task_title_from_dir(99)`.
  - **Then**: dies with message containing `cannot bootstrap CHANGELOG entry for Task 99: no directory matching 'implementation-guide/99-*/' found`. CHANGELOG.md (if present) byte-unchanged.
- **TC-AC5c (FR6)**: multi-match → die, lists matches.
  - **Given**: tmp project with `implementation-guide/1-bugfix-a/`, `1-chore-b/`, `1-feature-c/` (replicating the legacy task-1 condition).
  - **When**: call `resolve_task_title_from_dir(1)`.
  - **Then**: dies with message containing `multiple directories match`, each basename single-quoted, and the manual-workaround hint (`manually create '## Task 1: <title>' in CHANGELOG.md first`).

### CLI surface preservation + --note flag
- **TC-AC6 (FR8)**: `--help` unchanged; `--note` works in bootstrap path.
  - **Given**: snapshot of `retire --help` output captured at HEAD (before-state).
  - **When**: run `retire --help` on the modified branch.
  - **Then**: byte-identical to before-state.
  - **Plus**: run TC-AC1 setup with `retire --id=old-item --task=147 --note='migrated mid-task'`. Resulting block in CHANGELOG contains the `<!-- migrated mid-task -->` annotation in the same position the existing-entry path produces.

### Crash recovery (NFR1)
- **TC-AC7 (NFR1)**: re-run after simulated partial state succeeds and dedups.
  - **Given**: tmp project; manually pre-write CHANGELOG with the bootstrapped entry + appended block for `old-item` (simulating "CHANGELOG written, BACKLOG write crashed"); BACKLOG still contains `Old Item`.
  - **When**: `retire --id=old-item --task=147`.
  - **Then**: exit 0. CHANGELOG byte-unchanged (dedup detects block already present — covers `backlog-manager:471-474`). BACKLOG now lacks `Old Item`.

### Security guards preserved
- **TC-AC8a (NFR4 — symlink)**: symlinked CHANGELOG.md → refuse.
  - **Given**: tmp project; `CHANGELOG.md` is a symlink to another file.
  - **When**: `retire --id=old-item --task=147`.
  - **Then**: dies with `refusing symlink at` message (existing guard at `backlog-manager:444-445`). No file mutation.
- **TC-AC8b (NFR4 — non-integer task)**: `--task=foo` → refuse before any FS read.
  - **Given**: tmp project as TC-AC1.
  - **When**: `retire --id=old-item --task=foo`.
  - **Then**: dies with `invalid --task` message (existing guard at `backlog-manager:428-429`). No CHANGELOG read.
- **TC-AC8c (NFR4 — slug with shell metacharacter)**: hand-created directory with `;` / `$` / backtick in slug does not cause shell execution or path escape.
  - **Given**: tmp project with `implementation-guide/300-feature-foo;rm--no/`. (`mkdir` with quotes — slug is purely string-data.)
  - **When**: `resolve_task_title_from_dir(300)`.
  - **Then**: the title is `'foo;rm  no'` (literal; `-` → ` ` transform) and passes title validation (no `:`, no control chars). No `system()` call, no shell expansion. End-to-end retire against this dir succeeds and writes the literal title into CHANGELOG.
- **TC-AC8d (D7 — title validation rejects `:`):**
  - **Given**: tmp project with `implementation-guide/301-feature-foo:bar/`. (Hand-created; `task-workflow create`'s slug rule normally excludes `:`, this exercises the defensive guard.)
  - **When**: `resolve_task_title_from_dir(301)`.
  - **Then**: dies with `derived title 'foo:bar' violates CHANGELOG heading constraints (contains :)`.

### Stub overwritable by retrospective (FR3)
- **TC-AC9 (FR3)**: replacing placeholder Status/Impact with retrospective content yields a validator-clean CHANGELOG.
  - **Given**: post-TC-AC1 CHANGELOG (bootstrapped stub for Task 147).
  - **When**: in-memory edit (or `Edit` tool from the test) replacing `### Status: In Progress` → `### Status: Complete (2026-05-17)`, replacing `### Impact: Task in progress.` → `### Impact: <prose>`, inserting `### Notable` and `### Changes` subsections before `### Retired Backlog Items`. Then `backlog-manager validate`.
  - **Then**: exit 0. (Byte-identical-to-from-scratch was explicitly weakened in b-requirements AC9 — semantic validity is the bar.)

### Tree-mutator unit tests (`bootstrap_changelog_entry`)
- **TC-U1 (mutator)**: empty-tree bootstrap.
  - **Given**: a `$tree` from parsing a CHANGELOG with only `# Changelog\n`.
  - **When**: `bootstrap_changelog_entry($tree, 50, 'something')`.
  - **Then**: `$tree->{entries}` length is 1; the entry has `task_num == 50`, `title eq 'something'`, expected metadata array, exactly one `Retired Backlog Items` subsection with empty body.
- **TC-U2 (mutator)**: insertion at index 0 against existing entries.
  - **Given**: a `$tree` with two existing entries (Task 100, Task 50).
  - **When**: `bootstrap_changelog_entry($tree, 200, 'x')`.
  - **Then**: `$tree->{entries}[0]{task_num} == 200`, then 100, then 50.
- **TC-U3 (mutator)**: serialise + re-parse round-trip.
  - **Given**: any `$tree` after `bootstrap_changelog_entry`.
  - **When**: `parse_changelog_tree(serialize_tree($tree))` (via tmp file or string seam).
  - **Then**: re-parsed tree's first entry deep-equals the bootstrapped entry (same metadata keys/values, same subsection name and body, same title/task_num).

### Type-list loader edge cases
- **TC-LT1**: `_load_supported_types` filters out malformed values.
  - **Given**: tmp project with `cwf-project.json` containing `"supported-task-types": ["feature", "bad type", "x" x 100, "chore"]`.
  - **When**: call `_load_supported_types` (via the resolver — covered indirectly by resolver tests).
  - **Then**: returned list is `('feature', 'chore')` (the two values matching `/\A[a-z][a-z0-9-]{0,31}\z/`).
- **TC-LT2**: `_load_supported_types` dies on empty post-filter list.
  - **Given**: `cwf-project.json` with `"supported-task-types": []` or all-malformed values.
  - **When**: call `_load_supported_types`.
  - **Then**: dies with `cwf-project.json has no usable 'supported-task-types' values`.

## Test Environment

### Setup Requirements
- `prove` (Perl `Test::Harness`, core).
- `Test::More`, `File::Temp`, `File::Path` — all core.
- `git` available on PATH (for `git init` in fixtures).
- Tmp dirs under `/tmp/-home-matt-repo-coding-with-files-task-147-XXXXXX` per [[tmp-paths]]. `File::Temp::tempdir(CLEANUP=>1)` auto-removes on test exit.

### Automation
- Tests live under `t/` and run via `prove t/backlog-*.t`.
- `cwf-manage validate` runs automatically post-checkpoint-commit (existing hook).
- No CI changes required — existing test layout already covers `t/*.t`.

## Validation Criteria
- [ ] All TC-AC* pass (one per b-requirements AC).
- [ ] TC-U* pass (mutator unit tests).
- [ ] TC-LT* pass (type-list loader edge cases).
- [ ] `prove t/backlog-*.t` exits 0 across the full Backlog suite (no regressions in `t/backlog-tree-parse.t`, `t/backlog-tree-mutators.t`, `t/backlog-tree-validate.t`, `t/backlog-roundtrip-live.t`, `t/backlog-manager.t`, `t/backlog-manager-argv-utf8.t`).
- [ ] `cwf-manage validate` exits 0 post-implementation commit.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 147
**Blockers**: None identified

## Status
**Status**: Backlog
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

# Refactor BACKLOG/CHANGELOG to heading-tree model - Implementation Plan
**Task**: 132 (feature)

## Task Reference
- **Task ID**: internal-132
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/132-refactor-backlog-changelog-to-heading-tree-model
- **Template Version**: 2.1

## Goal
Stage the design (c-design-plan.md) into a buildable, reviewable, reversible sequence of changes. Concrete files and steps; no design rationale (covered in c) and no test cases (covered in e-testing-plan.md).

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why".

Each numbered step below maps to a checkpoint commit on the task branch. Steps land on the branch in order; the live BACKLOG.md / CHANGELOG.md migration is deliberately late so the new parser is fully under test before it touches user data.

## Files to Modify

### Primary changes (committed to repo)

| File | Disposition | Notes |
|------|-------------|-------|
| `.cwf/lib/CWF/Backlog.pm` | Substantial rewrite | New `parse_backlog_tree / parse_changelog_tree`, `serialize_tree`, tree-walking validators, in-place mutators. Old `parse_backlog_file` / `parse_changelog_file` retained transiently (Step 5) and removed in Step 9 once migration has run. `_build_fence_map` reused unchanged. |
| `.cwf/scripts/command-helpers/backlog-manager` | Per-subcommand refactor | Each `cmd_*` rewritten to operate on the tree. CLI surface preserved (FR3). |
| `.cwf/security/script-hashes.json` | Hash refresh | New SHAs for `Backlog.pm` and `backlog-manager` after each step that mutates them. |
| `t/backlog.t` | Test rewrite | Assertions move from flat-blob shape to tree shape. New round-trip property test (AC6). Sidecar copy `t/backlog.t.legacy-flat-blob` retained until Step 10 (per a-task-plan high-priority-risk mitigation), deleted before final commit. |
| `t/backlog-manager.t` | Test rewrite | End-to-end tests against the new helper. |
| `t/fixtures/backlog-manager/heading-tree/` | New fixtures | Per-rule positive and negative case fixtures (per FR4 acceptance). Old fixtures under `t/fixtures/backlog-manager/current/` remain as Task 131 baseline references during migration; deleted in Step 10. |
| `BACKLOG.md` | Migrated in place | One-shot conversion in Step 6; pre-migration snapshot at `/tmp/task-132/BACKLOG.md.pre-migration`. |
| `CHANGELOG.md` | Migrated in place | Same pattern; snapshot at `/tmp/task-132/CHANGELOG.md.pre-migration`. |
| `.claude/skills/cwf-backlog-manager/SKILL.md` | New file | Instructional skill per c-design § Skill Design. |
| `.claude/settings.json` | Permission entry added | `Skill(cwf-backlog-manager)` line, matching the `/cwf-init` step-6 convention. |

### Throwaway artefacts (NOT committed)

| Path | Lifecycle |
|------|-----------|
| `/tmp/task-132/migrate-backlog-format.pl` | Created Step 6, run during rollout, deleted in `j-retrospective` Step 8 |
| `/tmp/task-132/BACKLOG.md.pre-migration` | Snapshot before Step 6 migration; deleted in `j-retrospective` Step 8 after AC1–AC8 confirmed green |
| `/tmp/task-132/CHANGELOG.md.pre-migration` | Same lifecycle as BACKLOG snapshot |
| `/tmp/task-132/baseline-perf.txt` | Output of Step 1 perf measurement; survives until retrospective for Lessons Learned reference |

## Implementation Steps

Each step ends with `cwf-checkpoint-commit 132 f "..."` and `cwf-manage validate` clean.

### Step 1: Performance baseline (resolves ODQ #10)

- [ ] Write `/tmp/task-132/baseline-perf.pl` that requires the *current* `CWF::Backlog`, calls `parse_backlog_file('BACKLOG.md')` and `validate_backlog($sects, 'BACKLOG.md')` 10 times, prints median wall-clock in ms. Same for CHANGELOG.
- [ ] Run; record output to `/tmp/task-132/baseline-perf.txt`. Expected: sub-100ms per call (Task 131 norm).
- [ ] No checkpoint commit (no repo changes); record the number in this plan's "Actual Results" at task end.

### Step 2: Build new parser alongside old in `CWF::Backlog`

- [ ] Add two parser functions: `parse_backlog_tree($path)` and `parse_changelog_tree($path)` — separate names matching the existing `parse_backlog_file`/`parse_changelog_file` convention and the validator-pair naming. Both share the same single-pass algorithm internally; the split distinguishes BACKLOG entry-type conventions (`## Task:`, `## Bug:`) from CHANGELOG (`## Task N:`).
- [ ] Returns `($tree, $global_errors)` matching the existing function-pair shape.
- [ ] Tree shape per c-design § Tree Shape: `{intro, entries: [{type, task_num, title, header_lineno, metadata, subsections, body_raw}]}`.
- [ ] Reuse `_build_fence_map` for fence-state tracking — file-wide single source.
- [ ] Add accessor: `metadata_get($entry, $key)` returns the value or undef. Iterates `$entry->{metadata}`.
- [ ] Old `parse_backlog_file` / `parse_changelog_file` remain untouched.
- [ ] Add `serialize_tree($tree, $kind)` where `$kind` is `'backlog'` or `'changelog'` (decides H2 prefix and subsection canonical-order rules per design § Mutator API). Returns bytes.
- [ ] Unit tests in `t/backlog-tree-parse.t` (new file): parse a minimal fixture, assert tree shape; round-trip a fixture, assert byte-identical.
- [ ] **Checkpoint commit**: `cwf-checkpoint-commit 132 f "Add parse_backlog_tree / parse_changelog_tree and serialize_tree alongside Task-131 parsers; round-trip test green"`.

### Step 3: Tree-walking validators

- [ ] Add `validate_backlog_tree($tree, $path)` and `validate_changelog_tree($tree, $path)`. Each returns `\@errors` where each entry is `{rule, severity, line, message}`. Severity is `'error'` (default) or `'warning'`.
- [ ] Validators build the fence map **once per invocation** (from `tree.intro` + each entry's lines) and pass `$fence` as a shared parameter to every per-rule helper. No rule rebuilds the fence map. Matches the c-design § Parser Algorithm Outline single-source-of-fence-truth principle.
- [ ] Implement rules per c-design § Validator Rule Remap:
  - GLOBAL-001a/b — same as today (file-level BOM/CRLF; called from parser, returned as `$global_errors`).
  - GLOBAL-002 (NEW) — heading text contains no control characters.
  - BACKLOG-001 — `metadata_get($e, 'Task-Type')` and `metadata_get($e, 'Priority')` defined for each active entry.
  - BACKLOG-002 — Priority value matches `$VALID_PRIORITIES` regex (unchanged from Task 131).
  - BACKLOG-004 — no HTML comments anywhere in the file (file-line scan with fence-map).
  - BACKLOG-005 — entry `title` field contains no `~~` or `✓`.
  - BACKLOG-007 (NEW, warning) — `entry.body_raw` non-empty AND `entry.metadata` non-empty (body before metadata).
  - CHANGELOG-001 — exactly one `# Changelog` header in `tree.intro`.
  - CHANGELOG-002 — `metadata_get($e, 'Status')` and `metadata_get($e, 'Impact')` defined.
  - CHANGELOG-003 — subsection name list is a prefix-of `[Changes, Notable, Retired Backlog Items]` (other names allowed after).
  - CHANGELOG-004 (NEW, warning) — same condition as BACKLOG-007.
- [ ] Old validators (`validate_backlog`, `validate_changelog`) remain untouched.
- [ ] Unit tests in `t/backlog-tree-validate.t`: per-rule positive and negative case (per FR4 acceptance).
- [ ] **Checkpoint commit**: `cwf-checkpoint-commit 132 f "Tree-walking validators with full rule remap; per-rule positive+negative tests"`.

### Step 4: Tree mutators

- [ ] Add in-place mutators per c-design § Mutator API:
  - `set_metadata_field($entry, $key, $value)` — adds or updates the H3 metadata node.
  - `add_entry($tree, $entry)` — pushes onto `tree->{entries}`.
  - `delete_entry($tree, $idx)` — splices out by index.
  - `find_entry_by_slug($tree, $slug)` and `find_entry_by_title($tree, $title)` — return `($entry, $idx)` or `undef`.
  - `find_changelog_entry_by_task_num($tree, $num)` — for `retire`.
  - `append_retired_block_tree($changelog_entry, $title, $body_raw)` — locates the `Retired Backlog Items` subsection (creating if absent per design § Mutator API canonical-order rule), appends `#### <title>` block.
  - `block_exists_in_retired_tree($changelog_entry, $title)` — case-insensitive lookup.
- [ ] Old mutators (`set_priority_field`, `append_retired_block`, etc.) remain untouched.
- [ ] Unit tests in `t/backlog-tree-mutators.t`: each mutator's success and failure modes; round-trip after mutation passes `validate_*_tree`.
- [ ] **Checkpoint commit**: `cwf-checkpoint-commit 132 f "In-place tree mutators; round-trip-after-mutate green"`.

### Step 5: Refactor `backlog-manager` subcommands one at a time

For each subcommand, in this order: `validate`, `list`, `add`, `modify`, `delete`, `retire`. Each is its own checkpoint commit so review can land per-command.

- [ ] **`cmd_validate`**: replace `parse_backlog_file` + `validate_backlog` calls with `parse_backlog_tree / parse_changelog_tree` + `validate_backlog_tree`. Format errors with `[CWF] ERROR: <RULE> at line N: <message>`; warnings with `[CWF] WARN:`. Exit 0 if no errors (warnings allowed); 1 if any error. `--strict` flag escalates warnings.
- [ ] **`cmd_list`**: replace `entry_metadata` accessor with `metadata_get`; reuse the existing band-grouping logic. The Task-131 missing-entries bug disappears at this point (the new parser produces all entries by construction).
- [ ] **`cmd_add`**: build a new entry hash with `metadata` array containing Task-Type/Priority/Status/Identified-in nodes; call `add_entry` then `serialize_tree` then `atomic_write_text`. Body lines from `--body` / `--body-file` go into `entry.body_raw` (which is allowed to be non-empty for new entries — Postel-strict canonicalisation moves them to entry-level body, after metadata, on next write).
- [ ] **`cmd_modify`**: locate via `find_entry_by_slug` / `find_entry_by_title`; call `set_metadata_field`; serialise and write.
- [ ] **`cmd_delete`**: locate; call `delete_entry`; serialise and write.
- [ ] **`cmd_retire`**: locate the BACKLOG entry, locate the CHANGELOG task entry, call `block_exists_in_retired_tree` for dedup, call `append_retired_block_tree`. Two-file atomic write per Task 131 contract: serialise CHANGELOG, write CHANGELOG, then delete BACKLOG entry, serialise BACKLOG, write BACKLOG. Same dedup-on-retry recovery semantics.
- [ ] After all six are refactored: `cwf-manage validate` clean; `prove t/` green (existing tests still pass against the *old* parsers since those still exist).
- [ ] **One checkpoint commit per subcommand**: e.g. `cwf-checkpoint-commit 132 f "Refactor cmd_validate to use parse_backlog_tree / parse_changelog_tree + validate_backlog_tree"`.

### Step 6: Migration

- [ ] Write `/tmp/task-132/migrate-backlog-format.pl` per c-design § Migration Script.
- [ ] **Semantic idempotency check first**: try `parse_backlog_tree($path)` (the new parser); if it succeeds without GLOBAL/BACKLOG errors, the file is already in heading-tree format → exit 0 with "already migrated". Only if the new parser fails or returns format-mismatch errors do we fall back to the syntactic heuristic (`grep '^---$'` and `grep '^\*\*[A-Z]'` counts) per ODQ #7. Catches the case where someone hand-edited a file into a partial state that fools the heuristic.
- [ ] **File-wide pre-migration validation**: before any conversion, run the *old* `validate_backlog`/`validate_changelog` over the whole file. If any error fires, abort with the offending line numbers and rule IDs — do not migrate a file that fails its own pre-migration validator. Migration only runs against known-clean Task-131-format files.
- [ ] Snapshot live files first: `mkdir -p /tmp/task-132/ && cp BACKLOG.md /tmp/task-132/BACKLOG.md.pre-migration && cp CHANGELOG.md /tmp/task-132/CHANGELOG.md.pre-migration`.
- [ ] Run: `perl /tmp/task-132/migrate-backlog-format.pl`. Confirm idempotent re-run reports "already migrated" with exit 0.
- [ ] Verify with `backlog-manager validate` (now using the new tree validators per Step 5).
- [ ] AC4 grep gates: `grep -c '^---$' BACKLOG.md CHANGELOG.md` = 0:0; `grep -cE '^\*\*[A-Z][\w\- ]*\*\*:' BACKLOG.md CHANGELOG.md` = 0:0.
- [ ] **AC5a** (cardinality): pre-migration top-level entry count == post-migration parsed entry count.
- [ ] **AC5b** (identity): for each old entry's title, the same title (verbatim, case-sensitive exact match) exists in the post-migration tree.
- [ ] **AC5c** (metadata cardinality, NEW from plan-review): for each migrated entry, assert the `metadata` array contains the required keys (Task-Type and Priority for BACKLOG; Status and Impact for CHANGELOG); no required key has an empty value. Detects metadata loss that AC5a/b would miss.
- [ ] **AC5d** (body byte-count, NEW from plan-review): for each migrated entry, assert the body byte count is ≥ 90% of the corresponding pre-migration entry's body byte count. Detects large-content loss that AC5a/b/c would miss. The 10% margin accommodates the metadata-syntax rewrite (`**Foo**: bar` → `### Foo: bar`) and stripped leading/trailing blanks.
- [ ] **Checkpoint commit**: `cwf-checkpoint-commit 132 f "Migrate live BACKLOG.md and CHANGELOG.md to heading-tree format; AC4/AC5a/AC5b green"`. Stage: BACKLOG.md, CHANGELOG.md (the script lives in /tmp; not staged).

### Step 7: Refactor existing tests to new APIs

- [ ] Copy `t/backlog.t` to `t/backlog.t.legacy-flat-blob` as the safety sidecar (not run; reference only).
- [ ] Rewrite `t/backlog.t` assertions to use `parse_backlog_tree / parse_changelog_tree`, `validate_*_tree`, tree mutators. Coverage parity check: every BACKLOG-XXX rule from the old test file is asserted by name in the new file.
- [ ] Same for `t/backlog-manager.t` (which tests the helper end-to-end via `run_bm`; the helper itself is now tree-based, so the tests should mostly pass with fixture-text updates only).
- [ ] Build new fixtures under `t/fixtures/backlog-manager/heading-tree/` covering each rule's positive and negative case.
- [ ] **Coverage parity check (NEW from plan-review)**: write `/tmp/task-132/verify-rule-coverage.pl` that greps both `t/backlog.t.legacy-flat-blob` and the new `t/backlog.t` for `(BACKLOG|CHANGELOG|GLOBAL)-\d{3}` rule mentions; assert the new file's set is a superset of (old set minus retired rules). Run before checkpoint commit. Prevents silent rule-coverage loss.
- [ ] `prove t/` green; record test count for AC1.
- [ ] **Checkpoint commit**: `cwf-checkpoint-commit 132 f "Refactor t/backlog.t and t/backlog-manager.t to tree APIs; new heading-tree fixtures; prove t/ green"`. Stage: t/.

### Step 8: Build the `/cwf-backlog-manager` skill

- [ ] Create `.claude/skills/cwf-backlog-manager/SKILL.md` per c-design § Skill Design. Frontmatter with `user-invocable: true`, `allowed-tools: [Bash]` (YAML hyphen syntax, matching siblings). Body documents the helper path resolution (`cd "$(git rev-parse --show-toplevel)"` before invoking), the six subcommands with one-line purpose + one example each, and the list-form invocation rule with the `--title='Test $(date)'` worked example.
- [ ] Add `Skill(cwf-backlog-manager)` line to `.claude/settings.json` per the `/cwf-init` step-6 convention.
- [ ] Manual smoke test: invoke the skill explicitly (e.g. `/cwf-backlog-manager list`) and via natural-language intent ("show me the backlog"); confirm both produce the same output as `.cwf/scripts/command-helpers/backlog-manager list` directly. AC8a satisfied.
- [ ] Manual shell-injection test: `/cwf-backlog-manager add --title='Test $(date)' --task-type=chore --priority=Low --body='x'` against a temp fixture; confirm the resulting entry's title is the literal string `Test $(date)` (not the date command's output). AC8b satisfied.
- [ ] **Checkpoint commit**: `cwf-checkpoint-commit 132 f "Add /cwf-backlog-manager skill; AC8a/AC8b green"`. Stage: `.claude/skills/cwf-backlog-manager/SKILL.md`, `.claude/settings.json`.

### Step 9: Delete Task-131-era APIs from `CWF::Backlog`

- [ ] Remove `parse_backlog_file`, `parse_changelog_file`, `_parse_sections`, `_classify_backlog`, `_classify_changelog`, `_first_non_blank_line`, `entry_title`, `entry_slug`, `entry_body_start_index`, `entry_metadata`, `_metadata_field_index`, `set_priority_field`, `append_retired_block`, `_retired_insertion_point`, `_section_start_line`, `validate_backlog`, `validate_changelog`, `_validate_backlog_file_wide`, `_validate_active_backlog`, `_validate_changelog_task` (and any other supporting code that exists only to serve the flat-blob model).
- [ ] Update `@EXPORT_OK` to drop removed names; add new exports (`parse_backlog_tree`, `parse_changelog_tree`, `serialize_tree`, `validate_backlog_tree`, `validate_changelog_tree`, `metadata_get`, mutator names, finder names).
- [ ] Refresh script-hashes.json for the new `Backlog.pm` SHA.
- [ ] `prove t/` green (legacy sidecar test file is not a `.t` so it doesn't run; still present as reference).
- [ ] **Post-deletion live-file regression check (NEW from plan-review)**: run `backlog-manager validate` against the live (post-migration) BACKLOG.md and CHANGELOG.md, confirm exit 0. Catches any lingering reference to deleted APIs that `prove t/` might miss (e.g. error-path code that wasn't exercised by tests).
- [ ] `cwf-manage validate` clean.
- [ ] **Checkpoint commit**: `cwf-checkpoint-commit 132 f "Delete Task-131 flat-blob parser/validator/mutator APIs from CWF::Backlog"`.

### Step 10: Cleanup

- [ ] Delete `t/backlog.t.legacy-flat-blob` (legacy test sidecar, retained until coverage parity confirmed).
- [ ] Delete `t/fixtures/backlog-manager/current/` (Task 131 baseline fixtures, kept as reference during migration).
- [ ] Final `cwf-manage validate` clean.
- [ ] Final `prove t/` green; record net test count vs Task 131 (AC1).
- [ ] **Checkpoint commit**: `cwf-checkpoint-commit 132 f "Delete legacy test sidecar and Task-131 baseline fixtures"`.

(Note: the migration script and snapshots in `/tmp/task-132/` are deleted in `j-retrospective` Step 8, not here, per c-design § Migration Script.)

## Validation Criteria

Cumulative — every step must satisfy the items added at that step plus everything from earlier steps:

- After Step 2: tree-parser unit tests green; round-trip property test green on at least one BACKLOG fixture and one CHANGELOG fixture.
- After Step 3: every validator rule has a positive and negative test case; severity classification tested.
- After Step 4: each mutator has tests for success path + at-least-one-failure-path; tree round-trips after every mutation.
- After Step 5: `cwf-manage validate` clean; `prove t/` green; helper subcommands behave per Task 131 baseline against tree-based parser (`prove t/backlog-manager.t` exercises this).
- After Step 6: AC3, AC4, AC5a, AC5b all green; idempotent re-run of migration confirmed.
- After Step 7: AC1 satisfied (test count net change ≥ 0 vs 408 baseline); AC6 round-trip property test on live files green; AC7 closed-loop write/read green.
- After Step 8: AC8a, AC8b satisfied via skill smoke tests.
- After Step 9: `prove t/` still green; `cwf-manage validate` clean.
- After Step 10: AC2 confirmed (script-hashes.json all match); branch is in shippable state.

Final gate at end of Step 10: every AC1–AC8 box ticked; ready for `/cwf-testing-exec` to formalise the test-run record, then `/cwf-rollout` (which itself notes the migration was already executed in Step 6 — the rollout phase becomes a documentation step rather than an additional action).

## Test Coverage
**See e-testing-plan.md for complete test plan.** This implementation plan names the test files; `e-testing-plan.md` enumerates the test cases per file.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished. Steps 9 (delete old APIs) and 10 (delete sidecars) are easy to defer and would leave dead code. Don't.

If a step uncovers a design gap that requires going back to c-design-plan: pause, update design, then resume — don't paper over it in implementation.

## Decomposition Check
- [ ] **Time**: 3-5 sessions estimated (10 steps, each one short-to-medium) → no
- [ ] **People**: solo → no
- [x] **Complexity**: 10 distinct steps with cross-file impact → yes
- [x] **Risk**: live-file migration in Step 6 carries data-loss risk → yes
- [ ] **Independence**: tightly serial (each step depends on prior) → no

**Decision unchanged**: 2 signals trigger but the work is atomic. The 10 steps are de-facto sub-units within the single task; each step's checkpoint commit gives review-grain at that level without subtask overhead.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
- Baseline perf (Step 1): BACKLOG 2.19ms median, CHANGELOG 3.97ms median (n=10).
- Post-refactor perf: BACKLOG 4.02ms median (1.84×), CHANGELOG 7.49ms median (1.89×). Well inside 5× budget.
- Final test count: 412 (baseline 408, +4 net).
- Deviations: (1) `/simplify` pass added between Steps 11 and 12 (-122 lines across `Backlog.pm` + `backlog-manager`, `pre_meta_body` slot replaced with `body_before_meta` flag); (2) `backlog-manager normalise` subcommand promoted from the throwaway migration script in response to user request — added 3 subtests (AC18a/b/c).

## Lessons Learned
- The migration script needed three iterations to land cleanly. Up-front pre-mortem of "what could the validator falsely fire on" would have saved at least the BACKLOG-007 and AC5d rounds.
- 12 checkpoint commits in implementation exec is more than ideal — checkpoint when state is durably worth keeping, not after every edit.
- Permission-prompt friction from `perl <script>` (vs `chmod +x` then direct shebang exec) was a measurable wall-clock cost. Memory `feedback_chmod_and_execute.md` captured.

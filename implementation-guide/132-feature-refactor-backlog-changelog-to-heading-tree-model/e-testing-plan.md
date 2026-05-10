# Refactor BACKLOG/CHANGELOG to heading-tree model - Testing Plan
**Task**: 132 (feature)

## Task Reference
- **Task ID**: internal-132
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/132-refactor-backlog-changelog-to-heading-tree-model
- **Template Version**: 2.1

## Goal
Specify the test cases that gate each AC1–AC8 from b-requirements-plan.md, organised by test file and scope. Concrete enough that g-testing-exec can execute against this plan without re-deriving cases.

## Test Strategy

### Test Levels

| Level | Where | Purpose |
|-------|-------|---------|
| **Unit** | `t/backlog-tree-parse.t`, `t/backlog-tree-validate.t`, `t/backlog-tree-mutators.t` (new) | Parser produces correct tree shape; each validator rule fires/silences correctly; each mutator does what it says |
| **Integration** | `t/backlog-manager.t` (refactored) | Subcommand end-to-end via `run_bm()` against isolated fixtures: `add` then `validate` then `list` round trip; `retire` two-file write semantics |
| **System** | `t/backlog-roundtrip-live.t` (new) | Parse + serialise live `BACKLOG.md` and `CHANGELOG.md` post-migration → byte-identical (AC6) |
| **Migration** | `/tmp/task-132/migrate-backlog-format.pl` self-tests | Migration script's own AC5a-d assertions (cardinality, identity, metadata, body byte-count) |
| **Skill smoke** | Manual, recorded in g-testing-exec | AC8a (parity vs direct helper); AC8b (shell-metacharacter literal-pass) |
| **Performance** | `/tmp/task-132/baseline-perf.pl` + post-refactor companion | NFR1: post-refactor wall-clock no worse than 5× pre-refactor baseline |

### Test Coverage Targets
- **Validator rules**: 100% — every rule (`GLOBAL-001a/b`, `GLOBAL-002`, `BACKLOG-001/002/004/005/007`, `CHANGELOG-001/002/003/004`) has a positive case (rule silent on valid input) and a negative case (rule fires on a fixture crafted to violate it).
- **Mutators**: 100% — each mutator (`set_metadata_field`, `add_entry`, `delete_entry`, `append_retired_block_tree`) tested for success path and at least one failure mode.
- **Subcommands**: 100% — each of `add`, `delete`, `modify`, `list`, `validate`, `retire` has at least one end-to-end test through `run_bm()`.
- **Round-trip property**: parse + serialise byte-identical for (a) every fixture under `t/fixtures/backlog-manager/heading-tree/`, (b) live BACKLOG.md and CHANGELOG.md post-migration.
- **Net test count vs Task 131 baseline (AC1)**: ≥ 408 (the d-implementation Step 1 baseline number once measured).

## Test Cases

### Parser (`t/backlog-tree-parse.t`)

- **TC-PARSE-1**: minimal BACKLOG fixture (intro + one entry)
  - **Given**: a BACKLOG fixture with `# Backlog\n\n## Task: Foo\n\n### Task-Type: chore\n### Priority: Low\n\nbody\n`
  - **When**: `parse_backlog_tree($path)` called
  - **Then**: returns `{intro, entries}` where `entries` has cardinality 1; `entries[0].type eq 'Task'`; `entries[0].title eq 'Foo'`; `entries[0].metadata` has two nodes (`Task-Type=chore`, `Priority=Low`); `entries[0].body_raw` is `["body\n"]`; `entries[0].subsections` is empty
- **TC-PARSE-2**: BACKLOG fixture with multiple entries
  - **Given**: 3 entries: 2 Tasks + 1 Bug
  - **Then**: `entries` cardinality 3; types in order are `Task, Task, Bug`
- **TC-PARSE-3**: CHANGELOG fixture
  - **Given**: a CHANGELOG fixture with `# Changelog\n\n## Task 131: Foo\n\n### Status: Complete\n### Impact: ...\n\n### Changes\n- bar\n\n### Notable\n- baz\n`
  - **Then**: `entries[0].task_num == 131`; `metadata` has Status and Impact; `subsections` has Changes (with `### Changes` body content) and Notable (likewise); both subsection `body_raw` arrays preserve the bullet lines
- **TC-PARSE-4**: fenced code block with H3-looking content
  - **Given**: an entry whose body contains a fenced block with `### Fake: NotMetadata` inside
  - **Then**: parser does NOT add a metadata node for the fake H3; the fence-bound text remains in `body_raw` as raw lines
- **TC-PARSE-5**: Postel-liberal body-before-metadata
  - **Given**: an entry with `## Task: Foo\n\nprose first\n\n### Task-Type: chore\n### Priority: Low\n`
  - **Then**: `entries[0].body_raw` contains `"prose first\n"` (the prose appears before the first H3); `metadata` still has both fields
- **TC-PARSE-6**: empty file
  - **Given**: an empty BACKLOG.md
  - **Then**: returns `{intro=[], entries=[]}`; no errors
- **TC-PARSE-7**: round-trip for every fixture under `t/fixtures/backlog-manager/heading-tree/`
  - **Given**: each `*.md` fixture
  - **When**: read bytes → `parse_backlog_tree` → `serialize_tree` → bytes
  - **Then**: output bytes are byte-identical to input bytes
- **TC-PARSE-8**: GLOBAL-002 control-character rejection
  - **Given**: a fixture with `## Task: Foo\x01Bar` (control char in title)
  - **Then**: parser raises a hard error naming line 1 and rule `GLOBAL-002`

### Validators (`t/backlog-tree-validate.t`)

For each validator rule, one positive case (silent) and one negative case (fires).

- **TC-VAL-GLOBAL-001a-pos**: file has no BOM → silent
- **TC-VAL-GLOBAL-001a-neg**: file starts with BOM bytes → fires; severity `error`
- **TC-VAL-GLOBAL-001b-pos**: file has only LF → silent
- **TC-VAL-GLOBAL-001b-neg**: file has any CRLF → fires; severity `error`
- **TC-VAL-GLOBAL-002-pos**: heading text is plain ASCII/UTF-8 printable → silent
- **TC-VAL-GLOBAL-002-neg**: heading text contains `\x01` → fires; severity `error`; line number names the offending H2 line
- **TC-VAL-BACKLOG-001-pos**: entry has both Task-Type and Priority → silent
- **TC-VAL-BACKLOG-001-neg-tt**: entry missing Task-Type → fires for missing `Task-Type`; severity `error`
- **TC-VAL-BACKLOG-001-neg-pri**: entry missing Priority → fires for missing `Priority`; severity `error`
- **TC-VAL-BACKLOG-002-pos**: Priority `High` (or any valid value) → silent
- **TC-VAL-BACKLOG-002-neg**: Priority `Critical` (not in `$VALID_PRIORITIES`) → fires; severity `error`
- **TC-VAL-BACKLOG-004-pos**: BACKLOG with no `<!--` anywhere → silent
- **TC-VAL-BACKLOG-004-neg**: BACKLOG with `<!-- foo -->` outside fences → fires
- **TC-VAL-BACKLOG-004-pos-fence**: BACKLOG with `<!-- foo -->` *inside* a fenced code block → silent (fence-aware)
- **TC-VAL-BACKLOG-005-pos**: entry title `Foo` → silent
- **TC-VAL-BACKLOG-005-neg-tilde**: entry title `~~Foo~~` → fires
- **TC-VAL-BACKLOG-005-neg-tick**: entry title `Foo ✓` → fires
- **TC-VAL-BACKLOG-007-pos**: entry has metadata followed by body → silent (canonical order)
- **TC-VAL-BACKLOG-007-neg**: entry has body before metadata → fires; severity `warning`; exit code 0 (warning, not error)
- **TC-VAL-CHANGELOG-001-pos**: file has exactly one `# Changelog` in intro → silent
- **TC-VAL-CHANGELOG-001-neg-zero**: file has zero `# Changelog` → fires
- **TC-VAL-CHANGELOG-001-neg-multi**: file has two `# Changelog` lines → fires
- **TC-VAL-CHANGELOG-002-pos**: changelog entry has Status and Impact → silent
- **TC-VAL-CHANGELOG-002-neg**: changelog entry missing Status (or Impact) → fires
- **TC-VAL-CHANGELOG-003-pos**: subsections in order `[Changes, Notable, Retired Backlog Items]` → silent
- **TC-VAL-CHANGELOG-003-pos-extra**: subsections `[Changes, Notable, Retired Backlog Items, Future Work]` → silent (extras allowed at the end)
- **TC-VAL-CHANGELOG-003-neg**: subsections `[Notable, Changes]` (out of order) → fires
- **TC-VAL-CHANGELOG-004-pos/neg**: same shape as BACKLOG-007 but for changelog entries
- **TC-VAL-FENCE-INVARIANT**: a single fixture containing all of `<!-- foo -->`, `## ~~Foo~~`, `^####`, `### Changes`, `### Status: x` — all inside one fenced code block — every validator rule silent. Asserts the file-wide single-source fence map prevents cross-rule rebuilds from disagreeing.

### Mutators (`t/backlog-tree-mutators.t`)

- **TC-MUT-set-pos**: `set_metadata_field($entry, 'Priority', 'High')` updates the existing Priority node value; round-trip + validate both pass
- **TC-MUT-set-add**: `set_metadata_field` on a key that doesn't exist yet adds a new metadata node at canonical position; round-trip preserves
- **TC-MUT-add-pos**: `add_entry($tree, $new_entry)` appends; tree validates
- **TC-MUT-delete-pos**: `delete_entry($tree, 0)` removes the first entry; tree validates; entries cardinality decreases by 1
- **TC-MUT-delete-oob**: `delete_entry($tree, 999)` (out of range) raises a clear error
- **TC-MUT-find-by-slug**: `find_entry_by_slug($tree, 'add-delete-task-skill')` returns the matching entry
- **TC-MUT-find-by-title**: `find_entry_by_title($tree, 'Add Delete Task Skill')` returns the matching entry
- **TC-MUT-find-miss**: lookups that don't match return undef cleanly
- **TC-MUT-retired-create**: `append_retired_block_tree($changelog_entry, 'Foo', [...])` on a changelog entry that lacks a `Retired Backlog Items` subsection creates it (after Notable per canonical order); subsequent `validate` passes
- **TC-MUT-retired-append**: same call on an entry that already has the subsection appends a new `#### Foo` block at the end of the existing one
- **TC-MUT-retired-dedup**: `block_exists_in_retired_tree($changelog_entry, 'Foo')` returns true after a successful append; case-insensitive lookup confirmed (`'foo'` matches `'Foo'`)

### Helper subcommands (`t/backlog-manager.t`, refactored)

Reuse the existing `make_isolated()` + `run_bm()` scaffold from Task 131. One end-to-end test per subcommand, plus the regression cases that motivated the refactor.

- **TC-CMD-add-list-roundtrip**: `add` an entry; `list` shows it under the right priority band; `validate` passes
- **TC-CMD-modify**: `add` an entry; `modify --priority=High`; re-`list` shows it under High band; `validate` passes
- **TC-CMD-delete**: `add` then `delete` by slug; `validate` passes; entry no longer appears
- **TC-CMD-validate-clean**: `validate` against a clean fixture exits 0
- **TC-CMD-validate-warn**: `validate` against a body-before-metadata fixture exits 0 (warning) and prints `[CWF] WARN: BACKLOG-007`
- **TC-CMD-validate-error**: `validate` against a missing-Priority fixture exits 1 and prints `[CWF] ERROR: BACKLOG-001`
- **TC-CMD-validate-strict**: same warn fixture as above with `--strict` flag exits 1
- **TC-CMD-list-no-merge-regression**: `add` 50+ entries that, in the Task 131 model, would have merged; new parser correctly reports them all under `list`. Direct regression test for the bug that motivated this task.
- **TC-CMD-retire-success**: `retire` an entry from BACKLOG with `--changelog-task=N`; CHANGELOG entry N gains a `#### <title>` under `Retired Backlog Items`; BACKLOG entry is gone; both files pass validate
- **TC-CMD-retire-dedup-on-retry**: run the same `retire` invocation twice; second invocation no-ops (block already exists in retired); BACKLOG-side delete is idempotent
- **TC-CMD-retire-atomic-order**: simulated mid-write failure scenario (CHANGELOG written, BACKLOG not yet) — re-running the retire invocation completes successfully (Task 131 atomic-write contract preserved)

### Migration (`/tmp/task-132/migrate-backlog-format.pl` self-test + post-migration assertions)

The migration script runs its own AC5a-d assertions internally. In addition:

- **TC-MIG-1 (idempotent re-run)**: first invocation migrates BACKLOG and CHANGELOG; second invocation reports "already migrated" and exits 0
- **TC-MIG-2 (file-wide pre-validation)**: stage a BACKLOG fixture that fails old `validate_backlog` (e.g. missing Priority); migration aborts with the offending line numbers, makes no changes
- **TC-MIG-3 (semantic idempotency)**: stage a partially-migrated file (no `---` separators but `**Field**:` metadata still present) → semantic check (try `parse_backlog_tree`) errors out → falls back to syntactic heuristic → reports "ambiguous format; manual review required"
- **TC-MIG-4 (snapshot exists)**: after migration, `/tmp/task-132/BACKLOG.md.pre-migration` and `/tmp/task-132/CHANGELOG.md.pre-migration` exist and are byte-identical to pre-migration originals (verified by sha256sum comparison against the pre-run state)
- **AC5a/b/c/d** are evaluated against the live files post-migration as the script's own exit gate

### Round-trip property test on live files (`t/backlog-roundtrip-live.t`)

- **TC-ROUNDTRIP-LIVE-BACKLOG**: read live `BACKLOG.md` → `parse_backlog_tree` → `serialize_tree` → assert byte-identical to input. Required to be green post-migration. Satisfies AC6.
- **TC-ROUNDTRIP-LIVE-CHANGELOG**: same for `CHANGELOG.md`.

### Skill smoke tests (manual, recorded in g-testing-exec.md)

- **TC-SKILL-AC8a-list**: invoke `/cwf-backlog-manager list`; assert exit code and combined stdout+stderr match running `.cwf/scripts/command-helpers/backlog-manager list` directly
- **TC-SKILL-AC8a-validate**: same for `validate`
- **TC-SKILL-AC8a-mutating**: invoke a mutating intent ("add a Medium-priority chore titled X") through the assistant against a temp fixture; assert resulting state matches direct `add` invocation
- **TC-SKILL-AC8b-shell-injection**: `/cwf-backlog-manager add --title='Test $(date)' --task-type=chore --priority=Low --body='x'` against a temp fixture; assert resulting BACKLOG entry's title contains the literal string `Test $(date)` (no command substitution evaluated)

### Performance test (NFR1)

- **TC-PERF-baseline**: pre-refactor (Step 1) — measure parse + validate on live BACKLOG.md / CHANGELOG.md, 10 runs, median wall-clock. Recorded in `/tmp/task-132/baseline-perf.txt`.
- **TC-PERF-post**: post-refactor — same script, retargeted at `parse_backlog_tree` / `validate_backlog_tree`. Assert: median wall-clock ≤ 5× pre-refactor median (NFR1's regression budget). Expect comparable or better.

## Non-Functional Test Cases

| Dimension | How tested |
|-----------|-----------|
| **Performance (NFR1)** | TC-PERF-post above |
| **Usability (NFR2)** | Manual review of `validate` error messages — each error message names rule ID and line number; format matches `[CWF] ERROR: <RULE> at line N: <message>`. Tests TC-VAL-* implicitly assert this format. |
| **Maintainability (NFR3)** | Code review during plan-review subagents (already done). Plus: post-Step-9 grep for `entry_metadata\|parse_backlog_file\|set_priority_field` returns zero in `.cwf/` (confirms old APIs fully removed). |
| **Security (NFR4)** | TC-SKILL-AC8b (shell-injection); TC-VAL-GLOBAL-002 (control-char rejection); manual confirmation that `validate_path_allowlist` and `atomic_write_text` are still called from every write path (grep). |
| **Reliability (NFR5)** | TC-CMD-retire-dedup-on-retry, TC-CMD-retire-atomic-order, TC-MIG-2 (pre-validation gate), TC-MIG-4 (snapshot durability) |

## Test Environment

### Setup Requirements

- POSIX environment with Perl 5 (the project's normal dev env; no extras).
- `t/` test fixtures already include the Task 131 baseline harness (`make_isolated()`, `run_bm()`); reuse without modification.
- New fixtures generated under `t/fixtures/backlog-manager/heading-tree/` per d-implementation Step 7.
- For migration tests: a writable `/tmp/task-132/` directory (created by the migration script).
- For TC-ROUNDTRIP-LIVE-*: the live `BACKLOG.md` and `CHANGELOG.md` post-migration. These tests are added in Step 7 and pass *only after* Step 6 has migrated the files. Until then they're skipped via a TODO wrapper (matching Task 131's pattern at `t/backlog.t::validate_backlog: live BACKLOG passes`).

### Automation

- Test framework: Perl `Test::More` (existing project standard).
- CI integration: `prove t/` runs as part of `cwf-manage validate` and the project's normal pre-commit gate. No new CI surface.
- The `--strict` flag escalates validator warnings to errors when needed for stricter pre-commit gating; default `prove t/` does not use `--strict` (warnings stay warnings, exit zero, surface in test output).

## Validation Criteria

- [ ] All `TC-PARSE-*` cases pass — parser produces correct tree shape, fence-aware, GLOBAL-002 enforced, round-trip byte-identical for every fixture.
- [ ] All `TC-VAL-*` cases pass — every validator rule has positive + negative coverage; severity classification correct; fence-invariant TC passes.
- [ ] All `TC-MUT-*` cases pass — mutators behave per spec; round-trip after mutation passes validate.
- [ ] All `TC-CMD-*` cases pass — six subcommands work end-to-end; the missing-entries regression case (TC-CMD-list-no-merge-regression) demonstrably reproduces what Task 131 missed and shows it's now caught.
- [ ] All `TC-MIG-*` cases pass — migration is idempotent, file-wide pre-validation gate works, snapshots exist, AC5a-d gates green against live files.
- [ ] `TC-ROUNDTRIP-LIVE-BACKLOG` and `TC-ROUNDTRIP-LIVE-CHANGELOG` pass post-migration (AC6).
- [ ] Skill smoke tests TC-SKILL-AC8a-* and TC-SKILL-AC8b pass (AC8a, AC8b).
- [ ] TC-PERF-post within 5× of TC-PERF-baseline (NFR1).
- [ ] `prove t/` overall: net test count ≥ 408 (AC1).
- [ ] `cwf-manage validate` clean (AC2).
- [ ] `backlog-manager validate` against live files exits 0 (AC3).
- [ ] AC4 grep gates: `grep -c '^---$' BACKLOG.md CHANGELOG.md` = 0:0; `grep -cE '^\*\*[A-Z][\w\- ]*\*\*:' BACKLOG.md CHANGELOG.md` = 0:0.

## Decomposition Check
- [ ] **Time**: parallelisable with implementation (test cases are written alongside step-by-step impl) → no
- [ ] **People**: solo → no
- [x] **Complexity**: 5 test files, ~50 distinct test cases → yes
- [ ] **Risk**: testing risk is low (regression tests exist as the safety net) → no
- [ ] **Independence**: test files are independent but logically tied to the implementation steps → no

**Decision unchanged**: 1 signal triggers, well below the 2-signal decomposition threshold. Tests are bundled with the implementation per d-implementation step plan.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
- TC-PERF-baseline: BACKLOG 2.19ms / CHANGELOG 3.97ms median (n=10).
- TC-PERF-post: BACKLOG 4.02ms (1.84×) / CHANGELOG 7.49ms (1.89×) — well inside 5× NFR1 budget.
- Final test count: 412 (baseline 408, +4 net). All TC-PARSE-*, TC-VAL-*, TC-MUT-*, TC-CMD-*, TC-MIG-* (with proxy for TC-MIG-1), TC-ROUNDTRIP-LIVE-*, TC-SKILL-AC8a/b green.
- No TCs revealed implementation defects requiring d-implementation revisions; the three bugs caught during f-implementation-exec (BACKLOG-007 false fire, AC5d body-byte reframing, idempotency heuristic) all surfaced during the migration step itself, before the test surface was rewritten.

## Lessons Learned
- The "two TCs per validator rule (positive + negative)" pattern made coverage trivially auditable — a single grep on the test file maps each rule to its tests.
- The TC-ROUNDTRIP-LIVE-* tests are the most valuable safety net: a single byte difference between read and re-serialise will fail them. Worth keeping as a pattern in any future parser/serialiser refactor.

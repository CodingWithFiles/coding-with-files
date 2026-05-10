# Add backlog management helper script - Testing Plan
**Task**: 131 (feature)

## Task Reference
- **Task ID**: internal-131
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/131-add-backlog-management-helper-script
- **Template Version**: 2.1

## Goal
Define the test surface that proves all 17 acceptance criteria from b-requirements pass under the redesigned model (BACKLOG = active only, retire moves entries), the parser round-trips byte-identically against the live BACKLOG/CHANGELOG, and no existing CWF test regresses.

---

## Test Strategy

### Test Levels

- **Unit (`t/backlog.t`)** — `CWF::Backlog` library: parser classification, metadata extraction, entry helpers, validator rules, `_build_fence_map`, the four CHANGELOG-side mutators (`find_changelog_task`, `find_retired_subsection`, `block_exists_in_retired`, `append_retired_block`).
- **Unit (`t/common.t`)** — `generate_slug` (already covered from original impl pass; survives the redesign).
- **Unit (`t/template-copier-slug-validation.t`)** — already migrated to import `generate_slug` from `CWF::Common`; continues to pass.
- **End-to-end (`t/backlog-manager.t`)** — script invoked as a subprocess (or via `do` for in-process help/exit-code tests). Each subcommand exercised against fixtures with assertions on STDOUT, STDERR, exit code, and resulting file state. ~17 subtests, one per AC.
- **Integration / dogfood (manual + Step 9 of d-impl)** — script run against a temp working copy of the live BACKLOG/CHANGELOG; output spot-checked.

### Test Coverage Targets

- **Functional**: every AC1..AC17 has at least one subtest. AC1 is exempt from the f-implementation-exec gate (validator tightening at d-impl Step 5 means AC1 fails until h-rollout migrates the 61 markers); AC1 becomes a gate at h-rollout exit.
- **Round-trip**: `parse → write` produces byte-identical output for the post-migration BACKLOG.md and CHANGELOG.md.
- **Validator rules**: every rule (BACKLOG-001..006, CHANGELOG-001..003, GLOBAL-001) has at least one passing-input fixture and at least one failing-input fixture.
- **Fence-tracking parity**: at least one subtest asserts `_build_fence_map` is consistent across all four validator rules and the two mutators that consume it (a single fixture with HTML comments, struck-through patterns, `#### ` lines, and `### Changes` headings all inside one code fence — none should fire any rule).
- **Regression**: `prove t/` pass count after Step 9 = baseline − explicit deletions + explicit additions per the pre-seeded delta in d-impl Step 0; no previously-passing test fails.

---

## Functional Test Cases

Mapped 1:1 to acceptance criteria from b-requirements. Each is a `subtest` in `t/backlog-manager.t` unless noted.

### TC-AC1 (validate live, post-migration)
- **Given**: live BACKLOG.md and CHANGELOG.md after h-rollout migration (no HTML comments, no struck-through entries).
- **When**: `backlog-manager validate` runs.
- **Then**: exits 0, no STDERR output.
- **Phase gate**: this test is expected to fail at end of f-implementation-exec and pass after h-rollout. The Step 9 regression check excludes it.

### TC-AC2 (validate flags malformed inputs)
For each fixture:

| Fixture                                            | Expected rule    | Exit | STDERR pattern                                                |
|----------------------------------------------------|------------------|------|---------------------------------------------------------------|
| `malformed-priority/BACKLOG.md`                    | BACKLOG-002      | 1    | `[CWF] ERROR: …:<line>: priority value 'Needs-Triage'…`       |
| `body-with-separator/BACKLOG.md`                   | BACKLOG-003      | 1    | `[CWF] ERROR: …:<line>: body line matches separator pattern…` |
| `with-html-comment/BACKLOG.md`                     | BACKLOG-004      | 1    | `[CWF] ERROR: …:<line>: HTML comment not permitted in BACKLOG…` |
| `struck-through/BACKLOG.md`                        | BACKLOG-005      | 1    | `[CWF] ERROR: …:<line>: struck-through entry heading not permitted…` |
| `body-with-h4/BACKLOG.md`                          | BACKLOG-006      | 1    | `[CWF] ERROR: …:<line>: '#### ' reserved for retired-block headings…` |
| `missing-priority/BACKLOG.md`                      | BACKLOG-001      | 1    | `[CWF] ERROR: …:<line>: missing required Priority field…`     |
| `out-of-order-subsections/CHANGELOG.md`            | CHANGELOG-003    | 1    | `[CWF] ERROR: …:<line>: subsections out of order: expected Changes → Notable → Retired…` |
| `bom-prefixed/BACKLOG.md`                          | GLOBAL-001       | 1    | `[CWF] ERROR: …: BOM not allowed…`                            |
| `crlf/BACKLOG.md`                                  | GLOBAL-001       | 1    | `[CWF] ERROR: …: CRLF line endings not allowed…`              |

### TC-AC3 (CHANGELOG accepts HTML comments)
- **Given**: CHANGELOG fixture with `<!-- Note: implementation diverged because X -->` inside a Task entry's body.
- **When**: `validate`.
- **Then**: exit 0. Same comment in BACKLOG would fail (covered by TC-AC2 / BACKLOG-004).

### TC-AC4 (CHANGELOG optional fields and subsection order)
- **Given**: `omitted-changelog-fields/CHANGELOG.md` — entries omit `**Duration**:`, `### Changes`, `### Notable`, `### Retired Backlog Items` in various combinations.
- **When**: `validate`.
- **Then**: exit 0 (subsection presence is optional; only the order matters when multiple are present).

### TC-AC5 (list grouped output, default)
- **Given**: live BACKLOG (post-migration: only active entries).
- **When**: `list`.
- **Then**: STDOUT band headers in order Very High → High → Medium → Low → Very Low; one-line summary per entry; up to 20 entries shown.
- **Empty band**: priorities with zero entries do not emit a header.

### TC-AC6 (list soft-cap and --all-items)
- **Given**: `top-band-overflow/BACKLOG.md` — 25 entries in High band, 5 in Medium.
- **When (a)**: `list` (default).
- **Then (a)**: all 25 High-band entries shown; Medium not shown (top-band-no-split rule).
- **When (b)**: `list --all-items`.
- **Then (b)**: all 30 entries shown.
- **When (c)**: `list` run twice on identical input.
- **Then (c)**: byte-identical output (stable order).

### TC-AC7 (add valid entry)
- **Given**: temp BACKLOG (clean fixture).
- **When**: `add --priority=Medium --task-type=chore --title="Test" --body="x"`.
- **Then**: exit 0; subsequent `validate` exit 0; entry at end of file.

### TC-AC8 (add rejects)
For each rejection:

| Input                                       | Rule                          | Exit |
|---------------------------------------------|-------------------------------|------|
| `--priority=Needs-Triage`                   | b-req: banned priority (BACKLOG-002) | 1 |
| `--body` containing `^---$` line             | BACKLOG-003                   | 1    |
| `--body` containing `^#### ` line            | BACKLOG-006                   | 1    |
| `--body-file=/etc/passwd`                    | path allowlist                | 2    |
| `--body-file=../../escape`                   | path allowlist                | 2    |

### TC-AC9 (modify byte-preservation)
- **Given**: temp BACKLOG with one entry having `**Status**:` set.
- **When**: `modify --id=<slug> --priority=Low`.
- **Then**: exit 0; resulting entry has `**Priority**: Low`; **all other bytes identical** (verified via byte-level diff: `**Status**:` retained, body unchanged, `**Identified in**:` retained, blank lines unchanged).

### TC-AC10 (slug collision)
- **Given**: `slug-collision/BACKLOG.md` — two entries producing the same slug.
- **When**: `modify --id=<colliding-slug> --priority=Low`.
- **Then**: exit 1; STDERR contains both colliding titles.

### TC-AC11 (delete safety)
- **When (a)**: `delete --id=<slug>` (no `--confirm`).
- **Then (a)**: exit 1; STDERR mentions `--confirm`.
- **When (b)**: `delete --id=<slug> --confirm` on active entry.
- **Then (b)**: exit 0; entry removed; subsequent `validate` exit 0.

### TC-AC12 (retire moves entry)
- **Given**: temp BACKLOG with target entry titled "Foo"; CHANGELOG with implementing-task Task 131 entry that has `### Changes` and `### Notable` sections (no Retired yet).
- **When**: `retire --id=foo --task=131`.
- **Then**: exit 0. Post-conditions:
  - The "Foo" entry is **gone** from BACKLOG (no marker tombstone).
  - Task 131's CHANGELOG entry now has `### Retired Backlog Items` inserted **after** `### Notable`.
  - That subsection contains a `#### Foo` block whose body matches the original BACKLOG entry's body verbatim.
  - `validate` exits 0 on both files.
- **Sub-cases**:
  - Implementing task has only `### Changes`: `### Retired Backlog Items` inserted after `### Changes`.
  - Implementing task has neither: `### Retired Backlog Items` inserted right after the metadata block.
  - Implementing task already has `### Retired Backlog Items` with one block: new `#### Foo` appended to that subsection.

### TC-AC13 (retire --note handling)
- **When (a)**: `retire --id=<slug> --task=131 --note="Implementation diverged because X"`.
- **Then (a)**: exit 0; CHANGELOG block ends with `<!-- Note: Implementation diverged because X -->` after the body.
- **When (b)**: parametrised rejection — `--note=""` (empty), `--note="contains -->"`, `--note="line1\nline2"`, `--note="\x00"`, `--note="\xEF\xBB\xBF"` (BOM-like), `--note="\r"`.
- **Then (b)**: exit 1 with `[CWF] ERROR: backlog-manager retire: --note must be …` for each.

### TC-AC14 (retire missing CHANGELOG entry)
- **Given**: BACKLOG entry "Foo"; CHANGELOG has Tasks 100..130, no Task 999.
- **When**: `retire --id=foo --task=999`.
- **Then**: exit 1; STDERR matches `Task 999 has no CHANGELOG entry; create the entry first or pick a different --task`. **Both files unchanged** (mtime stable).

### TC-AC15 (retire idempotency + crash-state recovery)
**Part (a) — already retired**:
- **Given**: BACKLOG no longer has the entry; CHANGELOG already has the `#### Foo` block under Task 131's `### Retired Backlog Items`.
- **When**: re-run `retire --id=foo --task=131`.
- **Then**: exit 0; STDOUT/STDERR contains `[CWF] INFO: backlog-manager retire: foo not found in BACKLOG (already retired?)`; both file mtimes unchanged.

**Part (b) — crash recovery (CHANGELOG-written, BACKLOG-not)**:
- **Given**: `crash-recovery/BACKLOG.md` still has the active entry; `crash-recovery/CHANGELOG.md` already has the `#### Foo` block under Task 131's `### Retired Backlog Items`.
- **When**: `retire --id=foo --task=131`.
- **Then**: exit 0; BACKLOG entry now removed (BACKLOG mtime advanced); CHANGELOG unchanged (mtime stable, dedup detected the existing block); `validate` passes on both files.

### TC-AC16 (help and missing-arg behaviour)
- `backlog-manager` (no args) → exit 1, STDERR `[CWF] ERROR: backlog-manager: missing subcommand`.
- `backlog-manager --help` → exit 0, STDOUT lists all subcommands.
- `backlog-manager validate --help` → exit 0, STDOUT shows validate-specific usage.
- `backlog-manager add --priority=High` (missing other required flags) → exit 1, STDERR `[CWF] ERROR:`, no help text printed.

### TC-AC17 (round-trip integration chain)
- Subtest with explicit per-step assertions:
  ```
  add → validate (must pass) → modify → validate (must pass) → retire → validate (must pass)
  ```
- Per-step `is(rc, 0, "validate after <step>")` so a failure pinpoints which transition broke.

---

## Library-level Test Cases (`t/backlog.t`)

Beyond the AC mapping, `t/backlog.t` exercises the library directly:

- **TC-LIB-1 — `_build_fence_map`**: 6-line fixture with two fences; assert per-line booleans match expectation.
- **TC-LIB-2 — Round-trip**: parse + write of a sample BACKLOG → byte-identical.
- **TC-LIB-3 — Classification**: hand-crafted entries hit each kind (`active`, `intro`, `changelog_task`, `blank`, `unknown`).
- **TC-LIB-4 — Metadata extraction**: `entry_metadata` returns expected hashref; trailing whitespace trimmed at access time but raw_lines preserve it.
- **TC-LIB-5 — `find_changelog_task`**: hits exact integer Task number; ignores leading-zero matches.
- **TC-LIB-6 — `find_retired_subsection`**: returns correct line range; returns undef when absent; respects fence boundaries.
- **TC-LIB-7 — `block_exists_in_retired`**: matches case-insensitively, whitespace-stripped; ignores `#### ` lines inside fences.
- **TC-LIB-8 — `append_retired_block`**: insertion position correct for each c-design § Decision 7 case (after Notable / after Changes / after metadata); subsection created on first use; subsequent appends within existing subsection.
- **TC-LIB-9 — Fence-parity invariant**: single fixture with HTML comments, struck-through `## ~~`, `#### ` lines, and `### Changes` headings ALL inside one code fence; running each of `validate_backlog`, `validate_changelog`, `find_retired_subsection`, `block_exists_in_retired` produces zero findings.

---

## Non-Functional Test Cases

### NFT-1: Performance
- **Given**: live BACKLOG.md (~1810 lines pre-migration, ~1600 post) and CHANGELOG.md.
- **When**: `validate`, `list`, `list --all-items` each run.
- **Then**: each completes in under 2 seconds (b-req NFR1). `list --all-items` under 1 second.
- Measured via `time` in dogfood step; not asserted in `prove t/`.

### NFT-2: Security
- **Symlink defence**: with BACKLOG.md temporarily replaced by a symlink in a temp dir, `retire` exits with `[CWF] ERROR: refusing symlink` and does not write through.
- **Path allowlist**: `--body-file=/etc/passwd` exit 2; `--body-file=../../escape` exit 2 (covered in TC-AC8).
- **`--note` injection**: parametrised rejection of all non-printable-ASCII and empty (covered in TC-AC13).
- **Body separator collision**: body line `^---$` rejected (TC-AC8).
- **Retired-block heading collision**: body line `^#### ` rejected (TC-AC8).

### NFT-3: Usability
- All errors prefixed `[CWF] ERROR: backlog-manager <subcommand>:`.
- Help text matches NFR2 conventions.
- Asserted via STDERR pattern checks in TC-AC1..AC16.

### NFT-4: Reliability — round-trip + atomicity
- **Round-trip**: TC-LIB-2 above.
- **Two-file atomicity**: TC-AC15 part (b).
- **Single-file atomicity**: not separately tested — relies on `atomic_write_text`'s contract (already covered in `t/artefacthelpers.t`).

---

## Test Environment

### Setup Requirements
- Repo at HEAD on `feature/131-add-backlog-management-helper-script` branch.
- Perl 5.14+ with core modules.
- No external services, no test database.
- `t/fixtures/backlog-manager/current/` symlinks resolve correctly (relative paths). The `current/` symlinks point at the *post-migration* live files; pre-migration they will fail TC-AC1 (expected, gate on h-rollout).

### Automation
- Standard `prove t/` driver. Tests use `Test::More`.
- Pre-existing CWF tests (notably `t/templatecopier.t`, `t/template-copier-slug-validation.t`, `t/common.t`, `t/artefacthelpers.t`) MUST continue to pass post-implementation — d-impl Step 9 asserts this.
- `cwf-manage validate` MUST pass after the script and library SHAs are refreshed in `script-hashes.json`.

---

## Validation Criteria
- [ ] All 17 functional test cases (TC-AC1..AC17) implemented; all pass except TC-AC1 which is gated on h-rollout.
- [ ] All 9 library test cases (TC-LIB-1..LIB-9) implemented and pass.
- [ ] All validator rules (BACKLOG-001..006, CHANGELOG-001..003, GLOBAL-001) covered by both passing and failing fixtures.
- [ ] Fence-parity invariant (TC-LIB-9) passes — single source of fence semantics across rules and mutators.
- [ ] `prove t/` post-implementation pass count matches d-impl Step 0's expected count (baseline minus deletions plus additions); no regressions in pre-existing tests.
- [ ] Performance: live BACKLOG `validate`/`list` under 2 seconds.
- [ ] Security: symlink defence, `--note` rejection, body-separator rejection, body-h4 rejection, path-allowlist all hit.
- [ ] `cwf-manage validate` clean post-Step 8.

---

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ concerns? No.
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Parts that can be worked on separately? No.

No decomposition warranted.

---

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

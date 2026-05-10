# Add backlog management helper script - Implementation Plan
**Task**: 131 (feature)

## Task Reference
- **Task ID**: internal-131
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/131-add-backlog-management-helper-script
- **Template Version**: 2.1

## Goal
Concrete file-by-file implementation order to **amend** the existing helper from the original impl pass to match the redesigned model: drop marker classifications, drop `make_completed_marker` / `insert_changelog_bullet`, add CHANGELOG-side mutators (`find_changelog_task`, `find_retired_subsection`, `block_exists_in_retired`, `append_retired_block`), rewrite `cmd_retire`, tighten the validator (BACKLOG-004/005 generalised, BACKLOG-006 added, CHANGELOG-003 added). Tests track each step.

## Workflow
Add new code first → swap callers → trim old code → amend validator. This ordering keeps the codebase compiling at every step (the original draft of this plan reversed the first two steps and would have left the script importing deleted functions between the trim and the rewrite).

---

## Existing artefacts (from original impl pass — survive the redesign)

These are kept as-is unless explicitly modified below:
- `.cwf/lib/CWF/Common.pm::generate_slug` — kept verbatim. Shared with `template-copier-v2.1` and `backlog-manager`.
- `.cwf/scripts/command-helpers/backlog-manager` argument parser (`parse_args`), dispatch table (`%dispatch`), top-level help, `classify_exit_code`, exit-code translation, and `cmd_add`/`cmd_modify`/`cmd_delete`/`cmd_list` handlers — kept; minor tweaks per Step list.
- `.cwf/lib/CWF/Backlog.pm` Pass-1 splitter, fence-tracking, byte-preserving `raw_lines`, `entry_title`, `entry_metadata`, `entry_body_start_index`, `find_active_by_slug`, `find_active_by_title`, `set_priority_field`, `set_metadata_field` — kept.
- `t/backlog.t` parser/round-trip subtests, `t/backlog-manager.t` AC1/AC5/AC7/AC9/AC11/AC16 — kept (some assertion tweaks per Step list).
- `.cwf/security/script-hashes.json` entries for `backlog-manager` and `CWF::Backlog` — present but stale; refreshed in Step 8.

---

## Files to Modify

### Modified (existing files amended)
- `.cwf/lib/CWF/Backlog.pm` — drop marker classifications + `make_completed_marker` + `insert_changelog_bullet`; add `find_changelog_task`, `find_retired_subsection`, `block_exists_in_retired`, `append_retired_block`; broaden BACKLOG-004 (any `<!--`/`-->`); broaden BACKLOG-005 (any struck-through `^##`); add BACKLOG-006 (no `^#### ` in active body); add CHANGELOG-003 (subsection order: Changes → Notable → Retired).
- `.cwf/scripts/command-helpers/backlog-manager` — rewrite `cmd_retire` per c-design § Decision 6 (delete-and-append, not replace-with-marker); replace `--reason` / `--changelog-bullet` flags with `--note`; tighten `--note` to printable ASCII only; drop title-`-->` rejection from `cmd_add` / `cmd_modify` (no longer relevant).
- `t/backlog.t` — drop tests for removed marker classifications; add tests for new validator rules (BACKLOG-004 generalised, BACKLOG-005 generalised, BACKLOG-006, CHANGELOG-003); add tests for new mutators (`find_changelog_task`, `append_retired_block`, dedup).
- `t/backlog-manager.t` — replace AC12, AC13, AC14, AC15 with the new contracts; AC1/AC5/AC7/AC9/AC11/AC16/AC17 mostly stay (small refinements).
- `t/fixtures/backlog-manager/` — drop `mixed-markers/`; replace `crash-recovery/`; add `with-html-comment/`, `struck-through/`, `out-of-order-subsections/`, `body-with-h4/` (BACKLOG-006), `retire-with-note/`, `retire-no-changelog-entry/`.
- `.cwf/security/script-hashes.json` — refresh `backlog-manager` and `CWF::Backlog` SHAs after the edits.
- `BACKLOG.md` — **bulk migration of 61 HTML-comment lines** is part of h-rollout, not f. Listed here for traceability.

### Out of scope (deferred)
- `.cwf/lib/CWF/ArtefactHelpers.pm::validate_path_allowlist` symlink-resolution enhancement — already on BACKLOG ("Resolve symlinks in validate_path_allowlist").
- `atomic_write_text` TOCTOU window via `O_NOFOLLOW` — already on BACKLOG ("Close TOCTOU window in atomic_write_text via O_NOFOLLOW").
- Wiring `backlog-manager validate` into `cwf-manage validate` — separate follow-up.

---

## Implementation Steps

### Step 0: Setup & verification
- [ ] Confirm git tree is clean and on `feature/131-add-backlog-management-helper-script`.
- [ ] `prove t/ --quiet | tee /tmp/cwf131-baseline.txt` — record current pass count.
- [ ] **Pre-seed the regression delta** (Step 9 reads this): list the marker-era subtests that this task will explicitly delete (in `t/backlog.t`: `'classify: historical markers'`, `'classify: struckthrough variants'`, `make_completed_marker` subtests, `insert_changelog_bullet` subtests; in `t/backlog-manager.t`: AC3 "mixed markers accepted"). Plus the BACKLOG-006 / BACKLOG-006-WARN warning subtest. The Step 9 expected-pass-count = baseline − (count of these deletions) + (count of new validator/mutator/AC subtests added in Steps 1, 2, 5, 7).
- [ ] **AC1 baseline caveat**: AC1 (validate against live BACKLOG/CHANGELOG) currently passes if the existing impl was patched to tolerate the 61 markers. After Step 5 (validator tightening), AC1 will fail until h-rollout migrates the markers out. The Step 9 regression check explicitly excludes AC1; AC1 is a gate on the h-rollout exit, not f-implementation-exec.
- [ ] Re-read c-design-plan.md § Decisions 3, 5, 6, 7, 11.
- [ ] Re-read the *current* `CWF::Backlog.pm`. Note the actual classifier kinds (the live code uses `historical`, `struckthrough_completed`, `struckthrough_tick`; not `marker_*`). Step 4 below uses these real names.
- [ ] Confirm `t/backlog.t` and `t/backlog-manager.t` pass against the current impl.

### Step 1: Add a shared fence-state helper
- [ ] Add `sub _build_fence_map($lines)` to `CWF::Backlog`: returns an arrayref of booleans, one per input line, true when the line is inside a code fence. A line containing exactly `^```` toggles the fence state and is itself considered "in fence" (i.e. fence-delimiter lines are not editable content). Used by all four validator rules in Step 5 and the two mutators in Step 2 — keeps fence semantics identical across uses.
- [ ] Subtest in `t/backlog.t` for the helper: input with two fences and inter-fence content, assert per-line booleans match expectation.

### Step 2: Add CHANGELOG-side mutators to `CWF::Backlog`
Additive only — no existing code is touched. Order chosen so each new sub uses only previously-defined helpers.

- [ ] **`find_changelog_task($entries, $task_num)`** — walks `@$entries`, returns the entry hashref where `kind eq 'changelog_task'` and the header matches `^## Task $task_num:` (exact integer match). Returns undef if not found.
- [ ] **`find_retired_subsection($entry)`** — uses `_build_fence_map` over `$entry->{raw_lines}`. Returns `($start_idx, $end_idx)` of the `### Retired Backlog Items` subsection (matching only outside fences). `$start_idx` = index of the `### Retired Backlog Items` line itself. `$end_idx` = index of the next `^### ` heading outside fences (exclusive) or `scalar @raw_lines`. Returns undef if absent.
- [ ] **`block_exists_in_retired($entry, $title)`** — calls `find_retired_subsection`. Scans lines `[$start_idx+1 .. $end_idx-1]` for `^####\s+(.*?)\s*$` outside fences (regex `/^####\s+/` shared with the BACKLOG-006 validator in Step 5). Compares `lc` of captured title against `lc` of input title. Returns true on first match.
- [ ] **`append_retired_block($entry, $title, \@body_lines, $note)`** — mutates `$entry->{raw_lines}` in place. If the subsection exists, splice the new block at `$end_idx`. If absent, compute the insertion point per c-design § Decision 7 step 1 — at `entry_body_start_index($entry)` (the body-start index already points to the position immediately after the metadata block), advanced past `### Changes` / `### Notable` sections if present. Insert:
  ```
  ""
  "### Retired Backlog Items"   ← only if creating subsection
  ""                            ← only if creating subsection
  "#### $title"
  ""
  @body_lines                   ← verbatim
  ""
  ("<!-- Note: $note -->", "")  ← only if $note defined
  ```
  Trailing blank line included so subsequent appends start cleanly.
- [ ] Add to `@EXPORT_OK`. Update POD.
- [ ] Subtests in `t/backlog.t` per mutator (subsection-absent / present / multi-block / fence interaction).

### Step 3: Rewrite `cmd_retire` in the script (still imports old marker helpers; trim happens in Step 5)
- [ ] Replace flag handling: drop `--reason`, drop `--changelog-bullet`. Add `--note` (optional). `--note` validation: empty string → reject (`die "[CWF] ERROR: backlog-manager retire: --note must not be empty\n" if defined $note && $note eq ''`); otherwise must match `/^[\x20-\x7E]+$/` (printable ASCII, one or more characters); reject otherwise with `[CWF] ERROR: backlog-manager retire: --note must be printable ASCII`.
- [ ] Replace flow body per c-design § Decision 6:
  1. Read both files via `parse_backlog_file` + `parse_changelog_file`.
  2. `find_active_by_slug` (or `find_active_by_title`) on BACKLOG side; missing → INFO + exit 0; ambiguous → ERROR + exit 1.
  3. `find_changelog_task` for `--task=N`; missing → ERROR with the "create entry first" message + exit 1.
  4. Check `block_exists_in_retired` for the target's title. If true → `$need_changelog_write = 0`; else call `append_retired_block` and set `$need_changelog_write = 1`.
  5. Drop the target entry from the in-memory BACKLOG entry list.
  6. Symlink defence: `die ... if -l $BACKLOG_PATH || -l $CHANGELOG_PATH;` (existing pattern, unchanged).
  7. `write_changelog_file` if `$need_changelog_write`.
  8. `write_backlog_file`.
- [ ] Update `usage_retire` text: `Usage: backlog-manager retire (--id=SLUG | --exact-title=TITLE) --task=N [--note=TEXT]`.
- [ ] At this checkpoint `backlog-manager` no longer references `make_completed_marker` or `insert_changelog_bullet`, but both are still imported and exported (still compiles, still passes its own tests for non-retire commands).

### Step 4: Trim — drop marker code from `CWF::Backlog`
Now that no caller uses them, the marker code can be deleted without breaking compilation.

- [ ] Delete classification branches for `historical`, `struckthrough_completed`, and `struckthrough_tick` from `_classify_backlog`. Result: classifier returns `intro`, `active`, `changelog_task`, `blank`, or `unknown`.
- [ ] Delete `make_completed_marker` (function body) and remove from `@EXPORT_OK`.
- [ ] Delete `insert_changelog_bullet` (function body) and remove from `@EXPORT_OK`.
- [ ] Delete `_validate_historical` and the dispatch from `validate_backlog` to it.
- [ ] Delete the `use CWF::Backlog qw(... make_completed_marker insert_changelog_bullet ...);` entries from `backlog-manager`'s import list.
- [ ] Delete the corresponding subtests in `t/backlog.t`: `'classify: historical markers'`, `'classify: struckthrough variants'`, `make_completed_marker` and `insert_changelog_bullet` subtests, BACKLOG-006-WARN (struckthrough-warning) subtest.
- [ ] Delete `t/backlog-manager.t::AC3 "mixed markers accepted"` (the test was validating the old marker model; the new model rejects them).
- [ ] Delete the `t/fixtures/backlog-manager/mixed-markers/` fixture directory.
- [ ] `prove t/backlog.t t/backlog-manager.t` — should pass minus the deletions; new validator failures from existing fixtures are addressed in Step 5.

### Step 5: Amend the validator
All four rules use `_build_fence_map` from Step 1 — identical fence semantics.

- [ ] **BACKLOG-004 generalised**: replace per-marker checks with a single fence-aware walk that flags any line containing `<!--` or `-->` outside a code fence. Apply across the whole file (not just within entries).
- [ ] **BACKLOG-005 generalised**: flag any `^## ` line outside fences containing `~~` or `✓` (covers both struck-through patterns).
- [ ] **BACKLOG-006 (new)**: for each `kind eq 'active'` entry, build a fence map over its `raw_lines` and flag any line at index ≥ `entry_body_start_index` matching `/^####\s+/` outside fences. The `\s+` anchor (one or more whitespace) is the canonical match — same regex as `block_exists_in_retired`. `^####X` (no whitespace) is therefore not h4 markdown and is not flagged.
- [ ] **CHANGELOG-003 (replaces the old separator-collision check on the same rule number)**: for each `kind eq 'changelog_task'` entry, build a fence map and collect the order of `^### (Changes|Notable|Retired Backlog Items)` lines outside fences. Assert canonical sequence (Changes-then-Notable-then-Retired, with any subset allowed, never out-of-order). Note: the previous CHANGELOG-003 check (no `^---$` in body) was a duplicate of BACKLOG-003 applied to CHANGELOG; it's removed because CHANGELOG entries are not subject to the entry-separator collision (different file format).
- [ ] Drop the old `validate_backlog` rule numbers BACKLOG-004 (unclosed-marker) and BACKLOG-005 (orphan-reason); their numbers are now reused for the new generalised rules above.
- [ ] Add subtests to `t/backlog.t` per new rule using the new fixtures (`with-html-comment/`, `struck-through/`, `body-with-h4/`, `out-of-order-subsections/`).

### Step 6: Update test fixtures
- [ ] Delete `t/fixtures/backlog-manager/mixed-markers/` (no longer accepted by validator).
- [ ] Rewrite `t/fixtures/backlog-manager/crash-recovery/` for the new model: `BACKLOG.md` still has the active entry; `CHANGELOG.md` has Task <N> entry with `### Retired Backlog Items` containing a `#### <title>` block matching that entry. Re-run of `retire` should detect the existing block and only rewrite BACKLOG.
- [ ] Create `t/fixtures/backlog-manager/with-html-comment/BACKLOG.md` — entry with stray `<!-- something -->` inside body (BACKLOG-004).
- [ ] Create `t/fixtures/backlog-manager/struck-through/BACKLOG.md` — entry with `## ~~Task: Foo~~ ✓ COMPLETED` heading (BACKLOG-005).
- [ ] Create `t/fixtures/backlog-manager/body-with-h4/BACKLOG.md` — entry whose body contains `^#### Subhead` line (BACKLOG-006).
- [ ] Create `t/fixtures/backlog-manager/out-of-order-subsections/CHANGELOG.md` — Task entry with `### Notable` appearing before `### Changes` (CHANGELOG-003).
- [ ] Create `t/fixtures/backlog-manager/retire-with-note/` — minimal BACKLOG entry + CHANGELOG with implementing-task entry (AC13).
- [ ] Create `t/fixtures/backlog-manager/retire-no-changelog-entry/` — BACKLOG entry to retire under a Task <N> with no CHANGELOG entry (AC14).

### Step 7: Update `t/backlog-manager.t`
- [ ] **AC12** rewritten: `retire --id=<slug> --task=131` produces an `### Retired Backlog Items` subsection (created if absent; appended to if present), containing `#### <title>` + body verbatim. The BACKLOG entry is gone. `validate` passes. Verify subsection insertion position: after `### Notable` if present, else after `### Changes`, else after metadata.
- [ ] **AC13** rewritten: `retire --note="X"` produces `<!-- Note: X -->` after the body. `--note` containing any non-printable-ASCII character is rejected (parametrised: `-->`, `\n`, `\r`, `\x00`, `\xEF\xBB\xBF` BOM-like, etc.).
- [ ] **AC14** new: `retire --task=999` against a Task 999 with no CHANGELOG entry exits 1 with the "create entry first" message; both files unchanged.
- [ ] **AC15** rewritten: two-part — (a) re-run on already-retired entry exits 0 INFO; (b) crash-recovery (BACKLOG-still-has-entry + CHANGELOG-already-has-block) reconciles to clean state with no duplicate block.
- [ ] **AC2** updated: covers the new BACKLOG-004/005/006 + CHANGELOG-003 fixtures.
- [ ] **AC1** kept: live BACKLOG.md / CHANGELOG.md after rollout migration must pass `validate`. Pre-migration the test will fail (61 markers); that's expected until h-rollout runs. AC1 is therefore a "must pass after h-rollout" gate, not a Step 9 gate.
- [ ] **AC17** kept: `add → modify → validate → retire` chain, updated to use new `retire` API.

### Step 8: Permissions and hash refresh
- [ ] `chmod 0500 .cwf/scripts/command-helpers/backlog-manager`.
- [ ] Recompute SHA256 of `backlog-manager` and `CWF::Backlog` after edits; update `.cwf/security/script-hashes.json`.
- [ ] Run `cwf-manage validate` → must exit 0.

### Step 9: Regression check
- [ ] `prove t/` — pass count must equal Step 0 expected count (baseline minus deletions plus additions, per the pre-seeded delta).
- [ ] Manual smoke test against a temp working copy of BACKLOG/CHANGELOG: each subcommand runs to completion with sensible output.
- [ ] **AC1 deferred check**: at this point AC1 still fails (live BACKLOG has 61 markers). Explicitly note this in the f-implementation-exec results section. AC1 will pass once h-rollout migrates the markers.

---

## Test Coverage
**See e-testing-plan.md for the complete plan.** This d-impl identifies fixtures and per-step tests; e-testing-plan finalises assertions and adds non-functional checks.

## Validation Criteria
- All `prove t/` tests pass except AC1 (see Step 9 caveat).
- `cwf-manage validate` clean.
- `script-hashes.json` matches on-disk SHAs for both `backlog-manager` and `CWF::Backlog`.
- Visual diff of `CWF::Backlog.pm`: marker code is gone, mutators are added, validator rules are amended.

---

## Decomposition Check
- [ ] **Time**: >1 week? No — amendment of existing impl, ~half-day of edits.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ concerns? No — single domain.
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Parts that can be worked on separately? No — pruning and adding must happen in lock-step.

No decomposition warranted.

---

## Scope Completion
**IMPORTANT**: Complete all 9 implementation steps before marking task Finished. Do not defer Step 8 (permissions/hashes) or Step 9 (regression) — both are gate criteria.

**If we must defer**:
1. Get user approval with rationale.
2. Update success criteria to reflect descope.
3. Create follow-up task immediately.
4. Document deferral in Actual Results.

---

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

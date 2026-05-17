# retire bootstraps missing CHANGELOG task entry - Design
**Task**: 147 (feature)

## Task Reference
- **Task ID**: internal-147
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/147-retire-bootstraps-missing-changelog-task-entry
- **Template Version**: 2.1

## Goal
Pin down how `cmd_retire` bootstraps a missing CHANGELOG entry: which new functions exist, where they live, what the stub looks like byte-for-byte, where it gets inserted, and how failure recovery works.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### D1: Two new public functions in `CWF::Backlog`, no new module; one private scan helper to consolidate the local duplication
- **Decision**: Add `bootstrap_changelog_entry($tree, $task_num, $title)` and `resolve_task_title_from_dir($task_num)` to `.cwf/lib/CWF/Backlog.pm`. Export both via `@EXPORT_OK`. Internally, factor the directory scan into a private `_scan_task_dirs($task_num)` returning the full list of matches; `resolve_task_title_from_dir` enforces the "exactly one" contract on top.
- **Rationale**: `Backlog.pm` already owns the parsed-tree mutators (`append_retired_block_tree`, `_ensure_retired_subsection`, `delete_entry`); bootstrap is the same family. The title resolver is too small to justify a new `CWF::TaskDir` module (one caller).
- **Duplication acknowledgement**: `CWF::TaskContextInference` already contains two scans of `implementation-guide/N-*-*` (`_get_task_slug` at `:491-509`, `_get_task_dir` at `:560-578`). The new helper makes that count three across two modules. Unifying all three would mean refactoring `TaskContextInference` — scope creep for this task. Decision: factor only *within* `Backlog.pm` (so the new module ships one scan, not two), and add a BACKLOG item proposing a `CWF::TaskDir` consolidation across both modules. The remaining duplication (one local scan in `Backlog.pm`, two in `TaskContextInference.pm`) is the smallest stable state achievable without scope creep.
- **Trade-offs**: One backlog item carried forward. Contract differences between `_get_task_dir` (best-effort, first-match) and `resolve_task_title_from_dir` (unique-or-die) are real; a shared utility would still need both contracts as wrappers.

### D2: Title derivation = strip `<type>` prefix (anchored against known types), replace hyphens with spaces, validate unconditionally
- **Decision**: From directory `implementation-guide/N-<type>-<slug>/`, extract `<slug>` using a regex that anchors `<type>` against the supported set from `implementation-guide/cwf-project.json:supported-task-types` (`feature|bugfix|hotfix|chore|discovery`), with both start (`\A`) and end (`\z`) anchors, and `\Q$task_num\E` quoted: `qr/\A\Q$task_num\E-(?:feature|bugfix|hotfix|chore|discovery)-(.+)\z/`. Replace `-` with ` ` in the captured slug. Example: `147-feature-retire-bootstraps-missing-changelog-task-entry/` → `retire bootstraps missing changelog task entry`.
- **Type-set source**: At module load, read the set from `implementation-guide/cwf-project.json` and cache in a package variable. Falls back to the hard-coded five-element list if the JSON is unreadable (defensive — the project config already lists exactly these five; drift is a separate problem with its own visibility). Type set lives in one place: the project JSON. The CWF backlog should track unifying type-list consumption everywhere (`task-workflow`, `task-type-inference.md`, this new code) but that's out of scope here.
- **Rationale**: Deterministic, lossy-but-readable, retrospective overwrites. Anchored-against-known-types regex closes Robustness F1 (future hyphenated type tokens) and Security F1 (`1470-…` matching `^147-`). `\Q…\E` quoting on `$task_num` closes Security F2 (regex-metachar injection in the helper's contract, even when CLI guards remain in place).
- **Validation (unconditional, post-transform)**:
  - Result MUST be non-empty.
  - Result MUST NOT contain `:` (would break the `^## Task[ \t]+(\d+):` parser regex at `Backlog.pm:223`).
  - Result MUST NOT contain `\n` or any control character `[\x00-\x08\x0a-\x1f]` (matches `_check_heading_control` at `Backlog.pm:204-213`).
  - Result MUST be valid UTF-8 (Perl decode is implicit via the `:encoding(UTF-8)` discipline used elsewhere; explicit `utf8::valid` check before return).
  - Any violation → `die_user` with `[CWF] ERROR: backlog-manager: derived title '<offender>' violates CHANGELOG heading constraints`.
- **Why unconditional**: Slug-creation invariant from `task-workflow create` cannot be assumed at runtime — directories may be hand-created (legacy task 1's three variants exist that way) or restored from backup. FR4 / NFR4 require slug-as-data treatment regardless of source. Defensive validation costs ~6 lines, eliminates the Security F3 carve-out.

### D3: Placeholder metadata values
- **Decision**: `### Status: In Progress` and `### Impact: Task in progress.`
- **Rationale**: Satisfies CHANGELOG-002 (required keys) at `Backlog.pm:441-447`. "In Progress" matches the wf-step `**Status**: In Progress` convention already used in workflow files (`TaskContextInference.pm:530`). "Task in progress." is short, factual, and overwriteable by retrospective without ambiguity. No date stamp in Status (the corpus uses `Complete (YYYY-MM-DD)`); leaving the date out signals incompleteness clearly.
- **Trade-offs**: Could leave a HTML-comment marker (e.g. `<!-- bootstrapped-stub -->`) so retrospective can detect-and-overwrite. Rejected: BACKLOG-004 forbids HTML comments outside CHANGELOG, and adding any marker invites tooling to depend on it; the placeholder strings are themselves the signal.

### D4: Insertion position = always index 0
- **Decision**: `bootstrap_changelog_entry` splices the new entry at `$tree->{entries}` index 0 — top of file, immediately under the `# Changelog` intro.
- **Rationale**: The bootstrap path is reached only when `find_changelog_entry_by_task_num` found no entry for `N`. That state arises in practice during a mid-task retire, and the mid-task task always has the highest task number (older tasks already have entries written by retrospective, since they've completed at least a-h workflow). So `N` is, by structural assumption, the highest task number → top-of-file placement is the descending-order-correct answer in the only scenario that actually fires. The pathological case (bootstrap for an older `N` while a newer `N` has an entry) requires an older task to have skipped retrospective entirely — a workflow defect with its own visibility path, not a case the helper should silently paper over with sort logic.
- **Trade-offs**: A bootstrap against a genuinely-older `N` would land at the top, producing an out-of-order CHANGELOG. This is acceptable: it's loud (the file diff shows the wrong position), it's recoverable (re-order manually or via a one-shot edit), and it surfaces the underlying workflow gap rather than hiding it. The cost of the simpler implementation is paid in the cost of the workflow gap, not in the cost of the wrong insertion.
- **Resolves**: Robustness F4 (no insertion algorithm to specify tie-breaks for) and Misalignment F4 (no helper to extract).

### D5: Single CHANGELOG write (in-memory mutation only)
- **Decision**: Bootstrap runs entirely against the parsed `$cl_tree` in memory. The existing `write_tree($cl_path, $cl_tree)` call at `backlog-manager:481` is the only write — no new I/O.
- **Rationale**: Preserves NFR1 (CHANGELOG written exactly once per `retire`). The existing crash-recovery comment at `backlog-manager:467-469` continues to hold without modification: a crash before `write_tree(cl)` leaves CHANGELOG unchanged; a crash between the two writes leaves CHANGELOG with `{bootstrapped entry + block}`, BACKLOG unchanged → re-run finds the entry, dedups the block, writes BACKLOG.

### D6: New error-path layout in `cmd_retire`
- **Decision**: Replace the single `die_user` at `backlog-manager:464-465` with:
  ```
  my ($cl_entry, $cl_idx) = find_changelog_entry_by_task_num($cl_tree, $task);
  unless (defined $cl_entry) {
      my $title = resolve_task_title_from_dir($task);  # dies on 0 or >1 matches
      $cl_entry = bootstrap_changelog_entry($cl_tree, $task, $title);
  }
  ```
  Subsequent code (`block_exists_in_retired_tree`, `append_retired_block_tree`, dedup) is unchanged.
- **Rationale**: Minimal diff to `cmd_retire`; one branch, two function calls. All complexity sits behind named helpers that are independently testable.

### D7: Error messages
- **Decision** (directory names single-quoted to bound the token for downstream LLM-side parsers — Security F4):
  - Zero matches: `[CWF] ERROR: backlog-manager: cannot bootstrap CHANGELOG entry for Task N: no directory matching 'implementation-guide/N-*/' found`
  - Multiple matches: `[CWF] ERROR: backlog-manager: cannot bootstrap CHANGELOG entry for Task N: multiple directories match ('<dir1>', '<dir2>', ...); manually create '## Task N: <title>' in CHANGELOG.md first, then retry`
  - Unreadable `implementation-guide/`: `[CWF] ERROR: backlog-manager: cannot read implementation-guide/: <errno-text>` (no silent fall-through; Robustness F7)
  - Title-validation failure: `[CWF] ERROR: backlog-manager: derived title '<offender>' violates CHANGELOG heading constraints` (D2 validation)
- **Rationale**: Multi-match path names the workaround (status quo: hand-create). Unreadable-base dies loudly rather than degrading to "no matches". All messages preserve `die_user`'s `[CWF] ERROR: backlog-manager:` prefix for log-grep consistency. Single-quoting directory names prevents accidental injection into LLM context interpreting the error.

## System Design

### Component Overview
- **`CWF::Backlog::_scan_task_dirs($task_num)` (private)**: Single source of `opendir('implementation-guide')` + anchored regex scan within `Backlog.pm`. `die`s on `opendir` failure (Robustness F7). Returns the unsorted list of matching directory names (just the basename, no path). Internally `\Q$task_num\E`-quotes and anchors against the supported-type set (D2). Called by `resolve_task_title_from_dir`.
- **`CWF::Backlog::resolve_task_title_from_dir($task_num)`**: Strict resolver layered over `_scan_task_dirs`. Validates `$task_num =~ /^\d+$/` (defensive — caller already guards but contract must stand alone, per Security F2). Calls `_scan_task_dirs`; on 0 → die with zero-match message (D7); on >1 → die with multi-match message (D7); on 1 → applies D2 transform, runs unconditional title validation, returns the title string. No `$base` parameter — tests use `chdir` to a tmpdir, matching the pattern at `TaskContextInference.pm:495`.
- **`CWF::Backlog::bootstrap_changelog_entry($tree, $task_num, $title)`**: Tree mutator. Implementation calls `parse_changelog_tree` on the 7-line stub string (see "Stub serialisation" below) and plucks `entries[0]` — single source of truth for the entry-node shape, automatically tracks parser changes (Improvements F4, resolves Robustness F5). Splices the returned entry at `$tree->{entries}[0]` (D4). Returns the live entry reference for the caller to pass to `append_retired_block_tree`.
- **Empty-subsections invariant** (Robustness F3): The stub's `subsections` array contains exactly one entry (`Retired Backlog Items`, from the parsed stub). Because the stub is parsed via the canonical parser, the entry shape and subsection ordering are guaranteed by parser invariants, not by hand-construction. Subsequent `append_retired_block_tree → _ensure_retired_subsection` calls find the existing subsection by name and append blocks to it — no `splice` needed, no positional dependency.
- **`backlog-manager::cmd_retire` (modified)**: Single new branch at the `find_changelog_entry_by_task_num` call (D6). No other lines change.

### Data Flow (bootstrap path)
1. User runs `retire --id=<slug> --task=N`.
2. `cmd_retire` validates `--task` (existing integer guard).
3. `cmd_retire` rejects symlinks on `BACKLOG.md` / `CHANGELOG.md` (existing guard).
4. `cmd_retire` parses both files into trees (existing).
5. `cmd_retire` resolves the BACKLOG entry by `--id`/`--exact-title` (existing).
6. `cmd_retire` calls `find_changelog_entry_by_task_num` (existing) → no hit.
7. **NEW**: `cmd_retire` calls `resolve_task_title_from_dir($task)`. On 0 or >1 dir matches → `die_user` (writes nothing).
8. **NEW**: `cmd_retire` calls `bootstrap_changelog_entry($cl_tree, $task, $title)`. Returns `$cl_entry` reference into `$cl_tree`.
9. `cmd_retire` calls `append_retired_block_tree($cl_entry, ...)` (existing).
10. `cmd_retire` calls `delete_entry($bl_tree, $idx)` (existing).
11. `cmd_retire` writes CHANGELOG, then BACKLOG (existing, single write each).

### Interface Design

```
# CWF::Backlog

sub resolve_task_title_from_dir {
    my ($task_num) = @_;
    # $task_num: integer >= 1 (internally validated; defensive on contract)
    # Returns: derived title string (non-empty, no ':', no newlines, valid UTF-8)
    # Dies (die_user-style) on: invalid $task_num, unreadable
    #   implementation-guide/, 0 matches, >1 matches, derived title violating
    #   FR4 constraints.
    # Tests use chdir-to-tmpdir; no $base parameter.
}

sub bootstrap_changelog_entry {
    my ($tree, $task_num, $title) = @_;
    # $tree: parsed CHANGELOG tree (from parse_changelog_tree)
    # $task_num: integer >= 1
    # $title: validated title from resolve_task_title_from_dir
    # Returns: hashref of the newly-inserted entry node (live reference into $tree)
    # Mutates: $tree->{entries} (splice at index 0)
    # Implementation: parse_changelog_tree on the 7-line stub string + splice.
    # No I/O. No re-validation of $title (caller's responsibility — but tests
    # exercise the resolver→bootstrap chain end-to-end).
}
```

### Stub serialisation (byte-for-byte)
For task 147 (this task) the bootstrapped entry serialises to:
```
## Task 147: retire bootstraps missing changelog task entry

### Status: In Progress
### Impact: Task in progress.

### Retired Backlog Items
```
- 7 lines total before any block is appended.
- Heading line matches the parser regex `qr/^## Task[ \t]+(\d+):[ \t]*(.+?)[ \t]*\n?\z/` (`Backlog.pm:223`).
- Metadata lines match `qr/^([A-Z][\w\- ]*):[ \t]*(.*?)\s*\z/`.
- Subsection ordering with only `Retired Backlog Items` present passes `_check_subsection_order` (CHANGELOG-003) trivially — single subsection, no order violation possible.

## Constraints
- All FR/NFR from b-requirements-plan.md apply.
- Helpers MUST be exportable from `CWF::Backlog` (added to `@EXPORT_OK` list at `Backlog.pm:34-45`).
- Helpers MUST be callable without requiring a real file system in tests (`$base` parameter on the resolver; pure tree-mutation on the bootstrapper).

## Alternatives Considered (and rejected)

- **Promote scan to a `CWF::TaskDir` module spanning both `Backlog.pm` and `TaskContextInference.pm`**: Misalignment reviewer's suggestion. Rejected as scope creep; instead consolidated locally (D1) and recorded as a BACKLOG item.
- **Add `--title` flag for the multi-match case**: Rejected per b-requirements FR8 (no new flags). Multi-match is a one-occurrence corpus condition (task 1); preserving the no-new-flag invariant is worth the cost of a clear error message that names the manual workaround.
- **Sort-insert at descending-task-num position**: Original D4 proposal; replaced with "always index 0". The only state in which the bootstrap fires is "task N has no CHANGELOG entry", and that state in normal workflow implies N is the current (highest) task. Index 0 is the descending-order-correct position for the only scenario that fires; the simpler implementation is the correct one.
- **Use `<!-- bootstrapped -->` HTML-comment marker for retrospective detection**: Rejected per D3 — BACKLOG-004 forbids HTML comments in BACKLOG; CHANGELOG permits them, but adding any marker invites tooling dependency. Placeholder Status/Impact values are the signal.
- **Hand-construct the entry hashref in `bootstrap_changelog_entry`**: Original D5 proposal; replaced with "parse the 7-line stub string via existing parser". Single source of truth for entry shape, automatically propagates parser changes.

## Out of Scope / Backlog
- **Unify `implementation-guide/` directory-scan logic across `Backlog.pm` (1 new), `TaskContextInference.pm` (2 existing)**. Three slightly different contracts (strict, best-effort-first-match, best-effort-extract-slug). Worth a future BACKLOG item proposing a small `CWF::TaskDir` module; not in scope for this task.
- **Audit other helpers for the same FR4(e) carve-out pattern** (functions that consume `$task_num` without internal validation, relying on CLI guards). Not in scope; track as a defensive-hardening sweep if FR4(e) review prioritises it.
- **FR4(d) — env vars**: This change reads no new env vars. Out of scope, recorded for the audit trail.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ concerns? No — two helpers, one call site, one stub shape.
- [ ] **Risk**: High-risk? No.
- [ ] **Independence**: Separable? No.

## Validation
- [ ] Design exports both new helpers from `CWF::Backlog`.
- [ ] Stub serialisation passes `validate_changelog_tree` (CHANGELOG-002 + CHANGELOG-003).
- [ ] `cmd_retire` diff is bounded to one branch around line 464-465.
- [ ] Recovery story (D5) preserved without modification to comment at `backlog-manager:467-469`.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 147
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

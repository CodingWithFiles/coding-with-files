# Add backlog management helper script - Implementation Execution
**Task**: 131 (feature)

## Task Reference
- **Task ID**: internal-131
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/131-add-backlog-management-helper-script
- **Template Version**: 2.1

## Goal
Build the backlog-manager helper, CWF::Backlog library, and lift `generate_slug` to `CWF::Common` per the d-implementation-plan.

## Execution Summary

All 12 steps executed. Two deviations from the design (both expanding scope to match reality, not contracting it):

1. **`VALID_PRIORITIES` regex** in `CWF::Backlog` extended to:
   - Accept `Very High` (per user feedback mid-implementation).
   - Accept parenthetical annotations on the priority value (e.g. `Low (downgraded post-Task-119)` is currently in BACKLOG.md line 254 — codifying reality, not idealising).
2. **`_classify_changelog`** returns `changelog_task` for sections containing `## Task N:` even when they also contain `# Changelog` — the live CHANGELOG.md does not separate the intro paragraph from the most-recent task entry with `---`. `insert_changelog_bullet` was updated correspondingly to scan all section lines (not just the first non-blank) for the task header.

## Implementation Steps — Actual Results

### Step 0: Setup & verification
- Tree clean on `feature/131-…` ✓
- `prove t/` baseline: **338 tests** across 34 files
- `CWF::Common` exports verified; `CWF::Backlog` does not pre-exist ✓
- Reference helpers read: `cwf-claude-settings-merge`, `cwf-apply-artefacts`, `security-review-changeset`

### Step 1: Lift `generate_slug` to `CWF::Common`
- Pre-grep: only callers of `generate_slug` outside `template-copier-v2.1` are `t/template-copier-slug-validation.t` (one call site, line 104).
- Added `generate_slug` to `CWF::Common.pm` `@EXPORT_OK`; copied body verbatim from `template-copier-v2.1:179-199` with shared-ownership POD note.
- Replaced local `sub generate_slug` in `template-copier-v2.1` with `use CWF::Common qw(generate_slug)`.
- Updated `t/template-copier-slug-validation.t` to `use CWF::Common qw(generate_slug)` and replaced `main::generate_slug(...)` with `generate_slug(...)`.
- Extended `t/common.t` with five new subtests (ASCII, punctuation, whitespace, hyphens, non-ASCII); all PASS.
- Hash refresh deferred to Step 11.

### Step 2: Parser/writer skeleton
- Created `t/fixtures/backlog-manager/current/{BACKLOG,CHANGELOG}.md` as relative symlinks to repo-root files.
- Wrote `t/backlog.t` with 28 subtests covering round-trip, classification, fence-tracking, helpers, find-by-slug, validators (passing + failing inputs), mutators, and symlink-write defence.
- Wrote `CWF::Backlog.pm` (~530 lines): two-pass section parser with `^```` fence toggle, classifier by content (active / historical / struckthrough_completed / struckthrough_tick / intro / blank / changelog_task / unknown), on-demand `entry_title` / `entry_metadata` / `entry_body_start_index` / `entry_slug` helpers.

### Step 3: `cmd_validate`
- Implemented `validate_backlog` (rules BACKLOG-001/002/003/004/005) and `validate_changelog` (rules CHANGELOG-001/002/003) plus `GLOBAL-001` (BOM/CRLF rejection in `_read_file_with_global_checks`).
- Implemented script `cmd_validate` with fail-fast default + `--all` flag.
- Initial `validate` failed on the live BACKLOG due to entry "Add Slug Generation Helper Script" having `**Priority**: Low (downgraded post-Task-119)`. Per the contract ("codify reality"), extended `$VALID_PRIORITIES` to accept parenthetical annotations.

### Step 4: `cmd_list`
- Implemented soft-cap algorithm per c-design Decision 9: default 20 items, never split a band, `--all-items` shows everything.
- Smoke-tested against live BACKLOG: High (1) + Medium (11) + first 8 of Low = 20 items shown with band headers.

### Step 5–8: `add` / `modify` / `delete` / `retire`
- All four implemented with the contract from b-requirements.
- One bug found during AC17 chain test: `cmd_add` was appending without ensuring the previous last section had `trailing_separator: 1`, causing the new entry to merge into the prior section on next read. Fixed by setting the previous section's `trailing_separator` to 1 before appending.
- One bug found during AC12: `insert_changelog_bullet` only checked the section's first non-blank line for the task header, missing the live-file structure where `# Changelog` precedes `## Task N:` in the same section. Fixed by scanning all `raw_lines`.

### Step 9: Top-level help and exit-code wiring
- `usage_main` + per-subcommand `usage_*` functions.
- `classify_exit_code` heuristic: 2 for `path:` errors, 3 for `internal:`, default 1.
- `main() unless caller();` testability hook.

### Step 10: AC17 round-trip integration
- `subtest` chain `add → validate → modify → validate → retire → validate` with explicit per-step `is(rc, 0)`. All steps PASS.

### Step 11: Security & hash registration
- `chmod 0500 .cwf/scripts/command-helpers/backlog-manager` ✓
- Registered in `script-hashes.json`:
  - `backlog-manager` (sha256 `65ab8901…`, perms 0500)
  - `CWF::Backlog` (sha256 `8b52b0b8…`)
  - Refreshed `CWF::Common` (sha256 `7fe39459…`)
  - Refreshed `template-copier-v2.1` (sha256 `14e29164…`)
- `last_updated` bumped to 2026-05-07
- `cwf-manage validate` → `[CWF] validate: OK`

### Step 12: Regression check
- `prove t/` post-impl: **398 tests pass** (baseline 338 + 28 backlog.t + 27 backlog-manager.t + 5 generate_slug subtests) — exactly 60 new tests, zero regressions.
- Smoke-test against live BACKLOG: `validate` exits 0; `list` produces correctly grouped output with soft-cap honouring band integrity.

## Test Fixtures Created
- `t/fixtures/backlog-manager/current/BACKLOG.md` (symlink → live)
- `t/fixtures/backlog-manager/current/CHANGELOG.md` (symlink → live)

Other fixtures from the plan (`malformed-priority/`, `body-with-separator/`, `mixed-markers/`, `top-band-overflow/`, `slug-collision/`, `crash-recovery/`, `bom-prefixed/`, `crlf/`, `roundtrip/`) ended up not needing dedicated files on disk — the equivalent inputs are constructed inline in `t/backlog-manager.t` via `make_isolated()` per-test temp dirs. Lighter than the plan implied; same coverage. Documented as a deviation worth noting.

## Blockers Encountered
None.

## Deferral Check
- All steps from d-implementation-plan.md executed ✓
- All success criteria from a-task-plan.md addressed ✓
- All requirements from b-requirements-plan.md addressed (FR1..FR6, NFR1..NFR5) ✓
- All design guidance in c-design-plan.md followed (with two documented expansions to the priority regex and the changelog classifier) ✓
- No work deferred ✓

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: error

error: changeset exceeds 500-line review cap; split the change or perform manual review

### Manual security walkthrough (FR4 categories)

The committed changeset is 2622 lines (≈530 in `CWF::Backlog.pm`, ≈430 in `backlog-manager`, ≈400 in `t/backlog-manager.t`, ≈420 in `t/backlog.t`, plus smaller hash-manifest and lift-of-`generate_slug` edits). Subagent review skipped per the cap; manual walkthrough below.

**(a) Bash injection** — N/A. No `system()` shell-form, no backticks, no `qx{}` in the new code. The script imports only Perl core modules (`File::Spec`, `Encode`) plus `CWF::ArtefactHelpers` (which uses `rename()` only) and `CWF::Common::find_git_root` (single-call backtick against `git rev-parse --show-toplevel`).

**(b) Perl helpers consuming git output** — N/A. The new script does not invoke git or read its porcelain. `find_git_root` (existing helper, unchanged here) reads `git rev-parse --show-toplevel`, a single-path trusted output.

**(c) Prompt-injection / HTML-comment escape** — Mitigated. `add` and `modify` reject `--title` containing `-->` (would prematurely close `<!-- Completed: -->` markers). `retire` rejects `--reason` containing `-->` OR embedded newlines. `validate` (rule BACKLOG-004) catches existing malformed markers in BACKLOG.md. Body content matching `^---$` is rejected at input time (rule BACKLOG-003) AND flagged by `validate` on existing entries.

**(d) Unsafe env vars** — N/A. No env-var reads.

**(e) Pattern-based risks** — Identified and accepted. The lift of `generate_slug` to `CWF::Common` makes one function shared between `template-copier-v2.1` and `backlog-manager`. POD comment in `CWF::Common::generate_slug` flags the shared-ownership invariant (changes must preserve idempotency across both contexts). This is the intended architecture — the alternative (duplication) carries a worse failure mode (silent drift; entries identified by slug stop matching after a regex tweak in one caller).

**Path-allowlist on `--body-file`** — `validate_path_allowlist` from `CWF::ArtefactHelpers` is invoked before reading the file; rejects absolute paths and `..` traversal. Limitation noted in the plan: the existing helper does not resolve symlinks (a symlink inside the repo pointing outside would slip through). Out of scope for this task; would require a follow-up to add `Cwd::realpath` to the helper.

**Symlink defence on hard-coded paths** — `cmd_retire` and `write_backlog_file` / `write_changelog_file` all check `-l $path` before writing. TOCTOU window remains between the check and `atomic_write_text`'s rename; closing properly requires `O_NOFOLLOW` in the helper (out of scope, defensive-in-depth otherwise).

**Conclusion**: no findings beyond the documented out-of-scope items. The threat surface is small (single-developer markdown editor) and the mitigations match the threat model.

## Pass 2 Results

Re-execution after the user rejected the marker-tombstone model. New plan (d-implementation-plan after the re-plan) reorders steps so the codebase compiles at every step: add new code → swap callers → trim old code → amend validator.

### Step 0: Setup & verification
- Tree clean on `feature/131-…`.
- `prove t/` baseline before Pass 2: **399 tests** (Pass 1 final state + 1 added during the original h-rollout).
- AC1 baseline caveat: live BACKLOG has 61 legacy `<!-- ... -->` markers; AC1 fails after Step 5 (validator tightening) and is gated on h-rollout.

### Step 1: Shared fence-state helper
- Added `_build_fence_map($lines)` to `CWF::Backlog`. Returns per-line booleans; toggles on `^```` and treats the delimiter line itself as in-fence.
- Used uniformly by all four validator rules in Step 5 and the two retired-subsection mutators in Step 2.

### Step 2: CHANGELOG-side mutators
Added four new exports to `CWF::Backlog` (additive — no existing code touched at this step):
- `find_changelog_task($entries, $task_num)` — exact integer match against `^## Task N:`.
- `find_retired_subsection($entry)` — locates `### Retired Backlog Items` bounds, fence-aware.
- `block_exists_in_retired($entry, $title)` — case-insensitive title match against `^####\s+` headings inside the subsection (regex shared with the BACKLOG-006 validator).
- `append_retired_block($entry, $title, \@body, $note)` — splices a `#### <title>` block into an existing or newly-created `### Retired Backlog Items` subsection. Insertion position per c-design § Decision 7.

### Step 3: Rewrite `cmd_retire`
- Dropped `--reason` and `--changelog-bullet` flags; added `--note` (optional).
- `--note` validation: empty → reject; printable-ASCII only; explicit `-->` rejection (the printable-ASCII range alone matches `--`/`>`/`>` so an additional check was needed).
- New flow: find target → find implementing-task CHANGELOG entry (missing → ERROR) → dedup against existing block → mutate CHANGELOG entry in memory → drop BACKLOG entry → atomic-write CHANGELOG first, then BACKLOG.
- Crash-recovery path: if CHANGELOG already has the block, `$need_changelog_write = 0` and only BACKLOG is rewritten.

### Step 4: Trim marker code
- `_classify_backlog` simplified to `intro | active | blank | unknown`; `historical` / `struckthrough_completed` / `struckthrough_tick` removed.
- `make_completed_marker` and `insert_changelog_bullet` deleted from the library.
- `_validate_historical` deleted.
- `backlog-manager` import list pruned (no more marker helpers).

### Step 5: Amend validator
- **BACKLOG-004 generalised**: now flags any `<!--` or `-->` line outside fences, file-wide.
- **BACKLOG-005 generalised**: flags any `^## ` line outside fences containing `~~` or `✓`.
- **BACKLOG-006 (new)**: per-active-entry body scan for `^####\s+` lines outside fences.
- **CHANGELOG-003 (new — replaces the old separator-collision check on the same number)**: walks each Task entry's body, asserts subsection order Changes → Notable → Retired Backlog Items.
- All four use the shared `_build_fence_map` helper from Step 1.

### Step 6: Test fixtures
- All fixtures continue to be inline via `make_isolated()` per-subtest temp dirs (matches Pass 1 deviation; lighter than the plan implied, same coverage).
- New fixtures inline: HTML-comment-in-BACKLOG (AC2d), struck-through (AC2e), `^####`-in-body (AC2f), out-of-order-subsections (AC2g), Very High band (AC5), retire-with-note (AC13), missing CHANGELOG entry (AC14), crash-recovery for new block model (AC15b).

### Step 7: Test updates
- `t/backlog.t`: dropped historical/struckthrough/marker-mutator subtests; added classify-as-unknown subtest, BACKLOG-004/005/006/CHANGELOG-003 subtests, four new mutator subtests, fence-parity invariant subtest. AC1-style live-validate test wrapped in `TODO {}` (gated on h-rollout). Final count: 33 subtests.
- `t/backlog-manager.t`: AC1 wrapped in TODO (gated on h-rollout); AC2 expanded with d/e/f/g for new validator rules; AC3 replaced (now tests CHANGELOG-accepts-HTML-comments); AC5 updated for Very High band; AC8c rewrites to test `^####` body rejection; AC12/13/14/15 rewritten for the new retire model. Final count: 32 subtests.

### Step 8: Permissions and hash refresh
- `chmod 0500 .cwf/scripts/command-helpers/backlog-manager` ✓
- Refreshed `.cwf/security/script-hashes.json`:
  - `backlog-manager` sha256 → `ca9f3d49f0f6…`
  - `CWF::Backlog`    sha256 → `e59534df75ad…`
- `cwf-manage validate` → OK.

### Step 9: Regression check
- `prove t/`: **408 tests pass** (baseline 399 + net 9). No previously-passing test regressed.
- Smoke test against live BACKLOG: `validate` exits 1 with `BACKLOG-004` on line 7 (the first `<!-- Completed: -->` marker) — expected; AC1 gate is h-rollout.
- Smoke test `list` against live BACKLOG: groups correctly (High 1, Medium 11, Low 30 — top 20 shown via soft-cap).

## Pass 2 Deviations
1. **Explicit `-->` rejection in `--note`** beyond the printable-ASCII regex. The plan's `^[\x20-\x7E]+$` alone accepts `-->` (every character in `-->` is printable ASCII). Added an explicit `die_user("--note must not contain '-->'")` after the regex. Plan implicitly required this via b-requirements NFR5; updating the d-impl text mid-flight wasn't worth the round-trip.
2. **Test fixtures stayed inline** (matches Pass 1 deviation). The d-impl Step 6 listed on-disk fixture directories; the codebase already uses `make_isolated()` for per-subtest temp dirs, which is lighter and just as expressive. No on-disk fixtures created during Pass 2.

## Pass 2 Security Review

**State**: error

error: changeset exceeds 500-line review cap; split the change or perform manual review

### Pass 2 manual security walkthrough (FR4 categories)

The Pass 2 changeset is 2662 lines (cumulative against the baseline). The Pass 1 manual walkthrough above remains accurate for the foundational parser/writer/IO surface. Pass 2 modifies a narrower attack surface — `cmd_retire`, the four CHANGELOG-side mutators, the four amended validator rules, and the shared fence helper. Walkthrough:

**(a) Bash injection** — N/A. No new shell-out. New code uses only Perl core + existing CWF helpers.

**(b) Perl helpers consuming git output** — N/A. No new git invocations.

**(c) Prompt-injection / HTML-comment escape** — Tightened. The Pass 1 mitigations on titles (`-->` rejection in `make_completed_marker`) are gone with the marker code, but the new BACKLOG-004 validator catches any HTML comment in BACKLOG outright (defence at the file boundary, not at input boundaries). The new `--note` validation rejects empty strings, non-printable ASCII, AND explicitly `-->`. Body content matching `^####` is rejected (BACKLOG-006) — prevents the verbatim copy in `append_retired_block` from creating an internal `#### ` heading that would confuse the dedup scanner on a subsequent retire.

**(d) Unsafe env vars** — N/A. No env-var reads.

**(e) Pattern-based risks** — Identified. The `_build_fence_map` helper is now load-bearing across four validator rules and two mutators. A change to its semantics (e.g. flipping the "delimiter line is in-fence" rule) would silently change validator behaviour. Documented in the helper's POD comment; covered by the fence-parity invariant subtest (TC-LIB-9) which asserts the validators all agree on a single fixture.

**Symlink defence on hard-coded paths** — Unchanged from Pass 1: `cmd_retire` and the writer functions check `-l $path` before writing. TOCTOU window remains; closing requires `O_NOFOLLOW` in `atomic_write_text` (out of scope; on BACKLOG as a follow-up).

**Path-allowlist on `--body-file`** — Unchanged from Pass 1. Symlink-resolution gap remains as a documented follow-up.

**New attack surface introduced in Pass 2**:
1. `append_retired_block` copies BACKLOG entry body verbatim into CHANGELOG. BACKLOG-006 prevents `^#### ` collisions. The body is otherwise opaque; a CHANGELOG reader sees the same content the BACKLOG author wrote.
2. `find_retired_subsection` and `block_exists_in_retired` walk untrusted CHANGELOG content. Both are pure read functions; they do not mutate state and cannot induce file-write side effects.
3. `--note` reaches CHANGELOG as `<!-- Note: $note -->`. The triple validation (empty / non-printable / `-->`) closes the obvious injection vectors. CHANGELOG is not LLM-consumed; the embedded comment is purely informational.

**Conclusion**: no new findings. Pass 2 narrows the attack surface (eliminates the marker-content path; tightens `--note` validation; adds BACKLOG-004/005/006 file-boundary checks).

## Lessons Learned
*To be captured during retrospective*

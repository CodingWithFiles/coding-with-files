# Add backlog management helper script - Requirements
**Task**: 131 (feature)

## Task Reference
- **Task ID**: internal-131
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/131-add-backlog-management-helper-script
- **Template Version**: 2.1

## Goal
Specify what `backlog-manager` must do (subcommand contracts) and the format contract it enforces against BACKLOG.md and CHANGELOG.md. **BACKLOG = active items only; CHANGELOG = history.** No marker tombstones, no struck-through entries — the helper produces and validates a clean, two-file model.

---

## Format Contract — BACKLOG.md

The current BACKLOG.md contains 61 legacy HTML-comment lines (37 `<!-- Completed: -->`, 12 `<!-- Removed: -->`, 10 `<!-- Reason: -->`); the prior `### Retired Backlog Items` rollout already migrated the two struck-through entries out. The validator MUST flag all HTML comments and any struck-through heading as errors; the helper MUST produce only the active-entry form. Rollout (h-rollout) bulk-removes the legacy artefacts before the validator goes live.

### Active Entry — canonical form

```
## Task: <title>           (or `## Bug: <title>` for bug entries)

**Task-Type**: feature|bugfix|hotfix|chore|discovery
**Priority**: Very High|High|Medium|Low|Very Low
**Status**: <free-text, optional>      ← e.g. "Follow-up from Task 119", "Backlog"

<body — free-form prose, may contain markdown subsections, code fences, etc.>

**Identified in**: <free-text, optional>   ← e.g. "Task 113 j-retrospective"
```

- Header MUST start with `^## Task:` or `^## Bug:` followed by the title.
- **Metadata block** = the contiguous run of `**Field-Name**: value` lines that immediately follows the entry header (separated from the header by a single blank line). The block ends at the first blank line. `**Task-Type**:` and `**Priority**:` MUST appear in the metadata block; `**Status**:` is optional.
- `**Priority**:` value MUST match `^(?:Very High|High|Medium|Low|Very Low)(?:\s*\(.*\))?$` — the parenthetical is permitted for downgrade annotations like `Low (downgraded post-Task-119)`.
- **Body content is freeform** and may contain `**Field-Name**: …` lines (these are body prose, not metadata — only metadata-block fields are treated as metadata). Body is preserved byte-for-byte on round-trip.
- **Body restriction**: body lines MUST NOT match `^---$` exactly (collides with the entry separator). `add` / `modify` reject; `validate` flags.
- `**Identified in**:` may appear anywhere in the body and is treated as body prose.
- Entries separated by lines containing exactly `---`.

### Banned content in BACKLOG

- **HTML comments** anywhere in the file. Specifically: `<!-- Completed: ... -->`, `<!-- Removed: ... -->`, `<!-- Coalesced: ... -->`, `<!-- Reason: ... -->`, and any other `<!--` / `-->` patterns. The whole class is rejected.
- **Struck-through headings**: `## ~~Task: <title>~~ ✓ COMPLETED`, `## ✓ Task: <title>`, and similar.
- **Banned priorities**: `Needs-Triage` (closed by Task 130).

All three categories produce `validate` errors. None can be produced by the helper. The 61 legacy HTML-comment lines are migrated out during rollout (h-rollout); thereafter `validate` over the live file passes.

---

## Format Contract — CHANGELOG.md

```
# Changelog

<intro paragraph>

## Task <N>: <Title>

**Status**: Complete (<YYYY-MM-DD>)
**Duration**: <free-text>          ← optional (some entries omit, e.g. Task 127)
**Impact**: <free-text>

### Changes
- <bullets>

### Notable
- <bullets>

### Retired Backlog Items   ← optional, populated by `retire`

#### <retired-entry-title>

<body, copied from the BACKLOG entry; freeform>

<!-- Note: <optional implementation-deviation commentary> -->

---

## Task <M>: <Title>
...
```

- Top header `^# Changelog` exactly once.
- Per-task entry: `^## Task <N>: <Title>`. `**Status**:` and `**Impact**:` MUST be present; `**Duration**:` is optional.
- `### Changes`, `### Notable`, and `### Retired Backlog Items` are each independently optional. When present, the order MUST be Changes → Notable → Retired. The Changes-then-Notable order is pre-existing convention (every CHANGELOG entry that has both today follows it); `### Retired Backlog Items` is a new subsection introduced by this task and goes last by definition.
- **HTML comments are permitted in CHANGELOG.** They are conventionally used to capture implementation-deviation notes (where the implementation diverged from the original BACKLOG description). The validator does not flag any HTML-comment pattern in CHANGELOG.
- Entries separated by `---`.
- Reverse chronological order (newest at top).

---

## Functional Requirements

### Core Subcommands

- **FR1: `validate`** — Read BACKLOG.md and CHANGELOG.md from the repo root; exit `0` if both pass, non-zero with a path-and-line-prefixed `[CWF] ERROR:` message on the first failure (or list all failures with `--all`). Reports MUST cite file, line, and rule. Validator rules:
  - **BACKLOG-001**: every active entry has `**Task-Type**:` and `**Priority**:` in the metadata block.
  - **BACKLOG-002**: `**Priority**:` matches the canonical regex.
  - **BACKLOG-003**: body contains no `^---$` line.
  - **BACKLOG-004**: file contains no HTML comments (`<!--` / `-->`).
  - **BACKLOG-005**: file contains no struck-through entry headings.
  - **BACKLOG-006**: active entry bodies contain no `^#### ` lines (reserved for retired-block headings in CHANGELOG; their presence in BACKLOG would survive verbatim copy via `retire` and confuse dedup).
  - **CHANGELOG-001**: top-level `# Changelog` header present exactly once.
  - **CHANGELOG-002**: every per-task entry has `**Status**:` and `**Impact**:`.
  - **CHANGELOG-003**: subsection order Changes → Notable → Retired (when present).
  - **GLOBAL-001**: no BOM, no CRLF endings, valid UTF-8.

- **FR2: `list`** — Render active BACKLOG entries grouped by priority (Very High → High → Medium → Low → Very Low). Default cap: 20 items. **Soft cap rule**: if the highest-populated band alone has >20 items, show the whole band rather than splitting. `--all-items` flag bypasses the cap. Output: priority band header, then bullet per entry with title and one-line summary (first non-blank body line, truncated to terminal width).

- **FR3: `add`** — Append a new active entry to BACKLOG.md. Required: `--title`, `--task-type`, `--priority`, `--body` (or `--body-file`). Optional: `--status`, `--identified-in`. Rejects entries that would fail `validate`. Default position: end of file; explicit position via `--before <slug>` or `--after <slug>`. `--body-file` paths validated against `validate_path_allowlist`.

- **FR4: `modify`** — Edit an existing entry's `--title`, `--priority`, `--task-type`, `--status`, `--identified-in`, or `--body` (or `--body-file`). Identified by `--id <slug>` or `--exact-title`. Refuses on ambiguous match. Preserves entry position and unspecified fields byte-for-byte.

- **FR5: `delete`** — Remove an entry outright from BACKLOG (no CHANGELOG impact). Same identification model as `modify`. Refuses without `--confirm` flag. Intended for typos / accidental dupes — `retire` is the normal path for completed items.

- **FR6: `retire`** — Transactional move BACKLOG → CHANGELOG. Required: `--id <slug>` (or `--exact-title`), `--task <N>` (the implementing task number). Optional: `--note <text>` (implementation-deviation commentary, embedded as an HTML comment in the CHANGELOG entry).

  **Effects**:
  1. The matching BACKLOG entry is **deleted** (not replaced with a marker).
  2. Under the implementing task's CHANGELOG entry, an `### Retired Backlog Items` subsection is created (if missing) and an `#### <title>` block is appended containing:
     - the original entry's body (freeform prose, copied verbatim),
     - if `--note` was given: an `<!-- Note: <text> -->` HTML comment immediately after the body.
  3. **Insertion position** of the new `### Retired Backlog Items` subsection (when created): immediately after `### Notable` if present, else immediately after `### Changes` if present, else immediately after the metadata block. This guarantees the Changes → Notable → Retired order required by CHANGELOG-003.
  4. If the implementing task has no CHANGELOG entry yet (e.g. retrospective hasn't run), `retire` exits 1 with `[CWF] ERROR: backlog-manager retire: Task <N> has no CHANGELOG entry; create the entry first or pick a different --task`.
  5. Both file writes succeed atomically (see NFR4).

  **Field mapping** (BACKLOG entry → CHANGELOG entry block):
  - **Title** → `#### <title>` heading (h4 inside the implementing task's h2 section).
  - **Body** → block content, copied verbatim including any embedded `**Identified in**:` line.
  - **Priority** → DROPPED (irrelevant once retired).
  - **Task-Type** → DROPPED (the implementing task already has a type).
  - **Status** → DROPPED (was always free-text status of the BACKLOG entry pre-completion; not meaningful post-completion).
  - **`--note <text>`** → appended as `<!-- Note: <text> -->` after the body.

  **Idempotency / crash recovery**: see NFR4.

### Identification model

- Primary identifier: **slug** derived from title using the existing `generate_slug` algorithm (lowercased, spaces → hyphens, non-alphanumerics dropped). Lifted to `CWF::Common` and shared between `template-copier-v2.1` and `backlog-manager`.
- Collision: ambiguous slug → exit 1 with `--exact-title` hint.
- Title-only fallback: `--exact-title <full-title>` always works.

### User stories

- **As the maintainer** I want `backlog-manager validate` to run as part of `cwf-manage validate` so format drift is caught at every CWF security check.
- **As the maintainer** I want `backlog-manager list` to be the at-a-glance "what should I do next" view, defaulting to the top 20 items but never cutting a priority band in half.
- **As an LLM agent** I want `backlog-manager retire --task=N` to be the canonical way to close a BACKLOG item during a retrospective, so the BACKLOG-deletion / CHANGELOG-append coupling is enforced by the tool, not by hand.
- **As any user** I want `backlog-manager add` to refuse malformed entries up-front, so BACKLOG.md never enters an invalid state.

---

## Non-Functional Requirements

### NFR1: Performance
- All subcommands return in under 2 seconds on the current BACKLOG.md (≈1800 lines) and CHANGELOG.md.
- `list --all-items` renders to stdout in under 1 second.

### NFR2: Usability
- Errors emit `[CWF] ERROR: backlog-manager <subcommand>: <message>` on STDERR (consistent with other CWF helpers).
- **Exit codes**:
  - `0` — success
  - `1` — user input error (invalid flag, validation failure, ambiguous slug, banned priority, missing implementing-task CHANGELOG entry, etc.)
  - `2` — path validation error (`--body-file` outside repo, etc.)
  - `3` — internal error (unexpected file state, parse failure on a previously-valid file, etc.)
- **Help**:
  - `backlog-manager` (no args) → exit 1, `[CWF] ERROR: backlog-manager: missing subcommand. Run with --help for usage.`
  - `backlog-manager --help` / `-h` → top-level usage with all subcommands listed
  - `backlog-manager <subcommand> --help` / `-h` → subcommand-specific usage
  - Missing-required-flag errors do NOT print full help; they print `[CWF] ERROR:` and exit 1.
- `validate --all` lists every failure rather than stopping at the first; default behaviour is fail-fast.
- **Flag form**: `--key=value` only (no space-separated form). Boolean flags are bare; default off.

### NFR3: Maintainability
- Single Perl entry point at `.cwf/scripts/command-helpers/backlog-manager`; subcommand dispatch via a `%dispatch` hash in `main()`.
- Parser/validator/mutator logic in a sibling library module (`.cwf/lib/CWF/Backlog.pm`) so the script stays thin.
- `main() unless caller();` testability convention.

### NFR4: Reliability — atomicity
- Single-file writes use `atomic_write_text` from `CWF::ArtefactHelpers`.
- `retire` is the only two-file write. Sequence:
  1. Build new CHANGELOG content in memory (entry block appended under implementing task).
  2. Build new BACKLOG content in memory (entry deleted).
  3. atomic-write CHANGELOG.
  4. atomic-write BACKLOG.
- **Crash-state recovery**:
  - **Both writes succeeded**: subsequent `retire --id=<slug>` returns `[CWF] INFO: backlog-manager retire: <slug> not found in BACKLOG (already retired?)` and exits 0. No file writes.
  - **CHANGELOG written, BACKLOG not**: BACKLOG still has the entry; CHANGELOG has the block. Re-running `retire` detects the `#### <title>` block already exists under the implementing task and skips the CHANGELOG write step; only the BACKLOG delete is performed. No duplicate block.
  - **Neither written**: no state change, retry from scratch.
- **Block de-duplication rule**: `retire` parses the implementing task's CHANGELOG entry, locates the `### Retired Backlog Items` subsection (if present), and scans **only headings inside that subsection** for an existing `#### <title>` whose title (case-insensitive, leading/trailing whitespace stripped) matches the BACKLOG entry's title. A naive whole-entry scan is forbidden — entry bodies may legitimately contain `^#### ` lines as user-written prose, and treating those as retired-block headings would cause false-positive deduplication.

### NFR5: Security
- **No shell-out**. All file ops via Perl core modules.
- **Path inputs** (`--body-file` is the only user-supplied path; BACKLOG.md and CHANGELOG.md are hard-coded) MUST be validated against `validate_path_allowlist`.
- **Body-content safety**: `add` / `modify` reject `--body` (or `--body-file` content) that contains a line matching `^---$`.
- **`--note` safety**: `--note` value is restricted to printable ASCII (regex `/^[\x20-\x7E]*$/`). This rejects `-->` (would close the embedded HTML comment), CR, LF, NULL bytes, BOM, and other control characters. Multi-line / Unicode commentary is out of scope for v1; if richer commentary is needed, edit the CHANGELOG file directly post-retire.
- `use utf8;` mandatory.
- Permissions `0500`; registered in `.cwf/security/script-hashes.json`.

This addresses CWF FR4 categories: (a) input parsing safety (`---` separator collision), (b) output construction safety (`-->` in `--note`), and path-allowlist enforcement on user-supplied file inputs.

---

## Constraints
- Perl 5.14+, core modules only.
- No new dependencies beyond `CWF::ArtefactHelpers` and `CWF::Common`.
- Must work on the BACKLOG.md / CHANGELOG.md as they exist **post-rollout-migration** (the rollout strips the 47 legacy markers; thereafter the file is in canonical form).
- Must integrate cleanly with existing CWF tooling. Wiring into `cwf-manage validate` is a separate follow-up task.
- BACKLOG.md is a single file; the helper does not support a multi-file BACKLOG layout.

---

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ concerns? No — single concern.
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Parts that can be worked on separately? No — subcommands share parser; migration coupled to validator.

No decomposition warranted.

---

## Acceptance Criteria

- [ ] **AC1 (FR1)**: `backlog-manager validate` exits 0 on the post-migration BACKLOG.md and CHANGELOG.md.
- [ ] **AC2 (FR1)**: `validate` exits 1 with a path-and-line-prefixed `[CWF] ERROR:` for each violation: missing `**Priority**:` (BACKLOG-001), banned `Needs-Triage` (BACKLOG-002), body line `^---$` (BACKLOG-003), HTML comment in BACKLOG (BACKLOG-004), struck-through entry heading (BACKLOG-005), `^#### ` in active body (BACKLOG-006), missing top-level `# Changelog` (CHANGELOG-001), CHANGELOG entry without `**Impact**:` (CHANGELOG-002), out-of-order Changes/Notable/Retired (CHANGELOG-003), CRLF or BOM (GLOBAL-001).
- [ ] **AC3 (FR1)**: `validate` accepts a CHANGELOG entry that omits `**Duration**:`, `### Changes`, `### Notable`, or `### Retired Backlog Items` (or any combination).
- [ ] **AC4 (FR1)**: `validate` accepts HTML comments inside CHANGELOG (e.g. `<!-- Note: ... -->` blocks); same comment in BACKLOG would fail.
- [ ] **AC5 (FR2)**: `list` produces output grouped Very High → High → Medium → Low → Very Low; Very High band rendered if non-empty.
- [ ] **AC6 (FR2)**: `list --all-items` shows every active entry; `list` (default) shows top-20 with band-no-split soft-cap rule, regression-tested via a synthetic fixture.
- [ ] **AC7 (FR3)**: `add --priority=Very\ High --task-type=chore --title="Test" --body="x"` produces an entry that re-passes `validate`.
- [ ] **AC8 (FR3)**: `add` rejects `--priority=Needs-Triage`, `--body` containing a `^---$` line, and `--body-file=/etc/passwd` (path-allowlist failure → exit 2).
- [ ] **AC9 (FR4)**: `modify --id=<slug> --priority=Low` rewrites only `**Priority**:`; entry order, body bytes, and all other fields preserved.
- [ ] **AC10 (FR4)**: `modify --id=<colliding-slug>` against a BACKLOG with two entries producing the same slug exits 1 with the disambiguation hint.
- [ ] **AC11 (FR5)**: `delete --id=<slug>` without `--confirm` exits 1 with hint; with `--confirm` removes the entry; `validate` passes.
- [ ] **AC12 (FR6)**: `retire --id=<slug> --task=131` against an entry titled "Foo" produces, under Task 131's CHANGELOG entry: an `### Retired Backlog Items` subsection (created if absent), then a `#### Foo` block containing the original body verbatim. The BACKLOG entry is deleted. Subsequent `validate` passes.
- [ ] **AC13 (FR6)**: `retire --id=<slug> --task=131 --note="Implementation diverged because X"` appends `<!-- Note: Implementation diverged because X -->` after the body block. `--note` containing any non-printable-ASCII character (`-->`, embedded newlines, CR, NULL, BOM, etc.) is rejected (exit 1).
- [ ] **AC14 (FR6)**: `retire --id=<slug> --task=999` against a Task 999 with no CHANGELOG entry exits 1 with the "create the entry first" message; no file writes.
- [ ] **AC15 (NFR4)**: Re-running `retire` on an already-retired entry exits 0 with INFO message; no file writes. Crash-recovery scenario (BACKLOG-still-has-entry + CHANGELOG-already-has-block, simulated by hand-edit) is reconciled by re-running `retire`: only BACKLOG is rewritten; existing CHANGELOG block is detected and not duplicated.
- [ ] **AC16 (NFR2)**: `backlog-manager` (no args) → exit 1, missing-subcommand error. `--help` flows as specified.
- [ ] **AC17 (round-trip)**: `add` → `modify` → `validate` → `retire` of the same entry leaves both files in valid states at every step.

---

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

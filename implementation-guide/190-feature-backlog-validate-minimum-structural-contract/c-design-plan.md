# backlog validate minimum structural contract - Design
**Task**: 190 (feature)

## Task Reference
- **Task ID**: internal-190
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/190-backlog-validate-minimum-structural-contract
- **Template Version**: 2.1

## Goal
Define the design for asserting a minimum structural contract in
`backlog-manager validate`, satisfying FR1–FR5: a precise, corpus-safe predicate that
distinguishes a *conformant* (possibly empty) `BACKLOG.md` from a *foreign* one, surfaced
both at `validate` time and as a mutation precondition.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### KD1 — The contract is an *intro-region* scan, not a file-wide one
- **Decision**: The structural check (new rule **`BACKLOG-000`**) scans only the **intro
  region** — the source lines *before the first recognised entry*. For a file with **zero**
  recognised entries (the foreign case), the intro region *is the whole file*; for a file with
  real entries, only the preamble is scanned.
- **Rationale**: Grounded in the corpus. The live `BACKLOG.md` legitimately contains non-entry
  `## ` headings **inside entry bodies** (`## How Task Status Works`, `## Active Maintenance
  Requirements`). A file-wide "every `## ` must be an entry" rule would false-positive on our own
  backlog (violating AC4). Scanning intro-only follows the same *concept* as the existing
  `CHANGELOG-005` intro-scan (`Backlog.pm:449`), with the elegant property that the dangerous case
  (zero entries) gets whole-file coverage automatically while the safe case (real entries with rich
  bodies) is untouched.
- **Mechanism (corrected per review)**: Unlike `CHANGELOG-005`, which scans the pre-built
  `@{$tree->{intro}}` array, this rule emits a **line number**, and `$tree->{intro}` is
  `trim_blank_lines`'d and carries no source offsets. So the predicate obtains the line-numbered
  source + fence via the established **`_file_lines_and_fence($tree)`** helper (`Backlog.pm:412`,
  which also handles mutator-built trees with no cache), then scans the 0-based range
  `0 .. (header_lineno − 2)` (exclusive of the first entry's heading line; `header_lineno` is
  1-based, `Backlog.pm:247`), or `0 .. $#lines` when `entries` is empty. Emitted `line` is 1-based
  (`$i + 1`), matching every other rule in the module.
- **Trade-offs**: Cannot flag foreign content that appears *after* a genuine entry (a mixed file).
  That is not the reported failure mode and is an accepted boundary (see Residual Limitations).

### KD2 — Conformance predicate: intro carries only preamble, not managed-looking content
- **Decision**: Within the intro region, outside fenced code, the only permitted lines are: blank
  lines, plain prose, and **at most one leading top-level `# ` H1**. A `BACKLOG-000` error fires on:
  (a) any heading `^#{1,6} ` that is **not** the single leading H1 (i.e. any `##`–`######`, or a
  second `# `); (b) any list item `^\s*([-*+]|\d+[.)])\s`. Prose and blanks never fire.
- **Rationale**: A zero-entry *foreign* backlog's content is invariably headings (sections) or list
  items (flat lists) — the two dominant "different format" shapes. A *conformant* backlog's intro is
  title + prose only, verified across the live file (`# CWF System Backlog` + one prose line), the
  `intro-only-backlog` parse fixture (`# Backlog\n\nIntro paragraph.`), and the headerless entry
  fixtures (empty intro). This catches both heading- and list-structured foreign files while
  staying corpus-clean. **An H1 is permitted but not required** — headerless conformant backlogs
  (the common test shape) must keep passing, so the contract never *mandates* a header.
- **Trade-offs**: A purely-prose foreign file (no headings, no lists) is not flagged — but such a
  file has no structured content for CWF to misinterpret, and `add` still surfaces a new entry, so
  the "invisible items" failure does not arise. Accepted boundary.

### KD3 — Single predicate, reused by validate and the mutation gate (NFR3)
- **Decision**: One helper, `backlog_structure_errors($tree, $path)` in `CWF::Backlog`, returns the
  `BACKLOG-000` error list. `validate_backlog_tree` appends its result; the four mutation
  subcommands call it after parse and **abort before any write** if it returns non-empty.
- **Rationale**: Single source of truth — validate and the mutation gate cannot diverge.
- **Trade-offs**: None material; it is a pure function over the parsed tree.

### KD4 — Mutation gate checks *only* the structural rule, not all of `validate`
- **Decision**: The mutation precondition keys on `BACKLOG-000` specifically, not on the full
  `validate_backlog_tree` result. `retire` gates **before touching either** `BACKLOG.md` or
  `CHANGELOG.md`.
- **Rationale**: Mutations must refuse on a *foreign* file (can't safely manage it), but must not
  newly refuse on files with unrelated per-entry warnings/errors (e.g. a legacy `**Field**:` file,
  which has recognised `## Task:` entries and must remain convertible via `normalise`, not be
  blocked by the structural gate). Keying on `BACKLOG-000` keeps the blast radius to genuinely
  unmanageable files. (FR4)
- **Trade-offs**: A structurally-conformant file with a malformed entry can still be mutated as
  today — unchanged behaviour, intentionally.

### KD5 — CHANGELOG parity (FR5 decision)
- **Decision**: Implement the helper **generically** but **apply it to `BACKLOG.md` only** in this
  task. Record a backlog follow-up to extend the identical scan to `CHANGELOG.md` (which has the
  same vacuous-pass gap below its `CHANGELOG-001` header check).
- **Rationale**: Scope discipline — the reported failure is BACKLOG-specific and the task is titled
  accordingly; CHANGELOG is append-only via `retire`/bootstrap and lower-risk. The generic helper
  makes the later extension a one-line call plus its own corpus verification (the large live
  `CHANGELOG.md` needs its own AC4-style check), which is cleaner as a separate unit.
- **Review hook**: This is a deliberate scope boundary — if review prefers, folding CHANGELOG in now
  is low-cost (one call in `validate_changelog_tree` + changelog fixtures). Flagged for the
  pre-exec review.

## System Design
### Component Overview
- **`backlog_structure_errors($tree, $path)`** (`.cwf/lib/CWF/Backlog.pm`, new): pure predicate.
  Obtains `($lines, $fence) = _file_lines_and_fence($tree)` (established helper — uses the cached
  stream when present, serialises as a fallback for mutator-built trees). Computes the intro range
  as `0 .. (entries[0]{header_lineno} − 2)`, or `0 .. $#$lines` when `entries` is empty. Walks that
  range skipping fenced lines via `$fence`, applies KD2, returns a list of
  `{file,line=>$i+1,rule=>'BACKLOG-000',severity=>'error',message}` records. No second file read, no
  fence rebuild (NFR1).
- **`validate_backlog_tree`** (modified): appends `backlog_structure_errors(...)` to its returned
  errors. No change to per-entry rules.
- **`backlog-manager` mutation subcommands** `cmd_add`/`cmd_modify`/`cmd_delete`/`cmd_retire`
  (modified): after `parse_backlog_tree`, call the predicate; if non-empty, `die_user(<static
  message>)` before any `write_tree`. For `cmd_retire`, the check is placed **immediately after the
  BACKLOG parse (`backlog-manager:448`) and before the CHANGELOG bootstrap (`:466-468`)**, so a
  refusal mutates neither the in-memory CHANGELOG tree nor either file on disk (writes are at
  `:485-486`).

### Data Flow
1. `validate`: `parse_backlog_tree` → tree (with cached `_source_lines`/`_source_fence`) →
   `validate_backlog_tree` → per-entry rules **+ `backlog_structure_errors`** → merged error list →
   exit non-zero if any error.
2. Mutation: `parse_backlog_tree` → `backlog_structure_errors`; non-empty → `die_user` (exit 1), no
   write. Empty → existing mutate + atomic `write_tree`.

## Interface Design
### New/changed function contracts
- `backlog_structure_errors($tree, $path = 'BACKLOG.md') → \@errors` (exported alongside the
  existing `validate_*` functions). Deterministic; no I/O; safe to call from both validate and
  mutation paths.
- `validate_backlog_tree($tree, $path)`: unchanged signature; return now also includes any
  `BACKLOG-000` records.

### Error record / message (NFR2, AC7)
- `rule => 'BACKLOG-000'`, `severity => 'error'`.
- Message is **static expected-structure text** naming the expected shape and the format reference,
  and **does not echo the offending line verbatim** (FR4(c) injection-surface avoidance). It names
  the *kind* of offending construct and the line number only, e.g.:
  `"BACKLOG.md preamble contains an unmanaged <heading|list item> at line N; CWF tracks entries as
  '## Task: <title>' / '## Bug: <title>' blocks and does not manage other top-level structure. See
  .cwf/docs/skills/reference/cwf-backlog-manager.md."` (Line number is not attacker-controlled text;
  the construct kind is a fixed enum — no verbatim content is interpolated.)
- **Doc-reference correction (per review)**: the entry grammar is documented in
  `.cwf/docs/skills/reference/cwf-backlog-manager.md`, **not** `CWF-PROJECT-SPEC.md` (verified — the
  spec contains no `## Task:`/`## Bug:` grammar). NFR2/AC7's "point to the format" is satisfied by
  the skill-reference doc; the requirements' parenthetical `CWF-PROJECT-SPEC.md` is superseded here.

## Residual Limitations (accepted boundaries, to record)
- Foreign content **after** a genuine entry is not flagged (KD1).
- A purely-prose foreign file (no headings/lists) is not flagged (KD2).
- **Unterminated leading fence** (per review): a foreign file that opens with an unclosed ```` ``` ````
  marks every subsequent line in-fence to EOF (`_build_fence_map`, `Backlog.pm:132`), so its
  headings/lists are skipped and it passes. Accepted boundary — the dominant foreign shapes are not
  fenced; recorded, not fixed here.
- **Headerless legacy** (per review): a legacy `**Field**:` file that *retained* its `## Task:`
  headings parses to real entries and is correctly accepted/convertible (AC3). A legacy file with
  **no** `## Task:` heading parses to zero entries and, being prose-only, passes as benign (KD2) —
  indistinguishable from a prose-only file; accepted, not converted. The **AC3 legacy test MUST use a
  heading-bearing legacy fixture** (the existing `t/backlog-manager.t:882` fixture qualifies).
- `CHANGELOG.md` retains the symmetric gap until the recorded follow-up (KD5).
These are documented in `j-retrospective.md` and the relevant ones filed as backlog items.

## AC5 — canonical empty skeleton (resolved per review)
There is **no `cwf-init`/bootstrap-emitted `BACKLOG.md`** — `cwf-init` does not create one and there
is no `bootstrap_backlog` analogue to `bootstrap_changelog_entry` (verified). A `BACKLOG.md` first
appears hand-authored or via the first `add`. AC5 therefore reduces to two concrete shapes that MUST
validate clean under `BACKLOG-000`: (i) an **empty/whitespace-only** file, and (ii) the **intro-only**
form `# <title>\n\n<prose>\n` (the `t/backlog-tree-parse.t:163` `intro-only-backlog` shape). Both
contain only blank/H1/prose lines and pass KD2 by construction.

## Constraints
- Perl core-only, POSIX. Reuse cached `_source_lines`/`_source_fence` (no new I/O). No change to
  `GLOBAL-*`/`BACKLOG-00x` rules or the `normalise` path. Backward compatible with every currently
  valid `BACKLOG.md` (AC4 — verified against live file + all `t/` fixtures in the testing phase).

## Decomposition Check
- [ ] **Time**: >1 week? — No.
- [ ] **People**: >2 people? — No.
- [ ] **Complexity**: 3+ distinct concerns? — No (one predicate + two call sites + tests).
- [ ] **Risk**: high-risk components needing isolation? — No.
- [ ] **Independence**: separable parts? — No.

**Outcome**: 0 signals — single task.

## Validation
- [x] Contract predicate defined as a deterministic, testable rule (KD2) — satisfies FR1's
      design-deferral requirement.
- [x] Empty-vs-foreign-vs-legacy three-way discrimination resolved (KD1/KD2/KD4) — AC3.
- [x] Corpus-safety argued against live file + key fixtures (KD1/KD2) — AC4 to be proven in testing.
- [x] CHANGELOG parity decision recorded (KD5) — AC8.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

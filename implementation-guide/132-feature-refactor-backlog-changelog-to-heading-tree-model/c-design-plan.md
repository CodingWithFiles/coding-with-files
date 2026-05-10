# Refactor BACKLOG/CHANGELOG to heading-tree model - Design
**Task**: 132 (feature)

## Task Reference
- **Task ID**: internal-132
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/132-refactor-backlog-changelog-to-heading-tree-model
- **Template Version**: 2.1

## Goal
Settle the architecture and design decisions that satisfy the requirements: a structured-down-to-H3 entry tree, the writer/parser round-trip contract, the validator-rule remap, the mutator API, the migration mechanics, and the `/cwf-backlog-manager` skill shape. Leaves no ODQ open before implementation.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility.

Concretely for this task: testability of the parser (one function, deterministic, no I/O coupling); readability of the tree shape (a hash you can `Data::Dumper` and immediately read); consistency with Task 131 primitives (atomic_write_text, validate_path_allowlist, generate_slug stay where they are); simplicity of the body_raw model (raw bytes; no inner-text reparse); reversibility via the migration snapshot.

## Architecture Choice

**Decision**: Tree parser + tree-walking validators + tree-mutators + tree serialiser. One parse, one in-memory shape, every consumer reads from the tree.

**Rationale**: The Task 131 model — flat sections of opaque blobs, with accessors re-walking raw_lines on every call — is exactly what produced the silently-merged-entries bug. A parser that produces structure by construction (one entry node per `## (Task|Bug):`/`## Task N:` heading) makes that class of bug impossible. Putting metadata as first-class child nodes (per ODQ #2: H3 metadata is structurally one level below H2 titles) means validators and mutators traverse fields by name, not by regex over raw lines. Body content stays as raw bytes (per ODQ #1) so round-trip remains byte-identical for unmodified entries.

**Trade-offs**:
- ✓ Eliminates the parser-bug class behind Task 131's missing-separator regression
- ✓ Validators and mutators become tree walks (~half the LOC of today's regex re-derivation)
- ✓ Round-trip preserved: `body_raw` arrays carry bytes verbatim
- ✗ Bigger refactor than "fix the splitter" (parser, validators, all six mutators, all 408 tests, the live files)
- ✗ Some convenience: today's `entry_metadata($sect)->{Priority}` becomes `(grep { $_->{key} eq 'Priority' } @{$e->{metadata}})[0]{value}`. Wrap in a `metadata_get($entry, $key)` accessor to keep call sites tidy.

## System Design

### Component Overview

| Component | Responsibility | Lives in |
|-----------|----------------|----------|
| **`parse_to_tree`** | Read bytes → produce `{intro, entries}` tree with H3 metadata as nodes; preserve body bytes | `CWF::Backlog` |
| **`serialize_tree`** | Tree → bytes; canonical order on write (Postel-strict per ODQ #3) | `CWF::Backlog` |
| **`validate_*`** | Tree-walking validators emitting `[{rule, severity, line, message}]`; warn vs error per rule | `CWF::Backlog` |
| **Mutators** (`set_priority`, `add_entry`, `delete_entry`, `append_retired`) | In-place tree mutation (per ODQ #5); writer reads the mutated tree | `CWF::Backlog` |
| **Migration script** | One-shot Task 131-format → heading-tree migration (per ODQ #6); throwaway, deleted in retrospective | `/tmp/task-132/migrate-backlog-format.pl` |
| **`backlog-manager`** | CLI front: parses argv → invokes parser/mutators/serialiser → exits with error code | unchanged location |
| **`/cwf-backlog-manager` skill** | Instructional reference: lists subcommands + invocation patterns; LLM constructs the right Bash call | `.claude/skills/cwf-backlog-manager/SKILL.md` |

### Data Flow

```
   bytes               tree                      mutated tree         bytes
BACKLOG.md ──parse_to_tree──> {intro, entries}──mutate──> {intro, entries'}──serialize──> BACKLOG.md
                                  │                                          
                                  └──validate──> [{rule, line, msg}, ...] ──> stdout/exit
```

### Tree Shape (resolves ODQ #1)

```perl
{
    intro   => [@raw_lines],         # everything before the first H2 entry
    entries => [
        {
            type          => "Task" | "Bug",          # BACKLOG; or "Task N" for CHANGELOG (with task-num integer in `task_num`)
            task_num      => 131,                     # CHANGELOG entries only; undef for BACKLOG
            title         => "Add backlog management helper script",
            header_lineno => 158,                     # 1-based source line of the H2
            metadata      => [
                # H3 children whose text contains a `:` — ordered, observed order preserved
                { key => "Task-Type", value => "feature", lineno => 160 },
                { key => "Priority",  value => "High",    lineno => 161 },
                { key => "Status",    value => "Awaiting design", lineno => 162 },
            ],
            subsections   => [
                # H3 children WITHOUT a `:` — subsection nodes (CHANGELOG: Changes, Notable, Retired Backlog Items)
                # BACKLOG entries usually have an empty subsections list
                {
                    name      => "Changes",
                    lineno    => 165,
                    body_raw  => [@raw_lines],            # everything until next H3 or end-of-entry
                    # For "Retired Backlog Items" only, retired_entries lazily parses body_raw on demand
                    retired_entries => undef,             # populated by retired_subsection_entries() accessor
                },
                ...
            ],
            body_raw      => [@raw_lines],                # entry-level prose that appears BEFORE any H3 child
                                                          # (per Postel preference, this is empty in canonical order;
                                                          # populated for legacy / hand-edited entries)
        },
        ...
    ],
}
```

**Why this shape**:
- `metadata` and `subsections` are separate ordered arrays — keeps the value-bearing fields (H3 with `:`) distinct from structural subsections (H3 without `:`). Validators and mutators that care about `Priority` walk only `metadata`; ones that care about `Retired Backlog Items` walk only `subsections`. (Considered merging into a single `h3_children` array with a discriminator field; rejected on grounds that the type split is self-documenting and consumers always care about one or the other, not both interleaved.)
- `body_raw` at the entry level holds anything-before-first-H3-child — supports the Postel-liberal parser (entries with body-before-metadata still parse), and stays empty in the canonical write path.
- Each level keeps a `lineno` field so error messages can name the offending source line (NFR2).
- `retired_entries` is a lazily-computed accessor, not a parsed-up-front field — most code paths don't need it; only `retire`/`block_exists_in_retired` do.

### Heading-Text Parsing (resolves ODQ #8)

Single regex captures the heading-tree node shape:

```perl
# H2: ## Task: Title  /  ## Bug: Title  /  ## Task 131: Title
# H3: ### Priority: High  (metadata; key+value)
# H3: ### Changes        (subsection; key only)
# H4: #### <retired-entry-title>
qr/^(\#{2,6})[ \t]+(.+?)[ \t]*$/
```

Then `value =~ s/^([A-Z][\w\- ]*?):[ \t]*(.*)$/...` extracts key/value when present.

Normalisation rules:
- **Trim trailing whitespace** from the heading text. Round-trip preserves the *trimmed* form (the migration script applies the same trim, so the bytes that go in match the bytes that come out).
- **Reject embedded control characters** (U+0000–U+001F except `\t`) in heading text → parser raises a hard error with line number. Validator's `GLOBAL-002` rule.
- **GLOBAL-002 scope**: control characters only. The rule does **not** police printable-character injection (e.g. `**`, `~~`, embedded `#`). Rationale: heading text comes from files under git control, edited by trusted collaborators; the threat model is "accidental corruption", not "adversarial input". Markdown rendering ambiguities from printable characters (e.g. unbalanced `**`) round-trip safely because the body is preserved as raw bytes and the title field stores literal text. If we later need stricter heading-content rules, that's a separate task — not in scope here.
- **No Unicode normalisation form change** — accept whatever bytes are present (matches today's behaviour; avoids a normalisation-form decision creating round-trip noise).

### Parser Algorithm Outline

Single linear pass through the file's lines, maintaining: (a) a fence-state map built once for the whole file (re-uses `_build_fence_map`), and (b) a current-entry pointer.

```
1. Read bytes; do GLOBAL-001 BOM/CRLF checks; decode UTF-8; split into raw lines.
2. Build fence map across the whole file (single source of fence truth — no per-entry rebuild).
3. Scan lines:
   - If line is inside a fence (per fence map) → append to whichever raw-lines bucket
     is currently active (intro.raw_lines, current entry's body_raw, or current
     subsection's body_raw). Fenced lines are NEVER parsed as headings, even if
     they look like `## ` or `### `.
   - If line matches `^## (?:Task|Bug|Task \d+):` outside fences → start a new
     entry; close any open subsection / entry.
   - If line matches `^### ` outside fences AND we are inside an entry:
       * If text contains `:` → push onto entry.metadata.
       * If text does not contain `:` → push onto entry.subsections; this becomes
         the active subsection for following body_raw lines.
   - If line matches `^#### ` or `^##### ` etc. outside fences → treat as body
     content (raw line) of the current subsection or entry; do NOT structure further.
   - Any other line → append to the current bucket (intro / entry.body_raw /
     subsection.body_raw, depending on parser state).
4. End: return {intro, entries}.
```

Disambiguation note: if an entry has body prose appearing **before** any H3 child, that prose lands in `entry.body_raw`. Once the first H3 is seen, body_raw is "closed" for the entry; subsequent non-H3 content goes into the most recent subsection's body_raw (or, if no subsection has opened yet, into the metadata-following gap which is also captured as raw lines tracked alongside the metadata array). This makes `entry.body_raw` non-empty only in the Postel-liberal case (body-before-metadata, which BACKLOG-007 warns on).

### Validator Rule Remap (resolves ODQ #4)

| Old rule (Task 131) | New rule | Disposition | Notes |
|---|---|---|---|
| `GLOBAL-001a` (BOM) | `GLOBAL-001a` | KEEP verbatim | File-level byte check; format-agnostic |
| `GLOBAL-001b` (CRLF) | `GLOBAL-001b` | KEEP verbatim | File-level byte check; format-agnostic |
| — | `GLOBAL-002` | **NEW** | Heading text contains no control characters (security; ODQ #8) |
| `BACKLOG-001` (Task-Type/Priority required) | `BACKLOG-001` | REFRAME | "metadata key 'Task-Type' / 'Priority' must exist on each active entry"; check is now `grep { $_->{key} eq 'Task-Type' } @{$e->{metadata}}` |
| `BACKLOG-002` (Priority valid value) | `BACKLOG-002` | REFRAME | Same value set; lookup target shifts to `metadata_get($e, 'Priority')` |
| `BACKLOG-003` (body lines not `^---$`) | — | **RETIRE** | New format has no `---` separators anywhere; rule is now structurally impossible |
| `BACKLOG-004` (no HTML comments) | `BACKLOG-004` | KEEP | Same intent (`<!-- Completed: -->` markers were why Task 131 went sideways); easier to enforce on the parsed tree |
| `BACKLOG-005` (no struck-through entries) | `BACKLOG-005` | KEEP, REFRAME | "no entry whose `title` contains `~~` or `✓`"; check on the parsed `title` field, not raw lines |
| `BACKLOG-006` (no `^####\s+` in body) | — | **RETIRE** | The dedup-scanner / retired-block collision was a Task 131 raw-lines artefact. Body H4+ subsections in BACKLOG are now fine; retired blocks live structurally under CHANGELOG `### Retired Backlog Items`, not pattern-matched |
| — | `BACKLOG-007` | **NEW** (warning) | Per Postel ODQ #3: fires when `entry.body_raw` (the slot that holds prose appearing *before* the first H3 child) contains any non-blank line AND `entry.metadata` is non-empty. Means "body appears before metadata in the source" — non-canonical order. Soft warning, not error |
| `CHANGELOG-001` (single `# Changelog` header) | `CHANGELOG-001` | KEEP | Belongs at file/intro level; tree's `intro` block holds it |
| `CHANGELOG-002` (Status + Impact required) | `CHANGELOG-002` | REFRAME | "metadata key 'Status' and 'Impact' must exist on each changelog entry"; tree-walk |
| `CHANGELOG-003` (subsection order) | `CHANGELOG-003` | REFRAME | Subsections are now structured nodes; check `[s->{name} for s in $e->{subsections}]` is a prefix-of `[Changes, Notable, Retired Backlog Items]` |
| — | `CHANGELOG-004` | **NEW** (warning) | Per Postel ODQ #3: same condition as BACKLOG-007 but on CHANGELOG entries (body_raw non-empty AND metadata non-empty) |

Severity convention: `error` = exit non-zero (`1`), `warning` = stderr-printed but exit zero (`0`). CLI flag `--strict` escalates warnings to errors. CI gate (`cwf-manage validate` and any `prove t/` integration tests) call `backlog-manager validate` *without* `--strict`, so warnings surface but don't fail builds — they're a nudge, not a block. Migration script reports any warnings it encounters but does not block on them.

### Mutator API (resolves ODQ #5)

**Decision**: in-place tree mutation. Mutators receive a tree (and target identifiers), modify it in place, return success/failure. The writer reads the mutated tree.

**Rationale**: tree-in-tree-out is more idiomatic in immutable languages but doesn't earn its overhead in Perl. In-place matches Task 131's mental model and keeps mutator signatures minimal. Round-trip safety is preserved because `body_raw` arrays of unmodified entries are never touched.

API sketch:
```perl
sub set_metadata_field { my ($entry, $key, $value) = @_; ... }   # add or update
sub add_entry { my ($tree, $entry) = @_; push @{$tree->{entries}}, $entry; }
sub delete_entry { my ($tree, $idx) = @_; splice @{$tree->{entries}}, $idx, 1; }
sub append_retired_block { my ($changelog_entry, $title, $body_raw) = @_; ... }
```

The Postel-strict canonicalisation (always emit title → metadata → body) happens inside the **serialiser**, not the mutators. Mutators leave the tree as-is; serialiser walks `metadata` first (in observed order — within metadata, no internal canonicalisation), then `subsections` (in canonical order: Changes, Notable, Retired Backlog Items, then any others in **observed** order — no alphabetic resort, since unfamiliar subsection names are valid free-form prose), then entry-level `body_raw` (which the canonical form expects to be empty; if non-empty, it lands at the end with a leading blank line).

**Round-trip (AC6) and canonicalisation interaction**: serialisation reorders only when the input is non-canonical. For files that are already canonical (the common case post-migration), parse → serialise is byte-identical because the observed order *is* the canonical order. For non-canonical inputs (Postel-liberal hand-edits), parse → serialise differs from input by design; AC6 is tested against canonical fixtures, not against arbitrary input. The migration script does **not** canonicalise during the one-shot conversion — it preserves whatever order the Task 131 file had — so the post-migration file may still be non-canonical, and the next mutator-driven write canonicalises it. This keeps the migration's blast radius minimal (no surprise reorderings during the bulk conversion) while still ensuring the long-term steady state is canonical.

### Subcommand Surface (preserved per FR3)

`backlog-manager` keeps its six subcommands (`add`, `delete`, `modify`, `list`, `validate`, `retire`) with the same flag set. Internal implementations rewrite to operate on the tree:

- `cmd_list`: walk `tree->{entries}`, group by `metadata_get($e, 'Priority')`. Filtering bug from Task 131 disappears (it was the parser bug, not a list bug).
- `cmd_add`: build a new entry node, splice into `tree->{entries}`, serialise.
- `cmd_modify`: locate entry by slug or title, `set_metadata_field`, serialise.
- `cmd_delete`: locate entry, splice out, serialise.
- `cmd_retire`: locate entry in BACKLOG tree, locate target task in CHANGELOG tree, `append_retired_block` to its `Retired Backlog Items` subsection, atomic two-file write (CHANGELOG first per Task 131 contract).
- `cmd_validate`: parse + invoke validators, format errors/warnings, exit 0/1 (1 if any error).

### Migration Script (resolves ODQ #6, #7)

**Home**: `/tmp/task-132/migrate-backlog-format.pl` — one-shot Perl script. Created in f-implementation-exec, run during the rollout, **deleted in `j-retrospective.md` Step 8 after AC1–AC8 are confirmed green**. Not committed to the repo, not hash-pinned in `script-hashes.json`, no permanent surface.

**Rationale**: Task 132 is the only migration from Task 131 format to heading-tree format. After it lands, every BACKLOG.md / CHANGELOG.md in this repo is in the new format. No external CWF installs run the Task 131 helper against a production BACKLOG yet (it's brand new and unreleased). Any future format change would warrant a new targeted script, not a re-run of this one. Matches the Task 131 throwaway pattern (`/tmp/task-131/migrate-markers.pl`) and avoids accumulating dead one-shots in `.cwf/scripts/`.

**Idempotency** (resolves ODQ #7): the script inspects each file before touching it:
- If `^---$` count is 0 AND `^\*\*[A-Z][\w\- ]*\*\*:` count is 0 → already in heading-tree format → exit 0 with `[CWF] migrate: BACKLOG.md already in new format; no change`.
- If both counts > 0 → file is in Task 131 format; proceed.
- If exactly one count is 0 → file is in mixed/partially-migrated state → exit 1 with `[CWF] ERROR: ambiguous format; manual review required`.

**Migration steps** (per file):
1. Snapshot: `cp BACKLOG.md /tmp/task-132/BACKLOG.md.pre-migration` (created at the start of the rollout; same `/tmp/task-132/` directory holds the migration script itself).
2. Read with the *old* parser (Task 131's `parse_backlog_file`, sourced via `use lib` from a checked-out copy of the pre-refactor `Backlog.pm` if the new code has already replaced it; otherwise direct from the existing module).
3. For each active section, validate it satisfies the old BACKLOG-001 (Task-Type and Priority present); on validation failure, abort with the offending section's title and source line so the user can correct hand-edit damage before re-running.
4. Extract metadata (Task-Type, Priority, Status, Identified-in, etc.) by regex over raw_lines (Task 131's accessors, repurposed for one-shot use).
5. Construct new-format heading-tree string per entry: `## Task: $title\n\n### Task-Type: $tt\n### Priority: $p\n### Status: $s\n\n$body\n`. Body is the raw body_lines from the old section, stripped of leading/trailing blank lines (no other body normalisation).
6. Concatenate intro + entries (no `---` separators). Atomic write via `atomic_write_text` (same primitive as `backlog-manager` writes).
7. Re-read with the *new* parser; assert `entries count == old active sections count` (FR5/AC5a entry-count gate); assert each entry's `title` matches an old section's title (AC5b).
8. Same flow for CHANGELOG.md: convert each `## Task N:` entry's `**Status**:` / `**Impact**:` / etc. to `### Status: ...` etc.; subsections (`### Changes`, `### Notable`, `### Retired Backlog Items`) **survive verbatim with the order they were already in** — no canonicalisation reordering during migration, no synthesis of missing subsections. The Postel-strict serialiser will do canonical reordering on the next mutator-driven write; one-shot migration does not.

**Reversibility**: `cp /tmp/task-132/BACKLOG.md.pre-migration BACKLOG.md` (and equivalently for CHANGELOG) restores the pre-migration state. Both the snapshot and the migration script live for the duration of the rollout + testing-exec + retrospective phases (single session, no reboot expected); if the session is interrupted before retrospective, the user re-runs the migration (idempotency above) or restores from the snapshot.

### Skill Design (resolves residual content of ODQ #11/#12, all of #14)

`.claude/skills/cwf-backlog-manager/SKILL.md`:

Frontmatter (mirrors `/cwf-status`):
```yaml
---
name: cwf-backlog-manager
description: Add, modify, list, validate, retire, or delete BACKLOG.md / CHANGELOG.md entries via the heading-tree helper.
user-invocable: true
allowed-tools:
  - Bash
---
```

Workflow body is **instructional, not dispatcher-shaped**. It documents:
- Hardcoded helper path: `.cwf/scripts/command-helpers/backlog-manager`. The skill instructs the LLM to resolve this from the git root (e.g. via `cd "$(git rev-parse --show-toplevel)"` or by passing the absolute path produced from the same), so a working-directory pivot (`cd /tmp` then invoke) cannot trick the skill into running an attacker-staged binary at `/tmp/.cwf/scripts/command-helpers/backlog-manager`. The helper itself already does `find_git_root` for its own file resolution, but the skill instructions must not assume the LLM is in the repo root before invoking.
- Each subcommand's purpose, its flag set, and one or two invocation examples (lifted from the helper's `--help`)
- The list-form invocation rule: arguments containing user input MUST be passed as separate Bash array elements, never interpolated into a single shell string. Example given for `--title='Test $(date)'` showing why (the `$(date)` must remain a literal string in the entry, not a command substitution).
- Note that all subcommands (read and write) are valid for both LLM auto-invocation and explicit user invocation (per ODQ #14); no skill-side confirmation layer.

Registration: append `Skill(cwf-backlog-manager)` to `.claude/settings.json` permissions block, matching the `/cwf-init` step-6 convention (per ODQ #12).

## Constraints That Influenced Design

- **Round-trip safety (FR6)**: drove the choice to keep `body_raw` as raw bytes rather than re-parse the body into prose tokens / list nodes / fenced-code nodes. The body never round-trips through the parser, so it cannot drift.
- **Atomic two-file write (NFR5)**: drove the migration script's design — same `atomic_write_text` primitive, same CHANGELOG-first then BACKLOG ordering for `retire`, same dedup-on-retry contract.
- **POSIX-only Perl, no new CPAN deps (Constraints)**: ruled out a CommonMark/AST library; we write a small heading-tree parser ourselves.
- **Postel's Law on metadata ordering (ODQ #3)**: drove the split between liberal parser (entry-level `body_raw` slot exists for hand-edited weirdness) and strict serialiser (always canonical order out; Postel-strict).
- **No SHA-pinning of SKILL.md (ODQ #13)**: matches sibling skills; no new `script-hashes.json` category.

## Validator Performance Baseline (resolves ODQ #10)

Implementation phase opens with a baseline measurement. Run the Task 131 parser+validator on the live `BACKLOG.md` and `CHANGELOG.md` ten times, record median wall-clock. Same measurement post-refactor. NFR1's "no worse than 5×" is the gate; expectation is "comparable or faster" because the new parser is one pass and validators are pure tree-walks.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: 3-5 sessions estimated → no
- [ ] **People**: solo → no
- [x] **Complexity**: parser + validators + mutators + migration + tests + skill → yes
- [x] **Risk**: round-trip safety + migration data loss → yes
- [ ] **Independence**: tightly coupled (none ships standalone) → no

**Decision unchanged from a-task-plan / b-requirements-plan**: 2 signals trigger but the work is atomic. Keep as one task.

## Validation
- [ ] All ODQs (#1–#14) addressed; no open design questions remain
- [ ] Tree shape concrete and serialisable (`Data::Dumper`-able)
- [ ] Validator rule remap explicit (which old rules retire, reframe, survive; which new rules added)
- [ ] Mutator API sketched at the signature level (not implemented)
- [ ] Migration script home, idempotency check, and snapshot location named
- [ ] Skill SKILL.md shape sketched (frontmatter + instructional body)
- [ ] Plan-review subagents (Step 8) catch no blocking gaps

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
- Body-placement decision (prose-before-metadata-as-warning, canonical title→metadata→body, body-after-metadata) held end-to-end. BACKLOG-007/CHANGELOG-004 fire only on body-before-metadata violations and emit `warning` severity (exit 0) per design.
- Postel's-Law architecture (liberal parser + strict serialiser) confirmed in practice — the migration script's job was small (canonicalise) because the round-trip guaranteed everything else.
- Single-source fence-map (`_build_fence_map` cached on the tree) prevented cross-rule disagreement on edge cases.

## Lessons Learned
- The "body before metadata" invariant is best modelled as a single boolean flag on the entry, not as a separate body slot. The first cut used a `pre_meta_body` array slot which fragmented body across two buckets and complicated serialisation; `/simplify` collapsed it to `body_before_meta` + single `body_raw`. Boolean wins.
- Caching parser-derived state on the parse tree (`_source_lines`, `_source_fence`) is a cheap, high-payoff pattern for any parser+validator combo.

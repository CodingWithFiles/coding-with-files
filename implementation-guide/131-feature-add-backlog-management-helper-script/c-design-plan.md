# Add backlog management helper script - Design
**Task**: 131 (feature)

## Task Reference
- **Task ID**: internal-131
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/131-add-backlog-management-helper-script
- **Template Version**: 2.1

## Goal
Specify the module split, parser model, subcommand dispatch, and the few interesting algorithmic details (slug derivation, two-file atomic-write sequence, `### Retired Backlog Items` subsection insertion) so f-implementation-exec is mechanical.

---

## Design Priorities
Correctness > Readability > Consistency (with existing CWF helpers) > Simplicity > Reversibility.

---

## Re-design rationale (post-original-impl)

The first design accepted historical-marker entries (`<!-- Completed: ... -->`, `<!-- Removed: ... -->`, `<!-- Coalesced: ... -->`, `<!-- Reason: ... -->`) as a valid `kind` in BACKLOG, and `retire` produced one. The user rejected the marker model: BACKLOG holds active items only; CHANGELOG holds history; `retire` actually moves entries.

This redesign:
- **drops** all marker classifications from the parser (`marker_completed`, `marker_removed`, `marker_coalesced`, `marker_reason`, `struckthrough_completed`, `struckthrough_tick`)
- **drops** `make_completed_marker` and `insert_changelog_bullet` from the library API
- **adds** a `### Retired Backlog Items` insertion algorithm and a `retire` flow that deletes the BACKLOG entry and appends a `#### <title>` block under the implementing task in CHANGELOG
- **tightens** the validator: BACKLOG-004 (any HTML comment in BACKLOG) and BACKLOG-005 (any struck-through heading) — neither is permitted post-migration
- **adds** CHANGELOG-003 (subsection order: Changes → Notable → Retired)

---

## Key Decisions

### Decision 1: Module split (unchanged from original)

- **`backlog-manager`** (script, `.cwf/scripts/command-helpers/backlog-manager`, perms `0500`) — argument parsing, subcommand dispatch via inline hash table, exit codes, `[CWF] ERROR:` formatting. Thin orchestration only.
- **`CWF::Backlog`** (library, `.cwf/lib/CWF/Backlog.pm`) — file parsers, in-memory data model, writers, validators. All logic the script can't do in 5 lines.

**Rationale**: matches `cwf-claude-settings-merge` + `CWF::ArtefactHelpers` split. Library is unit-testable with `require` from `t/`.

### Decision 2: Slug algorithm — extract to `CWF::Common` (already done)

`generate_slug` already lives in `CWF::Common` and is shared between `template-copier-v2.1` and `backlog-manager` (lifted in the original f-implementation-exec; survives the redesign unchanged). POD comment in `CWF::Common::generate_slug` flags the shared ownership.

### Decision 3: Parser model — two-pass over byte-preserving entry list

The BACKLOG.md parser is the load-bearing piece.

**Pass 1 — Split into entries.** Walk the file line by line. Maintain a `$current_entry` accumulator (array of lines) and an `$in_fence` boolean. On `^```` the boolean toggles. **Only when `$in_fence == 0`** does a line matching `^---$` exactly close `$current_entry`, push to `@entries`, and start a new one. The separator line is associated with the **previous** entry as its `trailing_separator` flag, so writing back round-trips perfectly. Fence-tracking handles BACKLOG bodies that include code blocks containing `---` lines.

**Pass 2 — Classify each entry.**

| Pattern (first non-blank line)       | `kind`            |
|--------------------------------------|-------------------|
| `^# Backlog` or `^# Changelog`       | `intro`           |
| `^## Task: ` or `^## Bug: `          | `active`          |
| `^## Task <N>:` (CHANGELOG only)     | `changelog_task`  |
| All blank                            | `blank`           |
| Anything else                        | `unknown`         |

**Markers and struck-through headings classify as `unknown`** — the validator (BACKLOG-004 / BACKLOG-005) flags them, and the helper never produces them.

**No eager metadata parsing.** Metadata extracted on-demand by `entry_metadata`, `entry_title`. Subcommands that don't read metadata (`validate` for some rules, `delete`, `retire` for the BACKLOG side) treat entries as opaque structs.

**Metadata block syntax** (parsed on-demand): the contiguous run of `^\*\*([A-Z][\w- ]+)\*\*:\s*(.*?)\s*$` lines starting **immediately after** the header's blank line. The block ends at the first blank line OR the first line that doesn't match the field regex. Trailing whitespace in values is trimmed.

### Decision 4: Data model — minimal byte-preserving struct

```perl
{
    kind               => 'active',     # active | intro | changelog_task | blank | unknown
    raw_lines          => [ '## Task: Title', '', '**Task-Type**: chore', ... ],
    trailing_separator => 1,            # was followed by `^---$`?
}
```

Title, metadata, and body computed on-demand:

```perl
sub entry_title($entry);                    # returns "Title" from header line
sub entry_metadata($entry);                 # returns hashref of metadata block
sub entry_body_start_index($entry);         # raw_lines index where body starts
sub entry_body_lines($entry);               # convenience: raw_lines slice from body start
```

**Round-trip property**: writer concatenates `raw_lines` + `'---'` (if `trailing_separator`) for each entry. Untouched entries are byte-identical.

### Decision 5: Library API and error handling

Library dies on input/state failure with `[CWF] ERROR: <prog>: <message>\n`; script catches via `eval` and translates to documented exit codes.

```perl
# parsers / writers
sub parse_backlog_file($path);              # → arrayref of Entry hashrefs
sub parse_changelog_file($path);            # → arrayref of Entry hashrefs (with active = changelog_task)
sub write_backlog_file($path, $entries);    # atomic_write_text under the hood
sub write_changelog_file($path, $entries);

# validators (return error arrayrefs; do NOT die on validation issues)
sub validate_backlog($entries);             # → [{ file, line, message }, ...]
sub validate_changelog($entries);

# lookup
sub find_active_by_slug($entries, $slug);   # → ($entry, @collisions)
sub find_active_by_title($entries, $title);

# accessors
sub entry_title($entry);
sub entry_metadata($entry);
sub entry_body_start_index($entry);
sub entry_body_lines($entry);

# mutators (CHANGELOG-side, used by retire)
sub find_changelog_task($entries, $task_num);     # → entry hashref or undef
sub find_retired_subsection($entry);              # → ($start, $end) line indices, or undef
sub block_exists_in_retired($entry, $title);      # → bool (case-insensitive title match)
sub append_retired_block($entry, $title, $body_lines, $note);  # mutates raw_lines in place

# mutators (BACKLOG-side, used by add/modify/delete)
sub set_priority_field($entry, $value);           # mutates raw_lines
sub set_metadata_field($entry, $name, $value);    # mutates raw_lines (creates if missing in metadata block)
```

`make_completed_marker` and `insert_changelog_bullet` (from the original impl) are removed — they're unused after the redesign.

```perl
sub main {
    my $rc = eval {
        my $sub = shift @ARGV // die "[CWF] ERROR: backlog-manager: missing subcommand\n";
        my %dispatch = (validate => \&cmd_validate, list => \&cmd_list,
                        add => \&cmd_add, modify => \&cmd_modify,
                        delete => \&cmd_delete, retire => \&cmd_retire);
        my $handler = $dispatch{$sub} // die "[CWF] ERROR: backlog-manager: unknown subcommand '$sub'\n";
        return $handler->(parse_args(@ARGV));
    };
    if ($@) { warn $@; exit classify_exit_code($@); }
    exit ($rc // 0);
}
main() unless caller();
```

**Exit code classification**: messages with `path validation:` substring → 2; `internal:` → 3; default → 1.

### Decision 6: `retire`'s two-file atomic-write sequence

```
1. Read BACKLOG → @backlog_entries
2. Read CHANGELOG → @changelog_entries
3. Find target active BACKLOG entry by slug (or --exact-title).
   - Missing: INFO message ("not found in BACKLOG (already retired?)"); exit 0.
   - Ambiguous: ERROR; exit 1.
4. Find Task <N> CHANGELOG entry via find_changelog_task.
   - Missing: ERROR ("Task <N> has no CHANGELOG entry; create the entry first
     or pick a different --task"); exit 1.
5. Build the new CHANGELOG block lines:
     [ "#### <title>", "", <body lines verbatim from BACKLOG entry>, "" ]
   plus, if --note given:
     [ "<!-- Note: <note-text> -->", "" ]
6. Dedup: parse Task <N>'s body to locate the `### Retired Backlog Items` subsection.
   Subsection bounds: starts at the `^### Retired Backlog Items` line; ends at the next
   `^### ` heading or end-of-entry. Within those bounds, scan for `^#### ` lines —
   tracking code-fence state (toggle on `^```` lines) and only counting headings outside
   fences. Title comparison is case-insensitive and whitespace-stripped. If a match is
   found, skip CHANGELOG mutation; $need_changelog_write = 0. (BACKLOG-006 prevents
   `^#### ` lines from appearing in BACKLOG entry bodies, so the body-content false-positive
   case is already ruled out by validation upstream.)
7. Otherwise mutate @changelog_entries:
   - If `### Retired Backlog Items` exists, append the block at the section's end
     (before the next `### ` heading or end-of-entry).
   - If absent, create the section at the position dictated by CHANGELOG-003 ordering
     (see Decision 7).
   $need_changelog_write = 1.
8. Mutate @backlog_entries: drop the target entry from the list (and remove the
   target's trailing_separator side-effect: if the target had trailing_separator=1
   and was not the last entry, the previous entry's trailing_separator stays as-is —
   the previous entry's separator was already there, target's separator is what's
   removed). $need_backlog_write = 1.
9. Symlink defence: refuse if `-l BACKLOG.md` or `-l CHANGELOG.md`. Hard-coded
   repo paths; check is belt-and-braces against pre-created symlink attacks.
10. atomic_write_text(CHANGELOG) if $need_changelog_write.
11. atomic_write_text(BACKLOG)  if $need_backlog_write.
```

**Write order rationale (CHANGELOG before BACKLOG)**: a crash between steps 10 and 11 leaves CHANGELOG with the new block and BACKLOG with the entry still active. Re-running `retire` cleanly completes via dedup (skip step 10) + step 11. The reverse order would leave "BACKLOG-deleted but CHANGELOG-not-updated" — the original entry is gone with no record.

**No file lock is taken** — concurrent writers are not part of the threat model (single-developer maintenance helper).

### Decision 7: `### Retired Backlog Items` subsection insertion algorithm

When `retire` needs to create the subsection (it doesn't exist yet under Task <N>):

1. Within Task <N>'s entry body, locate insertion point per CHANGELOG-003 ordering:
   - Immediately **after** `### Notable` if present (after the section's last non-blank line, before the next `### ` or end-of-entry).
   - Else immediately after `### Changes`.
   - Else immediately after the metadata block (the line right after the last `^\*\*Field\*\*:` line). Any blank lines that follow the metadata block are part of the body and stay where they are; the new subsection is inserted *before* them. This keeps spacing stable for entries with bare metadata + no body and for entries with multiple trailing blanks.
2. Insert:
   ```
   <blank>
   ### Retired Backlog Items
   <blank>
   #### <title>
   <blank>
   <body lines verbatim>
   <blank>
   <!-- Note: <text> -->     ← if --note given
   <blank>
   ```
3. Dedup re-check: not needed at this branch (we only reach here if step 6 found no existing subsection).

When the subsection already exists, append the new `#### <title>` block at its end (before the next `### ` heading or end-of-entry).

**Trade-off**: bullet/block order is append-only (newest at the bottom of the subsection). The user can re-order manually if preferred.

### Decision 8: Argument parsing — minimal hand-rolled (unchanged)

```perl
sub parse_args {
    my @args = @_;
    my %opts;
    for my $arg (@args) {
        if    ($arg =~ /^--([\w-]+)=(.*)$/s) { $opts{$1} = $2; }
        elsif ($arg =~ /^--([\w-]+)$/)       { $opts{$1} = 1; }
        elsif ($arg eq '-h' || $arg eq '--help') { $opts{help} = 1; }
        else { die "[CWF] ERROR: backlog-manager: unknown argument '$arg'\n"; }
    }
    return %opts;
}
```

No `Getopt::Long`. Booleans are bare; values use `--key=value`.

### Decision 9: `list` rendering — soft-cap algorithm

Priority bands: `('Very High', 'High', 'Medium', 'Low', 'Very Low')`.

```perl
sub cmd_list {
    my %opts = @_;
    my @actives = grep { $_->{kind} eq 'active' } @{ parse_backlog_file($BACKLOG_PATH) };
    my %by_band;
    push @{ $by_band{ priority_canonical($_) } }, $_ for @actives;

    my @bands = ('Very High', 'High', 'Medium', 'Low', 'Very Low');
    my @output;
    my $shown = 0;
    for my $band (@bands) {
        my @entries = @{ $by_band{$band} || [] };
        next unless @entries;

        if ($opts{'all-items'}) {
            push @output, render_band($band, \@entries);
            $shown += @entries;
        }
        elsif ($shown == 0 && @entries > 20) {
            # Top-most populated band has >20 — show whole band, stop.
            push @output, render_band($band, \@entries);
            $shown += @entries;
            last;
        }
        elsif ($shown + @entries <= 20) {
            push @output, render_band($band, \@entries);
            $shown += @entries;
        }
        else {
            my $remaining = 20 - $shown;
            push @output, render_band($band, [ @entries[0 .. $remaining - 1] ]);
            $shown = 20;
            last;
        }
    }
    print join("\n", @output), "\n";
    return 0;
}
```

**Soft-cap invariant**: never split a band UNLESS we already showed entries from a higher band. The "don't split" rule applies only to the topmost-populated band.

`priority_canonical($entry)` strips parenthetical annotations (`Low (downgraded post-Task-119)` → `Low`) for grouping.

**Within-band sort order**: file order. Stable across runs.

### Decision 10: Validator failure output format

`validate` errors carry `{file, line, message}`. Default mode (fail-fast): print first error as `[CWF] ERROR: <file>:<line>: <message>` to STDERR; exit 1. `--all` mode: print every error; exit 1 if any.

### Decision 11: Validator rules — checks performed

- **BACKLOG-001**: every active entry has `**Task-Type**:` and `**Priority**:` in its metadata block.
- **BACKLOG-002**: `**Priority**:` value matches `^(?:Very High|High|Medium|Low|Very Low)(?:\s*\(.*\))?$` (parenthetical permitted). `Needs-Triage` and any other value fail.
- **BACKLOG-003**: no body line in any active entry matches `^---$` exactly.
- **BACKLOG-004**: no HTML comments anywhere in the file. Detection: any line containing `<!--` or `-->` outside a code fence. Catches all four marker variants plus any future `<!--` patterns.
- **BACKLOG-005**: no struck-through entry headings. Detection: `^## ~~Task:`, `^## ✓ Task:`, or any `^##` line containing `~~`.
- **BACKLOG-006**: no `^#### ` lines in active entry bodies. The `#### <title>` syntax is reserved for retired-block headings inside CHANGELOG's `### Retired Backlog Items` subsection; allowing it in BACKLOG bodies would (a) survive the verbatim copy into CHANGELOG and (b) confuse the dedup scanner. Users wanting emphasis can use `**Header**:` instead.
- **CHANGELOG-001**: top-level `^# Changelog` header present exactly once.
- **CHANGELOG-002**: every `^## Task <N>:` entry has both `**Status**:` and `**Impact**:` fields.
- **CHANGELOG-003**: subsection order Changes → Notable → Retired (when present). Implementation: walk each entry's body, collect the order of `^### (Changes|Notable|Retired Backlog Items)` lines, assert canonical order.
- **GLOBAL-001**: no BOM, no CRLF endings, valid UTF-8.

### Decision 12: Threat-model coverage (CWF FR4 categories)

| Category | Coverage |
|----------|----------|
| (a) Bash injection | N/A — no shell-out. Hand-rolled arg parser; all file IO via Perl core. |
| (b) Perl git output without `-z` | N/A — helper does not invoke git. |
| (c) Prompt-injection-style content escape | Mitigated. `add`/`modify` reject body lines matching `^---$` (separator collision) and lines matching `^#### ` (BACKLOG-006). `retire` rejects `--note` containing `-->`, embedded newlines, or any non-printable-ASCII character (regex `/[^\x20-\x7E]/` — covers CR, LF, NULL, BOM, control chars). `validate` flags HTML comments in BACKLOG (BACKLOG-004) — defence in depth. |
| (d) Unsafe env vars | N/A — helper reads no env vars. |
| (e) Pattern-based risks | Identified. `generate_slug` is shared between `template-copier-v2.1` and `backlog-manager`; future modifications must preserve idempotency across both contexts. POD comment in `CWF::Common::generate_slug` flags this shared ownership. |
| Symlink attack on hard-coded paths | Mitigated. Pre-write `-l $path` check on BACKLOG.md and CHANGELOG.md (Decision 6 step 9). |
| Path traversal via `--body-file` | Mitigated. `validate_path_allowlist` from `CWF::ArtefactHelpers`. Note: that helper does NOT canonicalise symlinks; out-of-scope for this task. Already on the BACKLOG as a follow-up ("Resolve symlinks in validate_path_allowlist", added during the original h-rollout). |

---

## System Design

### Component overview

| Component                                        | Lines (est.) | Responsibility |
|--------------------------------------------------|--------------|----------------|
| `backlog-manager` (script)                       | ~450         | Argument parsing, subcommand dispatch, exit code translation, top-level help, six `cmd_*` handlers |
| `CWF::Backlog` (library)                         | ~500         | File parsers, Entry data model, validators, writers, find-by-id, mutators (BACKLOG and CHANGELOG sides) |
| `CWF::Common::generate_slug` (already extracted) | ~15          | Slug derivation, shared with `template-copier-v2.1` |
| `t/backlog-manager.t`                            | ~270         | End-to-end tests for all six subcommands + edge cases |
| `t/backlog.t`                                    | ~160         | Unit tests for parser/writer round-trip, classifier, validators, mutators |

**Re-design impact**: f-implementation-exec amends the existing `CWF::Backlog.pm` and `backlog-manager` from the original pass; it does not rewrite from scratch. Net change is a reduction in code (marker classifications and `make_completed_marker` removed; new `append_retired_block` and CHANGELOG-side find/mutate added).

### Data flow — `retire` (the most interesting case)

```
CLI args → parse_args() → cmd_retire() →
  parse_backlog_file()  → @backlog_entries
  parse_changelog_file() → @changelog_entries
  find_active_by_slug(@backlog_entries, $slug)
    or exit 0 (already retired) / exit 1 (ambiguous)
  find_changelog_task(@changelog_entries, $task_num)
    or exit 1 (no implementing-task entry)
  block_exists_in_retired($task_entry, $title)
    → if true, $need_changelog_write = 0
    → else append_retired_block($task_entry, $title, $body, $note)
  drop target from @backlog_entries
  symlink defence on both paths
  write_changelog_file() [atomic, if needed]
  write_backlog_file()   [atomic]
  exit 0
```

### File layout

```
.cwf/
├── lib/
│   └── CWF/
│       ├── Backlog.pm        ← MODIFIED (drop marker classifications, add CHANGELOG mutators)
│       └── Common.pm         ← UNCHANGED (already has generate_slug)
├── scripts/
│   └── command-helpers/
│       └── backlog-manager   ← MODIFIED (rewrite cmd_retire, drop --reason / --changelog-bullet)
└── security/
    └── script-hashes.json    ← MODIFIED (refresh hashes for backlog-manager and CWF::Backlog)

t/
├── backlog-manager.t              ← MODIFIED (replace marker-era ACs with new ones)
└── backlog.t                      ← MODIFIED (drop marker classification tests, add new validator tests)

BACKLOG.md                         ← MODIFIED (h-rollout: 61 marker lines removed)
```

### Test fixtures

`t/fixtures/backlog-manager/` with subdirectories per scenario (most generated inline by `make_isolated()` rather than committed):

- `current/` — copy of the post-migration BACKLOG.md / CHANGELOG.md (AC1)
- `malformed-priority/` — entry with `**Priority**: Needs-Triage` (AC2 / BACKLOG-002)
- `body-with-separator/` — entry with body containing `^---$` (AC2 / BACKLOG-003)
- `with-html-comment/` — entry with stray `<!-- ... -->` line in BACKLOG (AC2 / BACKLOG-004)
- `struck-through-heading/` — entry with `## ~~Task: …~~` heading (AC2 / BACKLOG-005)
- `out-of-order-subsections/` — CHANGELOG entry with `### Notable` before `### Changes` (AC2 / CHANGELOG-003)
- `slug-collision/` — two entries that produce the same slug (AC10)
- `crash-recovery/` — pre-staged BACKLOG-active + CHANGELOG-already-has-block (AC15)
- `retire-with-note/` — minimal pair for AC13
- `retire-no-changelog-entry/` — BACKLOG entry to retire under a Task <N> with no CHANGELOG entry (AC14)

---

## Constraints
- Perl 5.14+, core modules only. `JSON::PP`, `File::Temp`, `Encode`, `FindBin`, `Cwd`.
- `use strict; use warnings; use utf8;` mandatory.
- File reads via `open(my $fh, '<:encoding(UTF-8)', $path)`; writes via `atomic_write_text`.
- Validator rejects BOM-prefixed files and CRLF (GLOBAL-001).
- All flags `--key=value` form; booleans bare.

---

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ concerns? No — single concern.
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Parts that can be worked on separately? No.

No decomposition warranted.

---

## Validation
- [ ] Design produces a parser/writer that round-trips the post-migration BACKLOG.md / CHANGELOG.md byte-for-byte.
- [ ] All 17 acceptance criteria from b-requirements have a clear implementation path.
- [ ] No new dependencies beyond `CWF::ArtefactHelpers` and `CWF::Common` (both existing).
- [ ] Threat-model concerns addressed by input validation at the CLI boundary (no defensive parsing on the writer side).

---

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

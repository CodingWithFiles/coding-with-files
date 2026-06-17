# Fix normalise wrapped-field stranding - Design
**Task**: 208 (bugfix)

## Task Reference
- **Task ID**: internal-208
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/208-fix-normalise-wrapped-field-stranding
- **Template Version**: 2.1

## Goal
Define the design for making `backlog-manager normalise` fold hard-wrapped legacy
`**Field**:` values into a single canonical `### Field: value`, with no orphaned
continuation prose.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Root-Cause Recap (grounded in code)
- `_canonicalise_entry_inplace` (`backlog-manager:525-548`) walks `body_raw` **one
  physical line at a time**. The promotion regex
  `/^\*\*(KEY)\*\*:[ \t]*(.*?)\s*\z/` captures only the matched line's tail as the
  value; continuation lines don't match `^\*\*`, fall through to `push @new_body`,
  and are stranded under the new heading.
- `body_raw` is a list of physical lines, each retaining its trailing `\n` (parser
  `_parse_tree`, `Backlog.pm:224`). Legacy `**Field**:` lines land in `body_raw`
  because they are not H3 headings; legitimate body prose also lives there.

## Key Decisions

### KD1 — Fold continuations with an index-driven walk
- **Decision**: Replace the per-line `for` loop with an index-driven walk. On a
  `**Field**:` match, consume following lines into the value until a **terminator**:
  the next `**Field**:` line, a blank line, a `^---$` separator, or end-of-body.
  Continuation lines are right-trimmed and joined with a single space, producing one
  logical value for `### Field: value`.
- **Rationale**: Canonical metadata is single-line (`_serialize_entry`,
  `Backlog.pm:350`), so collapsing a hard-wrap to one logical line is the correct
  target form. An index walk is the minimal change that lets promotion consume more
  than one line.
- **Trade-offs**: Slightly more code than the one-liner regex; the terminator set is
  the load-bearing correctness surface (covered by fixtures, KD3).

### KD2 — Terminator set (boundary contract)
A folded value ends immediately before the first of:
1. a line matching `^\*\*(KEY)\*\*:` (next field),
2. a blank/whitespace-only line (paragraph break — separates metadata from body),
3. a `^---\r?\n?$` separator line,
4. end of `body_raw`.
Terminator lines are **not** consumed into the value; blank lines and `---` retain
their existing handling (blank → body/trim; `---` → dropped). This preserves the
existing single-line and body-prose behaviour exactly — only multi-line values change.

**Trim contract (robustness F3).** The single-line canonical form
(`_serialize_entry` emits `### $key: $value\n`) requires the assembled value to carry
**no embedded `\n`**. So: the seed (captured tail of the `**Field**:` line) is taken
via the existing `(.*?)\s*\z` (newline already stripped); each consumed continuation
is right-trimmed of trailing whitespace **including its `\n`** before being appended
with a single leading space. The final value is thus one physical line, matching the
idempotency requirement.

**Seed-empty case (improvements F4).** A field whose value begins on the next physical
line (`**Field**:\n  value …`) yields an empty seed. Appending the first continuation
with a leading space would emit `### Field:  value` (double space). The fold must
treat an empty seed specially: the first continuation becomes the value head with no
leading space. Covered by a KD3 fixture row.

### KD2a — Scope of behaviours NOT changed (robustness F1/F2)
- **Mid-body field hoisting is pre-existing, in scope, unchanged.** `_serialize_entry`
  always emits all `metadata` before `body_raw`, so a legacy field sitting *below*
  body prose is hoisted into the metadata block on normalise. This already happens
  today (the AC18 fixture's `**Identified in**:` sits after body prose and AC18b
  accepts the hoist). The fold does not alter this; the KD3 fixture asserts the
  hoisted-metadata-then-body order as the intended outcome, not incidental output.
- **Paragraph-valued metadata (blank line *inside* a value) is explicitly out of
  scope.** A blank line is an unconditional terminator (KD2.2), so a value authored as
  two blank-separated paragraphs folds only its first paragraph; the remainder stays
  body prose. This is intended: canonical metadata values are single logical lines,
  never multi-paragraph. Named here so it is a documented boundary, not a silent gap.

### KD3 — Regression fixture is the real safety net
- **Decision**: Add a legacy fixture exercising the fold boundaries, asserting
  (a) a value wrapped across ≥2 physical lines appears whole in one `### Field:`
  heading, (b) no continuation fragment survives in the body, (c) idempotent re-run is
  byte-identical. Fixture rows cover each KD2 terminator and KD2 edge:
  - wrapped value terminated by **next `**Field**:`**;
  - wrapped value terminated by a **blank line** then genuine body prose (prose must
    survive intact, hoisted below the metadata block per KD2a);
  - wrapped value terminated by **`---`**;
  - wrapped value terminated by **end-of-entry**;
  - **seed-empty** field (`**Field**:\n  value`) → `### Field: value`, single space.
- **Rationale**: This failure is a *placement* defect; a targeted fixture is what
  actually pins it.

### KD3a — Why idempotency holds (robustness F4)
After the first normalise, a folded field is `### Field: value` (an H3 heading). The
parser (`_parse_tree`) routes H3 metadata into the `metadata` array, **not** into
`body_raw`. `_canonicalise_entry_inplace`'s fold loop only ever inspects `body_raw`
lines matching `^\*\*…`, so it never re-touches an already-promoted field — the fold
is a fixed point. KD3(c) asserts this empirically.

### KD4 — Drop the proposed "AC5d metadata-byte" guard (deviation from a-plan SC#2)
- **Decision**: Do **not** add a pre/post metadata-value byte comparison to AC5d.
- **Rationale**: The bug is misplacement, not loss — whole-entry bytes are conserved,
  which is why AC5d never fired (correctly). The plan/forwarded analysis proposed
  comparing *metadata-value* bytes pre/post. But pre-normalise, legacy fields live in
  `body_raw` and the metadata array is **empty** (verified against `_parse_tree` and
  the `t/` legacy fixtures), so "pre metadata-value bytes" ≈ 0 for every legacy entry.
  A 0→N comparison can only ever grow, so it never trips — it cannot detect
  misplacement. Misplacement is a *placement* property; the only non-circular detector
  is the correct fold itself plus KD3's fixture. Adding a byte heuristic that cannot
  catch the named failure class is guard theatre ("the best part is no part").
- **Trade-offs**: SC#2 in `a-task-plan.md` is superseded; updated there to "fold is
  correct + fixture proves it; AC5d unchanged". Flag for plan review and user sign-off.

## System Design
### Touch Points
- **`_canonicalise_entry_inplace`** (`backlog-manager`): index-walk fold (KD1/KD2).
  Subsection handling (`---` strip) unchanged — legacy metadata only appears at entry
  top level, never inside subsections.
- **`t/backlog-manager.t`**: new wrapped-field subtest under the AC18 block (KD3).
- **`.cwf/security/script-hashes.json`**: refresh `backlog-manager` hash in the same
  commit as the edit (hash-update convention).
- **Unchanged**: `_entry_byte_count`, AC5a/b/c/d gates, `_canonicalise_intro`,
  `serialize_tree`, parser.

### Data Flow (fold)
1. Walk `body_raw` by index `i`.
2. Line `i` matches `**Field**:` → seed value from its captured tail.
3. While line `i+1` is **not** a terminator (KD2), right-trim it, append with a single
   leading space, advance `i`.
4. Push the assembled `{key,value}` to `metadata`; `next`.
5. Non-field lines: existing behaviour (`---` dropped, else kept in `@new_body`).

## Interface Design
No CLI/interface change. `normalise [--dry-run]` signature, exit codes, and the AC5a–d
gate contract are unchanged. Behaviour change is confined to multi-line legacy values.

## Constraints
- Perl core-only; `use utf8;`; `#!/usr/bin/env perl`.
- Must remain idempotent on canonical input and byte-identical on re-run.
- Single-line fields and legitimate body prose must be untouched (regression-guarded).
- Hash refresh shares the implementation commit.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one fold + one fixture.
- [ ] **Risk**: high-risk components needing isolation? No.
- [ ] **Independence**: separable parts? No.

No signals → single task.

## Validation
- [ ] Plan review (Step 8) completed
- [ ] KD4 deviation (drop AC5d byte guard) accepted by user
- [ ] Terminator set (KD2) covers field/blank/`---`/EOF boundaries in fixtures

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

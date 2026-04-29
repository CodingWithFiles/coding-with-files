# Reject Overlong Task Slugs - Design
**Task**: 119 (feature)

## Task Reference
- **Task ID**: internal-119
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/119-reject-overlong-task-slugs
- **Template Version**: 2.1

## Goal
Architecture for the slug-length rejection feature: where the validation lives, how the error is emitted, what changes in the script's existing `generate_slug` / `parse_parameters` flow, and how the skill stops pre-truncating.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Decision 1 — Validation lives in the script, not the skill
- **Decision**: All slug-length validation is implemented in `.cwf/scripts/command-helpers/template-copier-v2.1`. The SKILL.md files for `/cwf-new-task` and `/cwf-new-subtask` instruct the LLM to pass the full `--description` and **not** pre-construct `--destination` (so the script's `construct_destination` runs and `generate_slug` produces the full slug). Skills do no length checking themselves.
- **Rationale**: A single source of truth. The script is reachable from any caller (skill, CI, manual invocation) and was the silently-truncating site to begin with. The skill is just one possible caller; pre-truncation in the skill would defeat the rejection goal (the very behaviour we observed during Task 118 dispatch).
- **Trade-offs**: The skill becomes thinner — relies on the script for correctness. Acceptable; mirrors the cwf-manage / die_msg pattern already used elsewhere in CWF.

### Decision 2 — Validate before any state change (atomicity)
- **Decision**: Validation runs inside `parse_parameters`, immediately after required-parameter checks, **before** `construct_destination` is called and well before `make_path` (line 423) creates the destination directory or any template file is copied.
- **Rationale**: NFR2 requires atomic failure. Today's `parse_parameters` already errors out cleanly for invalid args (exit 1, no filesystem writes). Putting the slug-length check in the same place inherits that atomicity for free. Validating later (e.g. inside `construct_destination`) would still work but couples concerns.
- **Trade-offs**: None of consequence. The check is O(1).

### Decision 3 — Use `die_msg(...)` helper, matching `cwf-manage`
- **Decision**: Add a `die_msg` helper to `template-copier-v2.1` that writes `[CWF] ERROR: <msg>\n` to STDERR and exits 1. Use it for the new validation. Existing `print STDERR "Error: ..."` + `exit N` blocks are out of scope (boy-scout would balloon the diff and is covered by a separate audit task).
- **Rationale**: Consistency — the existing `cwf-manage` `die_msg` (line 38) is the project's error convention. The Tasks 115/116 unit-test pattern (`*main::die_msg = sub { die "..." }` symbol-table override, eval{} catch) only works if `die_msg` is the single named sub. Inlining the format would prevent unit-testing.
- **Trade-offs**: Adds one new helper. Acceptable.

### Decision 4 — `generate_slug` no longer truncates; new check via `length()`
- **Decision**: Remove the trailing `substr($description, 0, 50)` from `generate_slug` (line 168). The function returns the full slug. A new check `length($slug) > SLUG_MAX_LEN` triggers `die_msg`.
- **Rationale**: Truncation is the bug we're fixing — leaving it in as defensive code creates a second silent-truncation path. Removing it makes `generate_slug` honest (it does what the name says: lowercase, replace, collapse).
- **Trade-offs**: Any caller that relied on `generate_slug` returning a bounded-length string is now exposed to longer values. The only caller in the codebase is `construct_destination` (line 183), which is the validated path. Verified by grep.

### Decision 5 — Limit lives as a script-level `use constant`
- **Decision**: `use constant SLUG_MAX_LEN => 50;` near the top of `template-copier-v2.1`, after `use` statements and before the first `sub`. Use `SLUG_MAX_LEN` in both the validation check and the error message string.
- **Rationale**: Named constant for maintainability (NFR3); single source of truth for FR3. `use constant` is the idiomatic Perl form and is already familiar from other CWF scripts.
- **Trade-offs**: Minor — `use constant` does not interpolate inside double-quoted strings without `()` invocation. Easy to handle with `SLUG_MAX_LEN()` in error messages or pre-computed in a `my $limit = SLUG_MAX_LEN;` local.

### Decision 6 — Single validation point: description-derived slug
- **Decision**: Validation derives one slug from `$params{description}` (always required, enforced by existing parse_parameters) and checks its length. Reject if `length($slug) > SLUG_MAX_LEN` **or** if `length($slug) == 0` (description stripped to nothing — e.g. all special chars). No separate validation of the `--destination` basename.
- **Rationale**: `--description` is a required parameter that's always present. If a caller (skill, CI, manual invocation) passes a pre-truncated `--destination` alongside `--description`, the description's full-length slug still gets validated and fails first — the destination is never reached. So a single check on the description-derived slug covers FR1 (overlong rejected) and FR1.5 (`--destination` bypass): the destination can't be silently used because the description gets validated first. Empty-slug case is a separate hazard: `generate_slug("!!!")` returns `""`, which currently passes the `>50` guard and would create absurd paths like `1-feature-`. One check, two reject conditions.
- **Trade-offs**: Drops an earlier-draft "validate destination basename too" defensive check. Accepted because no current caller exercises that path and the description check fires first anyway. If a future caller starts passing `--destination` without `--description`, the existing `parse_parameters` required-param error fires; we never reach a state where length validation matters but description is absent.

### Decision 7 — Character semantics: Perl codepoints (consistent with existing code)
- **Decision**: The 50-char limit is measured by Perl `length()` on the slug after `lc` + character-class filtering, which is per-codepoint. This matches the existing `substr($description, 0, 50)` semantics; no change to what "50 chars" means.
- **Rationale**: The existing `generate_slug` already strips non-`[a-z0-9 -]` via the regex at line 159, so multibyte chars get filtered out before the length check. In practice the slug is always ASCII. Locking in codepoints rather than bytes/graphemes preserves backwards compatibility for descriptions that previously fit just under 50.
- **Trade-offs**: None observable — non-ASCII descriptions already get stripped, so byte vs codepoint vs grapheme is moot for the input domain.

## System Design

### Component Overview
- **`template-copier-v2.1` (modified)**: Adds `SLUG_MAX_LEN` constant, `die_msg` helper, slug-length validation in `parse_parameters`. `generate_slug` simplified (no truncation).
- **`.claude/skills/cwf-new-task/SKILL.md` (modified)**: Step 2 ("Generate Slug and Directory Path") rewritten — LLM no longer truncates or pre-constructs `--destination`; passes `--description` raw and lets the script construct the path and validate length.
- **`.claude/skills/cwf-new-subtask/SKILL.md` (modified)**: Same change as cwf-new-task; removes the implicit reference to the old "truncate 50 chars" rule.
- **`t/template-copier-slug-validation.t` (new)**: Unit tests using `*main::die_msg` override (Tasks 115/116 pattern).
- **`.cwf/security/script-hashes.json` (modified)**: Refreshed `template-copier-v2.1` sha256 (any script change cascades to hashes per existing CWF convention).

### Data Flow
```
1. User invokes /cwf-new-task "long description that is too long..."
2. Skill (LLM) parses args, calls:
     task-workflow create --task-type=T --task-num=N --description="<full description>"
3. task-workflow execs template-copier-v2.1 with same args
4. parse_parameters validates required args, calls generate_slug(description), and
   checks slug length:
     - length($slug) > SLUG_MAX_LEN  → die_msg(overlong) → STDERR [CWF] ERROR: …, exit 1
     - length($slug) == 0            → die_msg(empty)    → STDERR [CWF] ERROR: …, exit 1
   No filesystem writes have happened at this point.
5. (If valid) construct_destination, copy_templates proceed normally
```

### Interface — error message format
Two cases, both prefixed `[CWF] ERROR:` (matches `cwf-manage` `die_msg` convention) and written to STDERR. Final wording finalised at impl time; templates:

```
[CWF] ERROR: Task slug 'error-on-overlong-slugs-instead-of-silent-truncation' is 52 characters; limit is 50. Use a briefer task description (try fewer or shorter words).

[CWF] ERROR: Task description '!!!' produces an empty slug after normalising. Use a description that contains at least one alphanumeric character.
```

This satisfies FR2: includes the offending slug (or description), actual length, the 50-char limit, and a recovery instruction. The empty-slug message includes the original description (since the slug itself is empty and unhelpful to display).

### Interface — script changes summary

Order of additions inside `template-copier-v2.1` (after existing `use` statements, before any constants — matches the `cwf-manage` helper-then-constant ordering):

```perl
# After the existing use-statement block, before any constants/subs:
sub die_msg {
    print STDERR "[CWF] ERROR: @_\n";
    exit 1;
}

use constant SLUG_MAX_LEN => 50;

# In parse_parameters, immediately after required-param checks, before any
# destination construction or filesystem work:
my $slug = generate_slug($params{description});
my $slug_len = length($slug);
if ($slug_len == 0) {
    die_msg("Task description '$params{description}' produces an empty slug after normalising. "
          . "Use a description that contains at least one alphanumeric character.");
}
if ($slug_len > SLUG_MAX_LEN) {
    my $limit = SLUG_MAX_LEN;
    die_msg("Task slug '$slug' is $slug_len characters; limit is $limit. "
          . "Use a briefer task description (try fewer or shorter words).");
}

# In generate_slug: remove the substr($description, 0, 50) at line 168;
# function returns the full slug.
```

(Pseudocode is illustrative — final wording in implementation.)

## Constraints
- The change must keep all current exit codes for unrelated error paths (no behavioural shift in existing failures)
- `template-copier-v2.0` is **not** modified — confirmed during planning that only v2.1 is wired through `task-workflow.d/create`
- The unit test must use the `*main::die_msg` override pattern from Tasks 115/116 to remain consistent with the existing test suite
- `.cwf/security/script-hashes.json` must be refreshed after the script change; this is mandatory for `cwf-manage validate` to pass

## Decomposition Check
- [ ] **Time**: <1 day → no decomposition
- [ ] **People**: 1 person → no decomposition
- [ ] **Complexity**: 1 contained concern (one script + 2 SKILL files + 1 test) → no decomposition
- [ ] **Risk**: low → no decomposition
- [ ] **Independence**: unitary → no decomposition

No signals triggered.

## Validation
- [ ] Design covers all FRs (FR1-FR5) and all NFRs from b-requirements-plan.md — verified by mapping decisions to requirements
- [ ] No new dependencies; uses existing Perl features (`use constant`, `length`)
- [ ] Test pattern aligns with Tasks 115/116 (`*main::die_msg` override + `eval`)
- [ ] Edge case: empty slug after normalising (description = "!!!") rejected with a distinct error, not silently accepted

## Notes (post plan-review)
- **Dropped**: an earlier draft validated the slug component of `--destination` separately. Plan-review (Improvements F1) flagged this as over-engineering: `--description` is always required, the description-derived slug is checked first, and the destination is never reached when the description fails. Single check is sufficient.
- **Added**: empty-slug rejection (Robustness F2). Without this, a description of all special characters slugifies to `""` (length 0), passes the `>50` guard, and creates a path like `1-feature-`. Treated as a separate die_msg case with a distinct recovery message.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 119
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Architecture executed as designed: validation in `parse_parameters`, single named constant `SLUG_MAX_LEN`, shared `die_msg` helper-then-constant ordering, two distinct die_msg paths for empty / overlong slugs, non-truncating `generate_slug` with leading/trailing hyphen strip. Decision 6 (single description-derived check) held up — the destination-basename validation drafted earlier would have been pure duplication, as confirmed during exec. Decision 5's `use constant` interpolation footnote was relevant (the `$limit` local was used as guarded against, then inlined to `. SLUG_MAX_LEN .` during /simplify).

## Lessons Learned
See j-retrospective.md.

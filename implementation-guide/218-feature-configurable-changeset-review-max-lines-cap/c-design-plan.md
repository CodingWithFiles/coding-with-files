# Configurable changeset-review max-lines cap - Design
**Task**: 218 (feature)

## Task Reference
- **Task ID**: internal-218
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/218-configurable-changeset-review-max-lines-cap
- **Template Version**: 2.1

## Goal
Design the config-read + precedence resolution that lets `security.review.max-lines`
set the changeset-review cap, resolving `CLI // config // 500`.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### D1 — Default moves from 500 to unset; resolve after CLI validation
- **Decision**: Change `%opt` line 135 from `max_lines => 500` to `max_lines => undef`.
  Keep the existing CLI-validation block (lines 167-171) unchanged — it validates
  `--max-lines` only `if (defined …)`, staying **fatal (exit 1)** on an invalid CLI
  value. Immediately after that block, resolve the effective cap:
  ```perl
  # Effective cap: CLI flag (validated above) > config key > built-in default.
  $opt{max_lines} = config_max_lines() // $DEFAULT_MAX_LINES
      unless defined $opt{max_lines};
  ```
  with a file-scoped `my $DEFAULT_MAX_LINES = 500;` constant, reused by the resolver
  and the interpolating `print_usage` POD heredoc (`<<"USAGE"`). Note the plain-`#`
  header banner (lines 29-33) cannot interpolate, so its "defaults to 500" prose stays
  a hand-maintained literal — the constant is the source for the two live-code sites,
  not for that comment (robustness F3).
- **Rationale**: Moving the default to unset is the only way to distinguish "flag
  absent" from "flag explicitly 500" (robustness finding / FR2 AC). Resolving *after*
  the existing validation keeps CLI-invalid fatal while letting config-invalid degrade.
- **Trade-offs**: One extra line of resolution; the `defined` guard at line 168 now
  also guards "CLI absent" (skips validation when no flag) — correct, because an
  absent flag needs no validation and the config path validates independently.

### D2 — New `config_max_lines()` sub mirrors `max_lines_exclude_paths()`
- **Decision**: Add a sub structurally parallel to the existing
  `max_lines_exclude_paths()` (lines 533-559): eval-guarded `CWF::Versioning::read_config`,
  defensive `ref … eq 'HASH'` navigation down `security.review`, read the `max-lines`
  scalar, validate, return an integer or `undef`.
  ```perl
  sub config_max_lines {
      my $cfg = eval { require CWF::Versioning; CWF::Versioning::read_config(); };
      return undef unless $cfg && ref $cfg eq 'HASH';
      my $sec = $cfg->{security};      return undef unless ref $sec    eq 'HASH';
      my $review = $sec->{review};     return undef unless ref $review eq 'HASH';
      my $v = $review->{'max-lines'};
      return undef unless defined $v;      # missing key / JSON null → "not configured", silent default
      if (ref $v || "$v" !~ /^[1-9]\d*$/) {   # bool/array/object ref, OR non-integer scalar
          warn "$PROG: warning: 'security.review.max-lines' is not a positive "
             . "integer; using built-in default\n";   # reuse the CLI positive-integer contract
          return undef;
      }
      return "$v" + 0;
  }
  ```
  **Surface, never smooth (robustness F1):** an unambiguous typo — a JSON boolean
  (`true` → blessed `JSON::PP::Boolean` ref), array, object, or a non-integer scalar
  — **warns** (naming the key only) before degrading. Only a missing key or JSON
  `null` ("not configured") is silent, because absence is not a typo. This satisfies
  FR3's "malformed value emits a warning" AC rather than degrading silently.
- **Rationale**: Consistency with the sibling key's reader (NFR3, "no new config
  machinery"). Every non-`undef`-returning path is fail-safe: absent/malformed → the
  caller's `// $DEFAULT_MAX_LINES`. A JSON number and a numeric string both stringify
  and match `^[1-9]\d*$` (FR3 JSON-scalar AC); arrays/objects/booleans are `ref`s and
  fall through; `null` is `undef`. The warning names the **key only** — no path or
  config contents echoed (best-practice finding).
- **Trade-offs**: `config_max_lines()` and `max_lines_exclude_paths()` share the
  `security.review` navigation. Two call sites only → Rule of Three says do **not**
  extract a shared `review_config()` helper yet; parallel structure is clearer than a
  premature abstraction. Revisit if a third `security.review.*` reader appears.
- **Perf note (robustness F2):** `CWF::Versioning::read_config` is not memoised, so
  `config_max_lines()` is a *second* full open+`decode_json` of the config per run
  (the sibling reader already does one). Accepted under correctness > maintainability
  > performance; the file is small and the read is once-per-invocation. NFR1's
  "config already read once" is superseded by this note.

### D3 — Fail-safe direction, no upper bound
- **Decision**: The resolver never returns a value larger than what config/CLI
  literally states; ambiguity always collapses to the stricter 500. No upper bound is
  imposed on a *valid* value.
- **Rationale**: FR3 / NFR4. Up-sizing is a deliberate, reviewed maintainer choice
  (`cwf-project.json` is in-repo and part of the changeset the gate itself reviews);
  the gate blocks (exit 2) rather than bypasses when exceeded, so a raised cap widens
  what is reviewed, it does not skip review.

## System Design
### Component Overview
- **Arg parse (lines 135-171)**: default→unset (D1); CLI validation unchanged (fatal).
- **Cap resolver (new, ~3 lines after line 171)**: `CLI // config // 500` (D1).
- **`config_max_lines()` (new sub)**: defensive config read + validation (D2).
- **`$DEFAULT_MAX_LINES` constant**: single source for `500`, used by resolver + docs.
- **Docs**: header comment (lines 29-33), `print_usage`/POD (lines 313-343), and
  `.cwf/docs/skills/security-review.md` gain the new key beside `max-lines-exclude-paths`.
- **Config**: `implementation-guide/cwf-project.json` gains `security.review.max-lines: 1000`.
  Raising *this* repo's live gate from 500 to 1000 is intentional dogfooding (the
  originating request): it gives headroom for legitimately larger CWF changesets while
  still blocking (exit 2) beyond 1000, and exercises the config-read path in situ.
  `1000` is a round doubling of the default, not a measured threshold.
- **Hash**: `.cwf/security/script-hashes.json` entry for `security-review-changeset`
  refreshed in the same commit (hash-updates convention).

### Data Flow
1. `@ARGV` parsed → `$opt{max_lines}` is the CLI value or `undef`.
2. If defined and malformed → **exit 1** (unchanged CLI contract).
3. If undef → `config_max_lines()` reads `security.review.max-lines`; valid → integer,
   else (`undef` + optional warning) → `$DEFAULT_MAX_LINES` (500).
4. `$opt{max_lines}` now always a positive integer → existing cap check at line 301
   (`$production > $opt{max_lines}` → exit 2) is unchanged.

## Interface Design
### Config key
```
security:
  review:
    max-lines: 1000                 # NEW — positive integer; absent → 500
    max-lines-exclude-paths: [ … ]  # existing sibling
```
### CLI (unchanged)
- `--max-lines=N` still overrides everything; invalid value still exits 1.

## Constraints
- Perl core-only, `use utf8;`, UTF-8 I/O.
- Hashed file → same-commit hash refresh.
- No change to exit-code contract (0/1/2) or the `--max-lines` CLI surface.

## Decomposition Check
- [x] Time / People / Complexity / Risk / Independence — none triggered. Single unit.

## Validation
- [x] Design review completed (map/reduce, phase c)
- [ ] Architecture approved (user reviews before exec)
- [x] Integration points verified (read_config, cap check, usage/POD, hash, config)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All design decisions implemented as specified: D1 (`CLI // config // 500` resolver),
D2 (no shared `review_config()` helper — Rule of Three not met at two call sites),
D3 (in-repo-only config source, self-referential boundary documented), and the
single-sourced `$DEFAULT_MAX_LINES` constant with a literal header banner (F3).

## Lessons Learned
D2's decline-to-abstract call proved right: the second config reader
(`config_max_lines`) shares only the eval-guarded `read_config` entry with its
sibling — extracting a wrapper would have hidden the per-key validation that differs
between them. Duplication of two lines beat a leaky abstraction.

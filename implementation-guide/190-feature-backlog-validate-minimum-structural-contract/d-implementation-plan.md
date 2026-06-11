# backlog validate minimum structural contract - Implementation Plan
**Task**: 190 (feature)

## Task Reference
- **Task ID**: internal-190
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/190-backlog-validate-minimum-structural-contract
- **Template Version**: 2.1

## Goal
Implement backlog validate minimum structural contract following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes (hash-tracked — see Hash/Perms Discipline below)
- `.cwf/lib/CWF/Backlog.pm` — add `backlog_structure_errors($tree,$path)`; export it; call it from
  `validate_backlog_tree`; POD note. (Module: sha256-only, perms stay `0600`.)
- `.cwf/scripts/command-helpers/backlog-manager` — import `backlog_structure_errors`; add a local
  gate `assert_backlog_structure($tree,$path)` (calls predicate, `die_user` on non-empty); invoke it
  in `cmd_add`/`cmd_modify`/`cmd_delete`/`cmd_retire` between parse and any write. (Perms stay `0500`.)

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh sha256 for the two files **in the same commit**.
- `t/backlog-tree-validate.t` — `BACKLOG-000` per-rule positive/negative unit cases.
- `t/backlog-manager.t` — mutation-gate cases (refuse on foreign; byte-unchanged; retire two-file).
- `.cwf/docs/skills/reference/cwf-backlog-manager.md` — document the structural contract + `BACKLOG-000`.
- BACKLOG.md (rollout): retire the seed item (`48b12c6`); file the KD5 CHANGELOG-parity follow-up and
  the residual-limitation items (fence-masking, headerless-legacy) via `backlog-manager add`.

## Implementation Steps
### Step 1: Predicate in `CWF::Backlog` (TDD — test first)
- [ ] Add failing `BACKLOG-000` cases to `t/backlog-tree-validate.t` (foreign `## ` heading; foreign
      list item; empty/intro-only clean; live-file-shaped clean; fenced-heading silent).
- [ ] Implement `backlog_structure_errors($tree, $path //= 'BACKLOG.md')`:
      ```perl
      my ($lines, $fence) = _file_lines_and_fence($tree);   # assumes a parse-sourced tree:
                                                            # line numbers are source-based
      my $hi = @{$tree->{entries}} ? $tree->{entries}[0]{header_lineno} - 2 : $#$lines;
      # First non-blank, non-fenced line in the intro range — only there is a leading H1 exempt.
      my $first = -1;
      for my $i (0 .. $hi) {
          next if $fence->[$i] || $lines->[$i] =~ /^[ \t]*\n?\z/;   # blank: matches
          $first = $i; last;                                       # trim_blank_lines (Backlog.pm:208)
      }
      my @errs;
      for my $i (0 .. $hi) {
          next if $fence->[$i];
          my $l = $lines->[$i];
          next if $l =~ /^[ \t]*\n?\z/;                  # blank
          next if $i == $first && $l =~ /^#[ \t]/;       # one leading single-'#' H1 allowed
          my $kind = $l =~ /^#{1,6}[ \t]/             ? 'heading'
                   : $l =~ /^[ \t]*([-*+]|\d+[.)])[ \t]/ ? 'list item'
                   : undef;
          next unless defined $kind;
          push @errs, { file=>$path, line=>$i+1, rule=>'BACKLOG-000', severity=>'error',
                        message=>"BACKLOG.md preamble contains an unmanaged $kind at line "
                                ."${\($i+1)}; CWF tracks entries as '## Task: <title>' / "
                                ."'## Bug: <title>' blocks and does not manage other top-level "
                                ."structure. See .cwf/docs/skills/reference/cwf-backlog-manager.md." };
      }
      return \@errs;
      ```
      Notes (per review): the H1 exemption regex `/^#[ \t]/` matches the same whitespace class as the
      heading classifier (so a tab-delimited `#\tTitle` is exempted, not flagged); the blank-line
      regex is kept in lockstep with `trim_blank_lines` (`Backlog.pm:208`); the predicate assumes a
      parse-sourced tree at all call sites (line numbers are source, pre-canonicalisation).
- [ ] Append `@{ backlog_structure_errors($tree, $path) }` to `validate_backlog_tree`'s error list.
- [ ] Add `backlog_structure_errors` to `@EXPORT_OK` (after `validate_changelog_tree`, line ~52).
- [ ] POD: one line under the rules section noting `BACKLOG-000` (structural/manageability).

### Step 2: Mutation gate in `backlog-manager`
- [ ] Import `backlog_structure_errors` in the `use CWF::Backlog qw(...)` list.
- [ ] Add `sub assert_backlog_structure { my ($tree,$path)=@_; my $e = backlog_structure_errors($tree,$path);
      die_user($e->[0]{message}) if @$e; }`.
- [ ] `cmd_add`: insert `assert_backlog_structure($tree,$bl_path)` between `parse_backlog_tree` (:338)
      and `add_entry`/`write_tree` (:339-340).
- [ ] `cmd_modify` (:383) and `cmd_delete` (:410): same — gate immediately after their parse, before
      mutate/write.
- [ ] `cmd_retire`: gate immediately after the BACKLOG parse (:448) and **before** the CHANGELOG
      bootstrap (:466-468), so a refusal writes neither file.
- [ ] **Fifth touchpoint (per review):** `validate_backlog_tree` is also called by `_normalise_one`
      (`backlog-manager:616`) as its post-canonicalisation gate, so `BACKLOG-000` now runs there too.
      KD4 holds (a heading-bearing legacy file parses to real entries → `BACKLOG-000` silent), but it
      must be verified, not assumed — see Step 4 corpus check. No code change at `:616`; named so the
      interaction is not a surprise.

### Step 3: Hash + perms refresh (same commit)
- [ ] Restore on-disk perms to recorded: `Backlog.pm` → `0600`, `backlog-manager` → `0500` (not 0700).
- [ ] Refresh `.cwf/security/script-hashes.json` sha256 for both files per
      `.cwf/docs/conventions/hash-updates.md` (per-file `git log` verification first); stage in the
      same commit as the edits.
- [ ] `cwf-manage validate` clean.

### Step 4: Tests + docs
- [ ] Mutation-gate cases in `t/backlog-manager.t` (Step-2 behaviour, two-file retire abort).
- [ ] `normalise` on the heading-bearing legacy fixture (`t/backlog-manager.t:882`) still passes
      `validate` post-canonicalisation (confirms the `_normalise_one` 5th touchpoint stays silent — KD4).
- [ ] Pin the accepted **unterminated-leading-fence** boundary as an explicit test (foreign content
      masked by an unclosed ```` ``` ```` passes silently), so a future fence-map change can't shift the
      contract unnoticed.
- [ ] Full `prove -lr t/` green; AC4 corpus check (live `BACKLOG.md` + all fixtures unchanged).
- [ ] Update `.cwf/docs/skills/reference/cwf-backlog-manager.md`.

### Step 5: Validation
- [ ] All ACs (AC1–AC8) demonstrated; output-level smoke test (foreign file → fails; empty → clean).

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Hash/Perms Discipline (plan-time disclosure)
Both primary files are hash-tracked (`.cwf/security/script-hashes.json:54,208`). Per
`.cwf/docs/conventions/hash-updates.md`, their sha256 entries MUST be refreshed in the **same commit**
as the edits, after a per-file `git log` check. `Backlog.pm` has **no `permissions` key** (lib module →
`0600`/`100644`); `backlog-manager` is `permissions: 0500` — restore to the **recorded** value after
editing, never a bumped `0700`. No new hashed files are added.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

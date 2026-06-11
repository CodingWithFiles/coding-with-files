# backlog validate minimum structural contract - Testing Plan
**Task**: 190 (feature)

## Task Reference
- **Task ID**: internal-190
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/190-backlog-validate-minimum-structural-contract
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for backlog validate minimum structural contract.

## Test Strategy
### Test Levels
- **Unit (predicate)**: `BACKLOG-000` positive/negative cases in `t/backlog-tree-validate.t`,
  driving `validate_backlog_tree` directly against inline fixtures (the established pattern in that
  file).
- **Integration (mutation gate)**: subcommand-level cases in `t/backlog-manager.t` — `add`/`modify`/
  `delete`/`retire` against foreign vs conformant files, asserting exit code, refusal message, and
  byte-unchanged files (two-file for `retire`).
- **Regression (corpus)**: full `prove -lr t/` plus `cwf-manage validate` to prove zero false
  positives on the live `BACKLOG.md` and every existing fixture (AC4).
- **System smoke**: drive the real `backlog-manager` binary on a temp foreign file and a temp empty
  file (output-level check, per the "rebrands need output-level smoke-test" lesson).

### Test Coverage Targets
- **Critical path (the predicate + gate)**: 100% of branches — each KD2 construct class (heading,
  list item, leading-H1 exemption, blank, fenced-skip) and both intro-range branches (entries
  present vs zero entries).
- **Every AC (AC1–AC8)** has at least one mapped test case below.
- **Regression**: all existing `t/` cases and `cwf-manage validate` remain green.

## Test Cases
### Functional — predicate (`BACKLOG-000`, unit)
- **TC-1 (AC1) foreign heading**: *Given* `"## Sprint 1\n\n- item\n"` (zero entries) *When*
  `validate_backlog_tree` *Then* ≥1 `BACKLOG-000` error; foreign `## ` heading reported.
- **TC-2 (AC1) foreign list**: *Given* `"# My Backlog\n\n- buy milk\n- fix bug\n"` *When* validate
  *Then* `BACKLOG-000` fires on the first list item (line 3); leading H1 itself does **not** fire.
- **TC-3 (AC2) empty/whitespace**: *Given* `""` and `"\n\n"` *When* validate *Then* no `BACKLOG-000`.
- **TC-4 (AC2/AC5) intro-only conformant**: *Given* `"# Backlog\n\nIntro paragraph.\n"` *When*
  validate *Then* no `BACKLOG-000` (H1 + prose permitted).
- **TC-5 (AC4) live-file shape**: *Given* a fixture mirroring the live file (title + prose intro,
  then real `## Task:` entries whose **bodies** contain `## ` headings) *When* validate *Then* no
  `BACKLOG-000` (body `## ` not scanned — intro-only).
- **TC-6 (AC3) legacy heading-bearing**: *Given* the existing legacy fixture (`t/backlog-manager.t:882`,
  `## Task:` headings + `**Field**:` bodies) *When* validate *Then* no `BACKLOG-000` (parses to real
  entries; routes to `normalise` via the unrelated `BACKLOG-001`, unchanged).
- **TC-7 (AC7) message content**: *Given* a foreign file *When* validate *Then* the message names the
  construct kind (`heading`/`list item`) + line number + the doc reference, and contains **no**
  verbatim copy of the offending line text.
- **TC-8 (boundary) fenced heading silent**: *Given* a `## Task:`-bearing file whose body has a
  `## ` inside a closed ```` ``` ```` fence *When* validate *Then* no `BACKLOG-000` from the fenced line.
- **TC-9 (boundary, accepted) unterminated leading fence**: *Given* a foreign file opening with an
  unclosed ```` ``` ```` then headings/lists *When* validate *Then* no `BACKLOG-000` — pins the
  documented accepted limitation so a future fence-map change can't silently alter the contract.
- **TC-10 (edge) tab-delimited H1**: *Given* `"#\tBacklog\n\nprose\n"` *When* validate *Then* no
  `BACKLOG-000` (H1 exemption matches the heading classifier's whitespace class).

### Functional — mutation gate (integration)
- **TC-11 (AC6) add refuses on foreign**: *Given* a foreign `BACKLOG.md` *When* `backlog-manager add …`
  *Then* exit 1, refusal message, file **byte-identical** to before.
- **TC-12 (AC6) modify/delete refuse on foreign**: same assertion for `modify` and `delete`.
- **TC-13 (AC6) retire two-file abort**: *Given* a foreign `BACKLOG.md` and an existing `CHANGELOG.md`
  *When* `backlog-manager retire …` *Then* exit 1 and **both** files byte-identical (gate precedes the
  CHANGELOG bootstrap).
- **TC-14 (AC3/AC6) add succeeds on conformant**: *Given* the live-shape conformant file *When* `add`
  *Then* exit 0, entry appended (gate does not over-refuse).
- **TC-15 (5th touchpoint) normalise on legacy**: *Given* the heading-bearing legacy fixture *When*
  `backlog-manager normalise` *Then* succeeds and the post-canonicalisation `validate` is `BACKLOG-000`-clean
  (confirms `_normalise_one:616` interaction — KD4).

### Non-Functional
- **Security (AC7/NFR4)**: TC-7 doubles as the prompt-injection check (no foreign content echoed);
  confirm `GLOBAL-*` checks still fire on a BOM/CRLF foreign file (no weakening). Both exec-phase
  security reviews expected `no findings` (pure predicate, no I/O/shell/env).
- **Performance (NFR1)**: no second file read / fence rebuild — assert by construction (predicate uses
  `_file_lines_and_fence`); no benchmark needed.
- **Reliability (NFR5)**: TC-11–13 assert byte-unchanged refusal (no partial writes).
- **Regression (AC4)**: `prove -lr t/` fully green; `cwf-manage validate` clean (incl. refreshed
  hashes for the two edited `.cwf` files).

## Test Environment
### Setup Requirements
- Perl core + `Test::More` (existing harness); inline string fixtures as in `t/backlog-tree-validate.t`.
- Mutation-gate cases write to a **temp dir** (`File::Temp`), never the repo `BACKLOG.md`/`CHANGELOG.md`
  (test-DB-equivalent isolation rule). Byte-unchanged assertions compare pre/post file digests.
- No network, no external services.

### Automation
- `prove -lr t/` is the runner; the new cases live in `t/backlog-tree-validate.t` and `t/backlog-manager.t`.
- `cwf-manage validate` run after the hash refresh as the integrity gate.

## Validation Criteria
- [ ] TC-1…TC-15 all pass.
- [ ] AC1–AC8 each demonstrably covered (mapping above).
- [ ] `prove -lr t/` green (no regressions); `cwf-manage validate` clean.
- [ ] Output-level smoke test: real binary fails on a temp foreign file, clean on a temp empty file.
- [ ] Both exec-phase security reviews: `no findings`.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

# security-review cap weights production over tests - Testing Plan
**Task**: 168 (chore)

## Task Reference
- **Task ID**: internal-168
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/168-security-review-cap-weight-production-code
- **Template Version**: 2.1

## Goal
Validate that `security-review-changeset --max-lines=N` caps on a production-weighted
line count (test/scaffolding lines excluded), that the exit-2 contract behaves, and
that existing helper behaviour is unregressed.

## Test Strategy
### Test Levels
- **Unit / functional (automated)**: new subtests in `t/security-review-changeset.t`,
  run via `prove -v t/security-review-changeset.t`. Each builds a synthetic git repo
  via the existing `make_synthetic_repo` and drives the helper via `run_helper`
  (returns `($stdout, $stderr, $rc)`).
- **Integration (manual / output-level)**: the two exec SKILL Step-8 blocks are
  LLM-executed prose — not unit-testable. Validated by re-reading the rewritten text
  for unambiguous exit-code branching, plus an end-to-end smoke run of the helper with
  `--max-lines` on a real task-shaped diff.
- **Regression**: full existing suite (14 subtests) must stay green, with explicit
  attention to the strict end-anchored assertion at `:559`.

### Test Coverage Targets
- **Critical paths (100%)**: production-count computation, the `P > N` cap boundary,
  the three exit codes (0/1/2), and `--max-lines` argument validation.
- **Edge cases**: test-only diff, mixed diff, binary files, absent `--max-lines`,
  `--max-lines=0` / leading-zero.
- **Regression**: all pre-existing TC-F*/TC-NF*/TC-Task141 subtests pass unchanged.

## Test Cases
### Functional Test Cases (new automated subtests)

- **TC-CAP1**: production-only diff exceeds the cap
  - **Given**: a synthetic repo whose only change is a CWF-internal script with > N
    added lines; no `security.review.test-paths` configured.
  - **When**: `run_helper(--max-lines=N)` with N below that line count.
  - **Then**: `$rc == 2`; stderr matches `cap exceeded: \d+ production lines > N`;
    stdout still contains the diff.

- **TC-CAP2**: task-166 shape — small production + large test diff stays under cap
  - **Given**: a repo with `security.review.test-paths: ["t/**"]` in `cwf-project.json`,
    a modest CWF-internal change (~production lines < N) plus a large `t/…​.t` addition
    that, combined, would exceed N on a raw line count.
  - **When**: `run_helper(--max-lines=N)`.
  - **Then**: `$rc == 0`; the subagent path is not short-circuited; stderr `(P production)`
    reflects only the non-test lines (P < N), confirming git's `:(glob,exclude)` excluded
    the `t/` diff.

- **TC-CAP3**: back-compat — no `--max-lines` never caps
  - **Given**: a production-only diff far exceeding any plausible cap.
  - **When**: `run_helper()` with no `--max-lines`.
  - **Then**: `$rc == 0`; no `cap exceeded` on stderr (behaviour identical to today).

- **TC-CAP4**: production count excludes test + context/header lines
  - **Given**: a mixed diff (production change with surrounding context, plus a `t/`
    addition).
  - **When**: `run_helper(--max-lines=<large>)` (won't trip).
  - **Then**: stderr `(P production)` equals the added+deleted production lines only —
    not the larger raw `M lines` figure, confirming context/headers and test lines are
    excluded.

- **TC-CAP5**: `--max-lines` argument validation
  - **Given**: invalid values.
  - **When**: `run_helper(--max-lines=abc)`, `--max-lines=0`, `--max-lines=007`.
  - **Then**: each → `$rc == 1` with a usage/validation warning on stderr; no cap
    evaluation occurs.

- **TC-CAP6**: binary production file contributes 0 to the count
  - **Given**: a binary blob added under `.cwf/scripts/` (cf. existing TC-F4) and a
    small text production change.
  - **When**: `run_helper(--max-lines=<small but above the text change>)`.
  - **Then**: `$rc == 0` (binary `numstat` `-` rows counted as 0, not as huge).

- **TC-CAP7**: malformed `test-paths` pattern fails safe
  - **Given**: `security.review.test-paths: ["../escape"]` (git rejects as outside-repo
    pathspec) with a `--max-lines` set.
  - **When**: `run_helper(--max-lines=N)`.
  - **Then**: `$rc == 1` (git fatal → `capture_git` exits 1); no silent discount, no
    exit-0 "no findings". Confirms the safe fail direction for bad consumer config.

### Non-Functional Test Cases
- **Regression**: `prove t/security-review-changeset.t` — all 14 existing subtests
  pass; `:559` (strict `^…$` anchor) verified explicitly.
- **Reliability**: exit-2 path leaves stdout intact (manual reviewer can still see the
  diff); exit-1 path (e.g. unresolvable task) surfaces as a SKILL error block, not a
  silent "no findings".
- **Integrity**: `cwf-manage validate` clean after the hash refresh (modulo the
  pre-existing `install-manifest.json` 0444 finding, untouched by this task).
- **Usability**: helper `--help` / `print_usage()` documents `--max-lines`; SKILL
  Step-8 prose unambiguously instructs capture-and-branch on the exit code.

## Test Environment
### Setup Requirements
- Perl with `prove` (Test::More); core modules only (no CPAN deps).
- The existing test harness (`make_synthetic_repo`, `run_helper`, `git_in`) is reused;
  no new fixtures infrastructure needed.

### Automation
- `prove -v t/security-review-changeset.t` is the single automated entry point, runs
  under the same conditions as the rest of the CWF test corpus.

## Validation Criteria
- [ ] TC-CAP1–CAP7 pass.
- [ ] All 14 pre-existing subtests pass, incl. `:559`.
- [ ] `wc -l` absent from both exec SKILL Step 8 blocks; both branch on exit code.
- [ ] a-task-plan success criteria 1–4 demonstrably met.
- [ ] `cwf-manage validate` clean (bar the pre-existing manifest-perms finding).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 168
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-CAP1–7 all pass; 14 pre-existing subtests unchanged (21/21). See `g-testing-exec.md`.

## Lessons Learned
Committing the synthetic repo's `cwf-project.json` *before* the recorded baseline keeps it out of the diff window, so config under test never pollutes the production count. See `j-retrospective.md`.

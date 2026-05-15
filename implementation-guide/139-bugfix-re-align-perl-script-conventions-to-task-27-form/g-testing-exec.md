# re-align Perl-script conventions to Task-27 form - Testing Execution
**Task**: 139 (bugfix)

## Task Reference
- **Task ID**: internal-139
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/139-re-align-perl-script-conventions-to-task-27-form
- **Template Version**: 2.1

## Goal
Execute the 10 test cases from `e-testing-plan.md` and confirm the implementation behaves as specified.

## Environment
- Repo on branch `bugfix/139-…` at commit `0420a14` (Task 139 implementation-exec).
- `PERL5OPT=-CDSLA` set in `~/.claude/settings.json` env.
- UTF-8 locale active.
- All test cases run from the repo root.

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | Validator rejects hardcoded `-C` shebang on a non-capturing script (TC-U10) | 1 violation, field=shebang, expected='#!/usr/bin/env perl' | exactly that | **PASS** |
| TC-2 | Validator accepts env shebang on capturing script (TC-U9) | 0 violations | 0 | **PASS** |
| TC-3 | Validator flags missing `-z` regardless of shebang form (TC-U3, TC-U3b) | 1 violation, field=git_z; shebang absent | 1 git_z only | **PASS** |
| TC-4 | Validator flags missing `use utf8;` (TC-U2, TC-U2b) | 1 violation, field=use_utf8 | 1 use_utf8 | **PASS** |
| TC-5 | Grandfathered file bypasses `-z` but not shebang (TC-U7) | 0 shebang/git_z violations; use_utf8 if pragma missing | as expected | **PASS** |
| TC-6 | Mid-implementation `cwf-manage validate` reports exactly 12 SHA mismatches | 11 scripts + PerlConventions.pm; no other violation kinds | exactly 12; all sha256 field | **PASS** (recorded in f-implementation-exec.md Step 4) |
| TC-7 | `cwf-manage validate` reports OK after hash regen | exit 0, `[CWF] validate: OK` | as expected | **PASS** |
| TC-8 | `backlog-manager list` smoke test | exit 0; priority-grouped output | exit 0; "Very High (2), High (1), Medium (12), …" header structure as before | **PASS** |
| TC-9 | Task-137 mojibake non-regression: add with `→` arrow, delete | both exit 0; BACKLOG.md shows literal `→` between calls; `git status BACKLOG.md` clean after delete | as expected | **PASS** |
| TC-10 | Final repo-wide grep `perl-git-paths` and `-CDSL\b` outside frozen scope | zero hits | both grep exit 1 (zero hits) | **PASS** |

**Unit-test run**: `prove t/validate-perl-conventions.t` — 17 subtests pass (10 flipped + 5 unchanged + 2 new TC-U9/U10).

**Full suite**: `prove t/` — `Files=42, Tests=463, Result: PASS`.

### Non-Functional Tests

| Aspect | Result |
|--------|--------|
| Reliability | Hash splice done as a series of single-key Edit operations; pre-splice review caught no surprise entries; post-splice validate clean. |
| Security | Validator surface narrowed (one new universal rule replaces a capture-only one). `-z` enforcement preserved. Hash regen kept manual per surface-don't-smooth invariant. See f-implementation-exec.md § Security Review. |
| Portability | `env perl` shebang restored as the POSIX-portable form. No kernel-shebang-argv-parsing dependency. |
| Usability | Validator error messages now cite the specific doc (`perl.md` for shebang/utf8, `git-path-output.md` for `-z`). User-facing `check_perl5opt` warning now recommends `-CDSLA` (not the older `-CDSL`). |
| Performance | No measurable change. |

## Test Failures
None on final run.

**During implementation, two transient failures surfaced and were resolved**:

1. **`t/cwf-manage-fix-security.t`** — failed between the validator amendment and hash regen because the modified `PerlConventions.pm` no longer matched its recorded SHA. Resolved by Step 5 (hash regen). Documented in `f-implementation-exec.md` Step 3.

2. **`t/backlog-manager-argv-utf8.t`** — failed once the shebang revert landed because the test was designed around the Task-137 mechanism ("shebang carries the `-A` flag"). Task 139 moves that contract to `PERL5OPT`. The test's helper was updated from `run_bm_shebang_only` (deleted `PERL5OPT` from child env) to `run_bm_with_perl5opt` (sets `PERL5OPT=-CDSLA` in child env). Same assertions, new mechanism. Documented in `f-implementation-exec.md` Step 7.

Both fixes are committed in `0420a14`.

## Coverage Report
- `t/validate-perl-conventions.t`: every rule branch (shebang, use_utf8, git_z, grandfather) exercised by ≥1 positive and ≥1 negative subtest.
- TC-U9 (positive canonical) and TC-U10 (negative hardcoded) cover the new shebang rule.
- TC-U7 (grandfather) covers the post-Task-139 semantics: shebang still enforced, only `-z` exempted.
- Integration coverage via `cwf-manage validate` confirms the validator and hash registry agree on the live tree.
- End-to-end UTF-8 mojibake non-regression covered by `t/backlog-manager-argv-utf8.t` (using `PERL5OPT=-CDSLA` as the contract carrier).

## Validation Criteria from e-testing-plan.md
- [x] `prove t/` passes with all subtests, including the 10 flipped fixtures and the 2 new TCs.
- [x] `cwf-manage validate` reports OK after hash regen.
- [x] Smoke tests TC-8 and TC-9 pass.
- [x] Final repo-wide grep (TC-10) returns zero live hits.
- [x] All 6 success criteria from `a-task-plan.md` met (cross-checked in `f-implementation-exec.md`).

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

This changeset correctly refactors Perl conventions by moving Unicode I/O flags from the kernel shebang line to PERL5OPT environment configuration, with comprehensive validator and test coverage to prevent regression.

Per-category summary from the subagent:
- **(a) Bash injection**: no shell-invoked commands in the diff; safe patterns preserved.
- **(b) Perl helpers consuming git output without `-z`**: `-z` enforcement unchanged; validator still requires `-z` on path-emitting captures.
- **(c) Prompt injection**: no user-supplied strings flow into LLM context.
- **(d) Unsafe env-var handling**: PERL5OPT is now the enforcement point (`$ENV{PERL5OPT} = '-CDSLA'` in the test child env); explicit, not shell-interpolated.
- **(e) Pattern-based risks**: validator's positive-form check is defensive — any hardcoded `-C` shebang is rejected universally; reduces surface, doesn't widen it.

## Lessons Learned
*To be captured during retrospective*

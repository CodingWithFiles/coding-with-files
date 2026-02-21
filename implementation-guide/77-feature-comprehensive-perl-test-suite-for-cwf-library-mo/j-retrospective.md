# Comprehensive Perl Test Suite for CWF Library Modules - Retrospective
**Task**: 77 (feature)

## Task Reference
- **Task ID**: internal-77
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/77-comprehensive-perl-test-suite-for-cwf-library-mo
- **Template Version**: 2.1

## Summary

Task 77 established `prove t/` as the standard quality gate for all 17 CWF library
modules. Delivered in a single session with 157 tests across 17 files, running in
under 1 second.

## Variance Analysis

| Metric | Planned | Actual | Variance |
|--------|---------|--------|----------|
| Effort | 3–5 days | ~1 session | -80% (faster) |
| Test files | 17 | 17 | 0 |
| Tests | ~100 (implied) | 157 | +57% |
| Suite runtime | <30s | 0.9s | 97% better |
| CPAN dependencies | Risk of Test2::Suite | 0 (core only) | Risk eliminated |
| Git fixture approach | t/fixtures/ bare repo | CWFTest::Fixtures helper | Simpler |

## What Went Well

**Three-tier categorisation was the key insight.** Deciding upfront to classify all
17 modules as Tier A (pure), Tier B (filesystem), or Tier C (git) eliminated the
need for a complex shared git fixture. Most modules turned out to be Tier A or B,
making the test surface much smaller than anticipated.

**`correlate_signals` and `format_output` are pure functions.** The two most
testable subs in the most complex module (`TaskContextInference`) happened to be
pure — no git, no filesystem. This gave meaningful coverage of the hardest module
without any git fixture.

**Core Perl is sufficient.** `Test::More` + `File::Temp` + `Digest::SHA` covered
all testing needs. `Test2::Suite` was never needed.

**`CWFTest::Fixtures.pm` was the right abstraction.** Centralising `create_git_repo`
and `create_task_dir` prevented duplication and made Tier C tests consistent.

## What Could Be Improved

**`grep` in `ok()` is a recurring footgun.** Five separate instances of
`ok(grep { ... } @list, $msg)` were written before the bug was identified. The
message string gets included in grep's list, causing a hash-deref crash. This is
an easy mistake to make in Test::More. A project-specific note or a wrapper like
`has_match` would prevent this.

**Expected values need module verification.** Three `task-state.t` subtests had
wrong expected values (0 instead of 7/4/7) because Blocked=15% rather than 0%
was assumed. Always verify expected values against the actual module logic, not
intuition.

**`@EXPORT_OK` is not always complete.** `CWF::TaskPath::detect_format` and
`version_compare` are useful public functions not in `@EXPORT_OK`. Without checking
exports first, the test file imported them and got a runtime error. Check exports
before writing the import line.

## Key Learnings

1. **`ok((grep {...} @list), $msg)` — always use extra parens in grep-in-ok calls.**
   Without them, Perl passes the message string to grep's list, causing a hash-deref
   crash when the list element is a hashref.

2. **`qw()` cannot express multi-word strings.** `qw(In\ Progress)` creates two words.
   Use a regular list: `('In Progress', ...)`.

3. **Check `@EXPORT_OK` before writing `use_ok` import lists.** Importing a function
   not in `@EXPORT_OK` silently fails at import and causes a runtime error on first call.

4. **Verify expected values against module constants, not intuition.** Status percentages
   in `CWF::TaskState` are a configuration table — don't assume `Blocked = 0%`.

5. **Regex anchoring matters for format validation.** `CWF::Validate::Consistency` uses
   `^\*\*Task\*\*:` — the standard `- **Task**:` bullet format does not match. Test
   data must match the actual regex, not the human-readable convention.

## Recommendations

### Immediate

1. **Document `grep`-in-`ok` footgun in `t/lib/CWFTest/Fixtures.pm` or a test-conventions
   doc** so future contributors don't repeat it. The i-maintenance.md already covers it.

### Future Work (BACKLOG)

No new BACKLOG items from this task — the maintenance plan in i-maintenance.md covers
ongoing upkeep adequately.

## Process Improvements

**Coverage grows organically.** The per-task maintenance contract (update `.t` when
modifying `.pm`) is the right model. No CI integration needed for an offline tool.

**Tier classification should be in the test file header.** All new `.t` files should
start with a `# Tier A/B/C:` comment explaining why. This was done informally but
not consistently.

## Status
**Status**: Finished
**Next Action**: Merge to main
**Blockers**: None

## Actual Results
All 9 test cases from e-testing-plan.md passed. 157 tests across 17 files.
Suite runtime: 0.9s. Zero CPAN dependencies. `cwf-manage validate` unaffected.

## Lessons Learned
See "Key Learnings" section above. The four patterns to watch for in future test
files: grep-in-ok parens, qw multi-word, @EXPORT_OK gaps, Blocked status value.

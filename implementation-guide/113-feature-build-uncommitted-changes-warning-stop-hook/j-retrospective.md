# Build uncommitted changes warning Stop hook - Retrospective
**Task**: 113 (feature)

## Task Reference
- **Task ID**: internal-113
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/113-build-uncommitted-changes-warning-stop-hook
- **Template Version**: 2.1
- **Retrospective Date**: 2026-04-25

## Executive Summary
- **Estimated**: 1 session, Low complexity
- **Actual**: 1 session, 31-line Perl script, 13/14 tests pass (TC-8 conflict deferred to backlog)
- **Outcome**: Second Stop hook deployed alongside Task 104; new project convention codified for Perl + git path handling (`-CDSL` + `-z` + `use utf8;`).

## Variance Analysis

### Scope Changes
- **Added** (positive): Project conventions doc `docs/conventions/perl-git-paths.md` written during exec to capture the `-CDSL` / `-z` / `use utf8;` combination. Wasn't in original scope but emerged from user review during design and was reinforced by a real bug caught during smoke testing (double-encoded UTF-8 mojibake).
- **Added** (positive): One BACKLOG follow-up — "Add Conflict-State Regression Test for stop-uncommitted-changes-warning" (chore, Low). Captures the TC-8 deferral.
- **Changed mid-flight**: Detection strategy iterated three times during design review:
  1. Initial: `git status --porcelain` only — missed untracked-dir expansion
  2. Refined: added `-c core.quotepath=false` for non-ASCII
  3. Final: switched to `-z` after user pointed out the canonical mechanism — strictly more robust than `core.quotepath=false`
- **Mid-exec correction**: switched from JSON `⚠` escape to literal `⚠`, which surfaced a `-CDSL` ≠ source-encoding gotcha. Fixed with `use utf8;`. Conventions doc updated to capture the gotcha.

### Quality Metrics
- **Tests**: 13/14 pass (TC-8 deferred as stretch — parsing path verified by code inspection)
- **Defects**: 1 caught and fixed during smoke testing (double-encoded UTF-8)
- **Script size**: 31 lines (vs Task 104's 42 — smaller because no library import overhead and a simpler detection condition)

## What Went Well
- **Plan reviews caught real issues**: requirements review caught `settings.json` vs `settings.local.json`; design review caught the `core.quotepath=false` gap and rename-pathspec semantics; implementation review caught the `substr($_, 3)` vs basename interaction. Map/reduce reviewers earned their cost on this task.
- **Smoke testing caught the mojibake** before the hook went live — visible in `xxd` output (`c3 a2 c2 9a c2 a0` instead of `e2 9a a0`). Without the smoke test, the bug would have shipped and only been noticed when a user wondered why their reminders said `â  ` instead of `⚠`.
- **User review of design choices was high-leverage**: the `-z` correction and the request to make it a project convention (rather than a one-off fix) turned a minor detail into a permanent improvement.
- **Sibling Task 104 hook was an excellent reference**: keeping the parsing idiom (`m{([^/]+)$} ? $1 : $_`), capping logic, and exit-0 discipline parallel made the script trivial to reason about.

## What Could Be Improved
- **Project conventions for Perl helpers were never centralised before this task.** Three command-helper scripts already used `#!/usr/bin/perl -CDSL` but the convention was never documented. The first time someone wrote a hook (Task 104) they used a different shebang (`#!/usr/bin/env perl`) without realising they were diverging. A retrospective audit of CWF Perl helpers might find similar undocumented conventions.
- **The implementation plan duplicated guidance the design plan already covered** — basename idiom, exit-0 discipline, and capping logic were spelled out in both c- and d-files. A more skeletal d- referencing back to c- would have been cleaner; this echoes Task 104's same observation.
- **TC-8 (conflict state) deferred** because reproducing a real merge conflict is brittle. This is the second hook task to leave a corner of porcelain handling unverified end-to-end. A test fixture that synthesises porcelain output (or fabricates index entries via `git update-index --cacheinfo`) would have closed this gap cheaply. Captured in BACKLOG.

## Key Learnings
- **`-CDSL` ≠ `use utf8;`**: the `-C` flags govern I/O streams; the pragma governs source-file decoding. Both are required for non-ASCII literals to round-trip correctly. This is now in `docs/conventions/perl-git-paths.md`.
- **`-z` beats `core.quotepath=false`** for verbatim path output. `core.quotepath=false` only suppresses byte-class escaping for >0x80; quotes, backslashes, and control chars stay escaped. `-z` is unconditional. The `core.quotepath` man page even points readers at `-z`.
- **Plan reviewer agents catch real bugs at low cost.** Across all four plan phases (b/c/d), reviewers flagged ≥1 actionable defect each time. The cost is ~3 short subagent calls per plan; the value is catching wrong-file references, dead code, and mis-applied conventions before they hit implementation.

## Recommendations

### Future Work
- **Conflict-state regression test** (BACKLOG, Low priority) — already filed.
- **JSON encoder consolidation** (deferred to future hook): if a third Stop hook lands, switch from hand-rolled `qq()` to `JSON::PP` (core module) so encoding gets centralised. Two callers don't justify it yet (Rule of Three).
- **Audit existing CWF Perl helpers against the new conventions doc**: walk through `.cwf/scripts/command-helpers/` and any other Perl scripts to identify divergence (missing `-CDSL`, `-z`, `use utf8;`). Could be a chore-level cleanup task. Not adding to BACKLOG yet — let it surface organically when those scripts are touched.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge
**Blockers**: None
**Completion Date**: 2026-04-25

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

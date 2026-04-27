# Honour CWF_SOURCE env var in cwf-manage update - Retrospective
**Task**: 115 (bugfix)

## Task Reference
- **Task ID**: internal-115
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/115-honour-cwf-source-env-var-in-cwf-manage-update
- **Template Version**: 2.1
- **Retrospective Date**: 2026-04-27

## Executive Summary
- **Estimated**: 0.5 day, Low complexity
- **Actual**: 1 session, ~12 line `resolve_source` helper, two call sites updated, 6 unit subtests + 4 smokes, plus a boy-scout `-CDSL`/`use utf8;` fix for pre-existing em-dash mojibake
- **Outcome**: External-user upgrade pain point closed. `CWF_SOURCE` now overrides `cwf_source` in `.cwf/version` for `cwf-manage update` and `list-releases`, matching the convention `install.bash` already established. Two sibling pain points (dirty-tree handling, `cwf-project.json` version drift) filed in BACKLOG during a-task-plan.

## Variance Analysis

### Time and Effort
- **Estimated**: 0.5 day total
- **Actual**: ~1 session — slightly over because the boy-scout UTF-8 fix added a small detour. Net still well under a day.

### Scope Changes
- **Added (boy-scout)**: shebang change `#!/usr/bin/env perl` → `#!/usr/bin/perl -CDSL` and `use utf8;` in `cwf-manage`. Surfaced when a TC-9 smoke output included `c3a2 c280 c294` (double-encoded em-dash) under the user's `PERL5OPT=-CDSL`. Pre-existing bug, not introduced by this task — but exactly the kind of "leave the place better than you found it" the user pushed back on when I initially proposed deferring to a separate task. Trivially fixable while already in the file.
- **Added during a-task-plan**: two BACKLOG entries from the same external-user report — "Make cwf-manage update handle a dirty working tree" (bugfix, High) and "Resolve cwf-project.json version drift vs .cwf/version" (discovery, Medium). Filing these as siblings rather than expanding scope kept Task 115 single-concern.
- **Deferred (documented)**: `write_version_file` atomicity hardening — noted in c-design Decision 2 as out-of-scope. Not added to BACKLOG because the fix preserves the existing (non-atomic) behaviour rather than making it worse; will earn its own task if the failure mode shows up.

### Quality Metrics
- **Tests**: 6/6 unit subtests pass, 4/4 manual smokes pass (TC-7..TC-10), full `prove t/` 235/235 pass
- **Defects caught during exec**: 1 plan gap (test skeleton missed `use lib '.cwf/lib'`), 1 hallucinated cite in the d-impl-plan-review summary (referenced a `t/versioning.t` pattern that doesn't exist), and the em-dash mojibake under `-CDSL`. All fixed in-task.
- **Code surface**: 12-line helper, 2 call-site substitutions, 2 doc blocks, 1 hash bump, 1 test file. No new dependencies.

## What Went Well
- **Plan-review subagents earned their keep again** — design review caught the empty-string env-var trap (`||` vs `defined && ne ''`), the asymmetric two-line logging proposal, and pulled the error-message wording closer to existing `die_msg` style. /simplify also caught a fact error in the d-impl plan-review summary (a fabricated `t/versioning.t` cite) — small, but exactly the kind of drift that becomes load-bearing later.
- **TDD held the line on test framework friction**. The test file failed to *load* on first run (missing `use lib '.cwf/lib'`); writing the test first meant we discovered this *before* writing the helper, when fixing it cost one line. Had we written code first and tests later, the same friction would have arrived after we'd already grown emotionally attached to the helper.
- **TC-10 was load-bearing and validated structurally + empirically.** The non-persistence property follows from the structure of `cmd_update` (read %v → mutate only `cwf_version`/`ref`/`sha`/`installed` → write %v back), but a real run against a sentinel `cwf_source=https://example.com/SENTINEL` is what makes the property visible in the artifact. Catching the bug would still need a test; the test exists.
- **Boy-scout fix landed naturally** because the file was already in the diff. Pushed back appropriately when the agent's first instinct was to file a separate task — the user's "why are we doing a massive ceremony to do a very minor totally obvious fix while we're doing this work?" was the right correction.

## What Could Be Improved
- **The d-impl plan-review summary contained a hallucinated cite** (`t/versioning.t` allegedly using `*main::die_msg` override — file exists but doesn't use that pattern). The Misalignment subagent emitted it; I copied it verbatim into the plan-review summary in d-impl-plan.md without verifying. /simplify caught it, but not for the right reason (they thought the file didn't exist; it does, just doesn't match the claim). Lesson: when a subagent makes a specific claim about an existing file, grep before propagating.
- **`cwf-manage` was non-conformant with the project's own Perl convention** (`docs/conventions/perl-git-paths.md`) and nobody noticed until the em-dash mojibake surfaced under `PERL5OPT=-CDSL`. Task 113's retrospective already recommended "Audit existing CWF Perl helpers against the new conventions doc"; that audit hadn't happened. This task knocked off one script; the rest of `.cwf/scripts/cwf-manage`'s siblings remain unaudited.
- **The d-impl plan didn't list `.cwf/security/script-hashes.json` in "Files to Modify"** even though any change to a `.cwf/scripts/` script forces a hash update. Foreseeable; should be a checklist item in the d-impl-plan template (or in the conventions doc) so it doesn't surface as a "deviation" on every script-touching task.

## Key Learnings

### Technical
- **Returning origin label alongside the value** from `resolve_source` (a 2-element list rather than a string) eliminates branching at the call sites for logging. Single-line `(from: $origin)` log shape works in both modes with no `if env: ... else: ...` at the call site. Consistently better than the two-line "override notice" alternative the design originally sketched; the design review caught and corrected it.
- **`-CDSL` and `use utf8;` are independent gates.** `-C` controls I/O encoding (already mandated by the project convention); `use utf8;` controls source decoding. With one and not the other, ASCII works but any non-ASCII source literal double-encodes on output. The conventions doc spells this out; this task confirmed it on a real bug.
- **For env-var precedence, write `defined $env && $env ne ''`, not `$env || $file`.** The `||` form treats `0` and `'0'` as falsy and short-circuits to file — usually irrelevant for a URL but the wrong idiom anyway. The explicit form documents intent and is robust.

### Process
- **Boy-scout the file you're already in.** When the user already has the file open in their working set and the fix is one line, deferring is more ceremony than the fix is worth. The CWF "no workflow shortcuts" rule is about *substantive* changes earning their own task plan, not about every co-located fix.
- **Plan reviewers can confidently emit specific-but-wrong claims.** Treat any "see file X, lines Y-Z" claim from a subagent as something to verify, not something to incorporate. /simplify's third-pass review caught one such claim that the original Misalignment review introduced.

## Recommendations

### Process Improvements
- **Add `.cwf/security/script-hashes.json` to the d-impl-plan checklist** for any task touching a `.cwf/scripts/` script. Or wire it into `cwf-checkpoint-commit` as a pre-commit auto-bump (like an "rebase rebuild script-hashes" step). Stays out of "Files to Modify" lists otherwise.
- **Schedule the Perl-conventions audit** that Task 113's retrospective recommended. Two tasks now have boy-scouted single scripts; the rest of `.cwf/scripts/` and `.cwf-skills/` deserve a one-pass sweep against `docs/conventions/perl-git-paths.md`. Filing as a BACKLOG follow-up.

### Future Work
- **Audit Perl helpers against `docs/conventions/perl-git-paths.md`** (chore, Low–Medium). Filed in BACKLOG.
- **`write_version_file` atomicity** (deferred — noted in c-design Decision 2). Not filing yet; will earn a task if a real crash-during-update produces a mangled `.cwf/version`.
- **Two siblings already filed in BACKLOG during a-task-plan**: dirty-tree handling for `cwf-manage update` (bugfix, High) and `cwf-project.json` version drift (discovery, Medium). Both from the same external-user upgrade report.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge
**Blockers**: None
**Completion Date**: 2026-04-27

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

# Preserve template symlinks in cwf-manage - Retrospective
**Task**: 135 (bugfix)

## Task Reference
- **Task ID**: internal-135
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/135-preserve-template-symlinks-in-cwf-manage
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-13

## Executive Summary
- **Duration**: 1 session (estimated: 1-2 days; well within plan).
- **Scope**: Original scope (preserve symlinks in `copy_tree`, detect symlink-vs-file drift in `cmd_validate`) delivered intact. Three small additions surfaced and folded in: (a) a `_collapse_dotdot` canonicaliser when `File::Spec->abs2rel` proved insufficient, (b) a `main() unless caller;` guard on the script to allow `require`-based testing, (c) a security-review-driven fix passing `$File::Find::name` (not `$_`) to `_escapes_src` plus a nested-escape test.
- **Outcome**: Both bugs fixed and verified end-to-end. New `CWF::Validate::Templates` module wired into `cwf-manage validate`; `copy_tree` preserves relative symlinks and refuses absolute / escaping targets. `prove -r t/` → 41 files, 458 tests, all green (run twice; no flakes). Live-repo smoke test green.

## Variance Analysis
### Time and Effort
- **Estimated**: Planning ~0.25d, Design ~0.25d, Implementation ~0.5d, Testing ~0.25d, Rollout n/a (internal bugfix).
- **Actual**: All four planning phases completed in one prior session; this session covered f + g + j. Total under the 1-2 day plan; no schedule pressure.
- **Variance**: Within plan. The only delays were two real-bug discoveries during exec (see "What Went Well" #2 and #3); both were caught by tests rather than the live repo.

### Scope Changes
- **Additions**:
  - `_collapse_dotdot` helper (~17 lines). Not in the original plan because the plan assumed `File::Spec->abs2rel` would canonicalise — it doesn't. Discovered when unit-testing `_escapes_src` directly. Without this, nested-directory symlinks could escape `$src` lexically.
  - `main() unless caller;` guard at the bottom of `cwf-manage` (~1 line). Needed to make the script `require`-able from the test process; the alternative (subprocess + diff-the-tempdir) would have been heavier and slower. Standard Perl idiom, zero overhead at normal-run time.
  - `_escapes_src($File::Find::name, ...)` substitution + nested-escape test TC-C6 (~17 lines total). Added after the testing-phase security review flagged the pattern risk; the call was working only because File::Find chdirs into each directory by default.
- **Removals**: None.
- **Impact**: All additions are small, well-tested, and reinforce the security property. None of them changed the public CLI surface or the on-disk layout.

### Quality Metrics
- **Test Coverage**: 15 new functional cases (10 validator + 5 copy_tree + 1 nested-escape regression + 5 _escapes_src unit assertions). Every reachable branch in the new validator exercised; every branch of `_escapes_src` covered (absolute short-circuit, parent-escape, multi-parent, sibling, same-dir).
- **Defect Rate**: 2 real bugs introduced and caught before commit: (a) `File::Spec->abs2rel` not canonicalising — caught by TC unit tests for `_escapes_src` during Step 6; (b) `$_` vs `$File::Find::name` — caught by testing-phase security review. 0 defects shipped to checkpoint commit on the task branch beyond the testing-phase commit `544956d` that fixed (b).
- **Performance**: Not measured. Install-time code path; sub-second irrespective of the change.

## What Went Well
1. **Planning paid off**: the four-phase plan (a/c/d/e) front-loaded the design choices (single exact-pattern check; `_escapes_src` as a single gate; uppercase `TEMPLATES` category) so the implementation phase was mechanical execution of already-decided shape. Zero design rework during exec.
2. **Unit-testing the security gate directly caught a real bug.** TC-Helper cases for `_escapes_src` immediately surfaced that `File::Spec->abs2rel` doesn't collapse `..` when the entry is nested. The fix (`_collapse_dotdot`) shipped in the same commit as the introduction of the helper — never reached the integration test.
3. **The testing-phase security review caught a real pattern risk.** Passing `$_` instead of `$File::Find::name` was working only by accident (File::Find's default chdir). The subagent surfaced this; fixing it removed the hidden dependency and added a regression test (TC-C6) for nested cases.
4. **End-to-end smoke test on the live repo** confirmed the validator's user-facing output is good (both `cwf-manage update` and `ln -sfn` recovery hints printed; clear category, file, field). Worth keeping as the standard last-mile check for any validator change.

## What Could Be Improved
1. **Plan claimed `cwf-manage fix-security` could recompute hashes.** It can't — it repairs permissions only, and treats sha256 drift as `UNFIXABLE` by design. The plan was wrong about the tool's behaviour. Lesson recorded in the retrospective and reinforced as principle in commit `14f4025`: the friction is deliberate; do not propose to smooth it.
2. **Two instinctive errors at the Bash tool layer**, both surfaced by the user and recorded as memory:
   - Reached for `perl -MDigest::SHA -e '...'` instead of `sha256sum` to compute hashes. Continuity-optimisation (matching the manifest's pedigree) over complexity-minimisation. Independent verifier vs. producer is also a hard requirement, not a stylistic preference.
   - Framed the manual hash-update step as friction worth automating away with a hypothetical `cwf-manage recompute-hashes` subcommand. That would defeat the integrity check. The reflex (smooth obstacles) is generally useful but security obstacles are precisely the ones that must remain rough.
   Both are now in memory (`feedback_complexity_over_continuity.md`, `feedback_surface_security_dont_smooth.md`) and won't recur.
3. **Subtest closures and `$a`/`$b`**: spent a non-trivial chunk of test-writing time debugging a `sort { $order{$a} <=> $order{$b} }` block returning undef inside a `subtest`. Switched to a monotonic-index walk; same coverage, less Perl trivia. Not a process improvement per se, but worth noting that `Test::More` subtest closures interact awkwardly with the `$a`/`$b` package globals.

## Key Learnings
### Technical Insights
- `File::Spec->abs2rel` is a lexical prefix-strip, not a canonicaliser. For any path-escape check, `..` segments must be collapsed before comparing. The new `_collapse_dotdot` is the project's reference helper for that pattern; future callers should reuse it rather than re-derive.
- File::Find's default `chdir` is a hidden parameter of any callback that touches `$_`. Always pass `$File::Find::name` to helpers that compute paths — the safety calculation must not depend on whether the caller has overridden the default.
- The `main() unless caller;` guard is a low-cost, high-value pattern for scripts that have testable internals. Worth applying to any CWF Perl script whose internals would benefit from `require`-based testing.

### Process Learnings
- **The security-review subagent is paying for itself**. Both subagent invocations during this task surfaced material that the code-author missed; the testing-phase one in particular caught a pattern risk that integration tests had silently green-lit. Keep invoking it at both impl-exec and testing-exec.
- **The 500-line cap is a real boundary.** The testing-phase changeset hit 514 lines (490 implementation + 24-line fix). The skill's protocol — record `state: error` plus a manual review note explaining the delta over the already-reviewed implementation diff — worked. The cap is calibrated correctly for subagent attention.
- **`anchor..HEAD` means commit-then-review for exec phases.** The security-review-changeset helper does not include the working tree; both exec phases needed a commit-then-review-then-amend (or follow-up commit) dance. Worth noting in `security-review.md` so future implementers don't trip on it.

### Risk Mitigation Strategies
- The "h1 high-priority risk" from a-task-plan around POSIX-only symlink behaviour proved bounded as predicted: the project is POSIX-only, every existing template symlink is `../pool/<name>`, the audit step in d-implementation-plan confirmed no escapes existed pre-fix. No retreat needed.
- The "h2 high-priority risk" around `script-hashes.json` schema change turned out to be a non-issue: no schema change was needed (the new module is just another entry in the existing `lib` section). The earlier worry that a "type field" might be needed was a strawman the design phase considered and discarded — correctly.

## Recommendations
### Process Improvements
- **Stop reaching for inline interpreter blobs at the Bash tool layer.** `sha256sum`, `wc -l`, `cut`, `awk` — pick the smallest POSIX tool. Inline `perl -e` / `python -c` blobs are forbidden by `feedback_no_heredocs.md`; this task adds the dimension that even *outside* shell heredocs, picking a perl one-liner when a POSIX standalone exists is wrong. Now in `feedback_complexity_over_continuity.md`.
- **For integrity-related friction, default to "it's deliberate"** unless and until you've verified it isn't. Recorded as `feedback_surface_security_dont_smooth.md`.

### Tool and Technique Recommendations
- Continue using `prove -r t/` twice as the standard reliability check in testing-exec — it's cheap (~10s each) and catches obvious flakes.
- The `main() unless caller;` testability pattern should be added to the CWF Perl-script convention doc so future scripts inherit it from the start.

### Future Work
- None directly arising from this task. The bugfix is complete and localised.

## Status
**Status**: Finished
**Next Action**: Task complete; suggest merge to main (human-only)
**Blockers**: None
**Completion Date**: 2026-05-13
**Sign-off**: the task maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- a-task-plan.md, c-design-plan.md, d-implementation-plan.md, e-testing-plan.md, f-implementation-exec.md, g-testing-exec.md — all in this task directory.
- Implementation commits on `bugfix/135-preserve-template-symlinks-in-cwf-manage`:
  - `0f9b745` planning, `8496077` design, `7894601` implementation plan, `ae579d6` testing plan
  - `87d3a25` implementation exec, `e817f36` impl security-review result
  - `544956d` testing-phase security-review fix (pattern + coverage)
  - `85cb55f` testing exec, `14f4025` withdraw recompute-hashes suggestion
  - Plus the j-retrospective commit (this checkpoint).
- New source: `.cwf/lib/CWF/Validate/Templates.pm`; new tests: `t/validate-templates.t`, extended `t/cwf-manage-update.t`.

# cwf-init runs security check - Retrospective
**Task**: 120 (bugfix)

## Task Reference
- **Task ID**: internal-120
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/120-cwf-init-runs-security-check
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-02

## Executive Summary
- **Duration**: 1 day (estimated: 0.5 day after design pivot — variance +50%, in-line with the larger surface)
- **Scope**: Originally a SKILL-level chmod+validate orchestration; pivoted at user request to a deterministic `cwf-manage fix-security` subcommand that does the repair itself. Final surface = ~150 lines of Perl in `cwf-manage`, one SKILL section, one new test file.
- **Outcome**: `/cwf-init` now self-heals fixable permission deltas (only when sha256 still matches) and refuses to proceed on tampering or missing files. Surfaced via deterministic Perl, not LLM orchestration. 7 new tests, 0 regressions in the existing 246-test suite.

## Variance Analysis

### Time and Effort
- **Estimated** (a-task-plan): 0.5 day, single SKILL.md edit + one test
- **Actual**: ~1 day, ~150 lines of new Perl (`cmd_fix_security` + helper) + dispatch + help text + hash refresh + ~210-line test file + SKILL.md section
- **Variance**: +50%, driven by the user's mid-design pivot from "blanket chmod orchestrated by SKILL" to "deterministic subcommand". This was the right call — the resulting design is auditable, testable, and removes the LLM from the integrity loop — but it doubled the implementation surface vs. the initial plan.

### Scope Changes
- **Mid-design pivot** (user-driven): from `/cwf-init` running `find … chmod 0755 + cwf-manage validate` directly, to a new `cwf-manage fix-security` subcommand that does the work deterministically. Captured as commit `2a59679 Task 120: Revise plans for deterministic fix-security subcommand`.
- **Recovery hints** (user-driven): added field-keyed `Recovery:` lines to the unfixable output suggesting `git pull` (CWF source) or `cwf-manage update` (installed project). Captured as `e37f39c Task 120: Add recovery hints …`.
- **Post-impl simplification** (`/simplify`): extracted `_print_unfixable()` helper to dedupe three near-identical UNFIXABLE block emissions; flattened 3-level chmod nesting via `next` guards. Captured as `0efa360 Task 120: Simplify cmd_fix_security (post-/simplify review)`. No behaviour change.

### Quality Metrics
- **Test coverage**: 7 new tests covering every branch of the classification table (clean, perms-only, sha mismatch, missing, mixed, unparseable hashes, idempotency) — 100% of the algorithm's documented behaviour.
- **Regression rate**: 0 — full suite went from 246 → 253 tests (+7), all passing.
- **Hash refresh count**: 2 (after initial impl, after `/simplify` refactor) — expected for any change to `cwf-manage`.

## What Went Well
- **The mid-design pivot landed cleanly** because the design plan was reviewed before implementation. The original "blanket chmod" approach would have worked but was inferior; switching to the deterministic subcommand surfaced as soon as the user asked the right question ("shouldn't this be deterministic?"), and both subsequent revisions (recovery hints, `/simplify`) layered cleanly on top.
- **Test-first paid off**: writing the 7-case test before `cmd_fix_security` made the algorithm's classification table executable. Three planning-time errors (TC-3 targeting `cwf-manage` itself; TC-4/5 targeting an untracked file `context-manager`; fixture using `cp -r` instead of `cp -rp`) all surfaced in the first test run rather than in production.
- **Reuse of existing patterns**: subprocess-style integration test fits the `cwf-manage-*.t` family; recovery output mirrors the validator's `field/actual/expected` format, so users see consistent shape across `validate` and `fix-security`.
- **`/simplify` produced two real wins** (`_print_unfixable` helper, flattened nesting) — the agents correctly rejected the lower-value findings rather than pushing every observation through.

## What Could Be Improved
- **Plan reviewer's `chmod 0755` overshoot was caught by the user, not the design review.** The c-design-plan review flagged plenty of minor items but missed the bigger question: "is a blanket chmod the right tool when we have per-file expected perms?" The user's "shouldn't we have a deterministic method" question redirected the design — a more aggressive design review might have surfaced that earlier.
- **Three planning-time test-target errors** (TC-3 self-tampering, TC-4/5 wrong file, fixture umask interaction) all came from not having read the tracked-file inventory before writing the plan. A cheap pre-flight `grep` of `script-hashes.json` would have caught the `context-manager` mistake.
- **Per-phase checkpoints have stale plan content**. The c/d/e checkpoints still describe the original blanket-chmod approach; the revisions live in two follow-up commits (`2a59679`, `e37f39c`). The squash makes this invisible on main, but the checkpoints branch carries the drift. The retrospective squash below resolves main; checkpoint cleanup is a future concern.

## Key Learnings

### Technical Insights
- **`(actual & expected) == expected` is a minimum check, not equality**, in `Validate::Security::_violation`. This shaped Decision 3 (chmod to *exact* recorded perms, not blanket 0755) and the test assertion that `cwf-manage` ends up at `0700`, not `0755`.
- **`cp -r` does not preserve perms with non-default umask**: under umask 077, source `0755` files land in the destination at `0700`. Test fixtures must use `cp -rp` (preserve) or the test produces false-positive `permissions` violations on the "clean" baseline.
- **Self-test bootstrap**: a script can't run itself to detect its own tampering. TC-3 had to tamper a peer script (`cwf-set-status`), not `cwf-manage`, because we run `cwf-manage fix-security` to detect the tamper.
- **`find -exec chmod` does not fail-fast** on per-file errors. The right defensive structure is "fix what you can, then re-walk to check what remains" — which is what `fix-security` does internally.

### Process Learnings
- **The right level of refactor for a security-adjacent change is a new subcommand, not a SKILL-orchestrated shell pipeline.** Pure-Perl logic is auditable, hash-tracked, and testable end-to-end without LLM-loops. The SKILL becomes call-and-check, which is the correct division of responsibility.
- **`/simplify` is high-value after every implementation phase, even small ones.** Three near-identical print blocks went unnoticed during initial coding; the helper extraction was a clear net win once flagged.
- **Plan reviewers can miss design-level questions by focusing on local quality.** The big "is this the right approach?" question is often the user's to ask. Worth being explicit about that in the review prompt.

### Risk Mitigation Strategies
- **Refusing to chmod a tampered file** is the load-bearing safety property of `fix-security`. Without it, the subcommand would mask tamper signals by "fixing" perms on files we can't verify. TC-3 directly tests this.
- **Best-effort fix + full-disclosure failure report**: a mixed install (some fixable, some not) gets the fixable parts repaired and the unfixable ones surfaced loudly. Failing fast at the first unfixable would obscure the full picture.

## Recommendations

### Process Improvements
- **Pre-flight grep before writing test cases**: confirm any path the test targets exists in the relevant inventory (`script-hashes.json`, etc.). Cheap; catches the `context-manager` class of error before the first test run.
- **Design reviewer prompt addition**: add a "is this the right approach for the problem?" check, separate from the "is this approach internally consistent?" checks already in the rubric.

### Tool and Technique Recommendations
- The `cp -rp` + `git init` fixture pattern in `t/cwf-manage-fix-security.t` is reusable for any future `cwf-manage` integration test. Worth lifting into `t/lib/CWFTest/Fixtures.pm` if a third such test arrives (Rule of Three).

### Future Work
- **`cwf-manage update` overlap with `fix-security`**: both chmod the scripts directory; `update` does blanket `0755`, `fix-security` does per-file recorded perms. Reconciling is a separate cleanup task — flagged in d-implementation-plan.md as out-of-scope.
- **`--dry-run` flag on `fix-security`**: previewing repairs without applying them would be useful for security-conscious users. Bugfix scope deferred this; suitable for a future small enhancement.
- **Manual smoke (TC-8/9/10)**: end-to-end SKILL exec has been documented in `g-testing-exec.md` with reproduction steps but is deferred to a separate Claude Code session in a scratch checkout. Should be run before tagging if integrity-critical.

## Status
**Status**: Finished
**Next Action**: Suggest user fast-forward main; tagging is human-only per CLAUDE.md.
**Blockers**: None
**Completion Date**: 2026-05-02
**Sign-off**: Matt Keenan + Claude Opus 4.7

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Implementation: `.cwf/scripts/cwf-manage` (cmd_fix_security, dispatch, help), `.cwf/security/script-hashes.json` (hash refresh)
- SKILL change: `.claude/skills/cwf-init/SKILL.md` (new step 1a)
- Tests: `t/cwf-manage-fix-security.t`
- Commits on task branch (pre-squash): `455068d → 0efa360` (9 commits)

# move PERL5OPT to project-local settings - Retrospective
**Task**: 153 (bugfix)

## Task Reference
- **Task ID**: internal-153
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/153-move-perl5opt-to-project-local-settings
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-21

## Executive Summary
- **Duration**: ~½ day (estimated: ~½ day, variance: 0%).
- **Scope**: External-facing bugfix — `PERL5OPT=-CDSLA` was recommended into the user-global `~/.claude/settings.json`, so multiple CWF installs on one machine clashed on a single global value. Moved it to the project-level `.claude/settings.json`, installed automatically by `cwf-claude-settings-merge` (which both `/cwf-init` and `cwf-manage update` already invoke). Docs, the `check_perl5opt` warning, and a dogfood commit followed.
- **Outcome**: Successful. One ~35-line code change in the existing settings writer, four doc surfaces retargeted, `cwf-manage` untouched. 16 unit subtests + integration green; security review no findings at both exec phases; `cwf-manage validate` clean.

## Variance Analysis

### Time and Effort
- **Estimated**: ~½ day (a:30m, c:60m, d:60m, e:30m, f:30m, g:15m, j:15m).
- **Actual**: ~½ day. No phase materially off estimate.
- **Variance**: 0%.

### Scope Changes
- **Additions**: None to the deliverable. Two BACKLOG follow-ups filed (canonical-value SSOT; the fix-security test-fixture bug discovered mid-task).
- **Removals**: Single-source-of-truth for the `-CDSLA` literal deliberately scoped out at design time (Decision 7) — the bug is *location*, not value duplication.
- **Impact**: None.

### Quality Metrics
- **Test coverage**: 11/11 e-plan TCs PASS, realised as `t/cwf-claude-settings-merge.t` TC-U7…TC-U13 plus end-to-end/doc checks.
- **Defects**: 0 introduced. 0 security findings across both exec-phase reviews.
- **`cwf-manage validate`**: OK (after in-commit sha256 refresh of the two hashed files and a permission-only repair of the unrelated `cwf-plan-reviewer-misalignment.md`).

## What Went Well
- **Verified the load-bearing premise before building.** "Project `.claude/settings.json` `env` overrides user-global and has no trust-gate" was checked against Claude Code's own docs in the planning phase. The whole fix is inert if that's false — confirming it first de-risked everything downstream.
- **Maximal reuse, minimal new surface.** Extending the single existing project-settings writer (`cwf-claude-settings-merge`) meant no new helper, no second wiring site, no `cwf-manage` edit, and only two hashed-file refreshes. Both the improvements and misalignment reviewers independently confirmed this was the right insertion point.
- **Plan-review subagents earned their keep.** Eight reviews across design + implementation produced load-bearing changes: dry-run must still warn; type-guard malformed `env`; `check_perl5opt` must not over-promise (restart/bare-shell); concrete env-only re-derivation for the dogfood commit; repo-wide closing grep; FR4(e) constant-only note; corrected `Common.pm` line anchors; extend the existing test file rather than create one.
- **Surfaced, did not smooth — twice.** A pre-existing red test (`t/cwf-manage-fix-security.t`) was *proved* pre-existing (re-ran at baseline `b5b8739` in a throwaway worktree) and filed to BACKLOG rather than absorbed; the permission drift was repaired with the canonical `cwf-manage fix-security` (a non-committable chmod), keeping it out of this task's diff.
- **Kept the regression guard clean.** Chose to phrase every retargeted doc without the literal `~/.claude/settings.json`, so the closing zero-hit grep is a strong, unambiguous invariant instead of needing an allow-list.

## What Could Be Improved
- **`echo "exit=$?"` habit leak (again).** Appended it to one Bash call (violates [[feedback_no_echo_exit]]; harness already reports exit codes). Recurs across tasks; a mechanical detector is already a BACKLOG item (Task 150 follow-up). Self-flagged in `f-implementation-exec.md`.
- **Test-regex delimiter slip cost one run.** My new `qr/…/` warning matchers contained `.claude/settings.json`, whose `/` closed the regex → compile error. The existing tests already used `qr{…}` for exactly this; matching their idiom from the start would have avoided the round-trip. Caught and fixed immediately.

## Key Learnings

### Technical Insights
- Claude Code applies `env` from a project `.claude/settings.json` to tool-call subprocesses and it overrides the user-global value, with no first-use trust prompt (the prompt gate applies to hooks, not `env`). For any "move the config location" change, verifying the host tool's precedence/trust behaviour up front is high-ROI.
- `cwf-claude-settings-merge` is the single writer of project `.claude/settings.json`, reached by both `/cwf-init` step 6d and `cwf-manage update` (`run_settings_merge`). New CWF-required settings belong there; `cwf-manage` needs no change to propagate them.
- `merge_env` must keep its written value a compile-time constant — the tool-call `env` path has no trust-gate, so a future non-constant value would be an injection surface (FR4(e), documented inline by the constant).

### Process Learnings
- **A hash manifest that expands beyond `.cwf/` can silently break fixtures keyed to `.cwf/`.** `t/cwf-manage-fix-security.t`'s `build_fixture` copies only `.cwf/`, but the manifest gained `.claude/agents/*` entries (~Task 148/149) — so the fixture has been missing those files (and the test red) ever since. When the manifest's coverage grows, audit fixtures that assume a fixed copy root.
- **Prove "pre-existing" empirically.** Re-running the failing test at the recorded baseline commit in a worktree turned "I think this isn't mine" into a fact for the record, and justified filing-not-fixing without scope creep.

### Risk Mitigation Strategies
- Add-if-absent + warn-on-mismatch + type guards keep the merge idempotent and non-destructive of deliberate user values, mirroring the existing `merge_allow`/`merge_hooks` discipline.
- Permission-only drift (sha intact) is repaired with `cwf-manage fix-security`, the canonical tool — never a hand-chmod baked into a feature diff, and never a hash recompute that would smooth a tampering signal.

## Recommendations

### Process Improvements
- For any task that relocates configuration into a host tool's settings, make "verify the tool's precedence + trust behaviour from its docs" an explicit planning-phase step.

### Tool and Technique Recommendations
- When adding regex matchers in `t/` for strings containing `/`, use `qr{…}` delimiters (the existing tests' idiom).

### Future Work (filed as BACKLOG during this task)
1. **Fix `t/cwf-manage-fix-security.t`** — `build_fixture` must copy every path the manifest enumerates (incl. `.claude/agents/*`), not just `.cwf/`. **Medium** — main is currently red on this.
2. **Single source of truth for the canonical `-CDSLA` value** — currently duplicated across INSTALL.md, perl.md, SKILL.md, `Common.pm`, and the new helper constant. **Low**.

## Status
**Status**: Finished
**Next Action**: Task complete; suggest merge per Step 12 (see chat).
**Blockers**: None identified
**Completion Date**: 2026-05-21
**Sign-off**: The maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`
- Design: `c-design-plan.md` (4 plan-review subagents)
- Implementation plan: `d-implementation-plan.md` (4 plan-review subagents)
- Testing plan: `e-testing-plan.md`
- Implementation exec: `f-implementation-exec.md` (security review: no findings)
- Testing exec: `g-testing-exec.md` (11/11 TCs PASS; security review: no findings)
- Checkpoint commits preserved on `bugfix/153-move-perl5opt-to-project-local-settings-checkpoints` via Step 10.

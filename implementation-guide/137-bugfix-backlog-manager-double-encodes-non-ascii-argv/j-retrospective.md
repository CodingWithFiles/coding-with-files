# backlog-manager double-encodes non-ASCII @ARGV - Retrospective
**Task**: 137 (bugfix)

## Task Reference
- **Task ID**: internal-137
- **Branch**: bugfix/137-backlog-manager-double-encodes-non-ascii-argv
- **Baseline Commit**: e8d1b8f487f2a3c44df2736111c870928324da47
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-15

## Executive Summary
- **Duration**: 1 session (estimate: 0.5–1 day; on-target at the optimistic end).
- **Scope**: Originally a one-flag shebang change across 11 scripts + matching doc updates. During execution we uncovered convention drift (Tasks 27 → 113 → 115 → 124) and an unrelated `validate_path_allowlist` cargo-cult. Doc updates were descoped mid-task into a Very-High follow-up; the shipped scope is the minimum needed to fix the reported bug.
- **Outcome**: Bug fixed. `backlog-manager add` with non-ASCII argv now writes clean UTF-8. New regression test (TC-F1) verified sensitive to the specific fix (catches a shebang revert). 461 tests pass, `cwf-manage validate` clean.

## Variance Analysis
### Time and Effort
- **Estimated** (from a-task-plan.md): 0.5–1 day single session.
- **Actual**: 1 session, on-target at the optimistic end. Mid-session re-scoping (deferring doc updates and `validate_path_allowlist` work) prevented a multi-session blowout.
- **Variance**: 0% on time, but with significant *intended* scope shrinkage during execution.

### Scope Changes
- **Additions**: None to delivered scope. Three Very-High / Low BACKLOG items added to capture the *deferred* work:
  - Very High: Re-align Perl-Script Convention to Task-27 Form and Anchor in CLAUDE.md
  - Very High: Split validate_path_allowlist into write/read/temp variants
  - Low: Make path-allowlists overridable in cwf-project.json
- **Removals from in-task scope** (deferred to the convention re-alignment follow-up):
  - Updates to `docs/conventions/perl-git-paths.md`, `.claude/skills/cwf-init/SKILL.md`, `INSTALL.md`, `.cwf/lib/CWF/Common.pm` warn-string, `.cwf/docs/skills/security-review.md`
  - PerlConventions.pm validator-message explanatory text changes (only the literal-string check changed)
  - Header-comment updates in PerlConventions.pm
  - TC-F8 (convention-doc assertion)
- **Impact**: Kept the bugfix landable as a single coherent change. Migration trap (existing users with `PERL5OPT=-CDSL`) is captured in f-implementation-exec.md and the Re-align backlog item.

### Quality Metrics
- **Test Coverage**: 3 new test subtests (TC-F1, TC-F2, TC-U3c). Suite grew 458 → 461. TC-F1 sensitivity verified by deliberate transient regression (mojibake reappeared with `-CDSL` shebang, restored on revert).
- **Defect Rate**: 0 post-implementation defects; one mid-implementation defect (BACKLOG round-trip blank-line normalisation) found and fixed before commit.
- **Performance**: N/A.

## What Went Well
- **Empirical-first investigation of the `-C` flag-set "Too late" interaction.** When the first attempt failed with `Too late for -CDSLA`, writing three standalone `/tmp/task-137/*.pl` scripts isolated the consistency rule between PERL5OPT and shebang in ~10 minutes — much faster than reading perldoc cold.
- **Sensitivity verification on TC-F1.** Reverting the shebang once and observing the mojibake reappear is conclusive evidence the test catches the bug, not a vacuous pass. The transient revert was 2 edits and a re-run — cheap proof.
- **Filing structural defects as backlog items instead of expanding scope.** The convention drift and `validate_path_allowlist` cargo-cult were both real, both wider than this task. Filing them under Very-High preserved the bugfix's small blast radius and recorded the work without losing it.
- **Verifier/producer implementation diversity preserved.** sha256 hashes regenerated with `sha256sum` (coreutils), verified by `Digest::SHA::sha256_hex` (Perl) inside `cwf-manage validate`. The two implementations agreeing is the integrity-check property; using the same implementation for both would have collapsed it.

## What Could Be Improved
- **Scope creep tendency.** Mid-task I drifted into editing SKILL.md, INSTALL.md, Common.pm warn-strings, validator header comments — none of which is part of the minimum fix. The user had to correct twice ("what are you doing??? what did i say was the scope for this task?", then "did we edit this file earlier in this task? is the minimal fix for the files we've changed?"). When a task has been explicitly re-scoped mid-flight, every subsequent edit should be checked against the new scope, not the original d-plan.
- **`security-review-changeset --phase=…` is invisible to working-tree changes.** Both exec phases tripped on this: the helper diffs `anchor..HEAD` over committed history, so uncommitted f-phase or g-phase work returns an empty changeset and the skill's literal text says "record `no findings: empty changeset`". I worked around it by capturing `git diff HEAD` manually and invoking the subagent with the raw diff. A backlog item for this already exists from Task 136 ("Improve security-review-changeset feedback on empty-from-uncommitted changesets") — Task 137 reinforces the case.
- **The d-plan was written against the originally-discovered scope, not the actual scope.** Once the scope shrunk, neither d-plan.md nor e-plan.md was updated. The wf step files now have a stale d-plan and an e-plan that includes TC-F8 (a test against deferred work). Acceptable for the bugfix workflow (it shows the *intent* at planning time), but worth noting that mid-task descopes leave plan docs slightly out of sync with shipped reality.
- **PERL5OPT migration trap not yet shipped to other users.** Anyone with a global `PERL5OPT=-CDSL` will hit `Too late for -CDSLA` on the next script invocation after pulling this commit. The mitigation (update `~/.claude/settings.json` to `-CDSLA`) is documented in f-implementation-exec.md but not yet in `INSTALL.md` or `cwf-init`. That migration text lands with the Re-align follow-up.

## Key Learnings
### Technical Insights
- **`-C` flag sets between PERL5OPT and shebang must match.** Perl rejects post-init `-C` differences with `Too late for -C…`. The fix isn't "set A in one place" — it's "set the same flag-set in both places, or use `#!/usr/bin/env perl` and let PERL5OPT carry everything".
- **The `A` flag is not implied by `D` or `S`.** `D` = file I/O layers; `S` = STDIN/STDOUT/STDERR; `L` = locale-conditional. `A` is the only flag that decodes `@ARGV`. The original `-CDSL` (Task 27 onwards) was incomplete for argv-consuming helpers.
- **TC-F8-style "doc-content" assertions are useful as scope anchors.** Even though TC-F8 is deferred, having it in e-plan.md makes the deferred surface explicit and falsifiable: when the convention re-alignment task runs, TC-F8 becomes its acceptance criterion.

### Process Learnings
- **For bugfix tasks, the d-plan is most useful as a checklist of files to edit, not as a binding spec.** Mid-task discoveries (convention drift) should re-shape scope freely; the d-plan stays as the original-intent record.
- **`git diff HEAD` is the right input to a security-review subagent when work is uncommitted.** Until the helper grows a "review working tree" mode, manual capture + Read-tool feed to the subagent is the workaround. Document the workaround inline in the workflow file's Security Review section so future readers see how the diff was constructed.
- **Sensitivity-verify regression tests by transient revert.** It's two edits and a re-run, and it's the only way to know the test actually proves what it claims. Worth adopting as a default for any test claiming to prove a fix.

### Risk Mitigation Strategies
- **Defer-not-decompose for orthogonal structural defects.** When a bugfix uncovers a related architectural issue (here, convention drift; cargo-cult `validate_path_allowlist`), file it as a backlog item rather than expanding the task. The task stays landable; the structural work gets its own deliberate planning pass.
- **Verifier/producer diversity for integrity checks.** Regenerating hashes with `sha256sum` (a different implementation from the in-tree `Digest::SHA` verifier) is the property that makes `cwf-manage validate` catch real tampering rather than just confirming the producer agrees with itself.

## Recommendations
### Process Improvements
- After mid-task descope, append a "Scope (minimal, post-discovery)" subsection to f-implementation-exec.md (already done this task) so the variance is recorded without rewriting d-plan history.
- Adopt the transient-revert sensitivity check as standard for any new regression test that claims to prove a bugfix.

### Tool and Technique Recommendations
- Improve `security-review-changeset` to detect uncommitted-but-relevant work (already a backlog item from Task 136). Until then, document the `git diff HEAD` workaround in `.cwf/docs/skills/security-review.md` as a known operator pattern.

### Future Work
Tracked in BACKLOG.md as filed during this task:
- Very High: Re-align Perl-Script Convention to Task-27 Form and Anchor in CLAUDE.md (carries the deferred doc updates and PERL5OPT migration text).
- Very High: Split validate_path_allowlist into write/read/temp variants.
- Low: Make path-allowlists overridable in cwf-project.json.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None
**Completion Date**: 2026-05-15

## Archived Materials
- Phase commits: `3db4b76` (a), `9a04984` (c), `8b23aeb` (d), `ef3d252` (e), `d4d5bea` (f), `d8ccecc` (g).
- New test: `t/backlog-manager-argv-utf8.t`.
- New subtest: `TC-U3c` in `t/validate-perl-conventions.t`.
- Smoke test (one-off, not committed): `/tmp/task-137/smoke/smoke-bug.pl`.

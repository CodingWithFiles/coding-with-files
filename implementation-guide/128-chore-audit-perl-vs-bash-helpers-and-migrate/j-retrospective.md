# Audit Perl-vs-Bash helpers and migrate - Retrospective
**Task**: 128 (chore)

## Task Reference
- **Task ID**: internal-128
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/128-audit-perl-vs-bash-helpers-and-migrate
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-06

## Executive Summary
- **Duration**: 1 session (estimated: 0.5–1 day; variance ~0%, came in at the lower end)
- **Scope**: Original framing was "audit and migrate where feasible". Discovery reframed it: 4 of 5 in-scope shell helpers had zero callers, and the 5th was a 4-line `cat`-or-fallback used in one place. Final scope: delete all 5, inline the one usage.
- **Outcome**: Success. Five dead/trivial helpers removed; integrity manifest pruned; `/cwf-config` works equivalently via inlined Bash; full test suite GREEN (325/325). Bonus: discovered and captured a Very-High-priority bug in the security-review subagent's pathspec/anchor construction.

## Variance Analysis

### Time and Effort
- **Estimated** (a-task-plan): 0.5–1 day, low–medium complexity.
- **Actual**: 1 session, evenly split across plan/exec/retrospective. No phase ran long.
- **Variance**: ~0%. The "delete instead of migrate" decision shortened implementation but the discovery + plan-review took proportionally longer, netting out.

### Scope Changes
- **Additions**:
  - BACKLOG entry "Bug: Security-review changeset construction is broken in three ways" (Very High priority) — added when the cap-overflow message during f-phase prompted inspection of the underlying `git diff` invocation. Three independent bugs surfaced (extension globs, hardcoded language stack, merge-base anchor).
  - Memory: `feedback_no_filename_decisions.md` — content classification, never extension classification.
- **Removals**:
  - Migration to Perl was reframed away. Discovery showed none of the helpers carried logic that justified Perl ceremony (no path-emitting git, no options, no error handling, no shared state). The simplicity principle ("the best part is no part") applied more strongly than the migration benefit.
  - Test edits to `t/validate-security-coverage.t` were dropped: plan-review surfaced that the test counts dynamically (`plan tests => scalar(@top_level) + 1`) so no edit was required. The plan's original "22 → 17" was stale on two axes (baseline of 22 was outdated; 22 vs 24 question was moot once the dynamic-count fact landed).
- **Impact**: Net simplification. Final delta on this task ~50 lines (5 helper deletions, 1 SKILL.md line, 5 manifest entries removed, 1 BACKLOG completion marker). No new code added.

### Quality Metrics
- **Test Coverage**: 325/325 tests passing (`prove t/`); coverage-regression test auto-adjusted from 24 → 19 top-level helpers.
- **Defect Rate**: Zero post-implementation defects found in this task. One pre-existing defect (security-review pathspec) discovered and captured to BACKLOG.
- **Integrity**: `cwf-manage validate` GREEN at every checkpoint commit.

## What Went Well

- **Discovery flipped the framing.** The backlog described "audit and migrate"; reading each helper plus its caller surface revealed the audit's real outcome was deletion. Naming the discovery findings explicitly in d-implementation-plan made the reframing reviewable rather than implicit.
- **Plan-review subagents caught four real issues** before implementation: (1) baseline test count of 22 was stale (24 actual), (2) test counts dynamically so no edit was needed, (3) atomicity gap between deletes and manifest updates, (4) BACKLOG entry should be closed by this task. All applied; none of them surfaced as defects later.
- **Atomicity discipline paid off.** Deletes + manifest edit landed in a single commit (`76d79a7`). At no point during implementation did `cwf-manage validate` see an inconsistent state.
- **Pre-flight verification re-ran the caller-surface grep** immediately before deletion. Cheap, repeated the d-phase finding, would have caught any caller introduced between phases.
- **The cap-overflow message surfaced a real bug, not just noise.** The 1422/1545-line cap-exceeded message in f and g led to inspection of the underlying `git diff` invocation; that inspection found three independent bugs in the security-review pathspec construction.

## What Could Be Improved

- **Security-review pathspec is broken on three axes** (now BACKLOG, Very High). Documented in detail in the new backlog entry. Briefly: (1) extension-based globs miss extensionless scripts, (2) hardcoded `*.pl/*.pm/*.bash/*.sh` doesn't generalise to non-CWF-stack consumers, (3) `merge-base HEAD main` over-includes earlier-task commits when those tasks are not yet merged. The cap-exceeded path silently records "review ran" without an actual review having occurred — a quiet failure mode.
- **Manual security review supplemented the cap-exceeded path twice.** Both f and g recorded `**State**: error` with a manual review attached. Acceptable, but the pattern is now established as a recurring workaround. Pressure to fix the underlying bug is real.
- **The d-phase plan's stale "22" count** would have fired in implementation if not caught by plan-review. It was lifted from Task 125's d-implementation-plan without re-checking — a footgun for cross-task copy. (Plan-review compensated, so no harm done; but worth noting that copy-paste from prior tasks needs re-verification against current state.)

## Key Learnings

### Technical Insights
- **The right answer to "should we migrate X?" is sometimes "X shouldn't exist."** Four of the five helpers were artefacts of a v1.x autoload design that never landed. Task 125 added them to the integrity manifest without questioning their existence — a natural consequence of that task's narrow scope. This task closed the loop. Future audits should ask "is this used at all?" before "what language should this be in?".
- **Filenames are not classifications.** Captured to memory: `feedback_no_filename_decisions.md`. Extensions are dead 8.3 Windows nonsense; classify by content (shebang, magic bytes, parser). The security-review pathspec is the canonical example of this anti-pattern in CWF source.
- **Dynamic-count tests scale better than hardcoded ones.** `t/validate-security-coverage.t`'s `plan tests => scalar(@top_level) + 1` survived this task without edit; a hardcoded `plan tests => 23` would have been a test edit on every helper add/remove. Worth standardising.

### Process Learnings
- **Plan-review subagents are paying for themselves.** Three out of four reviewers flagged the stale "22 → 17" count (different framings), one flagged the atomicity issue, one flagged the BACKLOG omission. Cost: one parallel Agent call. Benefit: zero rework in implementation. Continue using them.
- **Discovery output (decision matrix in d-plan)** is a structurally good way to capture an audit. Each helper got one row with LOC, logic summary, callers, decision. Future audit tasks should mirror this layout — it makes the reasoning reviewable and the conclusion explicit.
- **The cap-exceeded path needs to be louder.** Today it logs an `error:` line and proceeds to checkpoint. The user only inspected the underlying git command because they'd seen a similar overflow in Task 127 and wanted to understand why it kept happening. Without that vigilance, the broken pathspec could have stayed undiscovered indefinitely.

### Risk Mitigation Strategies
- **Pre-flight re-grep** caught nothing this time (caller surface was stable) but cost ~1 second and locks in a useful invariant: discovery findings are revalidated immediately before the irreversible step. Keep doing this for any deletion task.
- **Atomic commit boundary** prevented the "validate broken between steps" failure mode that the security-review subagent flagged. Worth standardising as a pattern: any change that touches both content and the integrity manifest must land in a single commit.

## Recommendations

### Process Improvements
- **Make the cap-exceeded security-review path more visible.** Today it's a quiet `error:` line in the wf step file. Options: print to stderr in addition to the file, or block the checkpoint commit on cap-exceeded (force a manual override). Tracked under the existing "Quantitatively justify the security-review subagent line-count cap" BACKLOG entry; mention this experience there if it's revisited.
- **Re-verify cross-task copy-paste against current state.** When lifting a section from a prior task's d-implementation-plan (counts, file lists, version numbers), grep/read the current state to confirm the numbers still hold. Caught here by plan-review; cheaper to catch at write time.

### Tool and Technique Recommendations
- **Standardise dynamic-count test pattern.** `t/validate-security-coverage.t` is the model. Any future test asserting "every X under Y is registered/conformant" should walk the filesystem and count, not hardcode N.
- **Discovery decision matrix template** for audit tasks. Columns: item, current state, callers, decision, rationale. The d-implementation-plan for this task had one; future audit tasks should adopt it.

### Future Work
- **Bug: Security-review changeset construction is broken in three ways** (Very High, on BACKLOG): replace extension globs with content-based detection; replace hardcoded language stack with a content-driven directory walk; replace `merge-base HEAD main` with an anchor that doesn't depend on merge policy or trunk name.
- **Quantitatively justify the line-count cap** (Low, on BACKLOG, Task 127 follow-up): once the underlying pathspec is fixed, revisit whether 500 is the right number. The two are related — the cap matters less if the diff doesn't over-include.
- **Tighten security-subagent prompt for sentinel-line compliance** (Low, on BACKLOG, Task 123 follow-up): orthogonal to the pathspec bug but in the same area; consider bundling.

## Status
**Status**: Finished
**Next Action**: Task complete; ready for merge to main
**Blockers**: None
**Completion Date**: 2026-05-06

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Plan: `a-task-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md`
- Execution: `f-implementation-exec.md`, `g-testing-exec.md`
- Implementation commit: `76d79a7` (5 deletions + manifest prune + SKILL inline + BACKLOG close, atomic)
- Backlog entry add: `e7865cf` (Very-High security-review bug)
- Test results: 325/325 passing; coverage test auto-adjusted 24 → 19 top-level helpers

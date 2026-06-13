# Bash tool-check framework - Retrospective
**Task**: 201 (feature)

## Task Reference
- **Task ID**: internal-201
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/201-bash-tool-check-framework
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-13

## Executive Summary
- **Duration**: ~1 working day across one workflow run (estimated 2-3 days; under estimate).
- **Scope**: Delivered the full mechanism as planned — fail-open PreToolUse `Bash` hook,
  three-layer rule merge, PCRE + provenance-gated Perl rules, exact-repeat bypass,
  install+upgrade gitignore wiring, integrity registration. Two additions were made
  during plan-review (the `--check` diagnostic and the 64 KB command cap); nothing was
  descoped.
- **Outcome**: Success. All seven success criteria met; TC-1…TC-16 + regression (60 tests)
  green; `cwf-manage validate` OK; exec-phase security review returned no findings.

## Variance Analysis
### Time and Effort
- **Estimated**: 2-3 days, High complexity (runtime engine + config/merge + install wiring).
- **Actual**: Completed in a single continuous workflow run. The pure-policy-lib + thin-
  I/O-hook split (mirroring `CWF::PlanningGuard` + `pretooluse-planning-write-guard`) meant
  most of the architecture was a known pattern, which compressed design and implementation.
- **Variance**: Under estimate. Reuse of an existing, tested hook shape was the main driver.

### Scope Changes
- **Additions**:
  - **`--check` diagnostic**: an operator-facing, human-terminal-only dump of the effective
    ruleset (dropped checked-in perl, overrides, final set). Added in plan-review to make
    the three-layer merge auditable before an operator relies on it. Documented as
    not-for-agent-context to avoid a reflected-output injection surface.
  - **64 KB command cap**: refuse-to-match (not truncate) above the cap, closing a
    truncate-to-evade vector and bounding match cost. Added as a defence-in-depth layer
    beneath the guaranteed harness `timeout`.
- **Removals**: None. Seeding CWF's own checked-in rules was always out of scope (the
  offending-command set drifts per model / per Claude Code version), and remains deferred.

### Quality Metrics
- **Test Coverage**: Critical paths 100% per the plan — deny/allow, the repeat-bypass state
  machine, the full fail-open matrix, the checked-in `perl`-drop, the never-`re 'eval'`
  guarantee, symlink-safe state, and the ReDoS bound under an external timeout.
- **Defect Rate**: Two implementation bugs caught and fixed during TDD authoring in
  implementation-exec; zero escaped to testing-exec or beyond.
- **Performance**: ReDoS bound verified (TC-14) — pathological `(a+)+$` stays bounded and
  fails open under external `timeout`.

## What Went Well
- **Pattern reuse**: cloning the planning-write-guard's lib/hook split gave a tested
  structure, the hook contract, and the integrity-registration mechanism for free.
  Correctness-over-novelty paid off.
- **Trust boundary landed cleanly**: provenance-keyed dropping of checked-in `perl` rules
  *before* compilation, keyed on the caller-supplied path rather than rule content, gave a
  defensible "no code executes on `git clone`" invariant that the security review endorsed.
- **TDD caught real bugs**: authoring tests first in implementation-exec surfaced two
  defects before they could reach the testing phase.
- **Fail-open posture held under test**: the 7-row reliability matrix (TC-13) confirmed
  every error path degrades to empty-stdout/exit-0.

## What Could Be Improved
- **Security-review cap friction**: the changeset helper's production-weighted cap (500)
  fired at 603 lines on the one changeset that most needed review. Handling it required a
  judgement call to override `--max-lines=800` for implementation-exec and to record
  testing-exec as `error` (byte-identical production). This worked but is a recurring
  rough edge for large single-file hooks — see Future Work.
- **Scope creep during plan-review**: the two additions (`--check`, 64 KB cap) were sound
  but were introduced after the requirements were locked. They were disclosed and the user
  flagged for review; in future, defence-in-depth knobs of this kind belong in the
  requirements/threat-model phase, not plan-review.

## Key Learnings
### Technical Insights
- A regex engine is safe to expose to less-trusted config **only** while `re 'eval'` is
  absent from scope — that single absence is what lets checked-in (clone-travelling) regex
  rules be carried safely, since an embedded `(?{...})` dies at match time and is caught.
- The arbitrary-Perl surface is acceptable when the trust gate runs *before* `eval`, keyed
  on provenance the caller derives from the file path — never on anything inside the rule.
- Bounding untrusted match cost wants layers: a best-effort in-process alarm + an input
  size cap, sitting beneath the one guaranteed bound (the harness `timeout` SIGKILL). Don't
  rest safety on alarm pre-emption alone.

### Process Learnings
- Reusing a known-good hook shape is the strongest single lever on estimate accuracy for
  this class of work.
- The exec-phase security-review contract is deterministic by design; when production code
  is byte-identical across two adjacent phases, re-invoking the reviewer adds no signal —
  recording the cap `error` with a pointer to the prior clean review is the correct,
  non-smoothing response.

### Risk Mitigation Strategies
- The two high-priority risks from a-task-plan (arbitrary-Perl/injection and fail-open
  correctness) were both retired by design choices verified in test, not by hope: the
  provenance drop (TC-3) and the fail-open matrix (TC-13).

## Recommendations
### Process Improvements
- Fold defence-in-depth knobs (input caps, diagnostics) into the requirements/threat-model
  phase for security-sensitive features, so they are not late plan-review additions.

### Tool and Technique Recommendations
- The lib/hook split with a deterministic classifier is a reusable template for any future
  PreToolUse guard; treat planning-write-guard and tool-check as the two reference shapes.

### Future Work
- **Seed CWF's own bash tool-check rules** (deferred from this task): populate the
  checked-in layer with rules for commands that trip permission prompts in this repo,
  revisited per model / Claude Code version. Regex-only (checked-in perl is dropped).
- **Security-review cap ergonomics for large single-file hooks**: consider whether the
  production-weighted cap should discount heavily-commented hook bodies, or whether the
  override path should be a first-class, recorded decision rather than an ad-hoc flag.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-13
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md … e-testing-plan.md (this task directory)
- Implementation/Testing results: f-implementation-exec.md, g-testing-exec.md
- Rollout/Maintenance: h-rollout.md, i-maintenance.md
- Code: `.cwf/lib/CWF/ToolCheck.pm`, `.cwf/scripts/hooks/pretooluse-bash-tool-check`
- Tests: `t/tool-check.t`, `t/pretooluse-bash-tool-check.t`
- Operator docs: `.cwf/docs/tool-check-rules.md`

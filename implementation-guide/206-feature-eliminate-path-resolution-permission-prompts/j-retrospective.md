# Eliminate path-resolution permission prompts - Retrospective
**Task**: 206 (feature)

## Task Reference
- **Task ID**: internal-206
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/206-eliminate-path-resolution-permission-prompts
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-15

## Executive Summary
- **Duration**: within the 1–2 day estimate.
- **Scope**: Delivered as planned, with one deliberate design pivot — instead of migrating
  the anchor snippets to a helper the skill *calls* (still `$(...)`-invoked, which Risk 1
  predicted would not help), the mechanism became a **UserPromptSubmit hook that injects
  literal paths** so skills never resolve at all. Goal unchanged; mechanism stronger.
- **Outcome**: Success. Zero-prompt acceptance criterion **confirmed live** this session
  (the `CWF PATHS` block is injected each turn). Full suite 874 green, `cwf-manage validate` OK.

## Variance Analysis
### Time and Effort
- **Estimated**: 1–2 days (Medium complexity).
- **Actual**: in band. Most thinking went into the mechanism choice (design phase); the
  ~20-skill migration was mechanical once the anchor block proved byte-identical everywhere.
- **Variance**: negligible. The risk was correctly front-loaded into design (Risk 1).

### Scope Changes
- **Addition**: `scratch_parent`/`scratch_dir` in `CWF::Common` as the single scratch-path
  deriver (success criterion #2 demanded one mechanism replacing every inline derivation).
  `scratch_parent` gained an optional pre-resolved-root arg so the hook costs one
  `git rev-parse`/turn (NFR1).
- **Addition (test)**: `t/skill-anchor-drift.t` was **inverted**, not deleted — Task 204's
  guard asserted the anchor block was present; the regression we now want is its absence.
- **Removal**: none descoped.
- **Impact**: net simpler runtime — skills carry literal paths, no per-call resolution.

### Quality Metrics
- **Test Coverage**: TC-1..TC-15; critical paths (num-validate-before-FS, symlink reject,
  no-chmod, not-a-repo degradation, hook fail-open) 100% covered. Full suite 874 green.
- **Defect Rate**: zero post-implementation defects; the one in-flight surprise (UTF-8
  em-dash mismatch in the strip script) was caught and fixed during execution.
- **Performance**: NFR1 met — one `git rev-parse`/turn.

## What Went Well
- **Risk 1 was the design.** The plan named "the prompt may be triggered by `$(...)` itself"
  as the top risk; design confirmed it empirically and pivoted to injection rather than a
  called helper. Naming the failure mode up front is why the mechanism is correct.
- **Byte-identity golden test** (TC-1) let the ~20-file migration proceed without fear of
  scratch-path drift.
- **Honest deferral resolved cleanly.** g-phase recorded the live smoke as deferred (settings
  load at session start); it activated naturally at the next session boundary and is now observed.
- **Both exec changeset reviews returned no findings**; symlink-reject/no-chmod defence positively tested (TC-7).

## What Could Be Improved
- **Self-test blind spot.** A hook cannot be live-verified in the session that registers it.
  This is intrinsic, but it meant acceptance had to span a session boundary — worth flagging
  in any future hook-shipping task so the smoke is scheduled for the *next* session, not claimed early.
- **UTF-8 in scratch scripts.** The strip script silently matched nothing until `use utf8;`
  was added (PERL5OPT=-CDSLA decodes file reads as UTF-8; an em-dash in raw-byte source won't
  match). Already a standing convention; this was a reminder it applies to one-off scripts too.

## Key Learnings
### Technical Insights
- **Inject, don't resolve.** When the constraint is "any agent-issued shell expansion prompts",
  the fix is to remove the need for the command, not to allowlist it — a hook that puts the
  answer in context each turn beats any callable helper.
- **`scratch_parent`'s optional root arg** is the pattern for "pure function, but let a hot
  caller supply a value it already has" — keeps single-source-of-truth without re-resolving.

### Process Learnings
- A guard test from a prior task can have its **premise inverted** by a later task; migrating
  a feature means migrating (sometimes flipping) its tests, not just deleting them.
- The status sweep before retrospective again paid off (all a–i terminal before writing j).

### Risk Mitigation Strategies
- Front-loading the single highest-uncertainty decision (mechanism choice) into the design
  phase, gated by an empirical trigger check, kept the downstream migration low-risk.

## Recommendations
### Process Improvements
- For any future hook-shipping task: plan the acceptance smoke as a **next-session** step and
  state so in the test plan, rather than discovering the session-cache limit at g-phase.

### Tool and Technique Recommendations
- Reuse `scratch_parent`/`scratch_dir` for every new scratch consumer; do not hand-roll the
  dashified path (now the documented single source of truth in `tmp-paths.md`).

### Future Work
- If/when a second injected field is added or `cwd` ceases to be single-user-trusted, re-run
  the security posture review (audit triggers recorded in i-maintenance.md).
- Optional sweep: confirm no remaining consumer hand-rolls the scratch path (dead-code audit).

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-15
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning/exec docs: `implementation-guide/206-feature-eliminate-path-resolution-permission-prompts/` (a–j)
- Key commits: f-exec (implementation, 31-file), g-exec (`1e2d34b`), h-rollout (`273de94`), i-maintenance (`d01d80a`)
- Tests: `t/scratch.t`, `t/userpromptsubmit-context-inject.t`, inverted `t/skill-anchor-drift.t`

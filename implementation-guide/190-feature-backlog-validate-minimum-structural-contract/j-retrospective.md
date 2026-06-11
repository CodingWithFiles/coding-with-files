# backlog validate minimum structural contract - Retrospective
**Task**: 190 (feature)

## Task Reference
- **Task ID**: internal-190
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/190-backlog-validate-minimum-structural-contract
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-11

## Executive Summary
- **Duration**: ~1 day across a single working session (estimated: 0.5–1 day; on plan).
- **Scope**: Delivered exactly as planned — a `BACKLOG-000` intro-region structural
  assertion in `CWF::Backlog` plus a mutation gate on `add`/`modify`/`delete`/`retire`
  in `backlog-manager`. No scope additions; the one open question (CHANGELOG parity,
  KD5) was explicitly scoped out and filed as a follow-up rather than folded in.
- **Outcome**: Success. A foreign-shaped `BACKLOG.md` now fails `validate` and is
  refused by every mutation path; empty-but-valid and legacy files still pass.

## Variance Analysis
### Time and Effort
- **Estimated**: ~0.5–1 day total (Medium complexity; risk was false positives, not size).
- **Actual**: ~1 day, single session, no phase materially over-ran.
- **Variance**: Within estimate. The predicate was small as predicted; most effort went
  to fixture design (empty-vs-foreign-vs-legacy discrimination) and confirming no false
  positives — exactly where the plan flagged the risk.

### Scope Changes
- **Additions**: None.
- **Removals**: CHANGELOG parity deferred to a follow-up (KD5) — a deliberate yes/no
  decision recorded in design (AC8), not descoped work. Accepted-boundary gaps
  (unterminated-leading-fence masking; prose-only/after-entry foreign content) were
  bounded out of v1 and filed Low.
- **Impact**: Kept the change minimal and reviewable; avoided the "drift into a schema
  language / CHANGELOG redesign" risk the plan named.

### Quality Metrics
- **Test Coverage**: TC-1…TC-15 (10 unit + 5 integration), all KD2 construct classes
  and all four mutation subcommands exercised; every AC1–AC8 maps to ≥1 case.
- **Defect Rate**: Zero defects found post-implementation. Two pre-existing,
  environment-specific suite failures were investigated and confirmed present on clean
  HEAD (not regressions) — the change strictly *reduced* the fix-security failures (3→1).
- **Performance**: NFR1 satisfied by construction — predicate reuses parser-cached
  `_source_lines`/`_source_fence`, no second read or fence rebuild.
- **Security**: Both exec-phase reviews `no findings`; the no-verbatim-echo property is
  pinned by TC-7.

## What Went Well
- **Risk-anchored design paid off**: the plan named "false positives on our own files"
  as the top risk; deriving the contract strictly from what the manager *reads* (intro
  region only, entry bodies unscanned) meant the live `BACKLOG.md` and all fixtures
  passed first time.
- **Empty-vs-foreign discrimination** (KD1/KD2/KD4) resolved cleanly via the
  intro-region scan + leading-H1 exemption, mirroring CHANGELOG-001's required-marker
  approach without inventing a schema language.
- **Security-by-construction**: choosing to interpolate only a fixed kind-enum + line
  number (never the offending text) closed the prompt-injection surface up front; TC-7
  turned that design promise into an enforced invariant.
- **Generic helper, narrow wiring**: `backlog_structure_errors` is format-agnostic and
  `@EXPORT_OK`, so KD5 CHANGELOG parity is a wiring task, not a rewrite.

## What Could Be Improved
- **Status hygiene**: phases a–e were left `In Progress` and had to be swept to
  `Finished` at retrospective (the recurring CWF status-sweep error). The per-phase
  checkpoint should set the *outgoing* phase terminal, not just the incoming one.
- **Stash/pop perms drift**: a `git stash` cycle silently bumped `backlog-manager` to
  0700, surfaced only at the f-phase validate. Worth remembering that stash round-trips
  reset working-tree modes on hash-tracked executables.

## Key Learnings
### Technical Insights
- A *manageability* assertion is best derived from the tool's read path, not from a
  notion of "valid markdown" — the file can be perfectly well-formed markdown and still
  be unmanageable. The contract is "what would `add`/`modify`/`retire` silently ignore?"
- Fence-aware scanning needs explicit boundary tests: an unterminated leading fence
  masks everything to EOF, a real fail-open edge that must be *pinned* (TC-8/TC-9) so a
  future `_build_fence_map` change can't shift the contract unnoticed.
- Exporting a generic predicate while wiring it to a single caller is a clean way to
  pre-stage parity work without taking on its risk now — provided the security invariant
  (no verbatim echo) is documented as a precondition of reuse.

### Process Learnings
- The plan's risk register predicted exactly where the effort landed (false-positive
  avoidance), which made fixture design the right place to spend time. Risk-first
  planning earned its keep on a small task.
- Distinguishing legitimate same-commit hash refresh from drift-absorption requires
  verifying the recorded hash matched HEAD *before* editing — a step worth doing
  explicitly rather than assuming.

### Risk Mitigation Strategies
- Stash-and-compare against clean HEAD is the reliable way to separate a pre-existing
  environment-specific test failure from a genuine regression; do it before claiming a
  failure is "not mine".

## Recommendations
### Process Improvements
- Consider having the checkpoint-commit helper mark the just-completed phase `Finished`
  (not only advance the next), to retire the recurring a–e status-sweep step.

### Tool and Technique Recommendations
- Keep the "interpolate fixed enum + integer, never untrusted content" pattern as the
  default for any validator message that reaches operator/LLM context; pin it with an
  `unlike(...)` guard as TC-7 does.

### Future Work
- **KD5 CHANGELOG parity** (Medium, filed) — wire the generic predicate into the
  CHANGELOG validate/mutation path, applying NFR2 stripping if any message ever cites
  line text.
- **Accepted-boundary gaps** (Low, filed) — tighten unterminated-leading-fence masking
  and prose-only/after-entry foreign detection.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-11
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning artefacts: `a-task-plan.md` … `i-maintenance.md` in this task directory.
- Implementation commits (task branch): `a9b282b` (f-exec), `31af1ce` (g-exec),
  `1874ebc` (h-rollout), `5a281f5` (i-maintenance).
- Seed backlog item retired to `CHANGELOG.md` against Task 190 (was seeded at `48b12c6`).
- Test results: TC-1…TC-15 in `t/backlog-tree-validate.t` and `t/backlog-manager.t`.

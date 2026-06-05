# Integrate Claude Code sandboxing into CWF - Retrospective
**Task**: 179 (feature)

## Task Reference
- **Task ID**: internal-179
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/179-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-05

## Executive Summary
- **Duration**: planning across prior sessions; f→j exec in a single session
  (estimated 2–4 days). Under the wall-clock estimate, as is typical for a
  CWF doc/tooling task with TDD groundwork already laid in planning.
- **Scope**: delivered SC1–SC3 + SC5 in full; **SC4 (R1) split to subtask
  179.1** — the pre-authorised descope (a-plan Risk 1 / b-AC4d), not a silent cut.
- **Outcome**: Success. Default-OFF, reversible, both exec-phase security reviews
  clean, full suite 665 green, `cwf-manage validate: OK`.

## Variance Analysis
### Time and Effort
- **Estimated** (a-plan): 2–4 days, Medium–High complexity.
- **Actual**: planning (a–e) done in earlier sessions with 4-reviewer plan
  reviews at b/c/d; implementation + testing + rollout + maintenance +
  retrospective in one continuous session.
- **Variance**: under estimate. The TDD plan and the pinned design (sidecar
  already dropped at c-review) meant exec was largely mechanical — tests written
  failing-first, all green on first implementation pass.

### Scope Changes
- **Removals (planned)**: R1 phase-scoped planning-write guard → **179.1**.
  Rationale: needs a matcher-regex widening (`Edit|Write`) and a
  fail-closed-without-bricking design that 179 deliberately did not take on; 179
  widened only the **event** allowlist (the clean seam R1 reuses). Seeded as a
  live BACKLOG item (TC-12).
- **Additions**: none of feature scope. Four implementation deviations recorded
  (below) — three are clarifications, one is a substantive correctness fix.
- **Impact**: kept the security-critical helper edit cohesive; R1's uncertainty
  isolated to its own subtask.

### Quality Metrics
- **Test coverage**: TC-1..TC-13 all mapped + PASS; ~17 new subtests across
  `validate-config.t`, `cwf-claude-settings-merge.t`, and the new
  `pretooluse-sandbox-logging.t`. Full suite 665 PASS.
- **Defect rate**: zero post-implementation defects; the only test failure was a
  regex-delimiter typo in a test, fixed immediately.
- **Performance**: R3 hook ~15 ms/call, spawn-dominated, no git / no
  task-context-inference (NFR1 recorded, not an SLA).
- **Security**: two exec-phase reviews (implementation + testing) → **no findings**.

## What Went Well
- **Plan review caught a security hole before it was built.** The c-design
  reviewers flagged the provenance *sidecar* as a credential-boundary-removal
  oracle; it was dropped for ownership-by-shape pre-implementation. Cheapest
  possible place to kill that design.
- **TDD held.** Every acceptance criterion had a failing test first; the build
  turned them green with no rework.
- **Default-OFF made rollout trivially safe** — merging changes no adopter's
  behaviour; the toggle is the per-adopter rollback (TC-6 proves clean removal).
- **Pattern reuse kept the helper consistent** — `merge_env`'s warn/authority
  stance, the gated-block validator shape, `read_json_file`/`atomic_write_text`,
  the `subagentstop` hook's fail-open `eval` skeleton.
- **Honest scoping of the unprovable** — the runtime `~`-expansion property is
  flagged as a residual rollout check rather than claimed-verified.

## What Could Be Improved
- **The plan shipped an internal contradiction that 4-reviewer review missed.**
  D5/AC3a/TC-7 asked for `failIfUnavailable` to be *both* authoritative *and*
  warn-not-overwrite-on-hand-set — mutually exclusive without provenance (the
  very provenance the sidecar was dropped to avoid). It surfaced only at
  implementation. Plan review checks per-requirement soundness well; it is
  weaker at catching *two requirements that cannot both hold*.
- **The CWF-shape predicate was left "to pin at exec."** It worked out cleanly
  (`^Read\(.+\)$`), but a sharper design phase would have pinned it, since it is
  the security-load-bearing removal rule.
- **Runtime matcher behaviour is untestable in the Perl suite** — an inherent
  gap for a feature that generates config for another tool; mitigated by the
  rollout check but worth noting for any future settings-generation work.

## Key Learnings
### Technical Insights
- **Bash-only sandbox reshapes the whole feature.** Because Read/Edit/Write
  bypass the sandbox, credential denial *must* be paired (`denyRead` for Bash +
  `Read(...)` denies for the Read tool); neither half alone closes it.
- **Ownership-by-shape beats a provenance sidecar** for reversible managed
  config: no persisted state to tamper, no second write to tear, removal touches
  only what the generator can re-derive. The cost — a user entry identical to a
  CWF default in the *generated* file is reclaimed — is acceptable when overrides
  have a proper home (`settings.local.json`).
- **For a security knob, authoritative-from-single-source beats preserve-hand-set.**
  Preserving a hand-weakened boundary is exactly the "smoothing" the project
  forbids; the knob in `cwf-project.json` winning is both correct and fail-safe.

### Process Learnings
- TDD + a fully-pinned design front-loads the thinking so exec is fast and low-risk.
- Recording deviations *as you make them* (with rationale) made the review
  hand-off and this retrospective straightforward.

### Risk Mitigation Strategies
- Sequencing the uncertain piece (R1) **last** and pre-authorising its split
  (SC4) meant the standalone-valuable parts shipped without waiting on it.
- Default-OFF is the strongest rollback for a risky boundary feature.

## Recommendations
### Process Improvements
- Add a plan-review lens for **mutually-contradictory requirements** (not just
  per-item soundness) — would have caught the D5/TC-7 tension at c/d, not f.
- When a design defers a security-load-bearing rule "to exec", treat that as a
  design gap to close, not a detail.

### Tool and Technique Recommendations
- The "run a temp copy of a FindBin-relative hook inside a tempdir" pattern
  (`pretooluse-sandbox-logging.t`) is a clean way to test hooks hermetically;
  worth reusing for future hook tests.

### Future Work
- **179.1** — R1 phase-scoped planning-write PreToolUse guard (seeded, BACKLOG).
- **Maintenance rhythm** — re-check the four Claude Code coupling assumptions per
  CC release (i-maintenance watch-list); the `~`-expansion live check at first
  real opt-in.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-05
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md` … `e-testing-plan.md` (baseline `a20b682`).
- Exec commits: f `16c1356`, g `fa9a222`, h `65c249c`, i `df22d32`.
- Security reviews: recorded verbatim in `f-implementation-exec.md` and
  `g-testing-exec.md` (both `no findings`).
- Follow-up: BACKLOG entry "R1: phase-scoped planning-write PreToolUse guard
  (CWF sandboxing 179.1)".

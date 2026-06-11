# Lint agent files for ignored allowed-tools key - Retrospective
**Task**: 193 (hotfix)

## Task Reference
- **Task ID**: internal-193
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/193-lint-agent-files-for-ignored-allowed-tools-key
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-11

## Executive Summary
- **Duration**: ~0.5 day, matching the estimate. No variance of note.
- **Scope**: Delivered exactly as planned — a new `CWF::Validate::Agents` validator
  flagging the silently-ignored `allowed-tools:` key in CWF agent frontmatter, wired into
  `cwf-manage validate`, with a `t/` regression suite. Scope held to the literal request;
  the general "unknown agent key" linter was deferred to the backlog at the review gate.
- **Outcome**: Success. Preventative guard in place; all 10 test cases pass; both exec-phase
  security reviews returned `no findings`; `cwf-manage validate` green on the real tree.

## Variance Analysis
### Time and Effort
- **Estimated**: ~0.5 day, Low complexity (single validator + wire-in + test).
- **Actual**: ~0.5 day. Phases run for this hotfix: a (plan), d (impl-plan), e (test-plan),
  f (impl-exec), g (test-exec), h (rollout), j (retro). No requirements/design phases
  (hotfix template omits b/c/i).
- **Variance**: None material. The one mid-stream cost — reworking detection after TC-7
  failed (see Quality Metrics) — was absorbed within the f-phase and did not move the estimate.

### Scope Changes
- **Additions**: None.
- **Removals/Deferrals**: The generalised linter (flag *any* silently-ignored agent
  frontmatter key, e.g. the existing `effort:` on `cwf-security-reviewer-changeset.md`) was
  deferred to a backlog item at the review gate — it needs an authoritative allow-list of
  valid agent keys, which is a moving target unsuited to a hotfix.
- **Impact**: Kept the change small, additive, and low-risk.

### Quality Metrics
- **Test Coverage**: 10/10 cases pass — TC-1..TC-8 (unit), TC-9 (real-tree integration),
  TC-10 (full suite, 734 tests). Critical path covered both directions (detect / stay silent);
  edge cases covered (body-only, unterminated block, no-frontmatter, non-CWF namespace,
  installed-context branch).
- **Defect Rate**: One defect, found and fixed in-phase by the test suite — the first
  detection cut flagged `allowed-tools:` *before* confirming the frontmatter block was
  terminated, so TC-7 (unterminated block) failed. Reworked to a two-pass
  find-close-then-scan. Zero escaped defects.
- **Performance**: N/A — read-only in-process line scan over ~5 small files.

## What Went Well
- **Test-first caught the real bug.** The robustness plan-reviewer insisted the unterminated
  block must be *skipped*, not body-scanned; that became TC-7; TC-7 then failed against the
  naive single-pass implementation and forced the correct two-pass design. The defect never
  left the f-phase. This is the plan-review → test → implementation chain working as intended.
- **Mirroring the sibling validator** (`CWF::Validate::Templates`) made the module, the test
  harness, the violation-hashref contract, and the hash/perms handling near-mechanical — low
  cognitive load, high consistency.
- **Scope discipline at the review gate.** Surfacing the generalisation as an explicit open
  decision (rather than silently expanding) kept the hotfix a hotfix.

## What Could Be Improved
- The TC-7 ordering bug was foreseeable at design time — "find the close first, then scan
  within" is the obviously-correct shape for a bounded block. The d-phase described the
  *invariant* (skip unterminated) but not the *control-flow shape*, so the first
  implementation reached for the simpler single-pass loop. A one-line note in the plan
  ("two-pass: locate close, then scan strictly inside") would have pre-empted it. Net cost
  was small because the test caught it, but it's a cheap planning improvement.

## Key Learnings
### Technical Insights
- For any "scan a bounded block" task, locating the terminator *before* inspecting the
  interior is the correct shape — a single-pass flag-on-first-match leaks past an
  unterminated block. Worth carrying into future frontmatter/section scanners.
- `allowed-tools:` vs `tools:` is a genuine fail-open footgun in Claude Code agent
  definitions: the wrong key is silently ignored, leaving the agent fully un-restricted.
  This validator is the standing guard; the asymmetry is documented in the module header.

### Process Learnings
- Plan-review findings that name an *invariant* should, where cheap, also pin the
  *implementation shape* that guarantees it — the gap between "skip unterminated blocks" and
  "two-pass scan" is exactly where the defect entered.
- The hotfix path (a,d,e,f,g,h,j) with both exec-phase security reviews remains
  proportionate even for a ~0.5-day additive change; no shortcut was warranted or taken.

### Risk Mitigation Strategies
- The a-phase "wrong scan target" high risk (dev `.claude/agents/` vs installed
  `.cwf-agents/`) was mitigated by the single-target resolver and *proven* non-vacuous by
  TC-4, which asserts the `.cwf-agents/` branch actually inspected a file rather than passing
  trivially. Asserting "the check did something" is as important as asserting its verdict.

## Recommendations
### Process Improvements
- When a plan-reviewer flags an invariant for a bounded-scan/parse task, add the control-flow
  shape (e.g. "two-pass: find terminator, then scan inside") to the d-phase, not just the
  rule. Cheap insurance against the easy-but-wrong first cut.

### Tool and Technique Recommendations
- Continue mirroring an existing sibling validator wholesale (module + test + hash entry +
  wire-in) when adding to the `CWF::Validate::*` family — it is the lowest-friction,
  highest-consistency path.

### Future Work
- **Deferred**: a generalised agent-frontmatter-key linter (allow-list of valid keys:
  `name`, `description`, `tools`, `model`; flag anything else — would also catch the existing
  `effort:` key). Captured as a backlog item; not scheduled.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-11
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, d-implementation-plan.md, e-testing-plan.md (this task dir)
- Implementation: `38ffb41` (f-exec — module, wire-in, test, hashes), `1896afb` (g-exec),
  `95ccd98` (h-rollout)
- Code: `.cwf/lib/CWF/Validate/Agents.pm`, `t/validate-agents.t`,
  wire-in at `.cwf/scripts/cwf-manage` `cmd_validate`
- Test results: g-testing-exec.md (TC-1..TC-10, all PASS)
- Security reviews: `no findings` on both f- and g-phase changesets (recorded inline)

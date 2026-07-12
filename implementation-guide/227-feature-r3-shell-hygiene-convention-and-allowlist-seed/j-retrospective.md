# R3 shell-hygiene convention and allowlist seed - Retrospective
**Task**: 227 (feature)

## Task Reference
- **Task ID**: internal-227
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/227-r3-shell-hygiene-convention-and-allowlist-seed
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-12

## Executive Summary
- **Duration**: Single working session (calendar estimate treated as noise per the plan — Task 219
  S7 finding; no day-count variance is meaningful).
- **Scope**: Delivered exactly the two R3 remainders named in the plan — a shipped shell-hygiene
  convention doc and a read-only Bash allowlist seed. R3 part 3 (the cwf-init path-injection hook)
  was correctly held out of scope (addressed by Task 224); no scope drift.
- **Outcome**: Success. All five success criteria met; full test suite green (Files=78,
  Tests=1078); `cwf-manage validate` OK. Merge to main is the only outstanding action and is
  human-only by policy.

## Variance Analysis
### Time and Effort
- **Estimated**: N/A — the plan explicitly treated calendar estimates as noise (Task 219/220
  precedent). Complexity was estimated **Medium**.
- **Actual**: Matched Medium. The intricacy landed where expected — not in the 5-entry seed
  (trivial: one constant + one `push`) but in the **test gate** design (the independent
  anti-tautology predicate) and the **exact-vs-prefix** distinction for `git branch`.
- **Variance**: None material. The plan-review and design-review rounds (three revision commits:
  `3576c62`, `8a1d532`, `8207fde`, `1711294`) front-loaded the hard thinking, so exec had no
  surprises beyond the expected stale-hash gate firing.

### Scope Changes
- **Additions**: One in-phase fix — the misalignment reviewer caught `shell-hygiene.md` using
  markdown-link cross-refs where the `cross-doc-references.md` convention prescribes
  `inline-backtick × path`; fixed in phase f, not deferred.
- **Removals**: None. R3 part 3 was never in scope (surfaced as a plan-time decision, not a
  mid-task descope).
- **Impact**: Negligible — the cross-ref fix was cosmetic-but-binding and cost minutes.

### Quality Metrics
- **Test Coverage**: Critical path (the safety gate) 100% — every corpus entry validated by the
  independent predicate; every planted-unsafe class rejected including the prefix-form-of-exact
  near-miss and a trailing-newline anchor probe. Full regression green.
- **Defect Rate**: Zero shipped defects. One transient 4-file failure during exec was the
  stale-hash integrity gate firing as designed (resolved by the in-task Step-4 hash refresh), not
  a code defect.
- **Reviews**: 5-reviewer exec MAP (f) + 2-reviewer MAP (g) = 7 reviewer passes; all clean except
  the one misalignment finding, fixed in-phase.

## What Went Well
- **Anti-tautology test design**: authoring the `%SAFE_PREFIX_KEYS`/`%SAFE_EXACT_KEYS` sets from
  first principles rather than from the shipped corpus means the gate can actually catch a bad
  corpus edit instead of rubber-stamping it. The reviewers explicitly endorsed this.
- **Exact-vs-prefix precision**: pinning `git branch --show-current` exact (rejecting the
  `git branch:*` prefix that would admit `git branch -D`) is the kind of blast-radius call the
  read-only admission criterion is meant to force; the near-neighbour table documents it.
- **Reuse over new machinery**: the seed rode the existing `merge_allow`/`partition_manifest`
  path — no second writer, additive + idempotent, so downstream adoption and rollback are both
  trivial.
- **Surface, never smooth**: the undocumented redirection/substitution harness behaviour was
  neither assumed-safe nor treated as a blocker — verified the doc status, caveated it in
  `shell-hygiene.md`, and seeded a backlog probe.

## What Could Be Improved
- **The redirection/substitution question stayed open.** A live probe needs a controlled
  single-rule harness fixture that this session's permission scope couldn't provide. The residual
  is real (undocumented, harness-wide) — it is routed to a backlog item, but it is a genuine
  known-unknown shipping with the feature.
- **A second hash-tracked file surfaced late.** The plan named only the helper for hash refresh;
  `cwf-agent-shared-rules.md` also needed one. `validate` caught it deterministically, but the
  plan could have enumerated *all* hash-tracked files it intended to touch up front.

## Key Learnings
### Technical Insights
- A curated security allowlist's real cost is the **curation contract**, not the entries: the
  independent test gate + read-only-for-whole-glob-space rule + near-neighbour justification is
  what keeps the next maintainer from quietly widening it.
- `substr`-based `:*` suffix splitting (no backtracking regex) plus `\A`/`\z` + `/aa` anchoring is
  the right shape for a security predicate — no catastrophic-backtracking or anchor-hole surface.

### Process Learnings
- Front-loading review into plan/design (four revision commits before exec) paid off: exec was
  mechanical and review-clean. This is the intended shape of the CWF phase chain working well.
- Enumerate every hash-tracked file a task will edit during planning, so the in-task refresh set
  is known before `validate` has to surface the omission.

### Risk Mitigation Strategies
- The plan's top risk ("allowlist widens default-permitted commands") was mitigated exactly as
  written — hard read-only constraint + a test asserting no mutating verb — and the design added
  the exact-vs-prefix refinement that the risk statement didn't anticipate.

## Recommendations
### Process Improvements
- In `d-implementation-plan`, add an explicit "hash-tracked files this task will edit" enumeration
  so the refresh set is planned, not discovered by `validate`.

### Tool and Technique Recommendations
- The anti-tautology predicate pattern (independent hand-authored membership sets validating a
  shipped constant) is worth reusing for any future curated security list in CWF.

### Future Work
- **Verify harness auto-approval of redirection/substitution under Bash prefix allow rules**
  (discovery, Medium) — already seeded in BACKLOG, identified-in Task 227. Needs a controlled
  single-`Bash(<verb>:*)`-rule harness fixture to probe the four vectors (`>`, `>>`, `` ` ``,
  `$(…)`) authoritatively.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-07-12
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md` … `e-testing-plan.md`; exec: `f-implementation-exec.md`,
  `g-testing-exec.md`; rollout/maintenance: `h-rollout.md`, `i-maintenance.md`.
- Checkpoint commits: `ecf931c` (a) → `81773f3` (i), baseline `8dce3a6`; three plan/design
  revision commits (`3576c62`, `8a1d532`, `8207fde`, `1711294`).
- Delivered artefacts: `.cwf/docs/conventions/shell-hygiene.md`, the `@READ_ONLY_ALLOWLIST` seed
  in `cwf-claude-settings-merge`, the FR3 anchor in `cwf-agent-shared-rules.md`, and the
  `t/cwf-claude-settings-merge.t` gate (TC-RO1..RO5).

# Always review docs regardless of line cap - Plan
**Task**: 223 (feature)

## Task Reference
- **Task ID**: internal-223
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/223-always-review-docs-regardless-of-line-cap
- **Baseline Commit**: 3f7bbed50b55d4c05431210fe9804f85d19446e2
- **Template Version**: 2.1

## Goal
Guarantee the exec-phase changeset review always assesses the task's docs —
independent of the production-line cap — so plan/design/test-doc problems are
caught before code is written, and stop CWF's own task-doc tree from inflating
the cap.

## Background
`security-review-changeset` gates review *invocation* on a production-line cap.
Today the cap is binary: when it trips (`exit 2`), the exec-phase skills (f/g)
Step 8 launch **no review agents at all** — so the CWF process docs that sit in
the changeset (design/implementation/test plans) go unreviewed alongside the
code. This is backwards: reviewing the plan docs is the cheapest, highest-value
review, and adapting a doc before code is written avoids reworking large code
changes later. Compounding it, a consumer's cap is inflated by CWF's *own*
task-doc markdown (Task 221 seeded generic doc globs — `docs/**/*.md`, `*.md` —
but neither matches the base-path task tree `<base-path>/**/*.md`; only this repo
escapes via a hardcoded `implementation-guide/**` in its own config). Surfaced
by an external consumer (gate-to-breakout-tech task 67), which is on an older CWF
but reproduces the residual gap on current main.

## Success Criteria
- [ ] When the production-line cap is exceeded, the changeset review sub-agents
      still run against the doc portion of the changeset — never a blanket
      "launch nothing".
- [ ] The CWF task-doc root, derived from the configured `base-path`, is
      discounted from the production-line count by default for **any** consumer,
      with no per-project config required.
- [ ] "Surface, never smooth" preserved: docs discounted from the *cap* remain
      fully *reviewed* content in every path (cap gates code-review scope/
      invocation, not doc visibility); no seeded glob discounts a
      `.cwf/{scripts,hooks,security,docs}` or `cwf-project.json` path.
- [ ] The f/g Step 8 contract, exec templates, and the SubagentStop verdict guard
      no longer carry the stale "exit 2 → no agents" instruction; behaviour and
      docs agree.
- [ ] Tests cover: cap-exceeded-still-reviews-docs, base-path exclusion for a
      non-default `base-path`, and the doc-still-in-`.out` invariant.

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Medium
**Dependencies**: Builds on Task 218 (cap mechanism) and Task 221 (seeded
excludes, cap 1000). Relates to open backlog item "Revisit the security-review
line cap: quantitative basis and edit-lines counting" — fold in or cross-ref at
requirements.

## Major Milestones
1. **Contract settled**: requirements + design fix the new exit/invocation
   contract — how "cap exceeded" splits into always-review-docs vs
   defer/scope-down code review — and enumerate every consumer of `exit 2`.
2. **Helper updated**: base-path-derived cap exclusion + the signal that lets
   f/g review docs even when code is over cap.
3. **Skills/templates updated**: f/g Step 8 review-invocation logic and the
   exec templates aligned to the new contract.
4. **Tests + docs + hashes**: security-review.md synced, tests added, sha256
   refreshed in the same commit (perms stay 0500).

## Risk Assessment
### High Priority Risks
- **Contract change ripples**: `exit 2` is consumed by the helper, both exec
  skills, the templates, and the SubagentStop verdict guard; a partial update
  leaves stale "no agents" behaviour.
  - **Mitigation**: design enumerates every `exit 2` consumer up front;
    output-level smoke test (generate a sample exec artefact and grep for stale
    "no agents"/exit-2 wording), not just source grep.

### Medium Priority Risks
- **base-path derivation over-excludes**: `base-path` is configurable and could
  be empty/unusual; a sloppy derived glob could discount real code.
  - **Mitigation**: derive strictly from the resolved `base-path`; extend Task
    221's live-tree guardrail asserting no `.cwf`/`cwf-project.json` path is ever
    discounted.
- **Doc-review flooding**: if "cap exceeded" now launches agents on docs, a huge
  adversarial-markdown doc changeset could itself overwhelm the agent.
  - **Mitigation**: design decides whether doc review needs its own ceiling, or
    whether the existing full-review-of-discounted-paths stance already bounds it.

### Low Priority Risks
- **Hash-tracked helper drift**: forgetting the same-commit sha256 refresh trips
  `cwf-manage validate`.
  - **Mitigation**: hash-updates.md plan-time disclosure; refresh in the edit commit.

## Dependencies
- Task 218 (configurable cap) and Task 221 (seeded excludes, cap 1000) — this
  extends their mechanism, adds no new runtime engine.
- Backlog: "Revisit the security-review line cap" (Medium) — decide fold-in vs
  cross-ref during requirements.

## Constraints
- Perl core-only; POSIX portability (macOS system Perl).
- Hash-tracked script: recorded perms 0500 are a ceiling; refresh sha256 in the
  same commit as the edit (hash-updates.md).
- Dog-food: this repo uses `base-path: implementation-guide`; validate against a
  non-default base-path in tests, not just the repo's own value.
- wf files edited only via CWF skills; helper/templates/docs edited directly.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — 1-2 days.
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? Borderline — helper logic,
      exit-contract/skill logic, docs/tests are layers of one change, not
      parallel concerns.
- [ ] **Risk**: High-risk components needing isolation? No — the contract-change
      risk is isolated in design, not by decomposition.
- [x] **Independence**: The base-path cap-exclusion and the always-review-docs
      guarantee *could* ship separately — but they share the same files (helper +
      f/g skills) and the same conceptual fix, so splitting adds coordination
      overhead for no benefit. One signal, not decomposing.

**Conclusion**: 1 borderline signal (Independence). Keep as a single task;
requirements/design revisit if the contract change proves larger than scoped.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 223
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 5 success criteria met (see `j-retrospective.md` variance analysis). The change
landed smaller than budgeted: the SubagentStop verdict guard and exec templates were
found to be non-consumers of `exit 2`, so no change was needed there.

## Lessons Learned
The plan's "every exit-2 consumer" list was partly speculative — verifying consumer
membership against source *during planning* (not design) would have sized it accurately.

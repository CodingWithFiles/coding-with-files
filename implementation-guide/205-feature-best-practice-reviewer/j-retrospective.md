# Best-practice reviewer for plan and exec steps - Retrospective
**Task**: 205 (feature)

## Task Reference
- **Task ID**: internal-205
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/205-best-practice-reviewer
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-15

## Executive Summary
- **Duration**: ~1 day across phases (estimated 2-3 days). Under estimate because
  the existing reviewer machinery (plan-review map/reduce, `cwf-security-reviewer-changeset`,
  `security-review-classify`, the tmp-paths/hash conventions) was reused wholesale
  rather than rebuilt — the dominant risk in planning (over-building) did not materialise.
- **Scope**: Delivered as planned — tag-aware best-practice reviewer in both the
  planning plan-review and the exec changeset review, JSON config merged from project
  + user `.cwf/`, three source kinds (file/dir/URL), fail-open no-op when unconfigured.
  One structural change vs the design: exec integration runs **in parallel** with the
  security reviewer (see Scope Changes).
- **Outcome**: Success. All five a-task-plan success criteria met; 21 unit + 881
  regression tests green; `cwf-manage validate` clean; security review `no findings`.

## Variance Analysis
### Time and Effort
- **Estimated**: 2-3 days, Medium complexity (whole task; per-phase not separately estimated).
- **Actual**: Compressed — planning a–e in one session, exec f/g in a second, rollout/
  maintenance/retrospective in a third. Implementation was the largest single phase
  (the helper + tests); the wf-step docs (h/i) were quick because the SaaS-shaped
  templates were largely N/A for a file-based tool.
- **Variance**: Under estimate (~1 day vs 2-3). Reuse of existing patterns was the
  main driver; the only re-work was the exec parallelism restructure (below).

### Scope Changes
- **Addition / restructure — exec reviewers run in parallel**: the design (KD8) had
  exec best-practice as a *second, sequential* `## Best-Practice Review` step mirroring
  the single security step. During exec the user required that **all** review
  sub-agents (planning and exec) launch in parallel, the sole exception being a strict
  output→input data dependency. Both exec SKILLs were restructured into one **Step 8
  (Changeset Reviews — parallel)**: the two deterministic helpers run in Prep (their
  `.out` files are the strictly-required agent inputs), then the security and
  best-practice changeset reviewers launch together in one message and are classified
  independently. Verdict contracts and helper/agent/classifier reuse unchanged.
- **Removals**: none.
- **Impact**: net positive — lower review wall-clock, no contract change. Captured as
  a durable principle in memory (`feedback-reviewers-parallel`).

### Quality Metrics
- **Test Coverage**: `t/best-practice-resolve.t` 21 subtests (TC-1…TC-22 less the
  planning-only TC-9, folded into TC-1) — every config-failure branch, every source
  kind, every confinement/skip/truncation path. Full `prove t/`: 70 files, 881 tests,
  0 failures.
- **Defect Rate**: one correctness fix found during testing — `realpath` resolves a
  non-existent leaf under an existing parent without error, so missing-source detection
  needed an explicit `-e` check, not a `defined` check. No post-implementation defects.
- **Performance**: N/A (deterministic CLI helper; no perf target).

## What Went Well
- **Pattern reuse paid off**: building the reviewer as a peer of the existing security
  reviewer (same helper→agent→classifier split, same tmp-paths/hash discipline) kept
  new surface small and meant the security model carried over for free.
- **Fail-open / no-op by design**: with no `best-practices.json` the feature does
  nothing, dog-fooded live in f/g (0 matches). This makes rollout and rollback trivial.
- **Surface-don't-smooth held under pressure**: the security cap breach (1082 production
  lines > 500) was surfaced as `error`-worthy yet the reviewer was still run deliberately
  on the full changeset to get a real verdict — neither hidden nor used to skip review.

## What Could Be Improved
- **Design under-specified the parallelism**: the exec-integration design described a
  serial second step; the parallel structure had to be corrected during exec after
  explicit (and repeated) user direction. A design-phase question — "should this reviewer
  be a parallel peer or a serial step?" — would have caught it before code.
- **Cap config vs CWF's own task size**: CWF's own feature tasks routinely exceed the
  default 500-line production cap, forcing a per-task "surface and review anyway"
  judgement each time. The cap is doing its job for *consumers* but is friction for this
  repo's self-development.

## Key Learnings
### Technical Insights
- A new reviewer should be a **parallel peer** in the existing MAP, never a new serial
  step. The only justification for serialising is a strict output→input dependency;
  fast deterministic helpers feeding agent inputs are not such a dependency.
- `realpath`/`Cwd::realpath` succeeds on a non-existent leaf under an existing parent —
  presence checks need `-e`, not truthiness of the resolved path.

### Process Learnings
- Estimation was conservative; reuse-heavy tasks land faster than their "spans config +
  matching + two surfaces" decomposition signals suggest.
- The generic rollout/maintenance templates assume a deployed service. For file-based
  CWF features the honest content is "ships via `cwf-manage update` post-release;
  integrity via `cwf-manage validate`; fail-open is the steady state" — worth not
  forcing the SaaS shape.

### Risk Mitigation Strategies
- The planning High risk (untrusted URLs → prompt-injection/SSRF) was mitigated exactly
  as designed: opt-in, https-only, host-allowlisted fetch performed agent-side; verbatim
  source content wrapped in a per-run random sentinel and declared UNTRUSTED; classifier
  rejects >1 verdict block so an embedded fence cannot forge a verdict. Residuals
  (DNS-rebinding, non-crypto sentinel) documented as accepted, not silently carried.

## Recommendations
### Process Improvements
- Add a design-phase checklist item for any new reviewer/agent: "parallel peer or serial
  step? justify any serialisation with a strict data dependency." (Now also in memory.)

### Tool and Technique Recommendations
- Consider raising `security.review.max-lines` (or widening `max-lines-exclude-paths`)
  for CWF's own repo so self-development stops tripping the cap on every sizeable feature.

### Future Work
- **(Already raised by the user as a VERY HIGH backlog item)** The Task-204 "resolve
  `.cwf` paths from project root" change made skills emit shell command-substitution
  blocks (`gcd=$(git rev-parse …); cd …`) that trigger a permission prompt on nearly
  every tool call. Find a zero-prompt anchoring mechanism (single self-resolving helper,
  an env var set once, or scripts that resolve their own root). This surfaced acutely
  during this very retrospective.
- A populated-`best-practices.json` live-agent run in a consuming repo (this repo ships
  no fixture with matching docs, so only the 0-match branch is exercised end-to-end here).

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-15
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning/design: `a-task-plan.md` … `e-testing-plan.md` (this task dir).
- Implementation/test: `f-implementation-exec.md`, `g-testing-exec.md`; helper
  `.cwf/scripts/command-helpers/best-practice-resolve`; tests `t/best-practice-resolve.t`.
- Agents: `.claude/agents/cwf-plan-reviewer-best-practice.md`,
  `.claude/agents/cwf-best-practice-reviewer-changeset.md`.
- Normative doc: `.cwf/docs/skills/best-practice-review.md`.
- Checkpoint commits preserved on the checkpoints branch (Step 10).
</content>
</invoke>

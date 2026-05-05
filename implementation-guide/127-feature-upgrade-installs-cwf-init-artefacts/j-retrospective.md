# upgrade installs cwf-init artefacts - Retrospective
**Task**: 127 (feature)

## Task Reference
- **Task ID**: internal-127
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/127-upgrade-installs-cwf-init-artefacts
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-05

## Executive Summary
- **Duration**: 1 day (estimated: 3-5 days; variance: -67% to -80%)
- **Scope**: Delivered the full success-criteria set from a-task-plan.md (every artefact category, three-way diff, K/I/D/A prompt, atomic apply, regression-free) plus the D12 manifest-SHA pin proposed during design. No items descoped.
- **Outcome**: Success. `cwf-manage update` now installs everything `/cwf-init` does, with Debian-style conflict resolution. New shared module (`CWF::ArtefactHelpers`) consolidates helper code. 325/325 tests pass.

## Variance Analysis

### Time and Effort
- **Estimated** (from a-task-plan.md): 3-5 days, Medium-High complexity.
- **Actual** (from `git log` timestamps): single working day (2026-05-05), with phases completed in two clusters:
  - Plan phases (a-e): ~26 minutes total (08:05 → 08:31)
  - Exec phases (f-g): ~4 minutes of wallclock between exec checkpoint commits, on top of preceding implementation-and-test work spread across the morning (~12:26 → 12:30)
  - Rollout + maintenance + retrospective: < 30 minutes
- **Variance**: Underran by a factor of 3-5×. Reasons:
  - Helper design (D2 — extract shared module instead of duplicating) made the implementation smaller than expected.
  - Reusing the existing `cwf-claude-settings-merge` (Task 126) as a pre-built primitive removed an entire workstream from the original estimate.
  - LLM-assisted execution flattens human time estimates that anticipated separate think/code/test passes.

### Scope Changes
- **Additions**:
  - **D12 (manifest-SHA pin in `.cwf/version`)** — added during design as a defence against local manifest tampering. Not in the original plan; small and isolated, so absorbed without rescheduling.
  - **`CWF::ArtefactHelpers` shared module** — emerged in design (D2). Refactored `cwf-claude-settings-merge` to use it; net code-loss with zero behaviour change (9 existing tests passed unmodified).
- **Removals**: None. Every success criterion from a-task-plan.md is met or has documented rationale.
- **Impact**: Net positive on quality (one validated path-allowlist + atomic-write code path) at trivial schedule cost.

### Quality Metrics
- **Test Coverage**: 33 test files, 325 tests, 100% pass. 54 new tests across 3 new files (`artefacthelpers.t`, `cwf-apply-artefacts.t`, `cwf-manage-update.t`). Coverage gaps documented in g-testing-exec.md § "Coverage gaps (intentionally deferred)".
- **Defect Rate**: Zero post-implementation defects. The only mid-flight issue was an over-strict path-allowlist check on the manifest's `files` map (basenames, not paths) caught and fixed during implementation, before the testing phase.
- **Performance**: Helper completes in <100ms in tests; well within NFR1 (~50ms subprocess overhead per design). No performance regressions.

## What Went Well
- **Design's `CWF::ArtefactHelpers` extraction (D2) was load-bearing**: the shared module was used by `cwf-apply-artefacts` from day one and let `cwf-claude-settings-merge` shrink without behaviour change. Validates designing for reuse before the second consumer exists when reuse is highly likely.
- **D12 manifest-SHA pin defended against a real threat (local tampering) for trivial cost**: ~50 lines including the validation path. Surfaced cleanly via `cwf-manage validate`.
- **Sentinel-wrapped CLAUDE.md preamble (`<!-- CWF-PREAMBLE-START/END -->`) plus `_split_block` / `_wrap_legacy_block`** handled the bootstrap, sentinel-migration, and idempotent-update cases without bespoke string arithmetic at each callsite.
- **Fork-based flock concurrency test**: discovered during testing that `flock(2)` is per-process and a single-process test would always succeed. The fork test demonstrates the actual semantics. Recorded as a Lesson Learned.
- **Three-tier path validation** (allowlist + lstat + `O_NOFOLLOW`) defended against symlink-TOCTOU at three layers; the unit test (`TC-INT-LOCK-SYMLINK-TOCTOU`) confirms the outer two layers reject before the inner layer is reached.
- **Plan-review subagents (Step 8 of design + impl planning) flagged the path-allowlist scope question early**, preventing a half-built allowlist that would have needed a refactor mid-implementation.

## What Could Be Improved
- **Security-review subagent cap (500 lines) is qualitatively justified but quantitatively unsupported**. Task 127's changeset (2166 lines) blew through it; the manual-approval workflow worked but the threshold itself has no empirical basis. Recorded as a follow-up backlog item (see Recommendations § Future Work).
- **Helper file size (~570 lines for `cwf-apply-artefacts`)**: at the upper limit of comfortable single-file Perl. Future strategy additions should consider splitting strategies into per-file modules under `.cwf/lib/CWF/Apply/`.
- **Mid-flight files-key allowlist defect**: applying the source/dest prefix-allowlist to a `files`-map basename was a category error (basenames are not paths). Caught during implementation but should have been spotted in design — d-implementation-plan.md described both checks but did not call out their distinct semantics.
- **Coverage gap on full clone+subtree-pull integration (TC-INT-AC1, marked PARTIAL)**: a fixture-server harness would close the gap. Deferred as out-of-scope for unit tests; called out as future work.

## Key Learnings

### Technical Insights
- **Shared modules pay for themselves immediately when there is one obvious second consumer.** D2's extraction of `CWF::ArtefactHelpers` happened simultaneously with the new helper that consumed it; no speculative future-second-consumer waiting.
- **HTML-comment sentinels are the right primitive for embedded-block management in user-edited markdown**: invisible in rendered output, grep-friendly, and survive arbitrary user edits outside the block.
- **`flock(2)` per-process semantics**: any concurrency test for `flock` must use `fork` (or a sub-shell). A single-process test will silently pass.
- **D12 (manifest-SHA pin) detects only local tampering**, not upstream MITM — which is fine because the upstream-fetch path uses `git` over HTTPS/SSH and is already authenticated. Documented this explicitly in the security review.

### Process Learnings
- **Time estimates that anticipate separate think/code/test cycles overshoot LLM-assisted work by a factor of 3-5×.** Future estimates should be calibrated downward when the work is largely "design + write + test" with no novel research.
- **Recording the changeset breakdown verbatim in the security-review section (per user directive)** preserves the manual-approval reasoning for audit. Should become a default for any task that exceeds the subagent cap.
- **The exec→testing→rollout→maintenance→retrospective chain is reliable** when phases are committed as soon as they're complete, with `git status` before every checkpoint commit (caught no surprises this task — the discipline is paying off).

### Risk Mitigation Strategies
- **Secret-redaction (`is_secret_path`) gating option D**: pre-empted the leak risk for `.claude/settings.json` and `.env*` without complicating the K/I/A branches. Pattern is reusable for other secret-bearing paths.
- **Bootstrap-from-no-manifest path (FR9)** treats on-disk as baseline so pre-D12 installs upgrade silently. Avoided false-positive prompts on every upgrade for the entire installed base.
- **Non-TTY default abort + `CWF_UPGRADE_RESOLVE` env knob**: lets CI upgrade non-interactively without baking a wrong default into the prompt path.

## Recommendations

### Process Improvements
- **Quantitatively justify the security-review subagent cap.** Run 5-10 representative changesets at 250 / 500 / 1000 / 2000 lines, measure subagent finding-rate and runtime, set the threshold from data. (See backlog item.)
- **Calibrate plan estimates downward by ~3-5× for LLM-assisted "design + implement + test" tasks** where no novel research is required.
- **Default to recording the changeset breakdown in security-review when the subagent cap is exceeded**, not just when the user asks.

### Tool and Technique Recommendations
- **Promote `_split_block` / `_wrap_legacy_block`** (currently inside `cwf-apply-artefacts`) to `CWF::ArtefactHelpers` if a third consumer appears.
- **Use the fork-based concurrency-test pattern** as a template for any future test that exercises `flock(2)`, `fcntl(F_SETLK)`, or other per-process kernel state.
- **Adopt HTML-comment sentinels** as the standard idiom for any future "managed block inside a user-edited file" need.

### Future Work
- **Quantify the security-review subagent-cap threshold.** Currently 500 lines with no empirical basis (Task 123). Should be re-derived from data. Backlog candidate: chore.
- **Add a fixture-server harness for full `cwf-manage update` end-to-end tests.** Current coverage stops at the helper-level; a real clone+subtree-pull integration test would close TC-INT-AC1 (marked PARTIAL). Backlog candidate: chore.
- **Consider splitting `cwf-apply-artefacts` strategies into per-file modules under `.cwf/lib/CWF/Apply/`** if a 6th strategy is ever added. The current 5-strategy single-file layout is at the comfortable upper bound.

## Status
**Status**: Finished
**Next Action**: Task complete — pending maintainer squash + tag + merge to main
**Blockers**: None identified
**Completion Date**: 2026-05-05
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- All workflow files in `implementation-guide/127-feature-upgrade-installs-cwf-init-artefacts/`
- Implementation commits on branch `feature/127-upgrade-installs-cwf-init-artefacts` (10 checkpoint commits, see `git log main..HEAD`)
- Production-code diffstat: 15 files, +1991/-64
- Test results: 325/325 across 33 files (`prove t/`)
- Security review: documented in f-implementation-exec.md § "Security Review" (manual approval, full changeset breakdown embedded for audit)

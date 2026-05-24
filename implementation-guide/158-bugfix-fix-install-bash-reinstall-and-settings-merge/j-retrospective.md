# Fix install.bash reinstall and settings-merge - Retrospective
**Task**: 158 (bugfix)

## Task Reference
- **Task ID**: internal-158
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/158-fix-install-bash-reinstall-and-settings-merge
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-24

## Executive Summary
- **Duration**: <1 day (estimated: <1 day, variance: ~0)
- **Scope**: Three downstream-reported items, all delivered. Scope was narrowed during design — an apply-artefacts "parity" option (Option A) was investigated and **rejected** in plan review, settling on Option B (settings-merge only).
- **Outcome**: Success. `install.bash` force-reinstall no longer aborts on a missing-dir pathspec; `post_install` now lands `.claude/settings.json` for a raw `CWF_FORCE` migration; the security-review doc matches the helper. Full suite (516 tests) + `cwf-manage validate` green.

## Variance Analysis
### Time and Effort
- **Estimated** (bugfix — no requirements/rollout/maintenance phases): Planning + Design + Impl-plan + Test-plan + Impl-exec + Test-exec ≈ <1 day total.
- **Actual**: ~matches. Design absorbed the most effort (the Option-A/B scope question), not implementation.
- **Variance**: Negligible on time. The effort distribution skewed toward design/verification rather than coding — correct for a Correctness-first bugfix with a subtle git-index failure mode.

### Scope Changes
- **Additions**: None beyond the three reported items.
- **Removals**: Apply-artefacts parity (Option A) rejected during plan review. The premise — that a `CWF_FORCE` reinstall empties `.cwf/rules-inject.txt` and breaks the rule-injection hook — was false: the file ships **populated** inside the `.cwf` subtree (only the *template* is empty), so a reinstall lays it down populated. The proposed apply-artefacts call would have *emptied* it (manifest `replace` from the empty template). Settling on Option B avoided introducing the very breakage it claimed to prevent.
- **Impact**: Smaller, safer change. The residual `.gitignore`/CLAUDE.md-preamble migration drift for raw `CWF_FORCE` installs is left as an out-of-scope optional follow-up (minor drift, not breakage, not reported).

### Quality Metrics
- **Test Coverage**: TC-1..TC-7 cover all three items plus the failure/edge paths the fixes turn on (the paths the removed `|| true` previously swallowed). Each confirmed RED pre-fix, GREEN post-fix.
- **Defect Rate**: One self-caught test-assertion defect during development (clean *working tree* vs clean *index* — corrected to `git diff --cached`). No product defects.
- **Performance**: N/A.

## What Went Well
- **Plan review caught a load-bearing false premise.** The d-plan robustness reviewer challenged the Option-A rationale; direct `git ls-files -s` verification refuted it. Three earlier reviewers had confirmed the "empty blob" fact but misattributed template vs. consumed dest. The map/reduce review plus one careful verify-the-source check is exactly the gate that prevented shipping a harmful change.
- **Failure paths were tested, not just happy paths.** The old `|| true` hid the bug precisely because failures were swallowed; the new tests (TC-2, TC-5) assert the install now *aborts loudly*.
- **Root-independent failure simulation.** A fake-`git` PATH shim (exit 1 on `rm`, `exec` real git otherwise) deterministically exercises the "tracked-but-git-rm-failed" branch without permission tricks, so it works under root/CI too.
- **Mirrored existing precedent.** Item 2 copied `cwf-manage`'s `run_settings_merge` shape (`-x` guard, abort-before-version-write) rather than inventing a new completion mechanism.

## What Could Be Improved
- **The security-review subagent does not honour its own sentinel-first contract.** In all attempts (f and g phases) the `cwf-security-reviewer-changeset` reasoning-model agent prefaced its `no findings` verdict with analysis, so the deterministic three-tier classifier fell through to the conservative `error` default. The reviews were substantively clean, but the recorded `State` is `error`, which is noisy and could mask a real malformed-output failure if it became routine. This is a tooling/contract mismatch, not a one-off.
- **A test assertion encoded the wrong invariant first.** `git status --porcelain == ''` conflated a clean working tree with a clean index; post_install legitimately leaves untracked artefacts. Caught and corrected, but a moment's thought about what install.bash actually leaves behind would have avoided it.

## Key Learnings
### Technical Insights
- **Verify which file a hook actually reads before asserting a breakage.** `.cwf/rules-inject.txt` (consumed by the hook) and `.cwf/templates/install/rules-inject.txt` (the empty template) are different files; conflating them produced a confident-but-wrong design rationale.
- **`git commit -- <pathspec>` fails wholesale on a non-matching pathspec**, leaving prior staged changes in the index. Building the pathspec from the set actually modified (the `removed[]` array) is the robust pattern.
- **A PATH-shadowing shim that passes through to the real tool** is a clean way to inject a single deterministic subcommand failure into an end-to-end test.

### Process Learnings
- Design-phase scope questions (A vs B) are worth resolving *before* implementation even for a "small" bugfix; here it changed the deliverable materially.
- Recording a conservative classification verbatim (and explaining why) beats silently reinterpreting a malformed gate output — but the underlying gate should be made reliable.

### Risk Mitigation Strategies
- The "measure twice" verification habit (direct `git ls-files -s`, reading the manifest) converted a plausible-sounding plan into a refuted one before any code was written.

## Recommendations
### Process Improvements
- Investigate the sentinel-first contract violation (below) so clean reviews classify as `no findings` rather than `error`.

### Tool and Technique Recommendations
- Reuse the fake-git PATH-shim technique for other install/update failure-path tests.

### Future Work
- **Backlog (filed)**: cwf-security-reviewer-changeset sentinel-first contract not honoured by the reasoning model → classifier defaults to `error` on clean reviews.
- **Out-of-scope notes (not filed as tasks unless a consumer reports)**: (a) raw `CWF_FORCE bash install.bash` migration does not pick up *new-version* root-level `.gitignore`/CLAUDE.md-preamble additions; (b) `cwf-apply-artefacts`' `replace` strategy for `rules-inject` reads the empty template, so `/cwf-init`/`cwf-manage update` may empty a consumer's populated `rules-inject.txt` — a separate latent oddity worth its own investigation.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge to main
**Blockers**: None identified
**Completion Date**: 2026-05-24
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, c-design-plan.md (Resolved Decision — Option B), d-implementation-plan.md, e-testing-plan.md
- Implementation: f-implementation-exec.md (commit 19af0eb); g-testing-exec.md (commit 6f3d517)
- Tests: t/install-bash-reinstall.t (TC-1..TC-7)
- Changed: scripts/install.bash, .cwf/docs/skills/security-review.md

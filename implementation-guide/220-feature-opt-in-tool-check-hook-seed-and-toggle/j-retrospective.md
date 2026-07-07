# opt-in tool-check hook seed and toggle - Retrospective
**Task**: 220 (feature)

## Task Reference
- **Task ID**: internal-220
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/220-opt-in-tool-check-hook-seed-and-toggle
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-07

## Executive Summary
- **Duration**: Single focused work-stream across a-j (9 checkpoints, baseline `ed72881`).
  Calendar duration treated as noise per Task 219 finding S7 — the signal is tier +
  risk register, not elapsed days.
- **Scope**: Delivered as planned — kill-switch, regex-only starter set + seed helper,
  `/cwf-config tool-check on|off|seed` + `/cwf-init` opt-in sharing one path, docs +
  backlog correction. One deliberate naming change (`enabled` → `active`) settled in
  requirements/design; no descoping.
- **Outcome**: Success. The shipped-inert Task-201 framework is now opt-in usable
  without hand-authoring a settings file, and the ship-inert guarantee is preserved
  (zero rules → strict no-op; kill-switch defaults true only once rules exist).

## Variance Analysis
### Time and Effort
Per-phase calendar estimates intentionally not tracked (S7). Effort landed at the
planned "Medium" tier. The only unplanned effort was a robustness bug fix adopted
during f-exec review (see Quality Metrics) — absorbed within the phase, no schedule slip.

### Scope Changes
- **Naming change (`enabled` → `active`)**: the a-plan success criteria named a global
  `enabled` flag with enable-gate semantics. Requirements/design resolved it to
  `active` — a **kill-switch** defaulting *true*, resolved over trusted layers only
  (project-local > user-global; checked-in ignored to close clone-suppression). This is
  a semantic improvement, not scope creep: an enable-gate defaulting false would have
  broken the "seed then it just works" flow, and a default-true kill-switch composes
  correctly with the zero-rules no-op.
- **Open decisions resolved**: D1 → checked-in regex-only starter layer (as
  recommended); D2 → flag lives in the tool-check settings file (no `cwf-project.json`
  coupling); D3 → absent flag == inert no-op (preserved byte-for-byte).
- **Removals**: none. The `--test`/`--lint` rule-authoring helper stayed carved out to
  a future item, as planned.
- **Rollout decision (h)**: this repo ships the *mechanism only* — no checked-in
  starter set committed for CWF's own development. Adoption remains a backlog item now
  that the mechanism exists.

### Quality Metrics
- **Test Coverage**: 39 new tool-check subtests (unit 13 + hook 17 + helper 9); full
  suite `Files=75, Tests=970, PASS`; no Task-201 regression.
- **Defect Rate**: one real bug caught pre-merge by the robustness changeset reviewer —
  `effective_active` wrapped `read_settings` in `eval`, but `read_settings` failed via
  `die_err` → `exit 1`, which `eval` cannot trap; a symlinked/corrupt user-global file
  turned an already-completed write into a misleading `exit 1`. Fixed with a `soft => 1`
  read mode + regression TC-S9. Zero post-release defects (feature not yet adopted here).
- **Performance (NFR1)**: kill-switch short-circuits before perl compile (TC-H7); no
  extra stat/read on the hot path (`load_merged` returns decoded layers from its single
  existing read pass).

## What Went Well
- **The changeset-review MAP earned its keep.** The 5-reviewer f-exec panel surfaced a
  genuine reliability bug (robustness) *and* a single-source-of-truth improvement
  (`trusted_layers` was duplicated hook-side + helper-side → hoisted into the pure
  `CWF::ToolCheck` module, unit-tested via TC-U3b). Both adopted; the trust boundary
  can no longer drift.
- **Security-by-construction held.** Fail-open envelope preserved; symlink-safe atomic
  writes (`O_EXCL` + `rename`, 0600, per-level `-d && !-l`); boolean-only coercion via
  `JSON::PP::is_bool` guarding against a Perl-truthy `"false"` string; checked-in layer
  excluded from trust. Security reviewer: no findings across both exec phases.
- **Dogfooding produced live evidence.** During exec the real user-global tool-check
  rule denied a stray `head` command — the hook path is exercised in ordinary
  maintainer use, not just tests.
- **Open decisions were resolved deliberately** (Task 219 R4 discipline) rather than
  silently picked, and each resolution is traceable through the phase files.

## What Could Be Improved
- **Best-practice reviewer keeps matching domain-mismatched tags** (`golang`,
  `postgres`) against a Perl/markdown changeset — the known spurious-match noise flagged
  in the Task 219 retrospective. It correctly returned "no findings" both times by
  falling back to language-agnostic principles, but the tag-matcher still wastes a
  reviewer slot. Tracked as the standing Task-219 backlog item; nothing new to add.
- **Test-authoring friction**: TC-H7's first compile-probe used an ambiguous
  `print($f …)` inside a JSON-embedded `BEGIN`; the sentinel silently didn't write.
  Switching to an unambiguous `mkdir` probe with a positive control fixed it. Lesson:
  a negative-control test (assert-absent) needs its positive control in the same case,
  or a no-op masquerades as a pass.

## Key Learnings
### Technical Insights
- **A default-true kill-switch is the right shape for an opt-in guard**, not a
  default-false enable-gate. The gate is "are there any rules"; the switch only ever
  *suppresses*. This keeps the empty-state no-op and the opt-in flow from fighting.
- **Trust boundaries must be single-sourced in the pure layer.** The duplicated
  `trusted_layers` was a latent drift bug; a pure, exported, unit-tested function is the
  only copy the hook and the helper both resolve through.
- **`eval` cannot trap an `exit`.** A helper that fails via `exit 1` inside an `eval`
  block is uncatchable — the fix is an explicit soft-return mode, not a bigger `eval`.

### Process Learnings
- **The exec-phase review MAP is a real quality gate, not ceremony** — this task is a
  clean case of it catching a bug that unit tests as-written would have missed
  (the failure needed a symlinked user-global layer, added only as the regression test
  *after* the reviewer flagged it).
- **Accept-with-rationale is a first-class disposition.** The misalignment finding
  (hand-rolled atomic writer vs shared `CWF::ArtefactHelpers`) was correctly *not*
  adopted: the shared writer uses `make_path` and does not reject a symlink target, so
  reusing it would lose the NFR4 defence. Recorded the rationale + a future
  converge-the-writers candidate rather than taking the weaker abstraction.

### Risk Mitigation Strategies
- The a-plan's top risk ("hot-path regression bricks Bash") was contained exactly as
  planned — a pure early-return before any rule load/eval, proven by the fail-open
  matrix (TC-H2/H3/H6) and the before-compile short-circuit (TC-H7).
- The "toggle = unregister would appear broken" risk was avoided by design: the switch
  is a runtime flag the always-registered hook reads, never a `settings.json`
  register/unregister (which is session-cached).

## Recommendations
### Process Improvements
- When a test asserts a *negative* (sentinel absent / probe didn't run), require its
  positive control in the same test case. Consider noting this in the testing-plan
  guidance as a standing pattern.

### Tool and Technique Recommendations
- Keep hoisting shared pure logic into `CWF::ToolCheck` (or the relevant pure module)
  the moment a second caller appears — the improvements reviewer catches these, but
  authoring them single-sourced from the start is cheaper.

### Future Work
- **Adopt tool-check for CWF's own repo** (existing backlog item): now that the seed
  mechanism exists, decide whether to commit a checked-in starter set for maintainers.
  A rollout/adoption decision, deliberately not bundled into this task.
- **Converge the three atomic-writers** behind a symlink-reject option on
  `CWF::ArtefactHelpers::atomic_write_text` (candidate from the misalignment review) —
  touches a shared hash-tracked lib used by other helpers; own task.
- **Best-practice tag-matcher spurious matches** — already tracked from Task 219; no new
  item.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-07-07
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning through testing: `a-task-plan.md` … `g-testing-exec.md` (this task dir).
- Rollout / maintenance: `h-rollout.md`, `i-maintenance.md`.
- Checkpoint commits (baseline `ed72881`): `0ab7630` a · `5135330` b · `e43d0ac` c ·
  `448c24c` d · `7c0a047` e · `98f0f97` f · `31f7e21` g · `789949c` h · `4fb9c13` i.
- Changeset-review outputs: per-task scratch dir
  (`*-review-output-{implementation,testing}-exec.out`).

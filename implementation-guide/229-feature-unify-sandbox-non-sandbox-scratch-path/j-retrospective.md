# unify sandbox and non-sandbox scratch path - Retrospective
**Task**: 229 (feature)

## Task Reference
- **Task ID**: internal-229
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/229-unify-sandbox-non-sandbox-scratch-path
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-13

## Executive Summary
- **Duration**: Within the 1–2 day estimate. Ten phases (a–j), no decomposition.
- **Scope**: Delivered as scoped — one canonical, context-invariant scratch path — but by a
  stronger mechanism than the plan anticipated: the fix does not *reconcile* `$TMPDIR`
  across contexts, it stops reading `$TMPDIR` entirely and derives the base from the EUID.
- **Outcome**: Success. The reporter's path-doubling is now structurally impossible, the
  hook/writer path divergence is closed, and the `$TMPDIR`-injection attack class is removed
  outright. One accepted regression (macOS Seatbelt) with a Medium backlog follow-up.

## Variance Analysis
### Time and Effort
- **Estimated**: 1–2 days, Medium complexity.
- **Actual**: In band. The design phase carried the weight (five open decisions to close);
  implementation was a net deletion plus a delegating refactor, so exec was light.
- **Variance**: None material. Effort shifted *earlier* than a typical feature — the hard
  work was the investigation/design call to eliminate the `$TMPDIR` read rather than
  normalise it, after which the code shrank.

### Scope Changes
- **Additions**:
  - `scratch_fail_hint($kind)` helper — not in the plan. Design D3 had proposed extending
    `scratch_dir`'s return to carry the attempted path in slot 1; implementation planning
    (d) refined this to a separate exported helper, keeping the existing `(undef, $kind)`
    contract intact. Cleaner, less coupling; the c-design wording is left as the historical
    record (superseded, not amended) per the per-phase-checkpoint model.
  - Two `t/security-review-changeset.t` cases (TC-TMPDIR-1/2/3, TC-209-2) had to change
    because they encoded the *old* `$TMPDIR`-honouring behaviour — see Removals.
- **Removals / deferrals**:
  - **macOS Seatbelt support**: hardcoding `/tmp/claude-<euid>` fails closed where the
    writable temp is under `/var/folders`. Accepted by the owner as a known limitation;
    Medium backlog item "Platform-specific scratch base (Linux/macOS/…)" added.
  - **TC-209-2** (char-device-doesn't-abort): now *skips* on the exact `mkdir_failed`
    signal, because `unshare -rm` remaps to uid 0 → `/tmp/claude-0` (uncreatable under a
    read-only `/tmp`). Owner chose the skip-on-signal over bind-mount/tmpfs scaffolding.
- **Impact**: Net-negative code size, net-lower attack surface, marginally faster hook path
  (one fewer `lstat`). The macOS regression is the only quality cost, and it is contained
  (fail-closed with a cause-naming diagnostic, never silent).

### Quality Metrics
- **Test Coverage**: `prove -r t/` — 78 files, 1077 tests, all pass. `t/scratch.t` reworked
  to 13 cases; two new standing regression guards (TC-10 poison-`$TMPDIR` invariance, TC-11
  intermediate-symlink reject).
- **Defect Rate**: One low-severity style finding (a reviewer caught `sub dash` reading
  `$_[0]` instead of unpacking `@_`), fixed in-phase. No functional defects.
- **Integrity**: `cwf-manage validate` OK after the same-commit four-file hash refresh.

## What Went Well
- **Simplification won over reconciliation.** The instinct-level fix (normalise/dedup
  `$TMPDIR` across contexts) was the plan's framing; the investigation showed the only
  mode-invariant input is the EUID, so the right move was to delete the `$TMPDIR` read.
  Removing the variable that caused the bug beat teaching the code to cope with it.
- **The owner's "juice worth the squeeze?" steer prevented a scaffolding rabbit hole.** The
  TC-209-2 fix could have grown namespace/bind-mount machinery; challenging the complexity
  produced a one-line skip that keys on the fix's own diagnostic and preserves loud failure
  for genuine aborts.
- **Design front-loading paid off.** Closing all five open decisions in c-design meant exec
  had no ambiguity to resolve mid-flight.
- **Same-commit hash discipline held** — no drift reached the retrospective.

## What Could Be Improved
- **c-design out-ran the implementation contract.** D3/Interface committed to a concrete
  return-shape change that d-planning then reversed. Design could have stopped at "callers
  get a uniform, cause-naming diagnostic on `mkdir_failed`" (the outcome) and left the
  mechanism (return-shape vs helper) to implementation planning — the outcome-shaped-criteria
  discipline the planning docs already advocate, applied one level down to design decisions.
- **Test fixtures encoded behaviour, not intent.** TC-TMPDIR-1/2/3 asserted "honours
  `$TMPDIR`" rather than "hook and writer agree", so a correctness-improving change looked
  like a test break. Asserting the *property* (invariance / agreement) would have made the
  tests flip cleanly to stronger guards instead of needing rewrites.

## Key Learnings
### Technical Insights
- The mode-invariance requirement has exactly one satisfying input here: the EUID. Any
  env-derived base (`$TMPDIR`, probes) is by definition mode-variant and attacker-influenceable.
- Adding a predictable directory in world-writable `/tmp` (`/tmp/claude-<euid>`) demands the
  symlink/`0700` guard be extended to that *new* level — the containment boundary stays the
  atomic `0700` create + fail-closed write; the `-l` reject is defence-in-depth, ordered
  mkdir-then-check to avoid a TOCTOU regression.
- `unshare -rm` remaps to uid 0, which silently changes an EUID-derived path — a trap for any
  test that shells into a user namespace and then asserts on a uid-derived location.

### Process Learnings
- Design decisions benefit from the same outcome-shaping the task/requirements phases use:
  name the observable result, defer the mechanism to implementation planning.
- Write regression tests against the invariant you care about, not the current implementation
  detail — the former strengthen under a good change, the latter break under one.

### Risk Mitigation Strategies
- The planned "writability regression" high risk was retired by making failure *loud and
  explained* (fail-closed + `scratch_fail_hint`) rather than trying to guarantee writability
  on every platform — an honest boundary beat an over-promised one.

## Recommendations
### Process Improvements
- Consider a light "design decisions should be outcome-shaped too" note in design guidance,
  mirroring the planning-phase rule — this task is the worked example.

### Tool and Technique Recommendations
- When a test breaks under a correctness improvement, first ask whether it asserted the
  *behaviour* or the *intent*; prefer rewriting to the invariant over patching the assertion.

### Future Work
- **Platform-specific scratch base (Linux/macOS/…)** — Medium, already in BACKLOG. Detect the
  platform/sandbox and select the writable temp per platform while keeping mode-invariance,
  restoring macOS Seatbelt support. Promote when macOS `mkdir_failed` reports recur.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-07-13
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning → maintenance: `implementation-guide/229-feature-unify-sandbox-non-sandbox-scratch-path/{a..i}-*.md`
- Implementation commits (pre-squash): f `efcea42`, g `ce4f621`, h `442c564`, i `7e75d93`
- Convention of record: `.cwf/docs/conventions/tmp-paths.md`
- Retired backlog item: `CWF::Common::tmp_base()` → CHANGELOG.md under Task 229

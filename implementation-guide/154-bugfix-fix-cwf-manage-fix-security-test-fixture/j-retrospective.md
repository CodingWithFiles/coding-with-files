# fix cwf-manage-fix-security test fixture - Retrospective
**Task**: 154 (bugfix)

## Task Reference
- **Task ID**: internal-154
- **Branch**: bugfix/154-fix-cwf-manage-fix-security-test-fixture
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-22

## Executive Summary
- **Duration**: single session (estimated <0.5 day, Low complexity — on estimate).
- **Scope**: unchanged from plan. One test helper + one call site + one new test case (TC-8). No production code, no hashed file, no hash refresh.
- **Outcome**: success. `t/cwf-manage-fix-security.t` 8/8; full suite 500 pass; `cwf-manage validate` OK; security review no findings.

## Variance Analysis
### Time and Effort
- **Estimated**: <0.5 day total (Low). **Actual**: on estimate — planning phases (a/c/d/e) done in prior sessions; exec (f/g) + retrospective (j) one session.
- **Variance**: none material. The design phase's perm-floor correction (below) added thought but prevented a wasted follow-up.

### Scope Changes
- **Additions**: none unplanned. TC-8 was specified in e-testing-plan.md ("will add"), authored in g — planned work, not scope creep.
- **Removals**: none.
- **Impact**: nil.

### Quality Metrics
- **Test coverage**: TC-1/2/7 red→green; TC-3/4/5/6 re-run green (unchanged); TC-8 new (16 assertions, all 5 `.claude/agents/*.md` at floor 0444). Full suite 499→500.
- **Defect rate**: 0 defects found in testing or review.
- **Security**: changeset review clean both phases (one advisory category-(e) pattern-risk note, already documented inline).

## What Went Well
- **Manifest-derived copy set** (Decision 1) satisfied the "don't silently re-break" criterion structurally: any future non-`.cwf/` tracked path is provisioned and asserted automatically, no test edit.
- **TC-8 asserts on the derived set, not a hard-coded count** — it doubles as the drift guard the design called for.
- **Surfaced, not absorbed**: the failure was recorded as a BACKLOG item in Task 153 rather than silently patched, then fixed here through the full workflow.
- **Fail-closed guard**: the `..`/absolute path `die` (stricter than the production callsite by design) made the security review trivially clean.

## What Could Be Improved
- The bug was a latent fixture gap that only surfaced when `.claude/agents/*` entered the manifest (~Task 148/149). A fixture that derived its copy set from the manifest originally would never have drifted — the lesson is to bind test fixtures to the same source of truth the code under test uses.

## Key Learnings
### Technical Insights
- **Perm check is a floor, not an exact match** (`Security.pm:117`, `cwf-manage:776`: `($actual & $recorded) != $recorded`). An earlier design draft wrongly flagged fresh-clone perms as a limitation; verifying the operator collapsed a phantom BACKLOG follow-up. `cp -p`'s real value is umask-independence (a no-`-p` copy under umask 077 lands at 0600 and fails the 0444 floor), not exact-perm fidelity.
- A passing fixture must satisfy all three per-entry manifest checks — existence, byte-identical content (SHA), and perm floor — which `cp -p` from `$REPO_ROOT` delivers in one step.

### Process Learnings
- Plan-review subagents (4 per planning phase) caught the perm-floor error at design time, before any code — cheaper than discovering it in exec.
- Authoring the new test case (TC-8) in the testing-exec phase (g), while the production-side helper landed in implementation-exec (f), kept the phase boundary clean: f delivered the fix, g delivered the test that pins it.

### Risk Mitigation
- Risk 1 (hard-coding re-breaks on the next tracked root) was mitigated exactly as planned by deriving from the manifest; TC-8 enforces it going forward.

## Recommendations
### Process Improvements
- When writing a fixture for a tool that reads a manifest/config as its source of truth, derive the fixture contents from that same source rather than enumerating paths by hand. Candidate convention note, not a blocking gap.

### Future Work
- None specific to this task. The sibling backlog item *"Install-time chmod 0444 on data/agents files (avoid post-install fix-security)"* remains independently valid but is out of scope here.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge to main
**Blockers**: None
**Completion Date**: 2026-05-22

## Archived Materials
- Planning: a-task-plan.md, c-design-plan.md, d-implementation-plan.md, e-testing-plan.md
- Execution: f-implementation-exec.md (commit fb7fdb2), g-testing-exec.md (commit 5bcea8e)
- Resolves BACKLOG item "Fix t/cwf-manage-fix-security.t: build_fixture omits .claude/ manifest paths" (identified in Task 153)

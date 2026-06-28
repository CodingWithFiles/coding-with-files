# fix hook sandbox tmpdir scratch path - Retrospective
**Task**: 215 (bugfix)

## Task Reference
- **Task ID**: internal-215
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/215-fix-hook-sandbox-tmpdir-scratch-path
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-28

## Executive Summary
- **Duration**: ~0.5 day (estimated: ~1 day; variance: −50%). All six phases
  (a,c,d,e,f,g) completed in a single session, ~12:11–16:49.
- **Scope**: The bug was fixed as scoped, but via a **different mechanism** than the
  a-plan anticipated — Approach A (self-validating uid probe) instead of the planned
  Approach B (persisted `$TMPDIR` cache). The simpler approach removed a whole
  milestone and three risks. One same-bug-class collateral fix was added.
- **Outcome**: Success. The unsandboxed context-inject hook now emits the in-sandbox
  writable scratch base; verified end-to-end live, full suite (937) green, validate
  clean.

## Variance Analysis
### Time and Effort
- **Estimated**: ~1 day total (Medium complexity).
- **Actual**: ~0.5 day, single session. Per-phase wall-clock (gaps included):
  - Planning (a): ~12:11
  - Design (c): ~15:02
  - Implementation plan (d): ~15:13
  - Testing plan (e): ~15:14
  - Implementation exec (f): ~16:41
  - Testing exec (g): ~16:49
- **Variance**: Under estimate. The design pivot to Approach A removed the cache
  writer, the hook edit, the `.cwf/.gitignore` artefact, and the cold-start handling
  the estimate had priced in.

### Scope Changes
- **Additions**:
  - **Collateral fix — `t/backlog-bootstrap-changelog.t`**: surfaced by the full-suite
    run as a pre-existing failure of the *same bug class* (hardcoded
    `tempdir(DIR => '/tmp')`, fails read-only under the sandbox). Fixed on sight to
    honour `${TMPDIR:-/tmp}`; grep confirmed it was the only test with that
    anti-pattern. A green suite is an a-plan success criterion, so the fix was in
    scope by that criterion.
- **Removals (vs the a-plan's anticipated design)**:
  - The persisted `.cwf/config.local.json` `$TMPDIR` cache (writer + read-merge-write).
  - The hook (`userpromptsubmit-context-inject`) edit and its same-commit hash refresh.
  - The shipped `.cwf/.gitignore` / `install-manifest.json` gitignore-entries work.
  - **Success criterion 4** (no machine path; gitignore artefact) → **N/A**: Approach A
    adds no new file, so there was nothing to gitignore or keep out of the manifest.
- **Impact**: Smaller blast radius (1 production file + tests + a non-hashed doc),
  fewer moving parts, three plan risks eliminated rather than mitigated (see below).

### Quality Metrics
- **Test Coverage**: 100% of the new branch — every arm of the three-way resolver
  (env / probe-adopted / four `/tmp` fall-throughs) has a dedicated case (TC-9..TC-14).
  Full suite: 937 tests, all PASS (74 files).
- **Defect Rate**: Zero defects introduced. One post-review doc-comment nit (probe
  "two stats" → "one lstat") caught by the robustness reviewer and fixed in-task.
- **Performance**: In-sandbox hot path (env branch) stays disk-free; the
  unsandboxed-hook probe branch costs a single `lstat`. No measurable regression.
- **Integrity**: `cwf-manage validate` clean; `Common.pm` sha256 refreshed in the same
  commit per the hash-updates convention.

## What Went Well
- **The design pivot (B→A) paid off.** Choosing a self-validating in-resolver probe
  over a persisted cache eliminated — not merely mitigated — three a-plan risks
  (cold-start/toggle-lag, accidental `.cwf/` cache commit, concurrent-writer race) and
  removed the entire "Install/integrity" milestone. Fewer parts, less new code.
- **Self-validating fallback.** The probe degrades to the status-quo `/tmp` base on any
  non-match (absent, non-writable, symlinked, empty), so the worst case is exactly
  today's behaviour — no new failure mode.
- **End-to-end live verification**, not just unit tests: with `$TMPDIR` deleted (the
  unsandboxed-hook condition) the resolver returned the in-sandbox writable base. The
  bug's success criterion was demonstrated against the real environment.
- **The full-suite gate did its job** — it surfaced the latent same-class defect in an
  unrelated test that source-grepping the planned files would never have found.
- **Review MAP clean**: 5 exec reviewers + 2 testing reviewers, all no findings bar one
  advisory improvement (logged, deferred).

## What Could Be Improved
- **The same bug class lived in more than one place.** The hardcoded-`/tmp` pattern in
  a test predated this task; the core fix addresses the resolver but the codebase still
  open-codes `${TMPDIR:-/tmp}` in four sites. A shared helper would have made the
  collateral fix a one-liner and prevent the next recurrence (see Future Work).
- **Plan/design mechanism drift.** The a-plan committed to Approach B mechanics
  (milestones, risks, constraints all framed around the cache) before design explored
  alternatives. The pivot was the right call, but the plan's risk section aged
  immediately. For bugfixes where the mechanism is genuinely open, the a-plan could
  stay mechanism-neutral and defer mechanism-specific risks to c.

## Key Learnings
### Technical Insights
- **Hook/Bash-tool sandbox asymmetry is the root cause and is reusable knowledge**:
  Claude Code hooks run *unsandboxed* (`$TMPDIR` unset → `/tmp`) while the Bash tool
  runs *sandboxed* (`$TMPDIR=/tmp/claude-<uid>`, `/tmp` read-only). Any hook that
  freezes a `${TMPDIR:-/tmp}` literal emits a path the in-sandbox shell cannot write.
- **The sandbox temp base is `/tmp/claude-<uid>`, not `/tmp/claude`** — undocumented
  naming; the probe derives it from the numeric effective uid (`$>`) rather than
  trusting an external string.
- **Self-validating probe > persisted state** for environment discovery: probing the
  live filesystem (`!-l && -d _ && -w _`) and falling back is simpler and safer than
  caching a value that can go stale across a sandbox toggle.

### Process Learnings
- **Run the full suite, not just the touched-file tests.** The collateral defect was
  invisible to the planned scope and only the whole-suite gate caught it.
- **Let design challenge the plan's mechanism.** The biggest win came from c overriding
  a's assumed approach — the workflow's phase separation worked as intended.

### Risk Mitigation Strategies
- Preferring an approach that *removes* a risk class over one that *mitigates* it: the
  probe has no cache, so the cache-staleness, cache-commit, and cache-race risks simply
  do not exist.

## Recommendations
### Process Improvements
- For bugfixes with an open mechanism, keep a-plan risks mechanism-neutral and let the
  design phase own mechanism-specific risk.

### Tool and Technique Recommendations
- The self-validating probe + safe-fallback pattern is worth reaching for whenever code
  must discover an environment-dependent path.

### Future Work
- **Extract `CWF::Common::tmp_base()`** (backlog): the `${TMPDIR:-/tmp}` selection is
  now open-coded in four sites (`Common.pm`, `pretooluse-bash-tool-check`,
  `best-practice-resolve`, and the `t/backlog-bootstrap-changelog.t` fix) — crossing
  the Rule of Three. An exported helper would consolidate them and make the next
  consumer correct by default. Raised by the improvements reviewer; deferred from this
  bugfix to avoid widening its blast radius into two further production sites.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-28
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, c-design-plan.md, d-implementation-plan.md, e-testing-plan.md
- Implementation: f-implementation-exec.md (commit 5c7669a)
- Testing: g-testing-exec.md (commit 8397322)
- Baseline commit: ba88c179a78a131d84a8aa25c653fc95359675e3 (Task 214)

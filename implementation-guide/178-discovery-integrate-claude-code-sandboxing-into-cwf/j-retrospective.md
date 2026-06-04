# Integrate Claude Code sandboxing into CWF - Retrospective
**Task**: 178 (discovery)

## Task Reference
- **Task ID**: internal-178
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/178-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-04

## Executive Summary
- **Duration**: <1 day (estimated: <1 day; variance ≈ 0). Planning (a–e) and exec (f–g)
  ran across two sessions with a compaction between; no calendar slippage.
- **Scope**: Delivered exactly the planned discovery — a cited, per-requirement
  feasibility assessment of CWF-managed Claude Code sandboxing for R1 (phase-scoped
  writes), R2 (credential deny-list), R3 (issue logging), plus an integration shape,
  weakness carry-forward, build/decompose recommendation, and one seeded backlog item.
  No production code, as constrained.
- **Outcome**: Success. All five SCs met; all six FRs satisfied; TC-1..TC-7 PASS; both
  exec-phase security reviews `no findings`. Recommendation: BUILD, staged
  (prerequisite → R2 → R1 → R3), decomposed at `/cwf-new-task` time.

## Variance Analysis
### Time and Effort
- **Estimated**: <1 day total (discovery: read/verify/assess/recommend, no code).
- **Actual**: <1 day. Planning a–e (prior session) + exec f–g (this session).
- **Variance**: ~0. The discovery framing held; no rework loops, no phase re-entry.

### Scope Changes
- **Additions**: None to the deliverable. One material *finding* expanded the analysis
  beyond what the plans anticipated (see Key Learnings): the sandbox is Bash-only, which
  forced R1/R2 to be assessed against the **permission system** (Edit/Read rules) as well
  as `sandbox.*`, not `sandbox.*` alone.
- **Removals**: None. The decision to seed **one** parent backlog entry (rather than
  three per-requirement entries) is a presentation choice, not a descope — the
  decomposition recommendation is carried inside that entry's body.
- **Impact**: None on timeline; the Bash-only finding strengthened the verdicts.

### Quality Metrics
- **Test Coverage**: TC-1..TC-7 = 7/7 PASS (artefact-audit coverage of every FR AC).
- **Defect Rate**: 0 findings across both exec-phase security reviews; 0 test failures.
- **Performance**: N/A (discovery produces documents).

## What Went Well
- **Plan-review paid for itself at exec time.** The d-plan review (4 reviewers) had
  already surfaced and corrected the `backlog-manager add --title` requirement and the
  script-path-vs-skill-name distinction, so Step 7 seeding ran clean on the first try
  (single live entry, `validate` exit 0).
- **Evidence-hierarchy decision (doc/schema quote > grep > never memory) worked exactly
  as designed.** Re-fetching the live docs at exec — rather than trusting the earlier
  in-session reading — is what surfaced the Bash-only fact and the verbatim
  "denyRead still allows `~/.aws`/`~/.ssh`" wording. Citation-over-inference is the
  Task-177 lesson, and it held.
- **Failure-wired verdicts prevented a green-but-empty table.** Forcing each verdict to
  carry its fail-open behaviour and enforceable-vs-advisory label produced an assessment
  that says what is *real*, not merely *configurable*.
- **The discovery stayed discovery.** No production config was written; TC-7 confirmed
  the exec commits touched only wf files + BACKLOG.md.

## What Could Be Improved
- **The plans under-anticipated the Bash-only boundary.** a–e spoke of R1 via "static
  `allowWrite`" as though the sandbox governed the Edit/Write tools. It does not. The
  exec evidence corrected this, but a sharper Stage-A question ("which tool does each
  requirement's boundary actually act on?") would have framed R1/R2 correctly from the
  requirements phase. Recommendation captured below.
- **`task-context-inference` emitted version-mismatch warnings** for unrelated legacy
  tasks (27/28/29) on every invocation. Harmless noise here, but it dilutes signal in
  the preamble output. Pre-existing; not introduced by this task.

## Key Learnings
### Technical Insights
- **The Claude Code sandbox isolates Bash subprocesses only.** Read/Edit/Write file tools
  use the permission system, not `sandbox.*`. Any CWF feature that set only
  `sandbox.filesystem.*` would leave the file tools unguarded — credential denial (R2)
  needs **paired** `denyRead` (Bash) + `Read(...)` permission deny (Read tool), and the
  planning-write boundary (R1) is a permission/PreToolUse concern, not a sandbox one.
- **No structured "sandbox violated" hook event exists.** R3 is intrinsically a proxy
  signal (PreToolUse catching a `dangerouslyDisableSandbox` retry; PostToolUseFailure) —
  it can never be a reliable violation detector. The verdict was capped accordingly.
- **Enforcement is the operator's, not CWF's.** `dangerouslyDisableSandbox` is
  agent-reachable; boundaries are advisory unless `allowUnsandboxedCommands:false`.
- **`cwf-claude-settings-merge` is the substrate, and it is narrow today** — writes
  `permissions.allow` only and accepts `{Stop, SubagentStop}` hook events only. Every
  R1/R2/R3 build path runs through extending it (manage `sandbox.*` + `permissions.deny`;
  widen hook events), each with a same-commit `script-hashes.json` refresh.

### Process Learnings
- Estimation for a tightly-scoped discovery was accurate; the "stop at a recommendation +
  seeded follow-up" constraint (Risk 4 mitigation) kept scope from creeping into a build.
- The explicit "we'll review after exec" gate the user set worked well with the
  checkpoint-per-phase rhythm: f and g committed independently, leaving a clean review
  surface before retrospective.

### Risk Mitigation Strategies
- Risk 1 (R1 has no clean mechanism) materialised as predicted — there is no per-phase
  static switch. Because the plan had named it the central open question and pre-listed
  candidate mechanisms, the null result was recorded as a finding (PreToolUse hook is the
  path), not a surprise.
- The transient-fetch-vs-absence rule was applied: the docs 301-redirected to
  `code.claude.com`; the redirect was followed and re-fetched rather than recorded as an
  absence.

## Recommendations
### Process Improvements
- **Add a "which tool does the boundary act on?" question to Stage A of any
  sandbox/permission discovery.** The Bash-only-vs-permission-system split is the single
  fact that most reshapes such an assessment; asking it at requirements time would have
  pre-empted the R1 "static allowWrite" framing.

### Tool and Technique Recommendations
- Keep the re-fetch-at-exec discipline (evidence hierarchy) as the default for any task
  whose verdicts depend on external/vendor documentation — it caught a material fact that
  an in-session memory would have carried wrong.

### Future Work
- Seeded: **"CWF-managed Claude Code sandboxing config (R2 credential deny-list, R1
  phase-scoped writes, R3 violation logging)"** (feature, Medium) — to be decomposed at
  `/cwf-new-task` time into the shared `cwf-claude-settings-merge` extension prerequisite
  + R2 + R1 + R3, with the carried weaknesses and the hash-refresh-same-commit constraint
  in the body.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-04
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, b-requirements-plan.md, c-design-plan.md,
  d-implementation-plan.md, e-testing-plan.md
- Findings: f-implementation-exec.md (mechanism inventory, verdict table, weakness
  carry-forward, recommendation, both security reviews)
- Testing: g-testing-exec.md (TC-1..TC-7, all PASS)
- Commits: f `4a01f43`, g `5fc68ad` (pre-squash; preserved on the checkpoints branch)
- Backlog: seeded feature entry in BACKLOG.md

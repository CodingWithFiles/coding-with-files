# Integrate Claude Code sandboxing into CWF - Plan
**Task**: 178 (discovery)

## Task Reference
- **Task ID**: internal-178
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/178-integrate-claude-code-sandboxing-into-cwf
- **Baseline Commit**: ed664b25541f0ae35de09633fe5155c500a502bc
- **Template Version**: 2.1

## Goal
Determine how CWF can drive Claude Code's built-in sandbox/permission boundary to
achieve three operator-requested protections — phase-scoped write isolation during
planning, default-deny reads of a CWF-editable credential list, and opt-in logging
of sandbox issues — and produce a grounded recommendation (not an implementation).

## Scope note (discovery, not build)
CWF does **not** enforce sandboxing; Claude Code does, from `settings.json`
(`sandbox.*` / `permissions.*`), enforced at the OS level (Seatbelt / bubblewrap).
So "integration" means CWF *generates, manages, or advises* that config (plus its
own editable lists and any phase-aware switching), and observes failures via hooks.
This task delivers a verified feasibility assessment + a recommended design shape +
seeded follow-up task(s); it writes no production sandbox code.

## Success Criteria
- [ ] **SC1 (feasibility, cited)**: For each of the three requirements, a verdict —
      Feasible / Feasible-with-caveats / Not-feasible — each backed by a cited
      Claude Code mechanism (settings key, hook event, or permission rule) confirmed
      against current docs/schemas this session, not from memory.
- [ ] **SC2 (phase-scoping mechanism)**: A concrete, named mechanism for switching
      the write boundary by workflow phase (a–e = planning) is identified, with its
      trigger and where the config lives, or its absence is recorded as a blocker.
- [ ] **SC3 (credential deny-list shape)**: The shape of a CWF-user-editable
      credential deny list is defined — where it lives (`cwf-project.json` vs a
      dedicated file), how it maps to `sandbox.filesystem.denyRead`, and how it
      merges with adopter edits and managed settings.
- [ ] **SC4 (logging signal + default-off)**: The observable signal for "sandbox
      issue" is identified (which hook/exit path actually exposes a violation or
      unsandboxed fallback), with a default-OFF, user-selectable switch design.
- [ ] **SC5 (recommendation + decomposition)**: A written recommendation states
      whether to build, how to stage it, and whether it needs to split into subtasks
      (e.g. per-requirement features), with the rationale.

## Original Estimate
**Effort**: <1 day (discovery — read/verify/assess/recommend; no production code)
**Complexity**: Medium — three distinct mechanisms, each with its own caveats; the
phase-switching one (SC2) is the most uncertain.
**Dependencies**: This session's `WebFetch`/`ToolSearch` access to current Claude
Code docs and tool/hook schemas; CWF's existing config (`cwf-project.json`) and hook
infrastructure (`.cwf/scripts/hooks/`) as the integration substrate.

## Major Milestones
1. **Mechanisms confirmed**: The sandbox/permission/hook features each requirement
   depends on are verified against current docs (settings keys, hook events).
2. **Per-requirement feasibility**: R1 (phase-scoped writes), R2 (credential
   deny-list), R3 (issue logging) each assessed with caveats and a config sketch.
3. **Integration shape**: How CWF manages the config (install-time vs per-phase),
   how its editable lists merge, and how hooks observe failures — described.
4. **Recommendation + follow-ups**: Build/don't-build, staging, and any subtask
   split written; backlog item(s) seeded.

## Risk Assessment
### High Priority Risks
- **Risk 1 (R1 has no clean mechanism)**: There may be no first-class way to switch
  `sandbox.filesystem.allowWrite` *by workflow phase* — settings are static per
  session/scope. The phase boundary might require a PreToolUse hook doing path
  checks (re-introducing parsing concerns) rather than the OS sandbox.
  - **Mitigation**: Treat SC2 as the central open question; enumerate candidate
    mechanisms (hook-based gate, per-phase settings fragment, `settings.local.json`
    rewrite) and record which actually work vs which are speculative. A null result
    (no clean mechanism) is a valid, valuable finding.
- **Risk 2 (enforcement is the operator's, not CWF's)**: Anything CWF writes to
  `settings.json` can be widened or disabled by the operator; CWF cannot guarantee
  the boundary holds. Over-promising "CWF sandboxes your planning phase" would be
  false.
  - **Mitigation**: Frame every recommendation as advisory config CWF *provides*,
    with the enforcement/ownership boundary stated explicitly.

### Medium Priority Risks
- **Risk 3 (logging signal may be weak)**: Sandbox violations may not be cleanly
  exposed to a hook; the only signal might be command failure + `dangerouslyDisable
  Sandbox` retries, which is noisy.
  - **Mitigation**: SC4 verifies the actual observable signal before designing the
    log; if weak, record the limitation rather than designing around an assumption.
- **Risk 4 (scope creep into building)**: Three requirements invite jumping to
  implementation.
  - **Mitigation**: Hard stop at a recommendation + seeded follow-up tasks; no
    `settings.json`/helper/hook production code in this task.

## Dependencies
- Current Claude Code docs (sandboxing, permissions, hooks, settings) and live hook
  event schemas — gathered this session, cited (per `feedback_no_fabricated_citations`).
- CWF substrate: `cwf-project.json` config conventions; the installed-hook pattern
  under `.cwf/scripts/hooks/`; the hash-integrity surface (new hooks/helpers would
  need hash entries — relevant to the *feature*, noted not done here).

## Constraints
- Discovery only: no production sandbox/permission config, no new helper/hook code.
  Sole durable output is the findings file + seeded backlog item(s).
- British spelling; no personal names in committed docs.
- Recommendations must respect CWF portability constraints (POSIX, core-Perl) and
  the "surface, don't smooth" security stance — a logging feature must not become a
  way to silently disable the boundary.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No (discovery is <1 day).
- [ ] **People**: >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? **Yes** — R1/R2/R3 are independent
      mechanisms. But this is the *discovery*; the concern is whether the eventual
      *feature* should split. That recommendation is SC5's job, not a reason to
      split the discovery.
- [ ] **Risk**: High-risk components needing isolation? No (no code shipped).
- [x] **Independence**: Parts separable usefully? **Yes, for the feature** — R1, R2,
      R3 could each be their own feature task. Flagged for SC5; the discovery itself
      stays whole (one coherent assessment).

Two signals point at the *feature*, not the discovery. The discovery remains a
single task; SC5 decides the feature's decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five SCs met. SC1: R1/R2/R3 each carry a cited verdict (Feasible-with-caveats /
Feasible-with-caveats / Feasible-with-caveats-unreliable). SC2: phase-switch mechanism =
a PreToolUse hook keyed on the wf step; no static per-phase switch exists (recorded as
such). SC3: deny-list shape = paired `denyRead` + `Read(...)` deny, editable list in
`cwf-project.json`. SC4: logging signal = PreToolUse/PostToolUseFailure proxy, default-OFF
switch. SC5: BUILD-staged recommendation + decompose-at-task-creation, one backlog entry.

## Lessons Learned
Risk 1 (no clean R1 mechanism) materialised as predicted; naming it the central open
question up front meant the null result was a finding, not a surprise. The Bash-only
sandbox boundary (surfaced at exec) was the fact the plan most under-anticipated — see
j-retrospective.md.

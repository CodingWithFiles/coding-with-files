# Bash tool-check framework - Plan
**Task**: 201 (feature)

## Task Reference
- **Task ID**: internal-201
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/201-bash-tool-check-framework
- **Baseline Commit**: 59ce57afa813a3388f53252f7236d6ad4744e3dd
- **Template Version**: 2.1

## Goal
Provide a configurable, layered PreToolUse framework that lets CWF and its
users define PCRE/Perl rules which intercept `Bash` tool calls and echo
avoidance guidance back to the agent, with an exact-repeat bypass so a
wrongly-flagged command can still proceed.

## Problem
Many Bash tool calls trip Claude Code's built-in permission prompts — usually
because the agent writes needlessly complex shell or reaches for tools the
harness sanctions (`sed`, `awk`, `find`, …). The exact set of offending
commands shifts from model to model and from one Claude Code version to the
next, so no fixed, shipped solution stays correct. CWF needs a *mechanism*
(rules the user owns) rather than a *fixed shape*.

## Success Criteria
- [ ] A fail-open PreToolUse `Bash` hook matches each command against an
      ordered rule set and, on first match, returns the rule's guidance as a
      `deny` reason so the agent can self-correct.
- [ ] An identical command repeated immediately (twice in a row) is NOT
      blocked — it falls through to Claude Code's native permission check.
- [ ] Rules merge from three layers with defined precedence:
      user-global `~/.cwf/tool-check/bash/settings.json`,
      project checked-in `{root}/.cwf/tool-check/bash/settings.json`,
      project-local `{root}/.cwf/tool-check/bash/settings.local.json`.
- [ ] Both rule kinds are supported: PCRE-only regex rules and (for complex
      cases) Perl-function rules.
- [ ] Fresh installs AND upgrades both add `.cwf/tool-check/*/settings.local.json`
      to `.gitignore`.
- [ ] Any config/engine error or pathological pattern never blocks a Bash call
      (fail-open), and tests cover matching, layering, repeat-bypass, and
      fail-open.

## Original Estimate
**Effort**: 2-3 days
**Complexity**: High
**Dependencies**: `cwf-claude-settings-merge` (hook registration), the
integrity manifest / `cwf-manage`, the install + upgrade scripts, `.gitignore`
management.

## Major Milestones
1. **Requirements locked**: rule model (regex vs Perl), layer precedence,
   repeat-bypass semantics, fail-open posture, security/trust boundaries.
2. **Design**: config schema, three-layer merge algorithm, repeat-detection
   state mechanism, FR4 threat model (arbitrary-Perl + injection + ReDoS),
   install/upgrade wiring.
3. **Implementation**: engine hook + lib, config loader/merge, a starter rule
   pack, install/gitignore/settings-merge/integrity integration.
4. **Test + rollout**: unit + end-to-end tests, manifest hash refresh,
   BACKLOG/CHANGELOG.

## Risk Assessment
### High Priority Risks
- **Arbitrary Perl / prompt-injection**: Perl-function rules and project-shipped
  config execute inside the hook; a hostile or compromised `.cwf/tool-check`
  could run attacker code or feed injected text into agent context.
  - **Mitigation**: design-phase FR4 threat model; treat project rule files as
    code-trust-equivalent to repo source; guidance text is rule-authored, never
    a reflected `tool_input` string; decide trust posture for user-global vs
    project-local vs checked-in layers.
- **Fail-open correctness**: a bug that blocks every Bash call would brick the
  agent.
  - **Mitigation**: whole body in `eval`, exit 0 / empty stdout on any
    exception; dedicated fail-open tests; fail-open is the explicit posture
    (opposite of the planning-write-guard).

### Medium Priority Risks
- **ReDoS**: a pathological PCRE could hang the hook on every Bash call.
  - **Mitigation**: bound matching with an alarm/timeout; on timeout fail-open.
- **Repeat-detection state**: "same command twice in a row" needs reliable,
  concurrency-safe per-session state.
  - **Mitigation**: design decision on scope (session-keyed) and storage; treat
    a missing/unreadable state file as "not a repeat" (fail-open to guidance).

## Dependencies
- `cwf-claude-settings-merge` and the `cwf-hook-event`/`cwf-hook-matcher`
  registration convention.
- Integrity manifest (`script-hashes.json`) and `cwf-manage` validate/fix.
- Install + upgrade scripts (for `.gitignore` and settings wiring).

## Constraints
- Perl core-only (macOS system-perl portability); `use utf8;` per repo rules.
- "Regex" means **PCRE only** (Perl's native engine) — no POSIX BRE/ERE, no
  glob, no second flavour. (User-confirmed.)
- Hook output must conform to the Claude Code PreToolUse JSON contract.
- Fail-open posture is mandatory (a tool-check must never brick Bash).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No.
- [ ] **People**: Does this need >2 people? No.
- [x] **Complexity**: 3+ distinct concerns (runtime engine, config/merge,
      install/upgrade integration).
- [ ] **Risk**: high-risk components — present (arbitrary Perl) but contained
      within the design phase, not a separate workstream.
- [x] **Independence**: parts are separable.

**Assessment**: 2 signals triggered, but the parts are tightly coupled (config
feeds the engine; install wires both up) — a single cohesive feature. Proceed
as one task; revisit subtasks only if the design balloons.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All seven success criteria met. Delivered as one cohesive task (the decomposition
assessment held); the 2-3 day estimate came in under, driven by reuse of the
planning-write-guard lib/hook shape.

## Lessons Learned
The two triggered decomposition signals (complexity, independence) were correctly
overridden by tight coupling — splitting would have added integration overhead for no
gain. Estimate accuracy benefited most from recognising an existing reusable pattern up front.

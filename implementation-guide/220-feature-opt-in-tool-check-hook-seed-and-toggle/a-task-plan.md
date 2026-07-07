# opt-in tool-check hook seed and toggle - Plan
**Task**: 220 (feature)

## Task Reference
- **Task ID**: internal-220
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/220-opt-in-tool-check-hook-seed-and-toggle
- **Baseline Commit**: ed728818b8bb4e5795d65c02c921b182eb109aa3
- **Template Version**: 2.1

## Goal
Make the shipped-inert Bash tool-check hook opt-in usable — a global runtime
enable flag the hook honours fail-open, a regex-only starter ruleset with a seed
action, and a `/cwf-config tool-check on|off|seed` surface that `cwf-init` offers
on explicit confirm — so a fresh user gets working shell-hygiene nudges without
hand-authoring an empty settings file.

## Success Criteria
- [ ] A global runtime `enabled` flag exists that the hook honours **fail-open**
      (`enabled:false` → immediate allow, before any rule evaluation), effective
      live — no session restart and no `.claude/settings.json` edit.
- [ ] `/cwf-config tool-check on|off|seed` flips the flag and installs the starter
      ruleset; each subcommand's effect is observable via the hook `--check`/`--test` path.
- [ ] A regex-only starter ruleset ships and installs into the resolved layer; every
      seeded rule fires on its target command and no-ops otherwise.
- [ ] `cwf-init` offers the seed on **explicit confirm** (opt-in); declining leaves
      the hook strictly inert (today's behaviour preserved byte-for-byte).
- [ ] Existing hook invariants hold — fail-open on empty/malformed/disabled, perl
      dropped from the checked-in layer — and `cwf-manage validate` passes; R3
      backlog premise corrected.

## Original Estimate
**Effort**: agent-paced, ~1–2 sessions (calendar estimate treated as noise per Task 219 finding S7 — the signal is the tier + risk register below)
**Complexity**: Medium
**Dependencies**: Task 201 tool-check framework; the `cwf-config` skill (today only touches `autoload.yaml`); the `cwf-init` flow; hash-tracking of `pretooluse-bash-tool-check` if its source changes

## Major Milestones
1. **Global enable flag**: hook short-circuits fail-open on a runtime flag, with tests.
2. **Starter ruleset + seed**: a regex-only starter set and the seed action that installs it into the resolved layer.
3. **Surface wiring**: `/cwf-config tool-check on|off|seed` subcommand + `cwf-init` opt-in confirm, both calling one seed/toggle path (DRY).
4. **Docs + backlog**: update `tool-check-rules.md`; correct the R3 premise.

## Risk Assessment
### High Priority Risks
- **Hot-path regression bricks Bash**: any change to `pretooluse-bash-tool-check` risks the fail-open guarantee.
  - **Mitigation**: the enable check is a pure early return *before* any rule load/eval; keep the existing fail-open envelope; test empty / malformed / disabled all resolve to allow (exit 0, empty stdout).
- **"Toggle = unregister" would appear broken**: hook registration in `settings.json` is session-cached (loads at session start), so unregistering wouldn't take effect mid-session.
  - **Mitigation**: toggle a *runtime flag the hook reads*, never register/unregister the hook. The hook stays always-registered and inert when off.

### Medium Priority Risks
- **Seed-layer choice** (checked-in regex-only vs user-global) affects perl-safety and shareability — see Open Decisions.
  - **Mitigation**: recorded as an explicit open decision; default recommendation is checked-in regex-only; resolve in requirements/design before any seed content is written.
- **Scope creep into a rule-authoring UI**.
  - **Mitigation**: authoring stays ad-hoc (LLM) + a separate `--test`/`--lint` helper item; explicitly out of scope here.
- **Auto-seeding contradicts "mechanism, not rules"** (the framework ships deliberately inert).
  - **Mitigation**: seed is opt-in behind an explicit confirm; declining preserves the inert default, so the philosophy holds.

## Open Decisions (per Task 219 finding R4 — resolve in requirements/design, do not silently pick)
- **D1 — Seed target layer**: checked-in project layer (`{repo}/.cwf/tool-check/bash/settings.json`, travels via clone, shareable, **regex-only**) vs user-global (`~/.cwf/…`, per-machine, perl allowed). Recommendation: checked-in regex-only.
- **D2 — Flag location**: a top-level `enabled` key in the tool-check settings file vs a `cwf-project.json` config key. Recommendation: the tool-check settings file, so the hook reads one source with no extra config coupling.
- **D3 — Flag default when seed is declined**: absent-flag semantics must equal today's inert no-op (fail-open, allow).

## Dependencies
- Task 201 tool-check framework (`pretooluse-bash-tool-check`, `CWF::ToolCheck`).
- `cwf-config` skill — presently manages only `~/.cwf/autoload.yaml`; this extends its remit to a behavioural-guard setting.
- `cwf-init` flow — must gain an opt-in confirm step.

## Constraints
- Perl **core modules only**; POSIX portability (macOS system Perl).
- The **fail-open** invariant is non-negotiable — a tool-check must never brick Bash.
- **perl rules never in the checked-in layer** (dropped before compile by design).
- `pretooluse-bash-tool-check` is hash-tracked — any source edit refreshes `script-hashes.json` in the **same commit** (hash-updates convention).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — agent-paced ~1–2 sessions.
- [ ] **People**: >2 people on different parts? No.
- [x] **Complexity**: 3+ distinct concerns? Borderline — hook flag / seed mechanism / config+init surface. Tightly coupled around one feature with a shared test surface.
- [ ] **Risk**: High-risk components needing isolation? No — the one hot-path risk is contained by the fail-open early-return.
- [ ] **Independence**: Can parts be worked separately? Partly, but they share one settings-file contract; splitting would create artificial coupling.

**Verdict**: 1 signal (complexity, borderline). Below the 2-signal threshold — **do not decompose**. The one genuinely separable piece (`--test`/`--lint` helper) is already carved out to its own future item.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered as planned. The one plan-level change: the global flag shipped as `active`
(default-true kill-switch) rather than `enabled` (enable-gate) — settled in
requirements/design. Open decisions D1/D2/D3 resolved as recommended.

## Lessons Learned
An opt-in guard wants a default-*true* kill-switch, not a default-false enable-gate:
the "any rules present" gate is the real enable signal, and a kill-switch only ever
suppresses — so it composes with the zero-rules no-op instead of fighting it.

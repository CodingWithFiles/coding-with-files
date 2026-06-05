# phase-scoped planning-write PreToolUse guard - Plan
**Task**: 180 (feature)

## Task Reference
- **Task ID**: internal-180
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/180-phase-scoped-planning-write-pretooluse-guard
- **Baseline Commit**: 9117bca9257f9a041eec37f2fa3b52d366afb28c
- **Template Version**: 2.1

## Goal
Deliver R1 from the CWF sandboxing feature (Task 179, c-design D7 / b-AC4d): when
sandboxing is on, a PreToolUse hook on `Edit`/`Write` that — during planning
phases (a–e) — gates writes to the current task's own planning files and blocks
edits to production crown jewels (`.cwf/`, `.claude/`, skills, helpers), failing
**closed** on ambiguous inference without bricking legitimate work.

## Scope note (grounded in Task 179)
179 shipped the substrate this rides on: the `read_hook_directives` **event**
allowlist already admits `PreToolUse` (the seam, confirmed at
`cwf-claude-settings-merge:94`), and the R3 hook
(`pretooluse-sandbox-logging`) is the model for a PreToolUse hook. **Two things
179 deliberately did not do, which 180 must:** (i) widen the **matcher** regex
(`/^[A-Za-z0-9_-]+$/`, `cwf-claude-settings-merge:98`) to admit `Edit|Write`;
(ii) the fail-closed-without-bricking enforcement design. Critical posture
difference: R3 is **fail-open observe-only**; R1 is **fail-closed enforcing** —
the opposite stance, made deliberately.

## Success Criteria
- [ ] **SC1 (matcher widening, scoped + safe)**: `read_hook_directives` admits a
      pipe-alternation of tool-name tokens (e.g. `Edit|Write`) while still
      rejecting shell/settings metacharacters; the inert-string rationale is
      restated; existing matcher tests (TC-M*) still pass; same-commit
      `script-hashes.json` refresh.
- [ ] **SC2 (phase-scoped gate)**: with sandboxing on, the PreToolUse hook on
      `Edit|Write`, during planning phases (a–e), **permits** writes to the
      current task's own planning files and **denies** writes to production
      crown jewels (`.cwf/`, `.claude/`, skills, helpers); it does **not** block
      during exec phases (f/g) where production writes are expected.
- [ ] **SC3 (fail-closed without bricking)**: on ambiguous/absent/error
      inference (`task-context-inference` exit 1/2/3, empty `task-stack`, a call
      outside any task) the gate **denies only the crown jewels** and surfaces a
      fixed-token message — never blocks unrelated writes (no brick), never
      silently allows a crown-jewel write.
- [ ] **SC4 (reuse + bounded cost)**: the wf step + task are derived from
      `task-context-inference` / `CWF::TaskContextInference.pm` (no re-parsing of
      branch/`task-stack`); the per-Edit/Write overhead (TCI shells out to git)
      is **measured** and bounded, recorded in testing (NFR1).
- [ ] **SC5 (opt-in + integrity)**: the gate is gated on the sandbox toggle
      (a dedicated sub-knob vs riding `sandbox.enabled` is fixed at
      requirements/design); registered via the merge helper; `cwf-manage
      validate` clean; no validate-silencing surface.

## Original Estimate
**Effort**: 2–4 days (matcher widening + guard hook + fail-closed policy +
path-classification + config + docs + tests).
**Complexity**: Medium–High — a fail-**closed** enforcing hook is higher-stakes
than R3's observe-only logger; the bricking/leak balance and path
classification are the hard parts.
**Dependencies**: Task 179 substrate; `task-context-inference` /
`CWF::TaskContextInference.pm`; `cwf-claude-settings-merge` matcher regex;
current Claude Code **PreToolUse deny-decision** hook output schema (re-cite at
design — R3 only needed exit 0, R1 must emit an actual deny); `hash-updates.md`.

## Major Milestones
1. **Matcher widening (prerequisite)**: regex admits `Edit|Write` safely;
   rationale restated; same-commit hash refresh; TC-M* green.
2. **Guard hook**: new `.cwf/scripts/hooks/pretooluse-…` keyed on `Edit|Write`,
   reusing TCI, emitting a PreToolUse deny for out-of-scope writes.
3. **Fail-closed policy**: crown-jewel deny-on-ambiguity, no-brick elsewhere,
   fixed-token surfacing; path classification hardened (traversal/relative/symlink).
4. **Config + gating + docs + tests**: toggle/sub-knob; registration; limitations
   doc updated; `cwf-manage validate` clean; NFR1 cost recorded.

## Risk Assessment
### High Priority Risks
- **Risk 1 (fail-closed bricks legitimate work)**: the central uncertainty. Too
  narrow an allow-set blocks planning-time writes (the task's own files, BACKLOG,
  scratchpad) and stalls the agent; too wide leaks a crown-jewel write.
  - **Mitigation**: derive the allow-set from the TCI-resolved current task dir;
    on ambiguity deny **only** crown jewels (not everything); test both
    directions exhaustively; consider an **observe-only first mode** (log would-block)
    before enforcing, to de-risk.
- **Risk 2 (matcher-regex widening weakens injection defence)**: the regex
  governs strings that reach a `.claude/settings.json` key (FR4(e) surface).
  - **Mitigation**: widen **minimally** to an allowlist of tool-name alternations
    (e.g. `^[A-Za-z0-9_-]+(\|[A-Za-z0-9_-]+)*$`), never arbitrary metacharacters;
    plan- and exec-phase security review; tests for rejected injections.

### Medium Priority Risks
- **Risk 3 (path-classification correctness)**: deciding "crown jewel" vs "this
  task's planning file" from `tool_input` paths (relative, absolute, `..`,
  symlink) is error-prone — a miss bricks or leaks.
  - **Mitigation**: canonicalise the target path; test traversal/relative/symlink;
    deny-on-uncertainty for crown jewels only.
- **Risk 4 (per-call cost)**: TCI shells out to git on every Edit/Write.
  - **Mitigation**: measure (NFR1); cache within a single hook invocation; accept
    or optimise the spawn cost.
- **Risk 5 (editing the security-critical, hash-tracked helper again)**: a bug in
  the widened `read_hook_directives` could mis-register hooks.
  - **Mitigation**: same-commit hash refresh; preserve existing matcher/event
    behaviour byte-for-byte (TC-M*/TC-U* regression); security review.

## Dependencies
- Task 179 deliverables: widened event allowlist, R3 hook model, `sandbox`
  config block + `_validate_sandbox_block`, `cwf-claude-settings-merge`.
- `task-context-inference` (exit 0 correlated / 1 disagree / 2 error / 3
  no-signals; emits `task_num` + `workflow_step`) and `CWF::TaskContextInference.pm`.
- Current Claude Code PreToolUse hook output schema for a **deny** decision.

## Constraints
- POSIX, **core-Perl only**; British spelling; no personal names.
- Same-commit `script-hashes.json` refresh for every hash-tracked edit; new hook
  registered + allowlisted via the merge helper; **no** validate-silencing surface.
- Fixed-token surfaced messages; no interpolation of tool_input/command into
  harness/LLM-visible output (FR4(c)/(e)).
- **Posture**: this is the one fail-**closed** enforcing path in the feature —
  the opposite of R3; the bricking/leak trade-off must be explicit and tested.

## Decomposition Check
- [ ] **Time**: >1 week? No (2–4 days).
- [ ] **People**: >2? No.
- [x] **Complexity**: 3+ concerns? Matcher widening + guard hook + fail-closed
      policy + config — but they converge on one helper + one new hook + the
      config block (cohesive, like 179).
- [x] **Risk**: high-risk component needing isolation? The fail-closed policy
      (Risk 1) is the uncertain core; an **observe-only first mode** is the
      in-task de-risking lever rather than a separate subtask.
- [~] **Independence**: matcher widening is a hard prerequisite for the hook to
      register with `Edit|Write`, so the pieces are sequenced, not independent.

**Decision**: Keep as a **single task**, sequenced matcher-widening →
guard-hook → fail-closed-policy → config/docs/tests. The genuine uncertainty
(Risk 1) is handled by an observe-only-first option the design phase will weigh,
not by further decomposition. Surfaced for plan review.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
SC1–SC5 all met. Delivered as a single task as decided; the "observe-only first
mode" de-risk lever shipped as the `observe` knob value. Under the 2–4 day
estimate (~1 day) — the 179 substrate carried most of the structure.

## Lessons Learned
The decomposition call (single task, sequenced) was right: the pieces converged
on one helper + one hook + the config block, exactly like 179. The central Risk 1
(fail-closed bricking) was defused at design time by the crown-jewel deny-list,
so exec carried no surprises on that axis.

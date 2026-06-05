# Integrate Claude Code sandboxing into CWF - Plan
**Task**: 179 (feature)

## Task Reference
- **Task ID**: internal-179
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/179-integrate-claude-code-sandboxing-into-cwf
- **Baseline Commit**: a20b682046d6b392416c4ab737f3ecdeaa901d6e
- **Template Version**: 2.1

## Goal
Build CWF-managed Claude Code sandboxing as a master opt-in toggle (default OFF) in
`cwf-project.json` that, when enabled, drives Claude Code's sandbox/permission config via
`cwf-claude-settings-merge` — a credential deny-list (R2), phase-scoped planning-write
isolation (R1), opt-in violation logging (R3), with `failIfUnavailable` defaulting `true`
— shipped with an honest advises-not-enforces limitations doc.

## Scope note (build, grounded in Task 178)
Task 178 (discovery) established the mechanisms and verdicts; this task implements them.
CWF does **not** enforce — it *generates/advises* config that Claude Code + the OS
enforce, and the operator can widen or disable. The central first-hand finding carried in:
**the sandbox is Bash-only**, so credential denial (R2) needs PAIRED `sandbox.filesystem.
denyRead` + `Read(...)` permission deny, and phase-scoped writes (R1) are a permission /
PreToolUse-hook concern, not a static `allowWrite` switch. See
`implementation-guide/178-discovery-integrate-claude-code-sandboxing-into-cwf/f-implementation-exec.md`.

## Success Criteria
- [ ] **SC1 (master toggle, default OFF)**: A single CWF setting in `cwf-project.json`
      gates the whole feature, defaulting **OFF**. With it off, `cwf-claude-settings-merge`
      writes **zero** `sandbox.*` / `permissions.deny` keys (verifiable: `--dry-run` shows
      no sandbox surface added). No regression to the existing `permissions.allow` / hooks
      / `PERL5OPT` behaviour.
- [ ] **SC2 (R2 credential deny-list)**: A user-editable list in `cwf-project.json`
      (default ≥ `~/.ssh`, `~/.aws`) compiles to **paired** `sandbox.filesystem.denyRead`
      **and** `Read(...)` permission deny in the merged `.claude/settings.json`; an adopter
      can narrow a shipped default via `allowRead` without editing CWF's files.
- [ ] **SC3 (`failIfUnavailable` default true + first-run guard)**: When sandboxing is on,
      CWF writes `failIfUnavailable: true` by default (authoritative — the knob value wins,
      not add-if-absent), overridable via the knob; **and** an unavailable sandbox surfaces
      an actionable message (deps to install / knob to flip), never a bare "won't start".
- [ ] **SC4 (R1 phase-scoped writes)**: During planning phases (a–e), writes are gated to
      the task's own planning files via a PreToolUse hook keyed on the current wf step —
      **or**, if design/impl shows this is disproportionate, R1 is split to a follow-up
      subtask with a recorded rationale (never silently dropped).
- [ ] **SC5 (R3 logging + limitations doc)**: Opt-in (default **OFF**) logging of the
      available proxy signal (PreToolUse `dangerouslyDisableSandbox` retry /
      PostToolUseFailure); and a shipped user-facing **Limitations** doc stating
      advises-not-enforces, Bash-only, agent-reachable escape hatch, and no-reliable-
      violation-event. Logging must not become a silent boundary-disable.

## Original Estimate
**Effort**: 2–4 days (helper extension + R2 + R1 hook + R3 + docs + tests).
**Complexity**: Medium–High — one security-critical helper, a new hook, a config surface,
and the Bash-only/permission-system split to get right.
**Dependencies**: Task 178 findings; `cwf-claude-settings-merge` (the substrate);
`cwf-project.json` config conventions; `docs/conventions/hash-updates.md`; current
Claude Code sandbox/permission/hook docs (re-cite at exec where behaviour is load-bearing).

## Major Milestones
1. **Substrate extended**: `cwf-claude-settings-merge` manages `sandbox.*` +
   `permissions.deny` and registers `PreToolUse`/`PostToolUseFailure` hooks (events widened
   beyond `{Stop, SubagentStop}`); master toggle + `failIfUnavailable` plumbing; same-commit
   `script-hashes.json` refresh. (Prerequisite — everything else rides this.)
2. **R2 shipped**: editable deny-list → paired `denyRead` + `Read(...)` deny; defaults.
3. **R1 shipped (or split)**: PreToolUse phase-write hook keyed on wf step, or subtasked.
4. **R3 + docs shipped**: opt-in logging; Limitations doc; tests + `cwf-manage validate`.

## Risk Assessment
### High Priority Risks
- **Risk 1 (R1 hook complexity)**: The PreToolUse phase-write gate is the most uncertain
  piece — it must infer the current wf step (on-disk task files / `task-stack`), fire on
  every Edit/Write call, and not break legitimate writes. Could balloon scope.
  - **Mitigation**: Sequence R1 **last**; the master toggle + R2 deliver standalone value.
    If R1 proves disproportionate, split it to a subtask (SC4 permits this with rationale).
- **Risk 2 (editing a security-critical, hash-tracked helper)**: A bug in the extended
  `cwf-claude-settings-merge` could mis-write `.claude/settings.json`, weaken the boundary,
  or corrupt existing user settings.
  - **Mitigation**: same-commit hash refresh (`hash-updates.md`); plan- and exec-phase
    security review; idempotency + merge + dry-run tests; preserve the existing
    add-if-absent semantics for `permissions.allow`/hooks/`PERL5OPT` byte-for-byte.

### Medium Priority Risks
- **Risk 3 (over-promising)**: presenting an advisory boundary as enforcement.
  - **Mitigation**: the Limitations doc is a tracked SC5 deliverable; every user-facing
    string says "advises", never "enforces".
- **Risk 4 (`failIfUnavailable:true` breaks unsupported platforms)**: fail-closed blocks
  start on native Windows / WSL1 / missing `bubblewrap`+`socat`.
  - **Mitigation**: first-run guard (SC3); unix-primary stance; the knob is overridable.
- **Risk 5 (merge-authority confusion)**: the helper's existing keys are add-if-absent;
  the toggle / `failIfUnavailable` / deny-list need *authoritative* writes or stale config
  persists.
  - **Mitigation**: define per-key merge authority explicitly in the design phase.

## Dependencies
- Task 178 findings file (mechanism inventory, verdict table, weakness carry-forward).
- `cwf-claude-settings-merge`, `cwf-project.json` + `.template`, `install-manifest.json`,
  `script-hashes.json`, the hook infrastructure under `.cwf/scripts/hooks/`.
- Current Claude Code docs (sandbox/permissions/hooks) for any behaviour the build relies on.

## Constraints
- POSIX, **core-Perl only** (macOS system-Perl portability).
- Every hash-tracked edit lands its `script-hashes.json` refresh in the **same commit**;
  add **no** surface that silences `cwf-manage validate` (surface, don't smooth).
- New helper/hook needs a `script-hashes.json` entry + allowlist/registration via the merge
  helper itself.
- British spelling; no personal names in committed docs.

## Decomposition Check
- [ ] **Time**: >1 week? No (estimate 2–4 days).
- [ ] **People**: >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? **Yes** — substrate extension, R2, R1 hook, R3.
- [x] **Risk**: high-risk component needing isolation? **Partially** — the
      `cwf-claude-settings-merge` edit is security-critical, and the R1 hook is uncertain.
- [~] **Independence**: R1/R2/R3 are *conceptually* separable, **but** all four concerns
      converge on **one** helper (`cwf-claude-settings-merge`) and **one** config file
      (`cwf-project.json`). Splitting them into subtasks would serialise edits to the same
      hash-tracked file and create artificial coupling (the guide's explicit
      "natural boundaries don't exist / forced decomposition creates artificial coupling").

**Decision**: Keep as a **single task**, implemented in the milestone order above
(prerequisite → R2 → R3 → R1-last). Two signals trigger, but the shared-helper coupling
makes a clean split impossible without churn. **The one genuine fault line is R1** (the
PreToolUse hook is independently deliverable and the most uncertain) — SC4 pre-authorises
splitting *only R1* into a subtask if design/impl shows it is disproportionate. Surfaced
for the plan review and the operator to confirm at review.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

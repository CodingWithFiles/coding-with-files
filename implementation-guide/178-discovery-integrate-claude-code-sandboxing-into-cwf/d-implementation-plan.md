# Integrate Claude Code sandboxing into CWF - Implementation Plan
**Task**: 178 (discovery)

## Task Reference
- **Task ID**: internal-178
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/178-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1

## Goal
Execute the c-design-plan investigation: gather cited evidence, fill the two tables in
`f-implementation-exec.md`, write the recommendation, and seed the backlog item(s) via
the helper. No CWF production code (no `settings.json`/helper/hook edits).

## Workflow
Gather doc/schema evidence → audit the CWF substrate first-hand → assign failure-wired,
enforceability-labelled verdicts → write recommendation → seed backlog via helper →
record what was found and why.

## Files to Modify
### Primary Changes
- `implementation-guide/178-.../f-implementation-exec.md` — the findings: mechanism
  inventory table, feasibility verdict table, substrate-gap notes, weakness
  carry-forward, recommendation.
- `BACKLOG.md` — the durable deliverable: seeded feature item(s), written **only**
  through `cwf-backlog-manager` (never a direct edit).

### Explicitly NOT modified (discovery constraint)
- `.claude/settings.json`, `.cwf/scripts/command-helpers/cwf-claude-settings-merge`,
  `cwf-project.json`, anything under `.cwf/scripts/hooks/` — no production change.

## Implementation Steps

### Step 1: Re-gather mechanism evidence (Stage A; FR1)
- [ ] `WebFetch` the current Claude Code docs and quote verbatim the fragments bearing
      on each requirement:
      - R1: `sandbox.filesystem.allowWrite` semantics; whether any per-session/
        per-phase switch exists; whether a `PreToolUse` hook is the only phase gate.
      - R2: `sandbox.filesystem.denyRead` + `Read(...)` deny; default-read-leaks-creds
        note; `allowManagedReadPathsOnly`; **how `denyRead` resolves symlinks /
        non-canonical / `~`-vs-`$HOME` paths** (quote the matching rule, or record
        that the doc is silent → Unverifiable).
      - R3: enumerate the **hook events** and identify whether any fires on a sandbox
        violation / unsandboxed fallback; `dangerouslyDisableSandbox` reachability
        (operator-only vs agent-invokable) and `allowUnsandboxedCommands`.
- [ ] `ToolSearch` the live hook/tool schemas where the doc is thin (e.g. the hook
      event list, the Agent/Bash `dangerouslyDisableSandbox` parameter).
- [ ] **Transient-failure rule**: if a fetch fails (network), re-attempt; do not
      record a verdict from a failed fetch. Reachable-but-silent → Unverifiable /
      Not-feasible-today (Stage A degradation rule). Record any doc that could not be
      reached as a gap, not a guess.

### Step 2: Audit the CWF substrate first-hand (Stage B; FR3)
- [ ] Re-read `cwf-claude-settings-merge` and confirm (already grep-verified this
      session): writes `permissions.allow` only — no `sandbox.*` / `permissions.deny`;
      `read_hook_directives` validates event to `{Stop, SubagentStop}` only.
- [ ] Read `implementation-guide/cwf-project.json` (the active config; not at repo
      root) + `.cwf/templates/cwf-project.json.template` for the config conventions a
      credential-list / logging-switch key would follow.
- [ ] Record the two extension gaps with their cost: (i) add `sandbox.*` /
      `permissions.deny` management to the merge helper; (ii) widen the hook-event
      allowlist for `PreToolUse`/`PostToolUse` — each implies a `script-hashes.json`
      refresh in the same commit.

### Step 3: Build the mechanism inventory table (FR1)
- [ ] One row per (requirement, mechanism): mechanism, citation (quoted doc/schema),
      "in `cwf-claude-settings-merge` today? (y/n)", gap/extension cost. "none found"
      is a valid cell and must propagate (Step 5/6).

### Step 4: Build the feasibility verdict table (FR2/FR4/FR5)
- [ ] One row per requirement: verdict ∈ {Feasible, Feasible-with-caveats,
      Not-feasible-today, Unverifiable}; **fail-open behaviour** (advisory-off vs
      hard-fail under `failIfUnavailable`); **enforceable-vs-advisory** (is
      `dangerouslyDisableSandbox`/unsandboxed fallback agent-reachable; does
      `allowUnsandboxedCommands:false` close it); key caveats.
- [ ] Apply the wiring: a "none found"/sole-Unverifiable mechanism ⇒ Not-feasible-today
      (candidate named); R3 with no structured violation event ⇒ at most
      Feasible-with-caveats-**unreliable**.
- [ ] Record R2 specifics: merge precedence + **removal case** (can an adopter un-deny
      a shipped default?), canonicalisation/symlink behaviour, `~`/`$HOME` expansion.
- [ ] Record R1's phase-switch trigger candidate (wf step inferred from on-disk task
      files / `task-stack`) and whether it can drive a static `allowWrite` or only a
      `PreToolUse` hook.

### Step 5: Weakness carry-forward (FR5)
- [ ] List the documented sandbox weaknesses bearing on the three requirements
      (default-read-leaks-creds; non-TLS egress proxy; `excludedCommands` no managed
      lockdown; fail-open; agent-reachable escape hatch) and which the feature must
      account for. State that R3 logging must not become a silent boundary-disable.

### Step 6: Recommendation + decomposition (FR6, Stage D)
- [ ] Write build / don't-build / build-subset + staging order; decide whether to split
      into per-requirement subtasks (R1/R2/R3) with rationale grounded in the verdicts
      (e.g. R2 likely cleanest; R1 gated on the phase-switch finding; R3 gated on the
      violation-signal finding). A "don't build X" is stated, not omitted.

### Step 7: Seed the backlog item(s) (FR6 deliverable)
The runnable helper is `.cwf/scripts/command-helpers/backlog-manager` (the `cwf-`
prefix is the *skill* name, not the script path); use the script path for CLI
invocations with exit-code capture.
- [ ] Draft each item body to a **project-namespaced scratch file first**
      (`.cwf/docs/conventions/tmp-paths.md`; no heredocs per `feedback_no_heredocs`).
- [ ] Fix the exact entry **title** string up front; it must be identical across the
      pre-add grep, the `add --title`, and the post-add count grep.
- [ ] `.cwf/scripts/command-helpers/backlog-manager list --all-items` — grep that
      title to detect a pre-existing live entry before adding (no duplicate).
- [ ] `.cwf/scripts/command-helpers/backlog-manager add --title="<exact title>"
      --task-type=feature --priority=<pri> --body-file=<scratch>` (list-form/opaque
      args; `--title` is **required** — the helper dies without it). Body carries:
      verdict-grounded scope, the carried caveats, and the **hash-refresh-same-commit**
      constraint for the future helper edit.
- [ ] **Partial-failure recovery**: on non-zero `add`, record the exit code and re-run
      from the scratch file; never leave zero/duplicate entries.
- [ ] **Single-entry assertion**: `backlog-manager validate --all` (exit 0) checks
      *format only* — it does **not** catch a duplicate. The duplicate/count guard is
      `list --all-items | grep -c "<exact title>"` == expected count. Report every
      exit code.

## Code Changes
N/A — discovery produces documents + a helper-mediated backlog edit; no source code
is modified.

## Test Coverage
**See e-testing-plan.md** — verification is a checklist against the FR ACs (every
mechanism cited, every verdict failure-wired + enforceability-labelled, substrate
gaps priced, single live backlog entry per item, no production code touched).

## Validation Criteria
**See e-testing-plan.md** for the full checklist.

## Scope Completion
**IMPORTANT**: Complete all steps before marking Finished. The recommendation +
backlog seed (Steps 6–7) is the deliverable — do not stop after the tables. If the
operator must review findings before the seed, that pause is explicit, not a silent
deferral.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Steps 1–7 executed in order. Steps 1–2 (gather + substrate audit) confirmed the two
helper gaps and the Bash-only boundary. Steps 3–5 produced the two tables + weakness
carry-forward. Step 6 wrote the BUILD-staged recommendation + decompose decision. Step 7
seeded one backlog entry via `backlog-manager add --title=... --body-file=<scratch>`
(exit 0; count 1; `validate` exit 0).

## Lessons Learned
The plan-review corrections to Step 7 (the required `--title`, script-path-vs-skill-name,
grep-not-validate as the count guard) meant the seed ran clean first time — the review
cost was repaid immediately.

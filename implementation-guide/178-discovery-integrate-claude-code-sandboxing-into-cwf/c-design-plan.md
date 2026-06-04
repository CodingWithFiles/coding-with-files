# Integrate Claude Code sandboxing into CWF - Design
**Task**: 178 (discovery)

## Task Reference
- **Task ID**: internal-178
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/178-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1

## Goal
Define the *investigation method* and the *shape of the discovery's outputs*: how each
mechanism claim is gathered and cited, how feasibility verdicts and their failure
outcomes are recorded, how the existing CWF substrate is checked, and how the
recommendation flows into seeded backlog item(s). This is a discovery — the design is
of the assessment, not of the sandbox feature.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

For a discovery: "testability" = every verdict re-checkable from its cited source;
"reversibility" = the only durable mutation (seeded backlog item) is helper-mediated
and trivially re-editable.

## Grounding already established (this session, first-hand)
- `cwf-claude-settings-merge` manages `permissions.allow` (Bash allowlist), hook
  registration, and `env.PERL5OPT`; it **does not** touch `sandbox.*` or
  `permissions.deny` (grep confirmed: only `permissions.allow` is written).
- Its `read_hook_directives` validates the hook event to **`{Stop, SubagentStop}`
  only** (line ~82) — `PreToolUse`/`PostToolUse` cannot be registered through the
  supported path today; an unknown event silently falls back to `Stop`.
- Sandbox/permission semantics (Seatbelt/bubblewrap; `sandbox.filesystem.allowWrite`
  / `denyRead`; non-TLS egress proxy; fail-open unless `failIfUnavailable`;
  `dangerouslyDisableSandbox` escape hatch; `allowManagedReadPathsOnly`) — gathered
  from the current Claude Code docs earlier this session; to be **re-quoted verbatim**
  in the f-file, not carried from memory.

## Key Decisions

### Decision 1 — Evidence hierarchy: live doc/schema quote > repo grep > (never) memory
- **Decision**: Resolve each mechanism claim from (a) a quoted line of the current
  Claude Code docs (`WebFetch`) or a live tool/hook schema (`ToolSearch`); (b) a
  first-hand grep/read of the CWF repo for the substrate side; never (c) remembered
  semantics. Doc text earlier in this session is re-fetched/re-quoted at exec.
- **Rationale**: This is the Task-177 lesson applied — replace inference with citation
  (`feedback_no_fabricated_citations`). The sandbox docs are prescriptive enough to
  cite directly; the CWF substrate is verifiable by reading the helper.
- **Trade-offs**: Re-fetching costs a little time; the payoff is durable, re-checkable
  verdicts.

### Decision 2 — Verdict carries a failure outcome, not just a label
- **Decision**: Every requirement row records verdict ∈ {Feasible, Feasible-with-
  caveats, Not-feasible-today, Unverifiable} **and** the wired consequences: a "none
  found"/sole-Unverifiable mechanism → Not-feasible-today (candidate named, never an
  empty cell); each Feasible(-with-caveats) verdict states its **fail-open behaviour**
  (silently advisory-off vs hard-fail under `failIfUnavailable`); R3 with no
  structured violation event is capped at Feasible-with-caveats-**unreliable**.
- **Rationale**: The robustness review showed each FR could "pass" while the assessment
  as a whole left R1's switch, R2's removal case, and R3's signal under-determined.
  Wiring the outcome into the verdict prevents a green table that asserts nothing.
- **Trade-offs**: More columns/notes per row; that is the point — the verdict must
  carry whether the protection is *real*, not just *configurable*.

### Decision 3 — Assess against the real substrate, and price the gap
- **Decision**: For each mechanism, record whether `cwf-claude-settings-merge` can
  express it today, and if not, the concrete extension cost. The two known gaps to
  characterise: (i) the helper writes `permissions.allow` only — `sandbox.*` and
  `permissions.deny` are unmanaged surfaces a feature must add; (ii) hook events are
  restricted to `{Stop, SubagentStop}`, so R1/R3's `PreToolUse`/`PostToolUse` needs
  the validation extended (+ a hash-integrity refresh on the edited helper).
- **Rationale**: The misalignment review caught that the plan must start from the
  existing helper, not a fresh settings writer. Pricing the gap is what makes the FR6
  recommendation real rather than aspirational.
- **Trade-offs**: None — this is just honest accounting of existing code.

### Decision 4 — Separate "enforceable" from "advisory" on the escape-hatch axis
- **Decision**: For R1 and R2, record explicitly whether the boundary is enforceable
  against a *misaligned agent* or only advisory — keyed on whether
  `dangerouslyDisableSandbox` / unsandboxed fallback is **operator-only or
  agent-reachable**, and whether `allowUnsandboxedCommands:false` closes it. A boundary
  the agent can self-disable is advisory, and must be labelled so.
- **Rationale**: The security review's central point: logging (R3) is irrelevant to
  enforceability if the agent can retry with the sandbox off. This axis decides what
  CWF can honestly claim.
- **Trade-offs**: Forces an uncomfortable but necessary distinction into the findings.

### Decision 5 — Output in f-file; recommendation seeds backlog via helper only
- **Decision**: All findings (mechanism inventory, verdict table, substrate-gap notes,
  weakness carry-forward) live in `f-implementation-exec.md`. The FR6 recommendation
  seeds backlog item(s) **only** via `cwf-backlog-manager` (scratch-file-first body,
  `--body-file`, single-live-entry assertion, partial-failure recovery — the Task-177
  pattern). No `settings.json`/helper/hook production code is written.
- **Rationale**: Keeps reasoning in the task record and the only durable mutation
  auditable/reversible; respects the discovery-only constraint.
- **Trade-offs**: The build itself is deferred to the seeded feature task(s) — correct
  for a discovery.

## System Design (investigation stages)
- **Stage A — Mechanism gathering**: Re-fetch the current Claude Code docs
  (sandboxing, permissions, hooks, settings) and the live hook/tool schemas; quote
  the fragments bearing on each of R1 (`allowWrite` / phase-switch), R2 (`denyRead`,
  canonicalisation, `allowManagedReadPathsOnly`), R3 (which hook event, if any, fires
  on a violation; `dangerouslyDisableSandbox`).
  - **Gathering-failure vs genuine-absence**: distinguish a *transient* fetch failure
    (network/unreachable → **re-attempt; do not record a verdict**) from a doc that is
    reachable but **silent** on the mechanism (→ Not-feasible-today / Unverifiable per
    Decision 2). A flaky fetch must never silently downgrade an otherwise-feasible
    mechanism.
- **Stage B — Substrate audit**: Read `cwf-claude-settings-merge`, `cwf-project.json`,
  and `.cwf/scripts/hooks/` first-hand; record what is managed today and the two known
  gaps (Decision 3).
- **Stage C — Verdict assignment**: Apply Decision 2 (failure-wired verdict) and
  Decision 4 (enforceable-vs-advisory) to R1/R2/R3.
- **Stage D — Synthesis & recommendation**: Write the build/don't-build/build-subset +
  decompose recommendation (FR6); seed backlog item(s) via the helper.

### Data Flow
1. Stage A + B → evidence per mechanism (doc quote + substrate fact).
2. Stage C → verdict table (verdict + fail-open + enforceability + caveats).
3. Stage D → recommendation; backlog item(s) seeded; f-file records the reasoning.

## Interface Design

### Mechanism inventory table (in f-implementation-exec.md)
```
| Req | Mechanism (settings key / hook event / rule) | Citation | In cwf-claude-settings-merge today? | Gap/extension cost |
```

### Feasibility verdict table (in f-implementation-exec.md)
```
| Req | Verdict | Fail-open behaviour | Enforceable vs advisory (escape-hatch) | Key caveats |
```
- Verdict ∈ {Feasible, Feasible-with-caveats, Not-feasible-today, Unverifiable}.
- A "none found" mechanism (FR1) ⇒ Not-feasible-today here ⇒ don't-build/defer in FR6.

### Backlog seed (output contract)
- One active entry per recommended build unit (whole feature, or per-requirement if
  FR6 recommends the split), body stating the verdict-grounded scope and the carried
  caveats; helper-mediated; exit code reported; single live entry per item.
- **Concrete recovery (not "the Task-177 pattern" by reference)**: before seeding,
  `backlog-manager list` is grepped for the title to detect a pre-existing live entry
  (avoid duplicate); the body is written to a project-namespaced scratch file first
  and passed via `--body-file`; on a non-zero `add` the failure + exit code are
  recorded and `add` re-run from the scratch file (never leave zero/duplicate entries).
- **Carried-forward constraint in the body**: each seeded item states that the
  feature's helper/hook edits must land their `script-hashes.json` refresh in the same
  commit (`docs/conventions/hash-updates.md`) and must not add any surface that
  silences `cwf-manage validate` — so the feature task inherits it rather than
  rediscovering it.

## Constraints
- No production sandbox/permission config, no new helper/hook code (discovery only).
- Helper-mediated backlog mutation only; ingested doc/schema text is evidence, never
  executed as instruction.
- Recommendations respect CWF portability (POSIX, core-Perl) and "surface, don't
  smooth" — no proposal that turns R3 logging into a silent boundary-disable.

## Decomposition Check
- [ ] Time >1 week? No.
- [ ] People >2? No.
- [x] Complexity 3+ concerns? Yes — but the *discovery* is one method over three
      requirements; the split decision is an output (FR6), not a reason to split the
      discovery.
- [ ] Risk needing isolation? No (no code shipped).
- [x] Independence? R1/R2/R3 separable — a *feature* property surfaced by FR6.

Discovery stays a single task.

## Validation
- [ ] Evidence hierarchy (Decision 1) applied to every mechanism row.
- [ ] Every verdict carries its failure outcome + fail-open behaviour (Decision 2).
- [ ] **Each R1/R2 verdict labelled enforceable-vs-advisory on whether
      `dangerouslyDisableSandbox`/unsandboxed fallback is agent-reachable (Decision 4).**
- [ ] Transient fetch-failure distinguished from genuine mechanism-absence (Stage A).
- [ ] Substrate gaps priced against the real helper (Decision 3).
- [ ] Recommendation seeds backlog via helper; single live entry per item; recovery +
      hash-refresh carry-forward in the body (output contract).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five Decisions held at exec. Decision 1 (evidence hierarchy) caught the Bash-only
fact by re-fetching live docs. Decision 2 (failure-wired verdict) produced a table that
states what is real, not just configurable. Decision 3 (price the substrate gap) gave the
recommendation its concrete prerequisite. Decision 4 (enforceable-vs-advisory) anchored
the `dangerouslyDisableSandbox` framing. Decision 5 (output in f + helper-mediated seed)
kept the only durable mutation auditable.

## Lessons Learned
Investigation Stage A should explicitly ask "which tool does each requirement's boundary
act on?" — the Bash-vs-permission-system split is the fact that most reshapes a
sandbox/permission assessment, and the staged design did not pre-pose it.

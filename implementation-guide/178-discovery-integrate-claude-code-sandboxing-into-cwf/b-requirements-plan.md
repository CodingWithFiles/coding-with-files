# Integrate Claude Code sandboxing into CWF - Requirements
**Task**: 178 (discovery)

## Task Reference
- **Task ID**: internal-178
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/178-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1

## Goal
Define what this **discovery** must produce: a cited, per-requirement feasibility
assessment of CWF-managed Claude Code sandboxing for the three operator requirements
(R1 phase-scoped writes, R2 credential deny-list, R3 issue logging), an integration
shape, and a build/decompose recommendation. The deliverable is findings + seeded
backlog item(s), not sandbox code.

## Requirements under assessment (the three operator asks)
- **R1**: During planning phases (a–e), the write boundary is limited to the task's
  own planning files — no edits to production code/skills/helpers.
- **R2**: Reads of user-wide credentials (`~/.ssh`, `~/.aws`, …) are denied by
  default, driven by a **CWF-user-editable** list.
- **R3**: Sandbox issues are logged so CWF can improve over time — **user-selectable,
  default OFF**.

## Functional Requirements
### Core Features
- **FR1 — Mechanism inventory (cited)**: Identify, for each requirement, the exact
  current Claude Code mechanism it would rely on.
  - **AC**: `f-implementation-exec.md` has a table mapping each of R1/R2/R3 to one or
    more concrete mechanisms — settings key (e.g. `sandbox.filesystem.allowWrite` /
    `denyRead`), permission rule (`Edit(...)`), hook event (e.g. PreToolUse /
    PostToolUse), or "none found" — each with a citation that is a quoted doc line
    or live schema fragment obtained this session, never memory
    (`feedback_no_fabricated_citations`).
  - **AC**: The inventory also names the **existing CWF substrate** each mechanism
    would ride: `.cwf/scripts/command-helpers/cwf-claude-settings-merge` (the helper
    that already merges `.claude/settings.json` and registers `.cwf/scripts/hooks/`
    hooks via `# cwf-hook-event:` / `# cwf-hook-matcher:` header directives) and the
    two config surfaces it bridges — `.claude/settings.json` (where `sandbox.*` /
    `permissions.*` live) vs `cwf-project.json` (CWF's own config). A mechanism the
    inventory records as "none found" **must** propagate to a Not-feasible verdict in
    FR2 and a corresponding don't-build/defer line in FR6 (the three FRs may not pass
    independently while contradicting each other).

- **FR2 — Per-requirement feasibility verdict**: Each requirement gets a verdict:
  **Feasible / Feasible-with-caveats / Not-feasible (today)**.
  - **AC (R1)**: States whether the planning-phase write boundary can be expressed
    via the OS sandbox (static `allowWrite`) and/or requires a PreToolUse hook, and
    names the trigger that distinguishes "in a planning phase" from "in an exec
    phase" (e.g. current wf step inferred from on-disk task files / `task-stack`).
    Must note that registering a `PreToolUse` hook through the supported path today
    requires extending `cwf-claude-settings-merge`, whose `read_hook_directives`
    currently validates the event to `{Stop, SubagentStop}` only — a feature-side
    cost feeding FR6. If no clean per-phase switch exists, the verdict is
    **Not-feasible-today** with the unverified/absent candidate named (never an empty
    cell).
  - **AC (R2)**: States how a CWF-editable list maps to `sandbox.filesystem.denyRead`
    (and/or `Read(...)` deny rules), how default entries ship, and the interaction
    with managed-settings lockdown (`allowManagedReadPathsOnly`). Must resolve the
    **merge precedence + removal** case: when CWF's shipped deny-list and an adopter's
    own entries disagree, does the merge union/overwrite/lose — and **can an adopter
    un-deny a shipped default path** (narrow the default), given the merge semantics?
    Must also record how `denyRead` resolves **symlinks and non-canonical/relative
    paths** (raw-string vs canonicalised match) and whether the shipped list uses
    `~` / `$HOME` / absolute paths (a default that silently fails to expand `~` would
    leave credentials readable while appearing protected).
  - **AC (R3)**: Answers the binary question — **is there a structured hook event
    that fires on a sandbox violation (yes/no)?** If no, R3's verdict is at best
    **Feasible-with-caveats** over a noisy proxy signal (command failure +
    `dangerouslyDisableSandbox` retry), explicitly labelled **unreliable**; it may
    not be smoothed into a clean "Feasible". Names which hook event / exit path
    carries the signal, if any.
  - **AC**: A verdict citing a mechanism that could not be confirmed this session is
    marked **Unverifiable**; a requirement whose *sole* candidate mechanism is
    Unverifiable yields **Not-feasible-today** (with the candidate named), never an
    upgrade to Feasible.
  - **AC (fail-open linkage)**: Each Feasible / Feasible-with-caveats verdict states
    its behaviour **when the sandbox is unavailable** (silently advisory-off vs
    hard-fail under `failIfUnavailable`), since that determines whether the protection
    is real or only present on supported platforms.

- **FR3 — Integration shape with CWF**: Describe where each piece lives in CWF and
  who owns enforcement.
  - **AC**: States which artefacts CWF would add/manage (`cwf-project.json` keys,
    a dedicated list file, an installed hook under `.cwf/scripts/hooks/`, settings
    fragments), at install-time vs per-phase, and **how the feature rides the existing
    `cwf-claude-settings-merge` helper** (extend it, or document why a separate
    settings-writing path is needed) rather than inventing a new surface — including
    the new hash-integrity entry any new helper/hook would need. Explicitly records
    the **enforcement-ownership boundary**: CWF *provides/advises* config; Claude Code
    + the OS enforce it; the operator can widen/disable it — so CWF cannot *guarantee*
    the boundary.

- **FR4 — Configurability & defaults**: Specify the user-facing knobs.
  - **AC**: R2's credential list is user-editable with a sensible shipped default
    (at minimum `~/.ssh`, `~/.aws`); R3's logging is a named switch defaulting to
    **OFF**; R1's phase-scoping is opt-in **(conditional on R1's FR2 verdict being at
    least Feasible-with-caveats — if R1 is Not-feasible, the "opt-in default" knob is
    moot and recorded as such)**. Each knob names its config surface
    (`cwf-project.json` vs the merged `.claude/settings.json`) and default.

- **FR5 — Risks, caveats & weaknesses carried forward**: Surface the sandbox
  limitations that bear on these requirements.
  - **AC**: Records the relevant documented weaknesses (e.g. default read policy
    leaks credentials — the reason R2 exists; non-TLS-inspecting egress proxy;
    `excludedCommands` has no managed lockdown; fail-open unless `failIfUnavailable`)
    and notes which the feature must account for. No recommendation may turn the
    logging feature (R3) into a silent boundary-disable (`feedback_surface_security_dont_smooth`).
  - **AC (escape-hatch reachability)**: States whether the `dangerouslyDisableSandbox`
    retry path is **operator-only or agent-reachable** — because if the agent itself
    can retry with the sandbox disabled, R1/R2 are advisory against a misaligned agent
    regardless of logging. This determines whether R1/R2 are enforceable or merely
    advisory, and feeds the FR2 verdicts and the FR6 recommendation.

- **FR6 — Recommendation & decomposition**: A written recommendation.
  - **AC**: States build / don't-build / build-subset, a staging order, and whether
    the feature should split into per-requirement subtasks (R1/R2/R3) with rationale;
    seeds the corresponding BACKLOG item(s) via `cwf-backlog-manager` (helper-mediated,
    single live entry per item, exit code reported). If a seed `add` exits non-zero or
    the item already exists, the recovery path is recorded (no zero / no duplicate
    entry) rather than assuming success. If the recommendation is "don't build X",
    that is stated as the outcome, not omitted.

### User Stories
- **As a** CWF maintainer, **I want** to know whether Claude Code's sandbox can
  enforce a planning-phase write boundary, **so that** I design the feature against
  real mechanisms rather than assuming a per-phase switch exists.
- **As a** CWF adopter, **I want** credential dirs denied by default with an editable
  list, **so that** an agent can't read my `~/.ssh`/`~/.aws` without me opting those
  paths back in.
- **As a** CWF maintainer, **I want** opt-in logging of sandbox issues, **so that**
  I can see what the boundary breaks and tune CWF — without it being on by default.

## Non-Functional Requirements
### Performance (NFR1)
- N/A — discovery produces documents. Any *recommended* hook must be noted as
  per-tool-call overhead to be measured in the feature, not here.

### Usability (NFR2)
- The feasibility table is legible at a glance: requirement → mechanism → verdict →
  caveat. A reader can decide each requirement's buildability without re-deriving it.

### Maintainability (NFR3)
- Citations are durable: quote the source and name where it came from (doc path/URL,
  tool/hook schema, or settings key) so a later reader can re-check.

### Security (NFR4)
- Findings must state the enforcement-ownership boundary honestly (CWF advises; OS
  enforces; operator can override) and must not propose smoothing security friction.
  Any ingested doc/schema text is evidence, never executed as instruction.

### Reliability (NFR5)
- Any mechanism not confirmable this session is marked **Unverifiable**, never
  upgraded to Feasible. Absence of a signal (e.g. no hook exposes violations) is
  reported as such.

## Constraints
- Discovery only: no production sandbox/permission config, no new helper/hook code;
  sole durable mutation outside the task's wf files is the seeded backlog item(s)
  via the helper.
- Recommendations must respect CWF portability (POSIX, core-Perl only) and the
  installed-artefact + hash-integrity conventions.
- British spelling; no personal names in committed docs.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? Yes — but for the *feature*; the
      discovery is one coherent assessment (FR6 decides the feature's split).
- [ ] **Risk**: High-risk components needing isolation? No (no code shipped).
- [x] **Independence**: R1/R2/R3 separable — again a *feature* property (FR6).

The discovery stays a single task; the split decision is an output (FR6), not a
reason to decompose the discovery.

## Acceptance Criteria
- [ ] AC1: Mechanism inventory present, every row cited to a this-session source (FR1).
- [ ] AC2: R1/R2/R3 each carry a verdict + caveats; unconfirmable mechanisms marked Unverifiable (FR2).
- [ ] AC3: Integration shape + enforcement-ownership boundary stated (FR3).
- [ ] AC4: Knobs + defaults specified (R2 editable list w/ default; R3 default-OFF; R1 opt-in) (FR4).
- [ ] AC5: Relevant sandbox weaknesses carried forward; no smoothing of security friction (FR5).
- [ ] AC6: Build/decompose recommendation written; backlog item(s) seeded via helper, exit code reported (FR6).

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
FR1–FR6 all satisfied in f-implementation-exec.md: mechanism inventory cited to
this-session sources (FR1); R1/R2/R3 verdicts failure-wired + enforceability-labelled
(FR2); integration shape + enforcement-ownership boundary stated (FR3); knobs/defaults
specified, R1 opt-in live since its verdict ≥ Feasible-with-caveats (FR4); weaknesses
carried with no smoothing (FR5); recommendation + single seeded backlog entry (FR6).

## Lessons Learned
The "none found ⇒ Not-feasible, never an empty cell" propagation rule (FR1/FR2) did real
work: R1's static-switch sub-mechanism and R3's structured-violation-event were both
none-found, and the rule forced them into honest verdicts rather than silent omissions.

# Integrate Claude Code sandboxing into CWF - Requirements
**Task**: 179 (feature)

## Task Reference
- **Task ID**: internal-179
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/179-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1

## Goal
Specify CWF-managed Claude Code sandboxing: a master opt-in toggle (default OFF) that,
when enabled, makes `cwf-claude-settings-merge` write sandbox/permission config —
credential deny-list (R2), phase-scoped planning writes (R1), opt-in logging (R3),
`failIfUnavailable` default-true — plus an honest limitations doc. Mechanisms and verdicts
are inherited from Task 178; this defines what the build must satisfy.

## Functional Requirements

### FR1 — Master sandboxing toggle (default OFF)
- **AC1a**: A single boolean key in `cwf-project.json` (proposed `sandbox.enabled`, exact
  key fixed in design) gates the entire feature; its **default is OFF** (absent key ⇒ off).
- **AC1b (no-regression)**: With the toggle OFF, `cwf-claude-settings-merge --dry-run` adds
  **zero** `sandbox.*` and **zero** `permissions.deny` keys, and the
  `permissions.allow` / `hooks` / `env.PERL5OPT` output is **semantically identical** to
  current behaviour. Verified against a **golden file generated from the current helper**
  (pinned to baseline), so the test survives benign serialisation changes.
- **AC1c (authoritative + reversible + provenance)**: Toggling ON then re-running is
  idempotent; toggling OFF then re-running **removes the keys CWF previously wrote** without
  disturbing user-authored keys. Because the existing helper is strictly add-if-absent and
  there is no provenance marker today, the design **must** define how CWF-owned entries are
  identified for removal (a managed sub-block, a provenance marker, or a known-set diff) and
  **must** resolve the collision case: *a user independently authored an identical entry*
  (e.g. `Read(~/.ssh)`) — state whether toggle-OFF keeps or removes it, and why.
- **AC1d (absent vs malformed)**: An **absent** sandbox config ⇒ OFF, silently and
  correctly. A **malformed** sandbox config (unparseable JSON, wrong-typed toggle, deny-list
  not an array / non-string entries) ⇒ **surface an error**, never silently degrade to OFF —
  silently treating a corrupt credential boundary as OFF is the "smoothing" the project
  forbids (`feedback_surface_security_dont_smooth`).
- **AC1e (schema-validated)**: The new `cwf-project.json` keys are validated by
  `CWF::Validate::Config` (a new per-block validator, consistent with the existing
  `_validate_versioning_block` / `_validate_wf_step_config_block`), so a malformed `sandbox`
  block is caught by `cwf-manage validate`, not only at merge time.

### FR2 — Credential deny-list (R2)
- **AC2a**: A user-editable list in `cwf-project.json` with a shipped default of at least
  `~/.ssh` and `~/.aws`.
- **AC2b (paired rules)**: Each entry compiles to **both** a `sandbox.filesystem.denyRead`
  entry (Bash subprocess path) **and** a `Read(...)` permission-deny rule (Read-tool path)
  in the merged settings — neither alone, because the sandbox is Bash-only (Task 178).
- **AC2c (path form)**: `~` is written in the form Claude Code expands to `$HOME` per the
  sandbox doc's path-prefix rule; the design records the exact path form used for each of
  the two rule families (they differ: sandbox `~/` vs permission-rule `//`/`~` syntax).
- **AC2d (narrowing)**: An adopter can **narrow** a shipped default via an `allowRead` entry
  **without editing CWF-owned files**; deletion is *not* the mechanism (cross-scope arrays
  union-merge — a deleted shipped default is re-added on next merge; documented and tested).

### FR3 — `failIfUnavailable` default-true + first-run guard
- **AC3a**: When sandboxing is ON, the merged settings contain
  `sandbox.failIfUnavailable: true` by **default**, sourced from a `cwf-project.json` knob
  whose value is **authoritative** (CWF writes the knob value, overwriting its own prior
  value; warn-on-hand-set-mismatch as `PERL5OPT` does today); operator-settable to `false`.
- **AC3b (first-run guard, observable + safe message)**: Given a host where the sandbox
  cannot initialise (e.g. `bubblewrap`/`socat` absent — the observable trigger), enabling
  sandboxing **surfaces a message naming the missing dependency or the knob to flip** —
  never a bare "Claude Code won't start". The message is composed from a **fixed token set**,
  **not** by interpolating raw dependency-probe stdout/stderr into the operator's terminal /
  LLM context. (Mechanism — hook vs `cwf-init` check vs doc — is a design choice.)

### FR4 — Phase-scoped planning writes (R1)
- **AC4a**: When sandboxing is ON, during planning phases (a–e) writes are gated to the
  current task's own planning files; edits to production code/skills/helpers are blocked.
- **AC4b (mechanism + reuse)**: The gate is a **PreToolUse** hook (Task 178: no static
  per-phase sandbox key; Edit/Write bypass the sandbox) keyed on the current wf step. It
  **reuses `task-context-inference` / `CWF::TaskContextInference.pm`** (which already emits
  `workflow_step:` from branch/worktree/`task-stack`/recency) rather than reimplementing
  branch/`task-stack` parsing.
- **AC4c (fail-closed on ambiguous input)**: The wf-step signal is partly attacker-
  influenceable on-disk state, and this hook is R1's *enforceable* path — so on ambiguous,
  malformed, or absent inference (empty `task-stack`, multiple in-progress tasks,
  `task-context-inference` exit 1, a call outside any task), the gate **fails closed**
  (most-restrictive phase) **and surfaces** a message, consistent with `failIfUnavailable:
  true`. The task path is derived from a trusted source, not free-form file content.
- **AC4d (split option)**: If design/impl shows R1 is disproportionate to the rest, it may
  be deferred to a follow-up subtask **with a recorded rationale and a seeded backlog item**
  — never silently dropped. (Mirrors a-plan SC4.)

### FR5 — Violation logging (R3, default OFF)
- **AC5a**: A `cwf-project.json` switch (default **OFF**) enables logging of the available
  proxy signal — a PreToolUse observation of a `dangerouslyDisableSandbox` retry and/or
  PostToolUseFailure (Task 178: no structured sandbox-violation event exists).
- **AC5b (bounded destination)**: The log destination/format reuses existing CWF
  conventions (a named `.cwf/` path or the project-namespaced scratch dir per
  `.cwf/docs/conventions/tmp-paths.md`) — **not** a new logging subsystem. Described
  honestly as a **best-effort proxy**, not an audit trail.
- **AC5c (observe-only, never blocks)**: Logging observes only — no log path may disable,
  relax, or silence a boundary or `cwf-manage validate`. A **log-write failure** (unwritable
  path, full disk) must **never block or relax** a tool call.

### FR6 — Substrate extension (`cwf-claude-settings-merge`)
- **AC6a**: The helper is extended to manage `sandbox.*` and `permissions.deny`, and to
  register `PreToolUse` / `PostToolUseFailure` hooks (its `read_hook_directives` event
  allowlist, currently `{Stop, SubagentStop}`, is widened).
- **AC6b (new config-read coupling, reuse)**: Today the helper reads only
  `script-hashes.json` and never opens `cwf-project.json`. It must now read the toggle/knobs
  — **reusing `read_json_file` (already imported from `CWF::ArtefactHelpers`) and the
  established `implementation-guide/cwf-project.json` discovery path** used by
  `cwf-version-bump` / `security-review-changeset`, not a parallel config reader.
- **AC6c (merge authority)**: Existing `permissions.allow` / `hooks` / `PERL5OPT` keep
  their current add-if-absent / dedupe semantics **byte-for-byte**; the new toggle-driven
  `sandbox.*` / `permissions.deny` keys are written **authoritatively** (so toggle-OFF
  removes them per AC1c). User-authored keys are preserved across merges.
- **AC6d (self-protected write target)**: The authoritative `sandbox.*` / `permissions.deny`
  keys are written **only** to `.claude/settings.json` — the scope the sandbox self-protects
  from writes — never to an unprotected sibling/include an agent could relocate or edit.
- **AC6e (integrity)**: Any new helper/hook file gets a `script-hashes.json` entry; every
  hash-tracked edit refreshes its hash in the same commit; `cwf-manage validate` is clean
  post-change. (Process constraint, restated in Constraints; the testable feature-level
  outcome is "validate clean".)

### FR7 — Limitations documentation
- **AC7a**: A user-facing doc states, in plain terms: CWF **advises**, the OS **enforces**,
  the operator can **override** (never "CWF enforces/sandboxes"); the sandbox is
  **Bash-only**; the `dangerouslyDisableSandbox` escape hatch is **agent-reachable**
  (advisory unless `allowUnsandboxedCommands:false`); there is **no reliable sandbox-
  violation event**; the boundary is fail-closed only while `failIfUnavailable` stays
  `true`; **and `denyRead` does not cover credentials already resident in the environment**
  (e.g. `AWS_SECRET_ACCESS_KEY`) — those need `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`, which is
  orthogonal to the deny-list (Task 178 § Step 5).
- **AC7b**: The doc is reachable from the feature's config surface (referenced from
  `cwf-project.json` docs / a `.cwf/docs/` page), not buried in a task file.

### User Stories
- **As a** CWF adopter, **I want** sandboxing off by default with one toggle to turn it on,
  **so that** the feature never changes my environment until I opt in.
- **As a** CWF adopter, **I want** `~/.ssh`/`~/.aws` denied by default with an editable
  list, **so that** an agent can't read my credentials once I enable sandboxing.
- **As a** CWF maintainer, **I want** an honest limitations doc, **so that** no one mistakes
  advisory config for an enforced boundary.

## Non-Functional Requirements
### Performance (NFR1)
- The R1/R3 PreToolUse hook runs per tool call. Its wf-step inference reuses
  `task-context-inference`, which shells out to `git` and walks the tree — so the overhead
  is **not** free; it must be bounded (no network; cache within a single hook invocation)
  and **measured** in testing, not assumed. A per-call cost regression is a test concern.

### Usability (NFR2)
- One toggle to enable; sensible defaults; an unavailable sandbox yields an actionable
  message (AC3b), not a cryptic failure.

### Maintainability (NFR3)
- Extends the existing helper rather than adding a parallel settings writer; per-key merge
  authority explicit and tested; self-documenting key names. **Precedence**: the
  extend-don't-fork preference yields to the no-clobber / no-regression / correct-removal
  guarantees (AC1b/AC1c/AC6c) if they conflict — correctness over architecture continuity.

### Security (NFR4)
- No regression to existing merge behaviour (AC1b); user settings preserved (AC6c); write
  target self-protected (AC6d); no surface that silences `cwf-manage validate` (AC5c);
  malformed config surfaces rather than silently disabling the boundary (AC1d); R1 gate
  fails closed on ambiguous input (AC4c); honest enforcement-ownership + env-inheritance
  framing (FR7).

### Reliability (NFR5)
- Merge is idempotent and reversible via the toggle (AC1c); **absent** config ⇒ safe OFF,
  **malformed** config ⇒ surfaced (AC1d); the helper never corrupts an existing
  `.claude/settings.json`.

## Constraints
- POSIX, **core-Perl only**; British spelling; no personal names in committed docs.
- Hash-refresh-same-commit for every hash-tracked edit; new helper/hook registered via the
  merge helper + allowlisted; no `cwf-manage validate`-silencing surface.
- `cwf-project.json` is the single source of truth for all knobs (toggle, deny-list,
  `failIfUnavailable`, logging switch); `.claude/settings.json` is generated, not the knob.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2? No.
- [x] **Complexity**: 3+ concerns? Yes — but they converge on one helper + one config file.
- [x] **Risk**: Yes (partial) — the security-critical helper edit; the R1 hook.
- [~] **Independence**: R1/R2/R3 conceptually separable, but code-coupled on the helper.

Per a-plan: single task, staged; **only R1** is pre-authorised to split (AC4d) if it proves
disproportionate. No change to that decision at requirements time.

## Acceptance Criteria
- [ ] AC1: Master toggle defaults OFF; OFF ⇒ no sandbox surface + no regression (golden
      file); authoritative+reversible with defined provenance; malformed surfaces;
      schema-validated (FR1).
- [ ] AC2: R2 deny-list editable, defaults `~/.ssh`/`~/.aws`, paired denyRead + Read deny,
      narrowable via allowRead (FR2).
- [ ] AC3: `failIfUnavailable` default-true authoritative + observable, safe-message
      first-run guard (FR3).
- [ ] AC4: R1 phase-write PreToolUse gate reusing `task-context-inference`, fail-closed on
      ambiguous input, or split-with-rationale+backlog (FR4).
- [ ] AC5: R3 opt-in default-OFF proxy logging, bounded destination, observe-only,
      never-blocks (FR5).
- [ ] AC6: Helper extended; config read reuses `read_json_file`; per-key merge authority;
      self-protected write target; validate clean (FR6).
- [ ] AC7: Limitations doc shipped and reachable, incl. env-inheritance caveat (FR7).

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

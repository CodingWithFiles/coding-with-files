# Integrate Claude Code sandboxing into CWF - Design
**Task**: 179 (feature)

## Task Reference
- **Task ID**: internal-179
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/179-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1

## Goal
Design the build for CWF-managed Claude Code sandboxing satisfying b-requirements FR1–FR7,
against the real substrate: `cwf-claude-settings-merge`, `CWF::Validate::Config`,
`task-context-inference`, the `.cwf/scripts/hooks/` conventions, and `cwf-project.json`.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility
(Per b-NFR3 precedence: correctness/no-clobber/no-regression beats extend-don't-fork.)

## Grounding (read first-hand this session)
- `cwf-claude-settings-merge` runs from git root on **relative** paths (`.cwf/...`,
  `.claude/settings.json`); writes `permissions.allow`/`hooks`/`env.PERL5OPT` only, strictly
  **add-if-absent**; reads only `script-hashes.json`; `read_hook_directives` validates
  **event** against `/^(?:Stop|SubagentStop)$/` (line 82) and **matcher** against
  `/^[A-Za-z0-9_-]+$/` (line 86) — `|` is excluded; imports `read_json_file` +
  `atomic_write_text` from `CWF::ArtefactHelpers`; `merge_env` (lines 262–285) is the
  authoritative-with-warn-on-mismatch pattern to mirror.
- `CWF::Validate::Config` per-block validators registered at lines 129–130; reusable
  `_is_bool` (135), `_scalar_repr` (141), `_violation` (221).
- `.cwf/security/` currently holds **only** `script-hashes.json` (the integrity manifest).
- `.cwf/scripts/hooks/*`: `#!/usr/bin/env perl`, header directives, **fail-open invariant**,
  output via `JSON::PP->encode` (never interpolate stdin into harness output), exit 0.
- `task-context-inference` emits `workflow_step:` with documented exit codes.

## Key Decisions

### D1 — One helper reads config (relative path); no parallel writer
`cwf-claude-settings-merge` gains a config read via `read_json_file('implementation-guide/
cwf-project.json')` — the **relative** form matching the helper's existing cwd==git-root
style (it does **not** adopt `CWF::Versioning`'s absolute `config_path`, which would be a
new dependency and a cwd-model mismatch). `sandbox.enabled` true ⇒ merge the sandbox surface;
false/absent ⇒ today's behaviour exactly.

### D2 — Ownership-by-shape removal; **no sidecar** (revised after review)
CWF owns, in the generated `.claude/settings.json`: the entire `sandbox.*` block, and any
`permissions.deny` entry **matching CWF's own deterministic generation shape**
(`Read(<P>)` / `Read(<P>/**)` for the credential-path forms it emits). Each merge:
- **ON**: write the desired `sandbox.*` + CWF-shaped `Read(...)` deny set (replace the
  CWF-owned region; user entries — anything not CWF-shaped — untouched).
- **OFF/absent**: remove the **entire** `sandbox.*` block and **all** CWF-shaped `Read(...)`
  deny entries (whole managed family, so a changed-then-disabled list leaves no orphans).
- **Rationale**: this is the simplification four reviewers converged on. It removes a whole
  generated artefact and — critically — closes a security hole: a non-hash-tracked sidecar
  that drives deletions is a *credential-boundary-removal oracle* (a tampered sidecar could
  silently strip the deny-list). Ownership-by-shape removes only entries CWF can re-derive,
  so nothing outside its own pattern is ever deleted, and there is no second write to tear.
- **User overrides** live in `.claude/settings.local.json` (Local scope, higher precedence,
  never touched); the generated `settings.json` deny/sandbox region is CWF-owned. Documented.
- **No-churn**: the existing `->canonical` encoder keeps the committed `settings.json` diff
  deterministic across toggles.

### D3 — Config knobs + schema validation (reuse `_is_bool`/`_violation`)
New `cwf-project.json` block (the **only** home of the shipped default; the helper carries
**no** hard-coded fallback list):
```json
"sandbox": {
  "enabled": false,
  "fail-if-unavailable": true,
  "credential-deny-list": ["~/.ssh", "~/.aws"],
  "violation-logging": false
}
```
Add `_validate_sandbox_block` to `CWF::Validate::Config` (registered beside the existing
block validators, **reusing** `_is_bool`/`_scalar_repr`/`_violation`): the three switches
must be boolean; `credential-deny-list` an array of strings. An absent `credential-deny-list`
with `enabled:true` ⇒ no deny entries (valid, logged). (b-AC1e.)

### D4 — Absent ⇒ silent OFF; malformed ⇒ surface; helper re-checks types itself
Absent `sandbox` block ⇒ OFF silently. Present-but-malformed (wrong-typed switch, non-array
list) ⇒ the helper **dies with `[CWF] ERROR:`** — never silent-OFF of a credential boundary
(`feedback_surface_security_dont_smooth`). The helper **re-validates the knob types itself**
before writing (it does not assume `cwf-manage validate` ran — mirroring the `merge_env`
"no trust-gate" comment). The schema validator (D3) catches the same at `validate` time.

### D5 — `failIfUnavailable` authoritative; pure-Perl dep probe; fixed-token guard
Write `sandbox.failIfUnavailable` from the `fail-if-unavailable` knob **authoritatively**
(knob value wins; warn — not overwrite — only on a *different* hand-set value, per
`merge_env`). The value is re-checked as a JSON boolean before writing (D4).
**First-run guard**: detect missing deps by a **pure-Perl `$ENV{PATH}` split + `-x` test**
for `bwrap` and `socat` (no shell, no `command -v` builtin, no `which` spawn — avoids the
FR4(a) surface entirely; no-op on macOS/Seatbelt). The dep names are **compile-time string
constants**. On a missing dep, print a **fixed-token** message naming the package and the
`sandbox.fail-if-unavailable` knob; raw probe data is never interpolated. The guard is
**advisory** (warn) and never blocks settings generation.

### D6 — R2 paired rules (Bash path + Read-tool path)
For each `credential-deny-list` entry `P`:
- **Bash path** → `sandbox.filesystem.denyRead: [P]` (`~/` expands to `$HOME`, sandbox doc
  path-prefix rule).
- **Read-tool path** → `permissions.deny: ["Read(P)", "Read(P/**)"]`.
Both CWF-owned (D2). **The `~` expansion in the `Read(...)` matcher is load-bearing and
must be behaviourally verified at impl** (a `Read(~/.ssh)` that does not expand would deny
nothing while appearing paired) — testing obligation, not assumed. Narrowing is
`allowRead`/local-scope, not deletion (b-AC2d); the reconciler re-adds a deleted shipped
default (union-merge), so narrowing genuinely requires `allowRead` — also behaviourally
verified (that `allowRead` wins over `denyRead`).

### D7 — R1 PreToolUse phase-write guard — **split to subtask 179.1**
Confirmed split (a-plan Risk 1, b-AC4d). R1 needs **two** substrate changes this task does
*not* make: (i) the **matcher regex** widened to admit `Edit|Write` (current
`/^[A-Za-z0-9_-]+$/` rejects `|` → would silently fall back to matcher-less); (ii) the
fail-closed-without-bricking design (deny only the production crown jewels — `.cwf/`,
`.claude/`, skills, helpers — on ambiguous `task-context-inference`, surface a message). Both
belong in 179.1. **179 widens only the event allowlist** (D-events below), which R3 needs and
R1 will reuse — a clean seam. Seed a backlog item for 179.1.

### D8 — R3 logging: opt-in, PreToolUse, minimal record, observe-only
`violation-logging: true` registers a new hook `.cwf/scripts/hooks/pretooluse-sandbox-logging`
(`# cwf-hook-event: PreToolUse`, `# cwf-hook-matcher: Bash` — `Bash` passes the existing
matcher regex, so **no matcher-regex change**; only the event allowlist is widened). When a
Bash call carries `dangerouslyDisableSandbox`, it appends a **minimal fixed record**
(timestamp + a flag/tool-name — **not** the raw command string) as one JSON line to a bounded
log under `.cwf/` (exact path per `.cwf/docs/conventions/tmp-paths.md`). The log is
**operator-facing only and never re-fed into LLM context**; if a future reader ingests it,
it must treat the content as untrusted (FR4(c)). **Fail-open**: a log-write failure is
swallowed; the hook never blocks (b-AC5c). **Why R3 stays while R1 splits**: R3 needs only
the event-allowlist widening 179 already does (no matcher-regex change, no fail-closed
design), is opt-in/default-OFF, and directly serves the operator's "improve CWF over time"
ask. R1 carries the two extra substrate/design costs above.

### D-events — Event allowlist widening (the one shared substrate change for hooks)
`read_hook_directives` event allowlist becomes `{Stop, SubagentStop, PreToolUse}`. The
**matcher** regex is unchanged this task (R3's `Bash` passes; R1's `Edit|Write` widening is
179.1). The widened-char rationale (keeping parsed strings inert in a settings key) is
restated when 179.1 touches the matcher regex.

## System Design
### Components (179 scope)
- **`cwf-claude-settings-merge`** (extended): relative config read (D1) → type re-check (D4)
  → desired-set computer (D3/D6) → ownership-by-shape reconcile (D2) → settings write via
  `atomic_write_text` to `.claude/settings.json` only (b-AC6d); `failIfUnavailable` + probe
  (D5); event-allowlist widening (D-events) + R3 hook registration.
- **`CWF::Validate::Config`** (extended): `_validate_sandbox_block` (D3).
- **`pretooluse-sandbox-logging` hook** (new, R3): D8.
- **Limitations doc** (new): `.cwf/docs/` page (FR7), incl. env-inheritance caveat.
- *(R1 guard + matcher-regex widening → subtask 179.1, D7.)*

### Data Flow (merge run, sandbox ON)
1. Read `cwf-project.json` `sandbox` block; re-check types (else die, D4).
2. Compute desired managed set (D3/D6) + `failIfUnavailable` (D5) + R3 registration (D8).
3. Reconcile by shape: replace CWF-owned `sandbox.*` + CWF-shaped `Read(...)` deny; leave
   non-CWF-shaped user keys untouched (D2). No second/sidecar write.
4. Merge the unchanged add-if-absent surface (`allow`/`hooks`/`PERL5OPT`) byte-for-byte.
5. `atomic_write_text` `.claude/settings.json`. Capability probe + fixed-token guard (D5).

## Interface Design
### `cwf-project.json` `sandbox` block — D3.
### Generated `.claude/settings.json` (sandbox ON, illustrative)
```json
{ "sandbox": { "enabled": true, "failIfUnavailable": true,
               "filesystem": { "denyRead": ["~/.ssh", "~/.aws"] } },
  "permissions": { "deny": ["Read(~/.ssh)", "Read(~/.ssh/**)",
                            "Read(~/.aws)", "Read(~/.aws/**)"] } }
```

## Constraints
- POSIX, core-Perl only; pure-Perl PATH probe (no shell/`which`); fixed-token guard message;
  British spelling; no personal names.
- Same-commit `script-hashes.json` refresh for the edited helper + `Config.pm` + the new R3
  hook; R3 hook registered + allowlisted via the merge helper; no validate-silencing surface.
- **No sidecar / no new persisted-state file** (D2 revision).

## Decomposition Check
- [ ] Time >1 week? No (R1 split out).
- [ ] People >2? No.
- [x] Complexity 3+ concerns? Cohesive on one helper + config + one hook.
- [x] Risk needing isolation? **R1** → subtask `179.1` (D7); seed backlog item.
- [x] Independence? R1 cleanly separable once the event allowlist is widened here.

## Validation
- [ ] D2 reconcile: add / idempotent-noop / toggle-OFF removes whole managed family /
      changed-list-then-OFF leaves no orphan / non-CWF-shaped user deny preserved.
- [ ] D3 `_validate_sandbox_block` rejects non-bool switches + non-array list (reuses
      `_is_bool`); absent list + enabled ⇒ valid.
- [ ] D4 absent ⇒ silent OFF; malformed ⇒ die; helper re-checks types without validate.
- [ ] D5 `failIfUnavailable` authoritative + bool-rechecked; PATH probe present/absent;
      guard message fixed-token only; advisory (never blocks).
- [ ] D6 paired denyRead + Read deny; **behavioural** test that `Read(~/…)` expands to
      `$HOME` and that `allowRead` narrows a `denyRead` default.
- [ ] D8 R3 PreToolUse+Bash registers under PreToolUse (not Stop-fallback); minimal record
      (no raw command); log-write failure never blocks.
- [ ] D1/AC1b sandbox-OFF golden file: zero sandbox/deny keys, allow/hooks/PERL5OPT unchanged.
- [ ] D-events allowlist = {Stop, SubagentStop, PreToolUse}; matcher regex unchanged.
- [ ] R1 split recorded + backlog seeded (D7).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

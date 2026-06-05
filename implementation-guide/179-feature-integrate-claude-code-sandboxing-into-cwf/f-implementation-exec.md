# Integrate Claude Code sandboxing into CWF - Implementation Execution
**Task**: 179 (feature)

## Task Reference
- **Task ID**: internal-179
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/179-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1

## Goal
Execute the d-implementation-plan build: extend `cwf-claude-settings-merge` +
`CWF::Validate::Config`, add the R3 logging hook, ship the limitations doc, seed
R1 (179.1). TDD throughout. R1 itself is split to subtask 179.1 by design (D7).

## Actual Results (by plan step)

### Step 1 — Config schema + validator (D3; FR1/AC1e) ✓
Added `_validate_sandbox_block` to `CWF::Validate::Config` (reuses
`_is_bool`/`_scalar_repr`/`_violation`; gated on `exists $config->{sandbox}`,
mirroring `_validate_versioning_block`), registered after the wf_step_config
validator. Tests TC-S1..S7 in `t/validate-config.t`: non-bool switches,
non-array / non-string-entry deny-list, absent block, `enabled:true`+absent list,
sandbox-not-object, full-valid. Green (26 tests).

### Step 2 — Helper reads config + re-checks types (D1/D4; FR1/FR6) ✓
`read_sandbox_config` reads `implementation-guide/cwf-project.json` via the
helper-local **relative** path (its cwd==git-root invariant — NOT
`CWF::Versioning`'s absolute path). **`-f && !-l` guard before the read**
(`read_json_file` dies on a missing file — would regress fresh installs).
Absent file / absent block ⇒ undef ⇒ OFF (today's behaviour). Unparseable JSON
dies inside `read_json_file`; a malformed block dies via
`validate_sandbox_block_or_die` (helper re-checks types itself — no trust-gate).
TC-1 (OFF, file-absent + block-absent, golden allow/hooks/env) and TC-2
(unparseable / non-bool / non-array all surface `[CWF] ERROR:`) green.

### Step 3 — R2 paired rules + ownership-by-shape reconcile (D2/D6; FR2) ✓
`reconcile_sandbox` removes the whole CWF-owned region every run (the entire
`sandbox.*` block + every CWF-shaped deny), then rewrites the desired set when
ON. `is_cwf_read_deny` pins the **CWF-shaped predicate** (see Deviation 2). R2:
each list entry → `sandbox.filesystem.denyRead` **and** `Read(P)` + `Read(P/**)`.
TC-4/5 (paired forms), TC-6 (removal, non-CWF `Bash(curl *)` preserved, AC1c
identical-collision removed, changed-list-no-orphan), TC-6b (idempotent) green.

### Step 4 — `failIfUnavailable` + dep probe + guard (D5; FR3) ✓
`failIfUnavailable` written **authoritatively** from the knob (see Deviation 1).
`dep_on_path`: pure-Perl `$ENV{PATH}` split + `-x`, **skips empty/`.` segments**
(no shell, no `which`). `sandbox_dep_guard`: fixed-token message naming package
(`bubblewrap`/`socat`) + the knob; compile-time dep→package literals; advisory
(warns, never blocks); no-op on darwin. TC-7 (authoritative), TC-8 (missing-dep
warn + `.`/empty-segment-not-resolved) green. Confirmed end-to-end in the ON
smoke run (socat genuinely absent here → correct warning, exit 0).

### Step 5 — Event allowlist + R3 hook (D-events/D8; FR5) ✓
`read_hook_directives` event allowlist widened to `{Stop, SubagentStop,
PreToolUse}`; **matcher regex unchanged** (`|` still rejected → 179.1). New hook
`.cwf/scripts/hooks/pretooluse-sandbox-logging` (modelled on
`subagentstop-security-verdict-guard`): whole body under `eval` (fail-open),
fixed-key `JSON::PP` record (timestamp + tool + presence flag, **never the raw
command**), logs to gitignored `.cwf/sandbox-violations.log`, exit 0. Registered
**only when** `violation-logging:true` (gated in `partition_manifest` on the
compile-time `$R3_HOOK_PATH`). TC-9 (gated registration), TC-10 (PreToolUse
accepted / `Edit|Write` matcher rejected), and `t/pretooluse-sandbox-logging.t`
(record shape, no-bypass-no-record, malformed-stdin fail-open, log-write-failure
swallowed) green.

### Step 6 — Limitations doc (FR7) ✓
`.cwf/docs/sandboxing.md`: CWF advises / OS enforces / operator overrides;
Bash-only; agent-reachable `dangerouslyDisableSandbox`; no reliable
violation event; fail-closed only while `fail-if-unavailable` true; **env-resident
credentials need `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`** (AC7a). Documents the
config block + narrow-via-`allowRead` + `settings.local.json` overrides (AC7b —
the reachable `.cwf/docs/` page; the template carries a `_sandbox-note` pointer).

### Step 7 — Integrity + full validate (same commit) ✓
`.cwf/sandbox-violations.log` added to the `gitignore-entries` manifest artefact
**and** `.gitignore`. `script-hashes.json` refreshed in this commit:
`cwf-claude-settings-merge`, `CWF::Validate::Config`, `install-manifest.json`
(edited), plus a **new** `pretooluse-sandbox-logging` entry (`permissions:
0500`). Full `t/` suite green (665 tests); `cwf-manage validate: OK`; OFF
dry-run on the real repo adds zero sandbox/deny keys and 3 hooks (R3 correctly
gated out).

### Step 8 — Seed R1 follow-up (179.1; D7) ✓
`backlog-manager add` seeded one live entry "R1: phase-scoped planning-write
PreToolUse guard (CWF sandboxing 179.1)" (feature/Medium, identified-in 179),
body naming the matcher-regex widening + fail-closed-without-bricking +
`task-context-inference` reuse + NFR1 cost. `grep -c` == 1; `backlog-manager
validate --all` exit 0.

## Deviations from plan (with rationale)

1. **`failIfUnavailable` is authoritative, not warn-not-overwrite.** D5/AC3a/TC-7
   carried a genuine contradiction — "authoritative, knob value wins" **and**
   "warn — not overwrite — on hand-set mismatch" cannot both hold without the
   provenance the sidecar was *dropped* to avoid (c-design D2). Resolved in
   favour of **authoritative**: the `fail-if-unavailable` knob always wins and is
   reflected; a value hand-set in the *generated* `settings.json` is overwritten
   (overrides belong in the knob or `settings.local.json`). This is consistent
   with D2 ownership-by-shape, the Constraint "cwf-project.json is the single
   source of truth", the user's stated intent (knob default true, user-changeable),
   and is the fail-safe choice (no preserved weakened boundary). TC-7 asserts the
   authoritative behaviour.

2. **CWF-shape predicate pinned to any `Read(...)` deny.** D2/d-Step 3 left the
   "CWF-shaped" predicate to exec. Pinned as `^Read\(.+\)$`: CWF emits no deny
   shape other than `Read(...)`, so in the *generated* `settings.json` the whole
   `Read(...)` deny region is CWF-owned. Gives orphan-free whole-family removal
   with **no persisted state**, and is exactly the AC1c documented stance (an
   identical user `Read(~/.ssh)` in the generated file is removed on toggle-OFF;
   user overrides live in `settings.local.json`). Non-`Read` denies are preserved.

3. **New test file `t/pretooluse-sandbox-logging.t`** for R3 hook behaviour (the
   e-plan named two files). The hook is a distinct script; a dedicated hermetic
   behaviour test (run from a tempdir copy so its `FindBin`-relative log never
   touches the repo) is cleaner than wedging it into the merge-helper suite.
   Registration/gating stays in `t/cwf-claude-settings-merge.t` as planned.

4. **No `~`-expansion fail-closed fallback branch.** d-Step 3 specified one "if no
   rule form reliably expands `~`". The `~/`-prefixed forms are emitted because
   the path-prefix expansion is the behaviour recorded first-hand in Task 178's
   discovery; the contingency does not trigger, so no fallback was coded. **Honest
   limit**: the Perl suite asserts the emitted *string forms* only — Claude Code's
   runtime `Read(~/…)` matcher expansion is a property it cannot exercise. Carried
   as a residual runtime-verification item for rollout (h), not claimed as
   verified this session.

## Blockers Encountered
None.

## Deferral Check
- [x] All d-plan steps 1–8 executed.
- [x] a-plan SC1–SC5 met (SC4 = R1 split, the approved descope; 179.1 seeded).
- [x] b-requirements FR1–FR7 addressed (FR4/R1 split per AC4d).
- [x] c-design D1–D8/D-events followed; D2 sidecar-free as revised; deviations above.
- [x] No work silently deferred — R1 split is recorded + backlogged.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*

## Security Review

**State**: no findings

I have everything I need. Let me reason through the five threat categories.

### Security review — Task 179 (implementation phase)

I reviewed the full changeset (1681 lines) and read the three production files
first-hand at HEAD: `cwf-claude-settings-merge`, `pretooluse-sandbox-logging`,
and `CWF::Validate::Config`, plus the new doc and `read_json_file` in
`ArtefactHelpers.pm`. The non-`.cwf` task-doc markdown (a–e files), BACKLOG, and
`script-hashes.json` carry no executable surface (integrity/permissions for the
latter are owned by `cwf-manage validate`, out of scope here).

**(a) Bash injection / unsafe command construction** — No new shell invocation
is introduced anywhere. The dep probe (`dep_on_path`/`sandbox_dep_guard`) is the
one place that could have reached for `which`/`command -v`/`system` and
deliberately does not: it splits `$ENV{PATH}` in pure Perl and uses a `-x`
filetest. No `system`, backticks, or `qx` added. Clean.

**(b) Perl helpers consuming git/user output without `-z` / input validation** —
No git porcelain is consumed by new code, so the `-z` concern does not arise.
Input parsing is JSON via `JSON::PP->decode` (structured, not newline-split).
credential-deny-list entries are validated as strings in two independent places
(`_validate_sandbox_block` and the helper's own `validate_sandbox_block_or_die`
— correct no-trust-gate stance). The R3 hook decodes stdin under a top-level
`eval` and bails on any non-HASH / malformed shape. Clean.

**(c) Prompt injection via user-supplied strings** — Handled correctly. The R3
hook records only a presence flag for `dangerouslyDisableSandbox`, a fixed
`event` token, and a type-guarded `tool_name`; never the raw `command`/
`tool_input`. Header + doc state the log is operator-facing and must never be
re-fed into LLM context. The dep guard emits a fixed-token message; no probe
output interpolated. Deny-list strings flow into `.claude/settings.json` (a
permission-engine file, not free-form LLM text) and originate from the
repo-owned `cwf-project.json`, not `{arguments}`/git output.

**(d) Unsafe environment-variable handling** — Only `$ENV{PATH}` is touched, for
the probe; it constructs `"$seg/$name"` for an `-x` test where `$name` is a
compile-time literal (`bwrap`/`socat`), and skips empty/`.` segments so a
current-dir PATH entry cannot mask a missing dep (TC-8). No env var influences a
write target. Clean.

**(e) Pattern-based risks (safe-here invariants for 179.1)** — (1)
`is_cwf_read_deny` removes every `^Read\(.+\)$` deny on toggle-OFF; safe because
c-design D2 defines the whole generated-`settings.json` `Read(...)` region as
CWF-owned (user denies belong in `settings.local.json`; TC-6 asserts AC1c). The
invariant must hold wherever the predicate is reused. (2) The R3 `tool_name` is
the only field copied from hook stdin; type-guarded and `JSON::PP`-encoded.
179.1 must not start recording the Bash command string without enforcing the
no-re-feed rule.

**Conclusion** — No actionable security concerns. Default-OFF; the credential
boundary fails *surfaced* (dies on malformed config) not silently-OFF; the dep
guard is advisory pure-Perl with no spawn surface; the R3 logger is
fail-open/observe-only and records no attacker-controlled command text.

```cwf-review
state: no findings
summary: Sandboxing diff is clean; default-OFF, fail-surfaced boundary, pure-Perl probe (no spawn), R3 logger records only a presence flag (no raw command). Two safe-here pattern notes recorded for 179.1: ownership-by-shape Read(...) deletion and the type-guarded tool_name log field.
```

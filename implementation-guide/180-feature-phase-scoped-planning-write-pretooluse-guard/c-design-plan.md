# phase-scoped planning-write PreToolUse guard - Design
**Task**: 180 (feature)

## Task Reference
- **Task ID**: internal-180
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/180-phase-scoped-planning-write-pretooluse-guard
- **Template Version**: 2.1

## Goal
Design R1 against the real substrate: extend `cwf-claude-settings-merge` (matcher
regex + gated registration), a new fail-closed PreToolUse hook reusing
`CWF::TaskContextInference`, an enum config knob, and a doc update — satisfying
b-requirements FR1–FR7.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility.
Per b-NFR3: correctness (no crown-jewel leak, no smoothing, trusted source) >
no-brick usability > extend-don't-fork.

## Grounding (read first-hand this session)
- PreToolUse can block via **`permissionDecision: "deny"`** + a reason — Task 178
  first-hand (`178/f-implementation-exec.md:41-42,93`). The **exact JSON
  envelope** (`hookSpecificOutput.{hookEventName,permissionDecision,
  permissionDecisionReason}`) is **re-verified against the current hooks doc at
  exec** (D4) — not assumed.
- `cwf-claude-settings-merge`: event allowlist already `{Stop,SubagentStop,
  PreToolUse}` (`:94`, 179); matcher regex `^[A-Za-z0-9_-]+$` (`:98`) still
  rejects `|`; R3 hook gating in `partition_manifest` (`next if $path eq
  $R3_HOOK_PATH && !$register_r3`) is the model for gated registration.
- `CWF::TaskContextInference::infer_task_context()` returns a hashref with
  `confidence` ∈ {`correlated`,`uncorrelated`,`no_signals`,`error`} and — **only
  on `correlated`** — a top-level `workflow_step`. **`workflow_step` is the
  letter-PREFIXED filename stem** (`f-implementation-exec`, `b-requirements-plan`
  — `TaskContextInference.pm:527-567`, POD `:683`), **not** a bare name. With
  Option A (D1) the hook needs **only** `confidence` + `workflow_step` — it does
  **not** need the task directory, so it does **not** call `resolve_num` (which is
  `CWF::TaskPath`'s, not TCI's, anyway). `infer_task_context` also `warn`s `$@`
  (may contain paths) to STDERR on error (`:127`) — the hook must contain that
  (D6). The hook `use`s the library directly (one process; no CLI parse).
- `CWF::ArtefactHelpers::validate_write_path_allowlist` (`:89`) is prefix+`..`+
  absolute defence but **dies** on abs/`..` — a *rejecter*, not a *classifier*;
  model, not drop-in (b-AC4b).
- Worktree-safe repo-root resolution is **`CWF::Common::find_git_root`**
  (`Common.pm:66`, prefers `--git-common-dir` over `--show-toplevel`) — named
  explicitly; TCI does **not** expose a resolver (it uses `getcwd` + an ad-hoc
  worktree regex), so "same as TCI" was wrong ([[feedback_worktree_cwd_dataloss]]).
- The helper has **two** sandbox validators: `_validate_sandbox_block`
  (`Config.pm`, `cwf-manage validate`) **and** `validate_sandbox_block_or_die`
  (`cwf-claude-settings-merge:323`, merge-time). Both must learn the new knob.
- `partition_manifest($json, $register_r3)` gates R3 via a **single scalar** +
  `next if $path eq $R3_HOOK_PATH && !$register_r3` (`:141`); a second gated hook
  needs a **second** parameter + path constant, not reuse of the R3 flag.

## Key Decisions

### D1 — Crown-jewel **deny-list** (Option A), collapsing the policy
Adopt b-question **Option A**. The entire policy reduces to one rule:
> **Deny a crown-jewel `Edit`/`Write` unless TCI positively and unambiguously
> resolves to a recognised exec phase. Permit everything that is not a crown
> jewel.**
This satisfies every invariant for free: task-own files live under
`implementation-guide/…` (never a crown jewel) ⇒ **always writable**; the middle
ground (`BACKLOG.md`, `README`) is not a crown jewel ⇒ **never bricked**; crown
jewels are protected in planning **and** on ambiguity (both fail to "positively
resolve to exec"). Option B (allow-list of task-own only) is **rejected** —
bricking-prone and adds a middle-ground question this avoids entirely.

### D2 — Default-deny gate logic (FR2/FR3, AC2b/AC3a)
```
if tool_name not in {Edit, Write}:     ALLOW    # this hook governs only these;
                                                 # defence vs matcher-less degrade (D6)
target = canonical(tool_input.file_path)        # D3; absent/unparseable → DENY (D6)
if target is NOT a crown jewel:        ALLOW    # task-own, middle ground, src
ctx = infer_task_context()                       # D1 reuse (only here)
if ctx.confidence == 'correlated'
   and is_exec_phase(ctx.workflow_step):  ALLOW  # the ONLY crown-jewel ALLOW
else:                                    DENY    # planning, unknown-step,
                                                 # uncorrelated, no_signals,
                                                 # error, exception → crown-jewel deny
```
- `is_exec_phase` **strips the leading `^[a-j]-` letter prefix** from
  `workflow_step` and matches the **name suffix** against a **closed literal set**
  (canonical exec set = `{implementation-exec}`; design may add `testing-exec`).
  Matching the name not the letter survives the v2.0/v2.1 `e`/`f` swap
  (`workflow-steps.md:11`); any unrecognised suffix (incl. future letters,
  `unknown`) ⇒ **not exec** ⇒ DENY. This is the single ALLOW gate for crown jewels.
- `workflow_step` exists only on `confidence=='correlated'` — the `&&`
  **short-circuits on confidence first**; do **not** reorder it (a reorder would
  deref an absent key; Perl would treat it as undef → DENY, still fail-closed, but
  keep the ordering explicit).
- Crown-jewel-ness is checked **first** so a non-crown-jewel write never calls TCI
  (NFR1 — most writes skip the git shell-out).
- **`testing-exec` caveat**: `_infer_workflow_step` falls back to most-recently-
  modified when no `In Progress` marker exists, so during exec the freshest file
  may momentarily be a later phase. Design fixes the exec set conservatively
  (`implementation-exec` only by default) and the test plan covers this.

### D3 — Crown-jewel set + canonical classification (AC3c)
- **Root**: resolved via **`CWF::Common::find_git_root`** (worktree-safe). **Most-
  restrictive worktree rule**: a target is a crown jewel if it falls under `.cwf/`
  or `.claude/` of the `find_git_root` root **or** of the active worktree root if
  that differs — both hold CWF system files worth protecting, so classify against
  either (fail-closed). The worktree case is a required test scenario.
- **Crown jewels**: canonical paths under `<root>/.cwf/` or `<root>/.claude/`.
- **Classify**: canonicalise `file_path` (collapse `..`, resolve relative against
  the active root, resolve symlinks on the existing prefix); under
  `.cwf/`/`.claude/` ⇒ crown jewel. **Unresolvable** (escaping symlink, `realpath`
  error, a Write to a not-yet-existing path whose parent escapes) ⇒ **conservative
  crown-jewel ⇒ DENY**. A naive string-prefix match is insufficient (a
  `task-own/../.cwf/x` must classify as crown jewel). New sibling classifier
  modelled on — not reusing — `validate_write_path_allowlist`.

### D4 — Deny mechanism + fixed-token message (AC2d)
Emit the PreToolUse **deny** decision. The reason is a **fixed enumerated token**
— `crown-jewel:.cwf` | `crown-jewel:.claude`, plus `phase:<name-suffix>` |
`phase:unknown`, plus `target:unresolved` — **never** the path, `tool_input`, file
body, or TCI's `task_slug`/branch string (AC3b/c). The `phase:` token is the
**normalised name suffix** (letter-stripped, version-stable per D2), so the token
set is a closed compile-time enumeration. ALLOW ⇒ exit 0, no decision emitted.
**Exec re-verification (two envelopes, both unverifiable in pure Perl):** (i) the
**deny output** envelope (`hookSpecificOutput.{hookEventName,permissionDecision,
permissionDecisionReason}`) and (ii) the **input** envelope key
(`tool_input.file_path`) are both re-confirmed against the current hooks doc at
exec and **cited**; the test plan includes a **positive parse test against a real
captured PreToolUse payload** so an envelope drift surfaces as a test failure, not
a silent session brick (the `target:unresolved` deny widens the brick surface to
all Edit/Write on drift — D6).

### D5 — Matcher-regex widening (AC1a/b/d)
`read_hook_directives` matcher validator (`:98`) becomes
`^[A-Za-z0-9_-]+(?:\|[A-Za-z0-9_-]+)*$` — admits `Edit|Write`; rejects `Edit|`,
`|Write`, `||`, and any metacharacter; a single token still matches (existing
single-token TC-M* unaffected). Inert-string rationale restated. **Event**
allowlist unchanged (179 already added PreToolUse). Same-commit hash refresh (AC6a).
- **TC-10 must be REWRITTEN, not kept green**: the existing
  `t/cwf-claude-settings-merge.t` TC-10 asserts `Edit|Write` is *rejected →
  matcher-less* (it encoded "179 widened only the event allowlist"). R1 inverts
  that: TC-10 now asserts `Edit|Write` is *accepted* as the matcher, plus new
  negatives for `Edit|`/`|Write`/`||`. The d-plan/e-plan name TC-10 as a changed
  test (the validation "TC-M* green" means the single-token cases, not TC-10).

### D6 — Posture: fail-closed enforcing (NFR4/NFR5) — opposite of R3
**No** outer fail-open `eval`. Structure (matches D2 order):
- **Tool-name gate first**: if `tool_name` ∉ {`Edit`,`Write`} ⇒ **ALLOW**. This
  is the defence against a matcher-less degradation — if the matcher directive
  ever failed validation and fell back to matcher-less, a PreToolUse hook fires on
  **all** tools (Bash/Read have no `file_path`); without this gate, `target:
  unresolved` would then DENY *every* tool call (a total brick). Non-Edit/Write ⇒
  allow closes that path.
- **Then** parse `file_path`. If it is **absent on an actual Edit/Write call**
  (malformed/drifted envelope) ⇒ **DENY** (`target:unresolved`) — the one deny
  beyond a confirmed crown jewel, justified because an unclassifiable Edit/Write
  target cannot be proven safe (NFR3: correctness > no-brick). The envelope key is
  re-verified at exec + a positive parse test guards drift (D4).
- Every other internal failure (TCI error/exception) still has the parsed target,
  so it denies **only** if that target is a crown jewel — non-bricking.
- **Contain TCI's STDERR**: `infer_task_context` `warn`s `$@` (may contain paths)
  on error (`TaskContextInference.pm:127`); the hook installs a local
  `$SIG{__WARN__}` (or redirects STDERR) around the call so no internal/path
  string leaks to the harness/LLM (AC3b/AC2d hold end-to-end).
- The crown-jewel-deny default is the **outermost** behaviour.

### D7 — Config: one enum knob bundling gating + observe-only (AC5a/c)
New `sandbox.planning-write-guard`: **`"off"` (default) | `"observe"` |
`"enforce"`**. `off` ⇒ hook not registered, zero settings surface. Default `off`
even when `sandbox.enabled:true`, so enabling sandboxing gives R2 without the
intrusive R1 until explicitly opted in (staged).
- **Both validators learn the enum** (the dual-validator gap): `_validate_sandbox_block`
  (`Config.pm`) **and** `validate_sandbox_block_or_die` (`cwf-claude-settings-merge:323`)
  must each accept only `{off,observe,enforce}` and **reject any other string
  (incl. empty) as a hard `[CWF] ERROR:` / violation** — fail-closed-loud, never
  silently treated as `off`-or-`enforce`. Otherwise `validate` and the merge run
  disagree (single-source-of-truth break).
- **Gating threads a second flag**: `partition_manifest` gains a `$register_guard`
  parameter (derived once as `planning-write-guard != off`, exactly like
  `$register_r3`) and a `$GUARD_HOOK_PATH` constant with its own
  `next if $path eq $GUARD_HOOK_PATH && !$register_guard` — the single R3 scalar
  does **not** generalise; the new hook is in the same `.cwf/scripts/hooks/` glob
  branch and would otherwise register unconditionally.
- The **hook itself** reads the knob to choose observe vs enforce (D8); the merge
  helper sees only the boolean — no enum logic duplicated into the helper.

### D8 — Observe-only mode (AC5c)
`observe` ⇒ run the identical classification, but on a would-deny **log** a
fixed-key record (reuse `.cwf/sandbox-violations.log`, already gitignored +
not-hash-tracked; `event: planning-guard-observe`, `phase`, `path-class` — **no
raw path/command**) and **PERMIT**. `enforce` ⇒ DENY (D4). Both modes covered by
tests. **Posture split**: `observe` is **fail-open** (a log-write failure is
swallowed and the write permitted, like R3); only `enforce` is fail-closed. Lets
an adopter watch what would block before turning on enforcement.

### D-events/D-matcher
Event allowlist unchanged. Only the matcher regex widens (D5). The new hook
declares `# cwf-hook-event: PreToolUse`, `# cwf-hook-matcher: Edit|Write`.

## System Design
### Components
- **`cwf-claude-settings-merge`** (extended): matcher regex (D5); a `$register_guard`
  param + `$GUARD_HOOK_PATH` second gate in `partition_manifest` (D7); the
  knob read in `read_sandbox_config`; and `validate_sandbox_block_or_die` extended
  for the enum (D7 dual-validator).
- **`pretooluse-planning-write-guard`** (new hook): D1–D6, D8. `use`s
  `CWF::TaskContextInference` + `CWF::Common::find_git_root`; tool-name gate;
  contains TCI's STDERR; emits deny or logs+permits.
- **`CWF::Validate::Config`** (extended): `planning-write-guard` enum in
  `_validate_sandbox_block` (hard-reject unknown values).
- **`cwf-project.json` + template**: `planning-write-guard: "off"`.
- **`.cwf/docs/sandboxing.md`** (extended): FR7 guard section.

### Data Flow (one Edit/Write call, guard=enforce)
1. Hook reads stdin JSON; extract `file_path`. Unparseable ⇒ DENY (`target:unresolved`).
2. Canonicalise → crown jewel? If **no** ⇒ ALLOW (exit 0). (No TCI call.)
3. `infer_task_context()`. Correlated + exec phase ⇒ ALLOW; else ⇒ emit deny
   (`crown-jewel:<area>`, `phase:<name|unknown>`).

## Interface Design
### `cwf-project.json` `sandbox` block (adds)
```json
"sandbox": { "...": "...", "planning-write-guard": "off" }
```
### Generated `.claude/settings.json` (guard on, illustrative)
```json
{ "hooks": { "PreToolUse": [ { "matcher": "Edit|Write",
    "hooks": [ { "type": "command",
      "command": ".cwf/scripts/hooks/pretooluse-planning-write-guard",
      "timeout": 5 } ] } ] } }
```
### Deny output (shape re-verified at exec — D4)
```json
{ "hookSpecificOutput": { "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "crown-jewel:.cwf phase:b-requirements-plan" } }
```

## Constraints
- POSIX, core-Perl only; British; no personal names.
- Same-commit `script-hashes.json` refresh for the helper + `Config.pm` + new
  hook; gated registration via the merge helper; no validate-silencing surface.
- Fixed-token enumerated messages; no `tool_input`/path/`task_slug` interpolation;
  hook reads no security-influencing env var for decisions (b-NFR4 FR4(d)).

## Decomposition Check
- [ ] Time >1 week? No.
- [x] Complexity 3+ concerns? Matcher + hook + classifier + config — cohesive on
      one helper + one hook + the config block.
- [x] Risk needing isolation? The enforce/brick risk — handled by the `observe`
      enum value (D7/D8), not a split.
- [~] Independence? Matcher widening precedes the hook; sequenced.
Single task.

## Validation
- [ ] D1/D2: crown-jewel deny iff not-positively-exec; non-crown-jewel always
      allowed; task-own + middle ground permitted.
- [ ] D3: canonical classification over relative/`..`/symlink; unresolvable ⇒
      deny; root resolved worktree-safe; `task-own/../.cwf/x` ⇒ crown jewel.
- [ ] D4: deny envelope (exec-verified); fixed enumerated token; no path/slug echo.
- [ ] D5: matcher admits `Edit|Write`, rejects `Edit|`/`|Write`/`||`/metachars;
      single-token TC-M* green; **TC-10 rewritten** (now asserts accept); hash
      refreshed same commit.
- [ ] D6: non-Edit/Write tool ⇒ ALLOW (matcher-less-degradation brick closed);
      malformed Edit/Write stdin ⇒ deny; TCI error with parsed target ⇒ deny only
      if crown jewel (non-bricking); TCI STDERR contained (no path leak);
      crown-jewel-deny is outermost; positive parse test vs a real PreToolUse payload.
- [ ] D7: enum validated in **both** validators; unknown value ⇒ hard error
      (not silent); second gate flag wired; `off` ⇒ no registration / OFF
      no-regression; default `off` under `sandbox.enabled:true`.
- [ ] D8: observe logs fixed-key (no raw path) + permits (fail-open); enforce
      denies (fail-closed); both tested.
- [ ] NFR1: per-call overhead measured against the ≤~50 ms/call budget (deferred
      to e-testing-plan; recorded, gross regression fails).
- [ ] Worktree: a `.cwf/` write under a worktree root is classified crown-jewel.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
D1–D8 implemented as designed. The crown-jewel deny-list (D1) collapsed the
policy cleanly; the dual validator (D7), tool-name-gate-first (D6), and the
second registration flag (D7) all carried into exec without rework.

## Lessons Learned
Choosing the lib/hook split (pure `CWF::PlanningGuard` vs thin hook) at design
time was the highest-leverage decision — it is what made the policy matrix
unit-testable without git/TCI. The fail-closed-unless-positively-exec framing
(D2) is what reconciled "fail closed" with "never brick".

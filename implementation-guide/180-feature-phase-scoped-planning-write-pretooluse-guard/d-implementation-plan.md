# phase-scoped planning-write PreToolUse guard - Implementation Plan
**Task**: 180 (feature)

## Task Reference
- **Task ID**: internal-180
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/180-phase-scoped-planning-write-pretooluse-guard
- **Template Version**: 2.1

## Goal
Implement the c-design build: matcher widening + gated registration in
`cwf-claude-settings-merge`, a new fail-closed PreToolUse guard hook with its pure
logic in a testable lib module, the enum knob in both validators + config, and the
doc. TDD throughout; same-commit hash refresh.

## Workflow
Patterns first → failing test → minimal impl → green → same-commit hash refresh →
**restore hashed-script working perms to recorded (0500/0444)** before commit
(the harness chmods `u+w` on edit — `feedback_hashed_script_working_perms`).

## Files to Modify
### Primary
- `.cwf/scripts/command-helpers/cwf-claude-settings-merge` — matcher regex (`:98`,
  D5); `$GUARD_HOOK_PATH` const; `partition_manifest($json,$register_r3,$register_guard)`
  + second `next if` gate; `read_sandbox_config` exposes the knob;
  `validate_sandbox_block_or_die` enum (D7); main wiring `$register_guard`. **Hash-tracked.**
- `.cwf/lib/CWF/PlanningGuard.pm` — **new** lib: the pure, TCI-free decision logic
  (`classify_path`, `decide`) so the policy matrix is unit-testable without git.
  `classify_path` is **modelled on, not reusing,** `validate_write_path_allowlist`
  — different contract: it must *classify* an arbitrary **absolute/relative**
  target (collapse `..`, resolve symlinks on the existing prefix, conservative
  crown-jewel on unresolvable), whereas the allowlist helper *rejects* (`die`s on
  abs/`..`) a known-relative manifest path; they cannot share code. **Hash-tracked
  (new) — a lib `.pm` gets a `sha256` entry with NO `permissions` key** (like
  `Config.pm`/`ArtefactHelpers.pm`; the Task-164 mistake — only executables carry
  a perms ceiling).
- `.cwf/scripts/hooks/pretooluse-planning-write-guard` — **new** thin I/O wrapper:
  `use FindBin; use lib "$FindBin::Bin/../../lib"; use CWF::Common qw(find_git_root);
  use CWF::TaskContextInference qw(infer_task_context); use CWF::PlanningGuard;`
  (no existing hook pulls in `lib/` — this is new wiring). Reads stdin,
  resolves roots, classifies, infers (STDERR contained), reads the knob, emits
  deny / observe-log / allow. **Hash-tracked (new), `permissions: "0500"`.**
- `.cwf/lib/CWF/Validate/Config.pm` — `planning-write-guard` enum in
  `_validate_sandbox_block` (hard-reject unknown). **Hash-tracked.**
- `implementation-guide/cwf-project.json` + `.cwf/templates/cwf-project.json.template`
  — add `"planning-write-guard": "off"` to the `sandbox` block.

### Supporting
- `.cwf/security/script-hashes.json` — refresh helper + `Config.pm`; add
  `CWF::PlanningGuard` + the new hook entries (`permissions: "0500"`). **Same commit.**
- `.cwf/docs/sandboxing.md` — guard section (FR7).
- `t/cwf-claude-settings-merge.t` (matcher rewrite TC-10 + gating), `t/validate-config.t`
  (enum), `t/planning-guard.t` (**new** — pure logic), `t/pretooluse-planning-write-guard.t`
  (**new** — hook I/O).

## Implementation Steps

### Step 1 — Matcher widening + TC-10 rewrite (D5; FR1) — tests first
- [ ] **Rewrite TC-10** in `cwf-claude-settings-merge.t`: a `# cwf-hook-matcher:
      Edit|Write` directive now registers with `matcher: "Edit|Write"` (was: asserted
      rejected → matcher-less). Add negatives: `Edit|`, `|Write`, `||`, `Edit|;rm`
      ⇒ matcher-less fallback. Single-token TC-M* unchanged.
- [ ] Widen the validator (`:98`) to `^[A-Za-z0-9_-]+(?:\|[A-Za-z0-9_-]+)*$`;
      restate the inert-string rationale in the comment. Green.

### Step 2 — Enum knob: both validators + config (D7; FR1/FR5)
- [ ] `validate-config.t`: `planning-write-guard` ∈ {off,observe,enforce} valid;
      unknown / empty / non-string ⇒ violation; absent ⇒ no violation (default off).
- [ ] Helper test: a malformed `planning-write-guard` ⇒ `validate_sandbox_block_or_die`
      dies `[CWF] ERROR:` (the merge-time validator, not only `cwf-manage validate`).
- [ ] Implement the enum check in **both** `_validate_sandbox_block` (`Config.pm`)
      and `validate_sandbox_block_or_die` (`cwf-claude-settings-merge:323`); unknown
      value is a hard error/violation (never silently `off`/`enforce`). The
      **allowed set is a single shared literal** — define it once (a constant in
      `Config.pm`, or in `CWF::PlanningGuard` if cleaner) and have both validators
      **and** the helper's `$register_guard` derivation consume it; do **not**
      hand-type `{off,observe,enforce}` in three places (that reintroduces the
      single-source-of-truth break one layer down). Add `"planning-write-guard":
      "off"` to config + template. Green.

### Step 3 — Gated registration: second flag (D7; FR5/FR6)
- [ ] Tests: manifest containing the guard hook (directives PreToolUse + `Edit|Write`):
      `off` ⇒ not registered, not in allow, OFF golden unchanged; `observe`/`enforce`
      ⇒ registered under `PreToolUse` with `matcher: "Edit|Write"`. R3 gating still
      independent (toggling one doesn't change the other).
- [ ] Add `$GUARD_HOOK_PATH`; extend `partition_manifest($json,$register_r3,$register_guard)`
      with `next if $path eq $GUARD_HOOK_PATH && !$register_guard`; main computes
      `$register_guard = $sandbox_on && (planning-write-guard ne 'off')`; thread it.
      Green.

### Step 4 — Pure decision logic `CWF::PlanningGuard` (D1–D3, D6; FR2/FR3/FR4) — tests first
- [ ] `t/planning-guard.t` against the pure functions (no git, fully deterministic):
      - `classify_path`: `<root>/.cwf/x`, `<root>/.claude/x` ⇒ crown jewel;
        `implementation-guide/180-…/x.md` ⇒ not; `task-own/../.cwf/x` ⇒ crown jewel;
        unresolvable/escaping ⇒ crown jewel (conservative); a `.cwf/` under a second
        (worktree) root ⇒ crown jewel.
      - `decide(tool, is_crown, confidence, workflow_step)`: non-Edit/Write ⇒ allow;
        non-crown ⇒ allow; crown + correlated + `f-implementation-exec` ⇒ allow
        (letter stripped, name-matched); crown + planning / uncorrelated / no_signals
        / error / `unknown` / unrecognised ⇒ deny; deny reason is a fixed enumerated
        token (no path).
      - **Ordering-regression case**: crown + `confidence=uncorrelated` **with an
        exec-looking `workflow_step` passed in** ⇒ **deny** (the only-correlated-
        positively-allows rule must gate on confidence first; this case fails if an
        implementer reorders the `&&`). The wrapper (Step 5) maps TCI output so only
        a `correlated` result yields a scalar `workflow_step`; every other
        confidence collapses to deny regardless of any (plural/absent) step field.
- [ ] Implement `CWF::PlanningGuard` (core-Perl only): `classify_path($target,
      \@roots)` (canonical/`..`-collapse/symlink-on-existing-prefix; modelled on, not
      reusing, `validate_write_path_allowlist`) and `decide(...)` returning
      `('allow'|'deny', $token)`. `is_exec_phase` = closed literal set on the
      `^[a-j]-`-stripped suffix. Green.

### Step 5 — The hook wrapper + observe mode (D4/D6/D8; FR2/FR3/FR5)
- [ ] `t/pretooluse-planning-write-guard.t` (hook run as a temp copy under a
      tempdir `.cwf/scripts/hooks/`, like `pretooluse-sandbox-logging.t`, so the
      `FindBin`-anchored log stays in the tempdir): a **real captured PreToolUse
      `Edit` payload** to a crown-jewel path ⇒ deny JSON (envelope + fixed token,
      **no path echo**) — **this fixture parse is the binding check** for envelope
      drift (the doc-citation is secondary, not a substitute); non-Edit/Write tool
      ⇒ allow; malformed stdin / missing `file_path` on Edit ⇒ deny
      `target:unresolved`; `observe` ⇒ logs fixed-key record (no raw path) + permits;
      observe log-write failure ⇒ swallowed + permit; enforce ⇒ deny; **observe log
      lands relative to the hook dir, not cwd**. TCI STDERR not leaked into stdout.
- [ ] Implement the thin hook: read stdin JSON; **tool-name gate first**
      (non-Edit/Write ⇒ exit 0); extract `file_path` (absent on Edit/Write ⇒ deny
      `target:unresolved`).
- [ ] **Two-root derivation (explicit)**: `@roots` = `find_git_root` (main root —
      it prefers `--git-common-dir`) **plus** the worktree root via
      `git rev-parse --show-toplevel` when it differs. **Contain STDERR of the
      `--show-toplevel` shell-out** too (not just TCI's `warn`), so no path leaks.
- [ ] `classify_path($target, \@roots)`; if crown jewel, call `infer_task_context`
      under a local `$SIG{__WARN__}` (contain its `$@` STDERR); `decide`.
- [ ] **Knob read, root-anchored**: read `planning-write-guard` from
      `<root>/implementation-guide/cwf-project.json` (resolve against the already-
      computed root — **not** a bare cwd-relative path, since the hook's cwd is not
      a guaranteed invariant), `-f` guard. `off`/absent ⇒ allow; `observe`/`enforce`
      per value; **invalid/unreadable ⇒ `enforce` (fail-closed)** — add a one-line
      comment noting the deliberate asymmetry (the *validators* reject a bad enum
      loudly at merge time; the *hook* cannot `die` mid-tool-call so it fails closed
      to enforce, never silently `off`).
- [ ] `enforce` ⇒ emit deny (**output envelope re-verified against the current
      hooks doc at exec + cited**, but the fixture test above is what binds);
      `observe` ⇒ append a fixed-key record to the **`FindBin`-anchored**
      `"$FindBin::Bin/../../sandbox-violations.log"` (same derivation as R3, cwd-
      independent — not a bare `.cwf/...`) + exit 0. Green.

### Step 6 — Limitations doc (FR7)
- [ ] `.cwf/docs/sandboxing.md`: a "Planning-write guard" section — protects crown
      jewels (`.cwf/`, `.claude/`) during planning; opt-in enum
      `planning-write-guard: off|observe|enforce` (default off, even with sandbox on);
      fail-closed enforcing posture (contrast R3); advisory (Edit/Write are not
      sandboxed — this is a permission/hook gate); `dangerouslyDisableSandbox` /
      agent-reachability caveats still apply (AC7a/AC7b).

### Step 7 — Integrity + full validate (same commit)
- [ ] Add `CWF::PlanningGuard` + `pretooluse-planning-write-guard`
      (`permissions: "0500"`) to `script-hashes.json`; refresh the helper +
      `Config.pm` entries — **same commit** (`hash-updates.md`).
- [ ] **Restore working perms to recorded** (`chmod 0500` the hook, the helper;
      `0444` any data file the harness bumped) before commit; confirm `git status`
      shows no spurious mode diff.
- [ ] Run full `t/`, `cwf-claude-settings-merge --dry-run` (guard off / observe /
      enforce), and `cwf-manage validate` — all clean.

### Step 8 — NFR1 cost note
- [ ] Per-call overhead measurement (≤~50 ms/call budget, b-NFR1) is an
      **e-testing-plan / g-exec** item — recorded there, not asserted here. Note the
      crown-jewel-first short-circuit means only crown-jewel writes pay the TCI cost.

## Code Changes
Edit sites fixed: helper `:98` regex, `:68`-style new `$GUARD_HOOK_PATH`,
`partition_manifest` signature + gate, `validate_sandbox_block_or_die` (`:323`),
main wiring (`:449`); `Config.pm` `_validate_sandbox_block`; new `CWF::PlanningGuard`
+ hook modelled on `pretooluse-sandbox-logging`. No pseudocode for routine merge
logic; the security-load-bearing pieces (classify_path canonicalisation, decide
matrix, fail-closed defaults, fixed-token) carry explicit tests above.

## Test Coverage
**See e-testing-plan.md.** Unit (pure `classify_path`/`decide` matrix — the bulk,
deterministic), integration (hook I/O incl. real-payload parse, observe vs enforce,
STDERR containment), regression (matcher single-token TC-M*, R3 gating
independence, OFF no-regression golden), negative (no validate-silencing; log not
hash-tracked). **NFR1** cost recorded in e/g.

## Validation Criteria
**See e-testing-plan.md.** Gate: full suite green; `cwf-manage validate` clean;
dry-run off/observe/enforce correct; both validators reject a bad enum; TC-10
rewritten; perms restored to recorded.

## Scope Completion
Complete Steps 1–8. No descope. Do not mark Finished until the hash refresh
(Step 7) + perm restore + `validate` are clean in the same commit as the edits.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 8 steps executed TDD-style. One ordering deviation (built `CWF::PlanningGuard`
before the validator steps, since the shared enum lives there — d-plan Step 2
sanctioned this) and one addition (the `read_hook_directives` directive-scan fix,
later simplified to remove the artificial cap). Same-commit hash refresh + perm
restore held; no spurious git mode diff.

## Lessons Learned
The plan's instruction to verify registration by dry-run (not source-grep) was
what surfaced the directive-scan misregistration. Step 7's explicit "restore perms
to recorded" guard kept the hashed-file edits clean. The decide-ordering
regression test the plan called for proved its worth as a fail-closed guard.

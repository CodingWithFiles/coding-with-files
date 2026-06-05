# phase-scoped planning-write PreToolUse guard - Testing Plan
**Task**: 180 (feature)

## Task Reference
- **Task ID**: internal-180
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/180-phase-scoped-planning-write-pretooluse-guard
- **Template Version**: 2.1

## Goal
Verify the build against b-requirements FR1–FR7 + the c-design validation rows,
using the Perl harness (`t/`) + `cwf-manage validate`. TDD — cases written
failing-first per the d-plan order. The **bulk of the policy matrix is unit-tested
on the pure `CWF::PlanningGuard` functions** (no git, deterministic); the hook
I/O, the substrate, and integrity get thinner integration coverage.

## Test Strategy
### Test Levels
- **Unit — pure logic (`t/planning-guard.t`)**: `classify_path` + `decide`
  matrices. The deterministic core; no git, no harness.
- **Unit — substrate (`t/cwf-claude-settings-merge.t`, `t/validate-config.t`)**:
  matcher widening (TC-10 rewrite), gated registration, dual-validator enum.
- **Integration — hook I/O (`t/pretooluse-planning-write-guard.t`)**: stdin parse,
  real-payload envelope, observe vs enforce, STDERR containment — hook run as a
  tempdir copy so its `FindBin`-anchored log stays hermetic.
- **Regression**: single-token TC-M*, R3-gating independence, sandbox-OFF golden.
- **No system/E2E tier**: Claude Code's runtime matcher + actual deny enforcement
  are owned by Claude Code + the OS (enforcement-ownership boundary, FR7); the deny
  **output** envelope is asserted as a string shape + re-cited at exec (D4).

### Coverage Targets
- **Critical path (100%)**: the `decide` matrix (every confidence × phase ×
  crown/non-crown), `classify_path` traversal/symlink/unresolvable/worktree,
  matcher widening accept+reject, dual-validator enum, gated registration,
  enforce-denies / observe-permits, fail-closed defaults.
- **Edge**: `Edit|`/`|Write`/`||` matcher reject; `task-own/../.cwf/x`; malformed
  stdin; invalid/unreadable knob ⇒ enforce; ordering-regression; testing-exec
  most-recent-fallback.

## Test Cases
### Functional — pure logic (`t/planning-guard.t`)
- **TC-1 (FR2/FR4, classify_path)**: `<root>/.cwf/x`, `<root>/.claude/x` ⇒ crown;
  `implementation-guide/180-…/x.md`, `BACKLOG.md`, `README` ⇒ not crown;
  `task-own/../.cwf/x` ⇒ crown (canonicalised, not string-prefixed); escaping
  symlink / unresolvable / not-yet-existing-escaping-parent ⇒ crown (conservative).
- **TC-2 (FR2/FR3, worktree)**: a `.cwf/` path under a **second (worktree) root**
  passed in `@roots` ⇒ crown (most-restrictive two-root rule).
- **TC-3 (FR2/FR3, decide matrix)**: non-Edit/Write ⇒ allow; non-crown ⇒ allow;
  crown + `correlated` + `f-implementation-exec` ⇒ allow (letter stripped,
  name-matched); crown + planning (`c-design-plan` etc.) ⇒ deny; crown +
  `uncorrelated`/`no_signals`/`error`/`unknown`/unrecognised-suffix ⇒ deny.
- **TC-4 (FR3, ordering-regression)**: crown + `confidence=uncorrelated` **with an
  exec-looking `workflow_step` argument** ⇒ **deny** (confidence gates first; fails
  if the `&&` is reordered).
- **TC-5 (FR2/AC2d, token)**: every deny returns a **fixed enumerated token**
  (`crown-jewel:.cwf|.claude` + `phase:<suffix>|phase:unknown` + `target:unresolved`)
  and **never** the input path/slug.

### Functional — substrate
- **TC-6 (FR1/AC1a-b/d — matcher widening, `cwf-claude-settings-merge.t`)**:
  **TC-10 rewritten** — `# cwf-hook-matcher: Edit|Write` ⇒ registers with
  `matcher:"Edit|Write"`; `Edit|`, `|Write`, `||`, `Edit|;rm` ⇒ matcher-less
  fallback; single-token TC-M* unchanged.
- **TC-7 (FR5/FR6 — gated registration)**: guard hook in manifest + directives
  (PreToolUse, `Edit|Write`): `planning-write-guard:off` ⇒ not registered, not in
  allow, OFF golden unchanged; `observe`/`enforce` ⇒ registered under `PreToolUse`
  with `matcher:"Edit|Write"`; R3 gating independent (toggling guard ≠ touching R3).
- **TC-8 (FR1/FR5/AC1e — dual-validator enum)**: in `validate-config.t`,
  `planning-write-guard` ∈{off,observe,enforce} valid; unknown/empty/non-string ⇒
  violation; absent ⇒ no violation. In the helper, a malformed value ⇒
  `validate_sandbox_block_or_die` dies `[CWF] ERROR:`. The allowed set is one
  shared literal (assert both validators agree — e.g. same rejection on `"enforce"`).

### Functional — hook I/O (`t/pretooluse-planning-write-guard.t`)
- **TC-9 (FR2/AC2d — enforce deny on a real payload)**: a **captured real
  PreToolUse `Edit` payload** targeting `.cwf/…`, knob `enforce` ⇒ deny JSON with
  the verified envelope + fixed token, **no path echo**. *(This fixture parse is
  the binding envelope-drift check.)*
- **TC-10 (FR2/FR3/D6)**: non-Edit/Write tool ⇒ allow (exit 0, no decision) —
  matcher-less-degradation brick closed; malformed stdin / missing `file_path` on
  an Edit ⇒ deny `target:unresolved`.
- **TC-11 (FR5/D8 — observe)**: knob `observe` + would-deny ⇒ appends a fixed-key
  record (`event:planning-guard-observe`, `phase`, `path-class`; **no raw path**)
  to the **`FindBin`-anchored** log (assert it lands relative to the hook dir, not
  cwd) **and permits**; a log-write failure ⇒ swallowed + permit (observe is
  fail-open).
- **TC-12 (FR5/D7 — runtime knob)**: `off`/absent ⇒ allow (passthrough);
  invalid/unreadable knob ⇒ **enforce** (fail-closed); knob read resolves against
  the git root, not cwd.
- **TC-13 (NFR4/AC3b — no leak)**: TCI's `warn`/`$@` and the `--show-toplevel`
  shell-out STDERR are contained — never appear on the hook's stdout/decision.

### Non-Functional
- **TC-14 (NFR1 — performance)**: measure per-Edit/Write hook overhead; record
  against the **≤~50 ms/call** budget (≈3× the R3 ~15 ms baseline). The
  crown-jewel-first short-circuit means a **non-crown write pays ~0** (no TCI) —
  measure both a crown-jewel path (full cost) and a non-crown path (short-circuit).
  Recorded, not asserted as an SLA; a gross regression past the budget fails.
- **TC-15 (NFR4 — testing-exec freshness)**: when `_infer_workflow_step` falls
  back to most-recently-modified and the freshest file is a later phase, the
  conservative exec set (`implementation-exec` only) is honoured — assert the
  classifier's behaviour on a `g-`/`h-` freshest-file scenario (deny unless the
  positively-resolved step is in the exec set).
- **Security**: no path silences `cwf-manage validate`; deny token + observe record
  carry no attacker-controlled string; matcher widening admits no metacharacter.
- **TC-16 (integrity)**: new hook + `CWF::PlanningGuard` hash-tracked (hook with
  `permissions:"0500"`, the `.pm` with **no** permissions key); helper + `Config.pm`
  refreshed **same commit**; observe log **not** hash-tracked; `cwf-manage validate`
  clean; working perms restored to recorded (no spurious git mode diff).

## Test Environment
### Setup
- Perl `t/` harness. `planning-guard.t` needs no git (pure functions; pass roots +
  TCI fields as arguments). `pretooluse-planning-write-guard.t` copies the hook
  into a tempdir `.cwf/scripts/hooks/` (FindBin-hermetic log) and feeds captured
  payloads on stdin. Config/manifest fixtures for the merge-helper tests as in
  Task 179. No production `.claude/settings.json` mutated (temp/dry-run).
### Automation
- `prove t/`; golden-file comparison (TC-7 OFF); `cwf-manage validate` (TC-16). No CI.

## Validation Criteria
- [ ] TC-1..TC-16 pass.
- [ ] Full `t/` suite green; `cwf-manage validate` clean.
- [ ] Matcher dry-run off/observe/enforce correct; OFF golden matches.
- [ ] Both validators reject a bad enum identically; same-commit hash refresh +
      perms restored.
- [ ] NFR1 cost recorded (crown-jewel vs short-circuit paths).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1..TC-16 all executed and pass (see g-testing-exec). 77 task-specific tests
across the four suites; full `t/` suite 686 green. NFR1 (TC-14) recorded: crown
36.9 ms / non-crown 25.9 ms. TC-16 integrity clean; observe log confirmed not
hash-tracked. Added one regression (TC-M6) for the directive-scan fix.

## Lessons Learned
Putting the bulk of coverage on the pure `CWF::PlanningGuard` functions paid off —
the deterministic matrix needs no git, and the hermetic git-repo hook test only
had to bind I/O. The real-payload fixture (TC-9) is the right binding check for
Claude Code envelope drift; a doc citation alone would not survive a schema change.

# phase-scoped planning-write PreToolUse guard - Implementation Execution
**Task**: 180 (feature)

## Task Reference
- **Task ID**: internal-180
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/180-phase-scoped-planning-write-pretooluse-guard
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially (TDD: failing test → impl → green)
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Status → Finished; full suite + `cwf-manage validate` clean

## Actual Results (by d-plan step)

- **Step 1 — matcher widening + TC-10 rewrite (FR1/D5)**: rewrote TC-10 to assert
  `Edit|Write` registers (was: asserted rejected) + negatives `Edit|`/`|Write`/`||`/
  `Edit|;rm` fall back; single-token unchanged. Widened the validator regex to
  `^[A-Za-z0-9_-]+(?:\|[A-Za-z0-9_-]+)*$`; restated the inert-string rationale.
- **Step 4 — `CWF::PlanningGuard` (FR2/FR3/FR4)** *(done before Steps 2-3 — see
  Deviation D1)*: pure `classify_path` (canonical/`..`-collapse/symlink-on-existing-
  prefix; conservative crown-on-unresolvable) + `decide` (confidence-first
  fail-closed; fixed token, no path) + `is_exec_phase` (letter-stripped, exec set =
  `implementation-exec` only) + shared `PLANNING_GUARD_VALUES`. `t/planning-guard.t`
  (TC-1..TC-5 + ordering regression), no git.
- **Step 2 — enum knob, both validators + config (FR1/FR5)**: enum check in
  `_validate_sandbox_block` (Config.pm) AND `validate_sandbox_block_or_die`
  (helper), both consuming the single shared `PLANNING_GUARD_VALUES`; added
  `"planning-write-guard": "off"` to config + template. Tests TC-S8..S10 +
  helper TC-PG1.
- **Step 3 — gated registration (FR5/FR6)**: `$GUARD_HOOK_PATH`, second
  `partition_manifest` flag + `next if`, `$register_guard = $sandbox_on &&
  (knob ne 'off')`. TC-PG2 (off/observe/enforce, sandbox-off gate, R3 independence).
- **Step 5 — the hook (FR2/FR3/FR5)**: thin `pretooluse-planning-write-guard`
  (tool-gate-first → crown-jewel-first short-circuit → root-anchored knob →
  contained TCI → decide → observe-log / enforce-deny). Two-root derivation,
  STDERR contained, FindBin-anchored observe log. `t/pretooluse-planning-write-guard.t`
  (8 hermetic git-repo subtests incl. real-payload deny envelope, TC-13 no-leak).
- **Step 6 — doc (FR7)**: `.cwf/docs/sandboxing.md` "Planning-write guard" section
  (off/observe/enforce, fail-closed contrast vs R3, advisory caveat, knob in the
  config example).
- **Step 7 — integrity**: refreshed helper + `Config.pm` shas, added
  `CWF::PlanningGuard` (no perms key) + `pretooluse-planning-write-guard` (`0500`)
  to `script-hashes.json` (same commit); working perms restored (0500 execs, 0600
  libs); `git diff --summary` shows no mode change; full `t/` (686) + dry-runs
  off/observe/enforce + `cwf-manage validate` all clean.
- **Step 8 — NFR1**: per-call cost measurement is a g-testing-exec item (recorded
  there). Crown-jewel-first short-circuit means non-crown writes skip TCI entirely.

## Deviations from Plan

- **D1 (reordering, not scope)**: implemented `CWF::PlanningGuard` (Step 4) before
  the validator/gating Steps 2-3. The shared `PLANNING_GUARD_VALUES` enum lives in
  PlanningGuard and both validators + the registration gate consume it, so the
  module had to exist first. The d-plan Step 2 explicitly sanctioned defining the
  enum "in CWF::PlanningGuard if cleaner".
- **D2 (latent Task-179 defect found + fixed — surfaced)**: `read_hook_directives`
  scanned only the **first 15 lines**, but the canonical CWF hook header places
  the `cwf-hook-event` / `cwf-hook-matcher` directives at ~line 18. So **both** the
  R3 logging hook (`pretooluse-sandbox-logging`, shipped in 179) **and** the new
  guard hook fell back to **Stop / no matcher** instead of registering under
  `PreToolUse` — verified empirically via dry-run. The new guard could not work
  without addressing this, and silently moving only my own directives up while
  leaving R3 broken would be smoothing over a discovered defect. Fix: scan the
  **leading comment block** (stop at the first non-comment line past the shebang)
  instead of a fixed line window — no arbitrary line cap at all (review feedback:
  the original 15 and an interim 50 were both artificial; the comment-block end is
  the natural bound). This repairs R3's registration as a
  tested consequence (regression TC-M6; dry-run now shows both hooks under
  PreToolUse with the correct matchers). No prod `.claude/settings.json` is
  affected in this repo (sandbox off here); adopters with sandbox on get the
  correct registration on their next `cwf-claude-settings-merge` run.

## Blockers Encountered

None. (D2 was diagnosed and fixed in-phase.)

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed (Steps 1-8)
- [x] All success criteria from a-task-plan.md met (SC1-SC5)
- [x] All requirements from b-requirements-plan.md addressed (FR1-FR7, NFR1 deferred to g)
- [x] All design guidance in c-design-plan.md followed (D1-D8)
- [x] No planned work deferred without user approval
- [x] If work deferred: NFR1 cost measurement is a planned g-testing-exec item (per d-plan Step 8)

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*

## Security Review

**State**: no findings

## Security review — Task 180 implementation changeset

I reviewed the implementation-phase changeset (anchor `9117bca`) covering the new PreToolUse guard hook, its pure decision lib, the `cwf-claude-settings-merge` matcher/window/gating changes, the two config validators, config/template/docs, and the workflow artefacts. I read the two new code files first-hand (`.cwf/scripts/hooks/pretooluse-planning-write-guard` and `.cwf/lib/CWF/PlanningGuard.pm`) rather than relying on the diff alone, and confirmed the integrity entries and referenced test files exist.

### (a) Bash injection / unsafe command construction
The hook shells out twice. `derive_roots` runs `git rev-parse --show-toplevel 2>/dev/null` — a fixed literal command with no interpolation, captured with STDERR redirected. `find_git_root` is the established worktree-safe resolver (it redirects its own STDERR). No task slug, branch, or path is ever interpolated into a shell string. TCI's git shell-outs are inside the library, unchanged by this task. No `system($string)` single-string form anywhere. Clean.

### (b) Perl helpers consuming git/user output without validation
`derive_roots` consumes a single `--show-toplevel` line via `chomp` (one path, no newline-splitting of porcelain) and compares it for set membership. `read_knob` reads `cwf-project.json` with `'<:raw'` + `JSON::PP->decode` under `eval`, with `-f`/`!-l` guards rejecting irregular/symlinked config (fail-closed to `enforce`). The merge-helper's `read_hook_directives` window widening (15→50 lines, stop at first non-comment) reads the hook's own header, not user data. No unsafe backtick interpolation. Clean.

### (c) Prompt injection via user-supplied strings
This is the highest-stakes category for this feature and it is handled correctly. The deny reason surfaced to the agent (`permissionDecisionReason`) is built solely from compile-time literals:
- `$DENY_CROWN` = `crown-jewel:.cwf|.claude` (a fixed literal naming the two roots, *not* derived from the target path).
- The phase suffix comes from `_phase_token`, which returns `phase:$s` only when `$s` is in the closed `%KNOWN_PHASES` set, else collapses to `phase:unknown`. `$workflow_step` itself originates from TCI's parsed output, never from `tool_input`.
- The unresolved branch emits the literal `target:unresolved`.

No path, file body, `task_slug`, or branch string can reach the agent-visible reason. TCI's `warn`/`$@` (which can contain paths) is contained by `local $SIG{__WARN__} = sub {}` in `infer_contained`, and TCI itself runs under `eval`. The `--show-toplevel` STDERR is redirected. So neither leak vector (deny reason, nor diagnostic STDOUT/STDERR) carries untrusted content. This satisfies the threat-model FR4(c)/(e) contract.

### (d) Unsafe environment-variable handling
The hook reads no security-influencing environment variable for its decisions — path/phase classification derives only from `tool_input.file_path` and TCI output (matching b-NFR4 FR4(d)). `FindBin` anchors both the lib path and the observe-log path, so cwd is not a trusted input. `_canonical_abs` uses `File::Spec->rel2abs`/`Cwd::abs_path` (cwd-relative resolution of a relative `file_path`), which is the correct and expected behaviour; both target and roots resolve under the same process cwd, so there is no inconsistency. Clean.

### (e) Pattern-based risks (safe-here-but-risky-elsewhere)
Three observations, all currently safe — reported per the carve-out framing, none actionable as defects:

1. **Matcher-regex widening**: `^[A-Za-z0-9_-]+(?:\|[A-Za-z0-9_-]+)*$`. The charset is `[A-Za-z0-9_-]` only, anchored, with `|` permitted strictly as a token separator between non-empty tokens. `Edit|`, `|Write`, `||`, `Edit|;rm` all fail (TC-10 negatives). No space, `;`, `$`, quote, `.`, or `/` is admissible. The value is copied verbatim into a `.claude/settings.json` matcher key and never reaches a shell. Safe here because the parsed value is an inert JSON string matched against tool names; audit any future reuse that passed this regex output to a shell.

2. **`classify_path` canonicalisation**: resolves symlinks on the longest existing prefix, re-appends not-yet-existing components, then collapses residual `.`/`..`. The dangerous direction (classifies non-crown but writes into `.cwf/`) is closed: `..` collapsed after symlink resolution (`task-own/../.cwf/x` → crown), and unresolvable → `1` (conservative crown → deny). Residual exposure is classic symlink-TOCTOU, inherent to every advisory PreToolUse gate (Edit/Write are not OS-sandboxed; docs are explicit).

3. **Fail-closed default asymmetry**: `read_knob` returns `enforce` on any unreadable/irregular/unparseable config but `off` on a cleanly-absent config/knob — the intended deny-on-ambiguity posture, the deliberate inverse of R3's fail-open stance; documented inline. No concern.

### Cross-checks
- Deny-reason token set is a closed compile-time enumeration; no `tool_input` interpolation.
- `decide` orders the confidence check before `is_exec_phase` (short-circuit `&&`); dedicated ordering-regression test.
- Both validators consume the single shared `PLANNING_GUARD_VALUES` literal — no enum drift.
- Gating threads a second independent flag (`$register_guard`/`$GUARD_HOOK_PATH`); R3-independence tested.
- Integrity entries present + refreshed same changeset (correctness is `cwf-manage validate`'s job).
- No path disables/relaxes/silences a boundary or `cwf-manage validate`; observe log is fail-open-by-design and operator-facing/untrusted.

I found no actionable security concerns in this changeset.

```cwf-review
state: no findings
summary: Fail-closed guard; deny reason is fixed-token only, matcher regex admits no shell/settings metachar, classify_path is conservative on traversal/symlink/unresolvable, no env/path leak to LLM. Residual symlink-TOCTOU is inherent to an advisory hook and documented.
```

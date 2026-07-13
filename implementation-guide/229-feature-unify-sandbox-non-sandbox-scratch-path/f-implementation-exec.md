# unify sandbox and non-sandbox scratch path - Implementation Execution
**Task**: 229 (feature)

## Task Reference
- **Task ID**: internal-229
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/229-unify-sandbox-non-sandbox-scratch-path
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [ ] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [ ] Verify all prerequisites met
- [ ] Execute implementation steps sequentially
- [ ] Update "Actual Results" for each step
- [ ] Document any deviations from plan

## Implementation Steps (from d-implementation-plan.md)

See d-implementation-plan.md § Implementation Steps 1–5. All executed.

## Actual Results

### Step 2: Core library (`CWF::Common.pm`)
- **Planned**: EUID base `$SCRATCH_BASE`, pure `scratch_parent`, two-level guard in
  `scratch_dir`, new `scratch_fail_hint`.
- **Actual**: Renamed `$SANDBOX_TMP_PROBE`→`$SCRATCH_BASE = "/tmp/claude-$>"`; rewrote
  `scratch_parent` to `return ("$SCRATCH_BASE/cwf$dashed", undef)` with the whole
  env→probe→/tmp branch deleted (net deletion). `scratch_dir` now iterates the
  mkdir→`-l`→`-d` triad over `($SCRATCH_BASE, $parent)`, base first. Added
  `scratch_fail_hint($kind)` (exported) returning a base-naming sentence for
  `mkdir_failed`/`symlink_parent`, `''` otherwise.
- **Deviations**: None.

### Step 3: Callers
- **Actual**: `best-practice-resolve` — `scratch_out_path` now delegates to
  `scratch_dir($num)` (inline `$ENV{TMPDIR}` derivation deleted), warn+exit-1 augmented
  with `scratch_fail_hint`; two stale `${TMPDIR:-/tmp}` doc-strings fixed.
  `security-review-changeset` — hint appended to the `scratch unavailable` warn; three
  stale `${TMPDIR:-/tmp}` strings fixed. `plan-mechanical-check` — hint appended to the
  `cannot resolve scratch dir` warn. All import `scratch_fail_hint`.
- **Deviations**: None.

### Step 4: Doc + tests
- **Actual**: Rewrote `tmp-paths.md` Convention/Derivation/Sandbox-alignment/Threat-model/
  Permission-allowlist for the EUID base; added the macOS known-limitation. Reworked
  `t/scratch.t` per e-testing-plan (seam → `$CWF::Common::SCRATCH_BASE`, probe TC-9..14
  dropped, TC-9..13 added incl. poison-`$TMPDIR` invariance and the intermediate-symlink
  guard) — 13 subtests green.
- **Deviations (test-only, user-approved)**: Two `security-review-changeset.t` cases
  needed updating beyond the plan because they encoded the *old* `$TMPDIR` behaviour:
  - **TC-TMPDIR-1/2/3**: flipped from "honours `$TMPDIR`" to "invariant under `$TMPDIR`,
    lands under `/tmp/claude-<euid>`" — a strictly better regression guard.
  - **TC-209-2** (char-device-doesn't-abort): uses `unshare -rm`, which remaps the
    process to **uid 0**, so the helper now derives `/tmp/claude-0` — uncreatable under a
    read-only `/tmp`. This is a fail-closed scratch error, *distinct* from the Task 209
    abort it guards (the fix names the cause in stderr). Per user decision, the case now
    **skips on that exact signal** (`scratch unavailable (mkdir_failed)`) rather than
    building bind-mount/tmpfs scaffolding to synthesise a writable uid-0 base; a genuine
    char-device abort still fails loudly, and the case runs normally anywhere the base is
    creatable. If this edge is ever hit for real, revisit with deeper testing.

### Step 5: Hashes + validation
- **Actual**: Refreshed sha256 for the four hashed files in this commit; working perms
  already matched recorded (0600 lib, 0500 scripts). `cwf-manage validate`: OK.
  `prove -r t/`: 78 files, 1077 tests, all pass. Smoke test: `best-practice-resolve`
  `.out` landed at
  `/tmp/claude-1000/cwf-home-matt-repo-coding-with-files/task-229/best-practice-context-implementation-exec.out`
  — identical to the `CWF PATHS` hook-advertised parent (hook/writer parity confirmed).

## Blockers Encountered

None. (The TC-209-2 uid-0 incompatibility above was surfaced and resolved by user decision.)

## Changeset Reviews (Step 8 — five reviewers, run in parallel)

Prep: `security-review-changeset` exit 0, 2446 lines (309 production); `best-practice-resolve`
3 matches → all five reviewers launched. Classified deterministically via
`security-review-classify`.

### Security Review

**State**: no findings

EUID-derived base removes the `$TMPDIR`-injection surface (net attack-surface reduction);
the two-level `0700`/symlink guard is correctly extended to the new `/tmp/claude-<euid>`
intermediate; task-number validation and list-safe `mkdir` preserved. One informational
pattern-note: `scratch_parent` is intentionally guard-free (safe because only the
non-writing hook consumes it; all writers route through `scratch_dir`) — audit any future
writer that bypasses `scratch_dir`.

### Best-Practice Review

**State**: findings

One low-severity Perl style divergence — `t/scratch.t sub dash` read `$_[0]` instead of
unpacking `@_` first (`perl/subroutines.md #115`), inconsistent with the module's own subs.
**Resolved**: rewritten to `my ($p) = @_; (my $d = $p) =~ …`. Rest conformant.

### Improvements Review

**State**: no findings

Net deduplication — removes `best-practice-resolve`'s second derivation point, centralises
the guard in `scratch_dir`, and shares one `scratch_fail_hint` helper across all three
callers; `$SANDBOX_TMP_PROBE` and the test mirror helper deleted.

### Robustness Review

**State**: no findings

Errors/edge cases handled soundly — two-level symlink guard (base before parent),
race-tolerant `mkdir`-then-check, fail-closed on an unwritable base with a cause-naming
hint. The macOS regression is deliberate and fail-safe; the TC-209-2 skip keys on the exact
fail-closed signal, preserving loud failure for a genuine abort.

### Misalignment Review

**State**: no findings

Reuses the `scratch_parent`/`scratch_dir` single derivation point; removes a second inline
`$TMPDIR` derivation; the new `scratch_fail_hint` and the test seam follow existing module
conventions. The remaining `$TMPDIR` reader is the documented `-tool-check` carve-out.

## Deferral Check
Before marking status=Finished, verify:
- [ ] All steps from d-implementation-plan.md executed
- [ ] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements-plan.md addressed (if applicable)
- [ ] All design guidance in c-design-plan.md followed (if applicable)
- [ ] No planned work deferred without user approval
- [ ] If work deferred: Follow-up task created and linked

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See the per-step "Actual Results" above (Steps 2–5).

## Lessons Learned
The change was net-negative in code size — deleting the `$TMPDIR`/probe branch and the second
derivation point, not adding logic. The one reviewer finding (`sub dash` reading `$_[0]`) was
a style slip caught by the best-practice pass and fixed in-phase.

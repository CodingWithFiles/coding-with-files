# unify sandbox and non-sandbox scratch path - Design
**Task**: 229 (feature)

## Task Reference
- **Task ID**: internal-229
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/229-unify-sandbox-non-sandbox-scratch-path
- **Template Version**: 2.1

## Goal
Design the EUID-derived scratch base: `scratch_parent` returns
`/tmp/claude-<euid>/cwf-<slug>` computed from the EUID integer alone, never reading
`$TMPDIR`. The `$TMPDIR`/probe machinery is retired, the second derivation point is
removed, the new intermediate dir is guarded, and the convention doc is reconciled.

## Design Priorities
Correctness first (project rule: correctness > maintainability > performance), then the
CWF lens: Testability → Readability → Consistency → Simplicity → Reversibility.

## Investigation findings
`$TMPDIR` per context (this environment, empirically confirmed + docs + user report):

- **Standard sandbox (Linux/WSL2)**: sandboxed Bash sees `TMPDIR=/tmp/claude-<uid>`
  (writable session temp); the unsandboxed hook sees `$TMPDIR` **unset**; off-sandbox
  `$TMPDIR` is unset and `/tmp` is writable. Empirically, `/tmp/claude-<uid>/cwf-…` is
  writable both sandboxed and off-sandbox (the latter creates the base under a writable
  `/tmp`). `/tmp` itself is read-only under the sandbox (confirmed: `mkdir /tmp/x` →
  "Read-only file system").
- **`$TMPDIR` is documented to differ by mode** (sandboxing.md) and to **change** on a
  sandbox→non-sandbox fallback. That is precisely why we stop reading it: the base must
  be mode-invariant, and the only value that is, is one derived from the EUID.
- **Report scheme**: the user's `$TMPDIR` carried the `cwf-<slug>` parent
  (`/tmp/cwf-<slug>[/claude-<uid>]`) — almost certainly a user `TMPDIR` override (the
  sandbox nests its session temp under an inherited `$TMPDIR`). Reading `$TMPDIR` is what
  let that value double the path; not reading it makes the bug impossible.
- **macOS Seatbelt — a working→broken regression the owner has explicitly accepted**:
  today `scratch_parent` reads `$TMPDIR` first, so an in-sandbox macOS process resolves to
  the Seatbelt writable temp under `/var/folders` and **scratch works there now**. The
  EUID base hardcodes `/tmp/claude-<euid>`, which Seatbelt does not make writable, so
  in-sandbox macOS goes from working to **fail-closed**. This is a deliberate owner
  decision (accept the macOS regression now, keep the Linux design pure); the fix is a
  platform-specific base, captured as a Medium backlog item. Not a silent footnote — the
  owner chose it after the hybrid `$TMPDIR`-fallback alternative was on the table.

## Key Decisions
### D1 — EUID-derived base, `$TMPDIR` not read
- **Decision**: `scratch_parent($root?)` returns `"$SCRATCH_BASE/cwf$dashed"` where
  `$dashed` is the existing `s{/}{-}g` transform of the main root and `$SCRATCH_BASE` is a
  package-scoped scalar defaulting to `"/tmp/claude-$>"` (`$>` = EUID). `$ENV{TMPDIR}` is
  **not read**. Pure string work (given a resolved `$root`); no filesystem, no `stat`.
- **Rationale**: EUID is the only mode-invariant, non-attacker-controlled input that
  names the sandbox's writable per-uid temp on Linux/WSL2. Because `$TMPDIR` never enters
  the path, the reporter's doubling is structurally impossible and the env-var-injection
  class (`..`, relative, hostile values) is gone — a net *removal* of code and attack
  surface versus today's `$TMPDIR`-honouring + probe branches.
- **Trade-offs**: couples to the undocumented `/tmp/claude-<uid>` name (already true of
  today's probe). A future rename or a non-Linux sandbox where that dir is unwritable
  fails **closed** (D3), not silently — accepted (macOS backlog follow-up).

### D2 — Retire the probe; `$SCRATCH_BASE` is the test seam
- **Decision**: Remove `$SANDBOX_TMP_PROBE` and the whole `$ENV{TMPDIR}`/probe/`/tmp`
  base-selection block. The package scalar `$SCRATCH_BASE` (default `/tmp/claude-$>`) is the
  **only** override point — tests set `local $CWF::Common::SCRATCH_BASE = tempdir` to redirect
  scratch hermetically. It is a package var, not an env var, and reads no env var.
- **Rationale**: One base, one code path. The scalar preserves the existing test seam's
  hermeticity (tests never touch the real `/tmp/claude-<uid>`) without an env read. Name
  it for what it now is (a base, not a "probe").

### D3 — Fail-closed with a static, cause-naming diagnostic, uniform across callers
- **Decision**: `scratch_dir` keeps `mkdir -m 0700 -p` semantics and, on failure, returns
  the **attempted parent path** alongside `$kind` (a contract extension — callers already
  branch on `$kind`, so returning the path in slot 1 rather than `undef` is safe). **All
  three** `scratch_dir` callers (`best-practice-resolve`, `security-review-changeset`,
  `plan-mechanical-check`) emit the **same** static hint on `mkdir_failed` — e.g.
  *"scratch base <path> not writable; a custom TMPDIR or non-Linux sandbox may be the
  cause"* — not just the one caller D5 touches. The hint is **unconditional** (we don't
  read `$TMPDIR`, so we can't detect an override) and names the concrete check, not an
  asserted cause.
- **Rationale**: "surface, never smooth" — every entry point that can hit `mkdir_failed`
  (a macOS user runs security-review and mechanical-check too) must give the same
  actionable, path-bearing line. Static wording avoids over-claiming on unrelated failures.

### D4 — Guard the new `/tmp/claude-<euid>` intermediate (race-tolerant, two-level)
- **Decision**: `scratch_dir` creates and validates **both** levels — the new
  `/tmp/claude-<euid>` intermediate (referenced directly via the `$SCRATCH_BASE` scalar,
  since it can't be recovered from `scratch_parent`'s combined return) **and** the
  `cwf-<slug>` parent — using the existing **race-tolerant ordering**: `mkdir(-m 0700)
  unless -d`, then an `lstat`-based `-l` reject *after* the mkdir (never lstat-before-mkdir,
  which would be a TOCTOU regression), returning `symlink_parent`. The leaf stays covered
  by the fail-closed write.
- **Rationale**: The EUID scheme adds a predictable directory in world-writable `/tmp`
  that the current single-level guard does not cover; a pre-planted **symlink** there would
  otherwise be followed. The `-l` check is **defence-in-depth**, not the boundary: the
  containment boundary remains the atomic `0700` create + fail-closed write (a pre-planted
  *real* dir owned by another user is defeated by the write failing, consistent with the
  single-user threat model — the guard does not re-assert ownership). `tmp-paths.md`
  § Threat model is updated to state the intermediate inherits this same boundary
  (harness-created `drwx------` in-sandbox; CWF-created `0700` off-sandbox).

### D5 — Remove the second derivation point (FR5)
- **Decision**: Refactor `best-practice-resolve::scratch_out_path` to call
  `scratch_dir($num)`, deleting its inline `$ENV{TMPDIR}`-based base + its own mkdir/guard.
- **Rationale**: It reimplements the derivation (with `$TMPDIR`) and would miss this fix.
  Both files are hash-tracked → same-commit refresh.
- **Error-contract mapping**: `scratch_out_path` today `warn`s the offending path then
  `exit 1`. With D3, `scratch_dir` returns `($attempted_path, $kind)`. The refactor
  assigns in **list context** (`my ($scratch, $kind) = scratch_dir($num)`), branches on
  `$kind`, and maps each kind (`not_a_repo`/`bad_num`/`symlink_parent`/`mkdir_failed`)
  to the existing warn-with-path + `exit 1` plus the shared D3 hint; the task number flows
  through `scratch_dir`'s anchored `bad_num` validation.

## Resolution table (pins FR1)
`$S = cwf<dashified-main-root>`; `<euid>` = `$>`. The base is **always** `/tmp/claude-<euid>`
regardless of `$TMPDIR`, so every row resolves to the same parent. Outputs are the
**pinned literal** strings the tests assert against.

| `$TMPDIR` at call time (Linux)        | Resolved parent           |
|---------------------------------------|---------------------------|
| unset (hook / off-sandbox)            | `/tmp/claude-<euid>/$S`   |
| `/tmp/claude-<euid>` (standard sandbox) | `/tmp/claude-<euid>/$S` |
| `/tmp/$S` (reporter override)         | `/tmp/claude-<euid>/$S`   |
| `/tmp/$S/claude-<euid>` (reporter Bash) | `/tmp/claude-<euid>/$S` |
| `/tmp/a/../b` (traversal) / relative `tmp` / empty | `/tmp/claude-<euid>/$S` |

The point of the table is that the right column never varies: `$TMPDIR` is not an input.
(On a macOS Seatbelt sandbox the *creation* of this parent fails closed — D3 — since the
writable temp is elsewhere; that is the accepted limitation, not a different resolved
string.)

## Component / data flow
- `CWF::Common::scratch_parent($root?)` — resolves the main root (or uses the passed
  `$root`), returns `"$SCRATCH_BASE/cwf$dashed"` where `$SCRATCH_BASE` defaults to `/tmp/claude-$>`. Pure
  string given `$root`; no `stat`, no `$ENV` read.
- `CWF::Common::scratch_dir($num)` — `scratch_parent` + the two-level `0700`-create with
  symlink-reject on **both** `/tmp/claude-<euid>` (D4) and the `cwf-<slug>` parent, + the
  `task-<num>` leaf; returns `($path, $kind)`.
- `userpromptsubmit-context-inject` hook — unchanged; consumes `scratch_parent` (now
  cheaper: no probe `lstat`).
- `best-practice-resolve` — `scratch_out_path` delegates to `scratch_dir` (D5).
- `security-review-changeset`, `plan-mechanical-check` — already call `scratch_dir`; they
  gain **only** the shared D3 hint line on `mkdir_failed` (no derivation change).

## Interface Design
`scratch_parent`/`scratch_dir` keep their two-value `($value, $err_kind)` shape and error
kinds (`not_a_repo`, `bad_num`, `symlink_parent`, `mkdir_failed`); the sole extension is
D3 — on failure `scratch_dir`'s slot 1 is the attempted path, not `undef` (callers branch
on `$kind`). The package scalar `$SCRATCH_BASE` (renamed from `$SANDBOX_TMP_PROBE`) is the
test seam. No new exported symbols.

## Constraints
- Perl core-only; `use utf8;`; the derivation is pure string work (given `$root`).
  Annotate the obscure `$>` at its single use site (`# $> = effective UID`).
- **Dead code to delete** (not carry over): once `$TMPDIR` is unread, the trailing-slash
  strip `$base =~ s{/+$}{}` and the intermediate `$base` branching variable in
  `scratch_parent` become inert — remove them; `scratch_parent` returns
  `"$SCRATCH_BASE/cwf$dashed"` directly.
- **Hash-tracked files = three**: `CWF::Common.pm`, `best-practice-resolve`, **and
  `security-review-changeset`** — the last carries stale `${TMPDIR:-/tmp}` path-form text
  in its header comment, a body comment, and `print_usage` output (≈ lines 65, 282, 398)
  that the FR7 parity sweep must correct → same-commit hash refresh for all three; confirm
  with `cwf-manage validate`.
- **Test-seam migration is a sweep, not a rename**: `t/scratch.t` obtains hermeticity via
  `local $ENV{TMPDIR}` in nearly every subtest; each must move to
  `local $CWF::Common::SCRATCH_BASE = tempdir` (initialise-in-the-`local`, per the seam
  idiom), and the probe-specific TC-9/TC-10 ("env wins over probe") cease to exist. The
  testing plan budgets for this.
- **Test oracle must be independent (not tautological)**: assert `scratch_parent` against
  the **hard-coded literal** `/tmp/claude-$>/cwf<dashed>` (built from `$>` and the known
  root in the test), and add an explicit "poison `$TMPDIR` does not change the output"
  assertion. Do not mirror the implementation in an `expected_parent` re-derivation.
- `tmp-paths.md` moves with the code: rewrite the Derivation snippet and Sandbox-alignment
  section to the EUID base (drop `${TMPDIR:-/tmp}` and the probe wording), update worked
  and allowlist examples, add the two-level guard to § Threat model, and record the macOS
  limitation.
- Out of scope: `pretooluse-bash-tool-check` state dir (it reads `$TMPDIR` too, but is
  **immune** to this bug — the dir is written *and* read only by the unsandboxed hook, so
  it never crosses the sandbox boundary that produces the read-only-`/tmp`/doubling
  failure; documented carve-out in `tmp-paths.md`); install-time paths; historical
  references; macOS/non-Linux writable base (backlog follow-up).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? If yes, consider decomposition
- [ ] **People**: Does this need >2 people working on different parts? If yes, consider decomposition
- [ ] **Complexity**: Does this involve 3+ distinct concerns? If yes, consider decomposition
- [ ] **Risk**: Are there high-risk components that need isolation? If yes, consider decomposition
- [ ] **Independence**: Can parts be worked on separately? If yes, consider decomposition

**Conclusion**: No decomposition — a base-derivation simplification plus a delegating
refactor, doc, and tests. Tightly coupled; no signal triggered.

## Validation
- [ ] `scratch_parent` returns `/tmp/claude-<euid>/$S` for every `$TMPDIR` in the table,
      byte-identical; no `$ENV{TMPDIR}` read
- [ ] Two-level symlink/`0700` guard covers the new `/tmp/claude-<euid>` intermediate (D4)
- [ ] Fail-closed diagnostic is static and cause-naming (D3); macOS accepted
- [ ] `$SANDBOX_TMP_PROBE`/`$TMPDIR` base-selection removed; `best-practice-resolve`
      delegates to `scratch_dir` (D2, D5)
- [ ] Test oracle asserts hard-coded literals, not a mirrored derivation
- [ ] `tmp-paths.md` rewritten to the EUID base; macOS limitation recorded

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
D1, D2, D4, D5 implemented as designed. **D3 superseded**: its proposed contract extension
(`scratch_dir` returning the attempted path in slot 1) was refined during implementation
planning (d) into a separate exported `scratch_fail_hint($kind)` helper, keeping the existing
`(undef, $kind)` contract intact. This design text is left as the historical record.

## Lessons Learned
Design decisions carry more value when outcome-shaped: D3 should have committed to the
outcome ("uniform, cause-naming diagnostic on `mkdir_failed`") and left the mechanism
(return-shape vs helper) to implementation planning — the same discipline the planning
phase already applies to success criteria, one level down.

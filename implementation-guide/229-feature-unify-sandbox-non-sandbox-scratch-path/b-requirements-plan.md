# unify sandbox and non-sandbox scratch path - Requirements
**Task**: 229 (feature)

## Task Reference
- **Task ID**: internal-229
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/229-unify-sandbox-non-sandbox-scratch-path
- **Template Version**: 2.1

## Goal
Specify the observable behaviour of scratch-path resolution so that one path-based
permission rule matches whether the session is sandboxed or not — by deriving the
scratch base **purely from the caller's EUID** (`/tmp/claude-<uid>/cwf-<slug>`) and
never reading `$TMPDIR`, while preserving the existing writability and symlink-attack
guarantees. (Mechanism detail is chosen in design.)

**Approach note (owner-decided)**: the base is `/tmp/claude-<euid>`, the per-uid
directory Claude Code's sandbox uses as its writable session temp (`$TMPDIR`) and which
is equally writable/creatable off-sandbox. `$TMPDIR` is **not** consulted, so a
context-varying or user-overridden `$TMPDIR` cannot poison the path — the reporter's
doubling becomes structurally impossible, and the env-var attack surface disappears.

## Functional Requirements
### Core Features
- **FR1 — EUID-derived, context-invariant base (no doubling)**: The scratch parent is
  `/tmp/claude-<euid>/cwf-<slug>`, derived from the EUID integer and the main git root
  only. It is byte-identical whatever `$TMPDIR` holds — unset, the standard
  `/tmp/claude-<uid>`, or a poisoned `/tmp/cwf-<slug>[/…]` — because `$TMPDIR` is never
  read. A repeated `cwf-<slug>` segment (the reporter's doubling) is therefore
  structurally impossible: the base is fixed and nothing is appended to `$TMPDIR`.
  (Assumes single-user host where EUID == the uid the sandbox provisions
  `/tmp/claude-<uid>` for; `$>` is that uid.)
  - AC: with `$TMPDIR` ∈ { unset, `/tmp/claude-<uid>`, `/tmp/cwf-<slug>`,
    `/tmp/cwf-<slug>/claude-<uid>`, a relative or `..`-bearing value }, `scratch_parent`
    returns exactly `/tmp/claude-<euid>/cwf-<slug>` — no variation, no doubled segment.
- **FR2 — Same path across contexts and modes**: The path resolved in the unsandboxed
  context-inject hook, the sandboxed Bash tool, and off-sandbox execution are identical
  — what is advertised is what gets written to — because all three compute it from the
  same EUID. This subsumes the old within-session sandbox↔non-sandbox "fallback
  stability" concern: the path cannot move when the mode flips, as it never depended on
  the mode-varying `$TMPDIR`.
  - AC: for a fixed repo/EUID, hook-context and Bash-context resolutions (and an
    off-sandbox resolution) produce the same absolute string.
- **FR3 — Writability, and macOS as a known limitation**: `/tmp/claude-<euid>` is
  writable sandboxed on Linux/WSL2 (it is the session temp) and creatable off-sandbox
  (`/tmp` writable). Where it is genuinely unusable — a user `$TMPDIR` override, **or a
  macOS Seatbelt sandbox whose writable temp is under `/var/folders`** — creation fails
  **closed** at `mkdir` with a clear diagnostic, never a silent divergence or
  wrong-location write. macOS-sandbox support is an **accepted, documented limitation**
  for this task; a platform-specific scratch base (Linux/macOS/…) is a planned
  follow-up once user data is in.
  - AC: `scratch_dir($num)` creates the leaf under a Linux sandbox and off-sandbox; when
    the base is forced unwritable it returns a `mkdir_failed`-class error carrying a
    static hint that names the likely cause (unwritable `/tmp/claude-<euid>` — a custom
    `TMPDIR`/non-Linux sandbox may be the reason). This is the single home for the
    fail-closed behaviour.
- **FR4 — Guards preserved and extended to the new intermediate**: The `0700` atomic
  create, symlink-parent rejection, and task-number validation behave as before, and the
  **new `/tmp/claude-<euid>` intermediate** — predictable and in world-writable `/tmp` —
  gets the same `0700`-create + symlink-reject treatment as the `cwf-<slug>` parent, so
  the guard is not weakened by the added level.
  - AC: existing guard cases (bad_num, symlink_parent on the `cwf-<slug>` parent) pass
    unchanged, **plus** a pre-planted symlink at `/tmp/claude-<euid>` is rejected, not
    followed.
- **FR5 — Single derivation point**: Resolution is centralised in
  `scratch_parent`/`scratch_dir`, and every writer consumes it. This task must also
  **eliminate the existing second derivation point** — `best-practice-resolve`'s
  `scratch_out_path` inlines its own `$TMPDIR`-based copy, so it independently diverges
  today and would not receive the fix. No inline or `$TMPDIR`-based derivation is
  reintroduced anywhere. (The mechanism — delegating to `scratch_dir($num)` — is the
  implementation plan's to specify.)
  - AC: after the change, a grep finds no `$TMPDIR`+`cwf` derivation outside
    `CWF::Common`; `scratch_out_path` no longer computes its own base.
- **FR6 — Retire the `$TMPDIR`/probe machinery; stay hermetically testable**: The
  `$TMPDIR`-honouring branch and the `$SANDBOX_TMP_PROBE` fallback are removed.
  Resolution remains testable with no `$ENV{TMPDIR}` manipulation and no real-filesystem
  dependency for the string derivation (the injection seam is design's choice).
  - AC: `scratch_parent` performs no `$ENV{TMPDIR}` read; tests redirect the base without
    setting any environment variable.
- **FR7 — Convention parity**: `tmp-paths.md` describes the EUID-based behaviour with no
  stale `${TMPDIR:-/tmp}` / doubled / probe forms; the Derivation snippet, sandbox-
  alignment section, worked examples, and allowlist examples all match the code, and the
  macOS known-limitation is recorded.
  - AC: the doc's worked examples and derivation match the code; macOS limitation noted.

### User Stories
- **As a** CwF user whose session can drop from sandbox to non-sandbox mid-task,
  **I want** the scratch path to stay put **so that** my one allowlist rule keeps
  matching and writers don't prompt or fail.
- **As a** devops operator, **I want** one clearly-named `cwf-<repo>/` parent per repo
  (never a doubled `cwf-<repo>/cwf-<repo>/`) **so that** I can see what is live vs
  deletable.

## Non-Functional Requirements
### Performance (NFR1)
- Given a pre-resolved `$root` (the hook passes it), the base derivation is **pure string
  work with no filesystem access and no `$ENV{TMPDIR}` read** — better than the prior
  Task 215 profile, which cost one probe `lstat`. (Without `$root`, `scratch_parent`
  still calls `find_git_root()` as today — the pure-string claim is scoped to the
  resolved-root path the hook uses.)

### Usability (NFR2)
- A single Write/Bash allowlist rule per repo suffices across both modes (the path is
  now genuinely mode-invariant on Linux/WSL2).
- Existing error kinds (`not_a_repo`, `bad_num`, `symlink_parent`, `mkdir_failed`)
  remain unchanged in meaning; the fail-closed diagnostic is specified in FR3.

### Maintainability (NFR3)
- Perl core-only; `use utf8;`; resolution testable with **no `$ENV{TMPDIR}` manipulation**
  and no real-filesystem dependency for the string derivation. (The exact injection seam
  is design's choice.)

### Security (NFR4)
- **Env-var-injection surface eliminated**: `$TMPDIR` is not read, so the whole class of
  hostile/relative/`..`-bearing `$TMPDIR` concerns (threat category d) no longer applies
  to this path. The base is derived from the EUID integer.
- The single-user threat model in `tmp-paths.md` is preserved. The symlink/`0700` guard is
  **extended** to the new `/tmp/claude-<euid>` intermediate (FR4), so the added level does
  not weaken the boundary; `tmp-paths.md` § Threat model is updated to record it.
- The allowlist stays bounded to the project parent — no widening of the pre-approved
  subtree; no-secrets guidance unchanged.

### Reliability (NFR5)
- No silent failure: an unusable base (user `$TMPDIR` override, or a non-Linux sandbox)
  fails **closed** at `mkdir`, never a read-only literal, wrong-location write, or hook
  crash. The observable fail-closed behaviour and its diagnostic are specified once, in
  **FR3** (this NFR does not restate the AC).

## Constraints
- Perl core-only; `use utf8;`; `PERL5OPT=-CDSLA` already in the settings env.
- Hashed-file surface is at least **two** files: `.cwf/lib/CWF/Common.pm` and
  `.cwf/scripts/command-helpers/best-practice-resolve` (the FR5 second-derivation-point
  fix). If the FR7 parity sweep finds stale `${TMPDIR:-/tmp}`/old-form references in
  another hashed script's comments/usage strings (e.g. `security-review-changeset`) that
  would now mislead, that file joins the same-commit hash refresh. Confirm with
  `cwf-manage validate`.
- Keep the single derivation point; do not reintroduce `$TMPDIR`-based or inline shell
  derivation.
- **macOS (and any non-Linux sandbox) is an accepted known limitation** for this task:
  `/tmp/claude-<euid>` is not the Seatbelt writable temp, so sandboxed macOS fails closed.
  A platform-specific scratch base is a planned follow-up (backlog entry added) once user
  data is in.
- Out of scope (per `tmp-paths.md`): the `pretooluse-bash-tool-check` state dir (separate
  base + dashify rule; runs consistently unsandboxed so it does not diverge);
  install-time one-shot paths; historical references in BACKLOG/CHANGELOG/older task
  files; user-owned `settings.local.json` allowlist entries.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? If yes, consider decomposition
- [ ] **People**: Does this need >2 people working on different parts? If yes, consider decomposition
- [ ] **Complexity**: Does this involve 3+ distinct concerns? If yes, consider decomposition
- [ ] **Risk**: Are there high-risk components that need isolation? If yes, consider decomposition
- [ ] **Independence**: Can parts be worked on separately? If yes, consider decomposition

**Conclusion**: No decomposition — no signal triggered (single function + doc + tests).

## Acceptance Criteria
- [ ] AC1: `scratch_parent` returns `/tmp/claude-<euid>/cwf-<slug>` for every `$TMPDIR`
      shape in FR1 (unset, standard, poisoned `/tmp/cwf-<slug>[/…]`, relative, `..`) —
      byte-identical, no doubling (FR1).
- [ ] AC2: Hook-context, Bash-context, and off-sandbox resolutions produce the same
      string (FR2).
- [ ] AC3: Given a resolved `$root`, `scratch_parent` performs no `$ENV{TMPDIR}` read and
      no filesystem access; the test seam redirects the base without any env var (FR6, NFR1).
- [ ] AC4: `scratch_dir` creates scratch under a Linux sandbox and off-sandbox; when the
      base is forced unwritable it fails closed with a static cause-naming hint (FR3);
      guard cases (bad_num, `cwf-<slug>` symlink_parent) unchanged **and** a symlink at the
      `/tmp/claude-<euid>` intermediate is rejected (FR4).
- [ ] AC5: `scratch_parent`/`scratch_dir` is the sole derivation; `best-practice-resolve`
      no longer inlines its own; `$SANDBOX_TMP_PROBE`/`$TMPDIR` branch removed; grep finds
      no other derivation (FR5, FR6).
- [ ] AC6: `tmp-paths.md` (derivation snippet, sandbox-alignment, worked/allowlist
      examples) matches the EUID-based code and records the macOS limitation (FR7).

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Every acceptance criterion met and test-covered: hook/writer path agreement (smoke test),
idempotency/invariance (TC-10, TC-TMPDIR-1/2/3), writability + symlink/`0700` guards
preserved and extended to the new intermediate (TC-7, TC-11).

## Lessons Learned
Requirements phrased as invariants (paths agree; output invariant to `$TMPDIR`) translated
directly into durable regression guards; behaviour-phrased fixtures did not (see e/j).

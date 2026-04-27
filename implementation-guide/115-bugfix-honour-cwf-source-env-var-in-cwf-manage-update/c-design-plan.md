# Honour CWF_SOURCE env var in cwf-manage update - Design
**Task**: 115 (bugfix)

## Task Reference
- **Task ID**: internal-115
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/115-honour-cwf-source-env-var-in-cwf-manage-update
- **Template Version**: 2.1

## Goal
Add a single resolution helper in `.cwf/scripts/cwf-manage` that returns the effective CWF source URL by preferring `$ENV{CWF_SOURCE}` over `cwf_source` in `.cwf/version`, and route `cmd_update` and `cmd_list_releases` through it.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Decision 1: Precedence — env > file, with defined-and-non-empty check on both
- **Decision**: When `$ENV{CWF_SOURCE}` is defined and non-empty, it overrides `cwf_source` from `.cwf/version`. When unset *or* empty, fall back to the file value. The file value itself is also subject to the defined-and-non-empty check (a `cwf_source=` line with empty value is treated the same as a missing line). If both are empty, die with a clear message.
- **Rationale**: Matches the convention `install.bash:24` already establishes (`${CWF_SOURCE:-<default>}`) — env wins. Users developing CwF locally need a one-shot way to point `update`/`list-releases` at `file:///` without editing the installed `.cwf/version`. The empty-string check avoids the `||` trap (Perl's `||` would also short-circuit on `0`, which isn't a concern here, but `defined && ne ''` is the pattern that says exactly what we mean).
- **Trade-offs**:
  - **+** Familiar shell convention; symmetric with install-time behaviour.
  - **−** Silent override could surprise users who forget the env var is exported in their shell. Mitigated by always logging the effective source and its origin (Decision 4).
- **Alternative considered**: file > env (env as fallback). Rejected — backwards from `install.bash`, defeats the "one-shot override" use case the bug report described.
- **Implementation idiom** (informational; full code lives in d-implementation-plan):
  ```perl
  my $env  = $ENV{CWF_SOURCE};
  my $file = $v->{cwf_source};
  return ($env,  'CWF_SOURCE env var')   if defined $env  && $env  ne '';
  return ($file, '.cwf/version')          if defined $file && $file ne '';
  die_msg("No CWF source: CWF_SOURCE unset and cwf_source missing/empty in .cwf/version");
  ```

### Decision 2: Transient override — do not persist
- **Decision**: An env-driven `update` does **not** rewrite `cwf_source` in `.cwf/version`. The file's `cwf_source` is preserved as the persisted source-of-record.
- **Rationale**: `CWF_SOURCE` is a session-scoped override, not a re-pin. Persisting would mean a one-shot `CWF_SOURCE=file:///… cwf-manage update` permanently switches the installation's source — surprising and hard to undo.
- **Trade-offs**:
  - **+** Predictable: env var affects this invocation only.
  - **+** Naturally safe with current code — `cmd_update` already reads `$v{cwf_source}` once and doesn't reassign it before `write_version_file` (`.cwf/scripts/cwf-manage:201, 232–236`). Decision 1 changes the *use* of the value, not its persistence.
  - **−** No way to "stick" a new source via `cwf-manage`; user must edit `.cwf/version` directly. Acceptable — re-pinning is rare and deliberate enough to warrant a manual edit.
- **Test consequence**: regression test asserts `cwf_source` field in `.cwf/version` is unchanged after an env-driven update.
- **Out-of-scope assumption (atomicity)**: This decision relies on `write_version_file` either completing fully or not opening the file at all. The current implementation truncates-then-writes (`'>'` mode), so a crash mid-write loses all metadata including `cwf_source`. Hardening the writer to atomic temp-file-plus-rename is **not in this task's scope** — file as a follow-up backlog item if it becomes a problem in practice. Recovery path today is `cwf-manage rollback <known-good-ref>`.

### Decision 3: Single resolution point — `resolve_source(\%v)` helper
- **Decision**: Extract a pure helper `sub resolve_source { my ($v) = @_; ...; return ($source, $origin); }` that returns a two-element list — the effective source string and a short human-readable origin label (`'CWF_SOURCE env var'` or `'.cwf/version'`) — or dies. Both `cmd_update` (line 201) and `cmd_list_releases` (line 124) call it instead of reading `$v{cwf_source}` directly.
- **Rationale**: One enforcement point eliminates drift between commands; the helper is pure (input: hashref + env; output: list), so it's directly unit-testable via the existing `do $SCRIPT` + `main::resolve_source(...)` pattern in `t/cwf-manage-list-releases.t`. Returning the origin label alongside the value keeps Decision 4's logging trivial — no separate origin-detection logic at the call sites.
- **Trade-offs**:
  - **+** Testable in isolation; no need to mock `git clone`.
  - **+** Future readers (e.g. a third call site) get the env-aware behaviour for free.
  - **−** Tiny indirection cost. Acceptable — the helper is 5–10 lines.

### Decision 4: Always log effective source with its origin (single line)
- **Decision**: `cmd_update` and `cmd_list_releases` log the effective source and its origin in a single line, on every invocation:
  - `[CWF] Cloning CWF source from <source> (from: CWF_SOURCE env var)...` (env override)
  - `[CWF] Cloning CWF source from <source> (from: .cwf/version)...` (default)
  - Equivalent shape for `cmd_list_releases`'s "Available releases from <source> (from: ...)".
- **Rationale**: Counters the "silent override" risk from Decision 1. One line, no branching at the call site (the origin string comes back from `resolve_source` per Decision 3), no asymmetric output between the env and non-env cases. The user sees exactly what URL is in play and why, every time.
- **Trade-offs**: Slightly chattier in the default (non-env) case than today. Negligible.
- **Alternative considered**: Two lines — a separate "override notice" line in the env case only. Rejected per design-review feedback: branching log flow, asymmetric output between modes.

### Decision 5: `cmd_status` keeps reading the file value
- **Decision**: `cmd_status` (line 116) continues to display `$v{cwf_source}` from `.cwf/version`, ignoring `$ENV{CWF_SOURCE}`.
- **Rationale**: `status` reports *installed state* — what's pinned on disk — not session-scoped behaviour. Mixing the two would make `status` output non-reproducible across shells.
- **Trade-offs**: A user who has `CWF_SOURCE` exported won't see it reflected in `status`. Acceptable — they can `echo $CWF_SOURCE` and the next `update` will log the override (Decision 4).

### Decision 6: Document in `cwf-manage` usage block
- **Decision**: Mirror `install.bash:10–15` in the `usage` sub of `.cwf/scripts/cwf-manage` — add a short "Environment" section listing `CWF_SOURCE` with the same one-line description.
- **Rationale**: Symmetric documentation; one paragraph, no separate doc file needed.

## System Design

### Component Overview
- **`resolve_source(\%v)`** *(new, pure helper)*: Returns `$ENV{CWF_SOURCE}` if non-empty; else `$v{cwf_source}` if present; else dies with `"No CWF source: set CWF_SOURCE or ensure cwf_source is in .cwf/version"`.
- **`cmd_update`** *(modified)*: Replaces direct `$v{cwf_source}` read at line 201 with a `resolve_source(\%v)` call. Adds the override-notice log when env was the source. Does **not** touch `cwf_source` in the version-file write block (lines 232–236) — preserving Decision 2.
- **`cmd_list_releases`** *(modified)*: Same change at line 124.
- **`cmd_status`** *(unchanged)*: Continues to read `$v{cwf_source}` directly.
- **`usage`** *(modified)*: Adds an Environment section documenting `CWF_SOURCE`.

### Data Flow

```
        $ENV{CWF_SOURCE}  ──┐
                            ├─→ resolve_source(\%v) ─→ $source ─→ git clone / ls-remote
read_version_file → %v ──→  ┘                                       (in cmd_update / cmd_list_releases)
```

`cmd_update` writes back to `.cwf/version` *without* touching `cwf_source` (Decision 2):

```
%v after read    ─→ update %v{cwf_version,cwf_ref,cwf_sha,cwf_installed}
                 ─→ write_version_file(%v)        # cwf_source carried through unchanged
```

## Interface Design

### `resolve_source(\%v)` — internal Perl sub

```
Input:  hashref %v as returned by read_version_file
Reads:  $ENV{CWF_SOURCE} (live read, no caching)
Output: list — ($source, $origin)
          $source: effective source URL string
          $origin: short label, one of 'CWF_SOURCE env var' or '.cwf/version'
Errors: die_msg("No CWF source: CWF_SOURCE unset and cwf_source missing/empty in .cwf/version")
        when both env var and file value fail the defined-and-non-empty check
```

**Edge cases the helper must handle correctly**:
- `CWF_SOURCE` unset → fall back to file
- `CWF_SOURCE=""` (explicitly empty) → fall back to file
- `cwf_source=` line in `.cwf/version` (empty value) → treat as missing
- Both unset/empty → die with the wording above

No public CLI surface change. No new flags. `cwf-manage update [ref]` and `cwf-manage list-releases` invocations are unchanged in shape; only the source-resolution behaviour changes.

### Documentation surface

Add to `usage` sub (one block, mirroring `install.bash:10–15`):

```
Environment:
  CWF_SOURCE   Override CWF source repo URL for this invocation
               (default: cwf_source from .cwf/version)
```

## Constraints
- Must not change `.cwf/version` schema or any field semantics.
- Must not introduce new dependencies (`cwf-manage` is `use strict; use warnings;` Perl with stdlib only — keep it that way).
- Must remain backwards-compatible: any existing invocation without `CWF_SOURCE` set behaves identically to today.
- Helper must be unit-testable via the existing `do $SCRIPT` + `main::sub_name` pattern in `t/cwf-manage-list-releases.t`.

## Decomposition Check
- [x] **Time**: <1 day. **No** decomposition.
- [x] **People**: Single contributor. **No** decomposition.
- [x] **Complexity**: One concern (env-var precedence). **No** decomposition.
- [x] **Risk**: Low — local script change, regression test covers it. **No** decomposition.
- [x] **Independence**: Tightly coupled phases. **No** decomposition.

**Conclusion**: Confirmed — single top-level task.

## Validation
- [x] Design review completed (plan-review subagents — 3× Explore subagents, findings synthesised)
- [x] Architecture decisions documented with rationale and trade-offs
- [x] Integration points (call sites for `resolve_source`) enumerated: `cmd_update:201`, `cmd_list_releases:124`

### Plan-review summary
Three parallel Explore subagents reviewed for Improvements / Misalignment / Robustness. Applied:
- Single-line logging with `(from: ...)` origin suffix (Improvements review)
- `defined && ne ''` check on both env var and file value (Robustness review)
- Terser error message wording matching existing `die_msg` style (Misalignment review)
- Explicit edge-case enumeration in the helper interface spec (Robustness review)

Out-of-scope (noted in Decision 2): `write_version_file` atomicity hardening — candidate for a separate backlog item, not blocking this fix.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 115
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

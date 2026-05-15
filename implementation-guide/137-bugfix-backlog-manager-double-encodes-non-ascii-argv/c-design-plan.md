# backlog-manager double-encodes non-ASCII @ARGV - Design
**Task**: 137 (bugfix)

## Task Reference
- **Task ID**: internal-137
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/137-backlog-manager-double-encodes-non-ascii-argv
- **Template Version**: 2.1

## Goal
Define the project-anchored fix for non-ASCII `@ARGV` decoding across Perl helpers.

## Empirical Ground Truth (Verified This Session)
Before proposing a design, the following claims were tested at the shell, not asserted:

1. **`-CDSL` does NOT decode `@ARGV`.** `D`=file I/O, `S`=STDIN/STDOUT/STDERR, `L`=locale-conditional. The `A` flag (and only `A`) decodes `@ARGV`.
2. **`PERL5OPT=-CA` (and `-CDSLA`) DOES decode `@ARGV`.** Counter to a fabricated claim earlier in the session, the env var does work. Verified: `PERL5OPT=-CDSL ./test '→'` → bytes `e2 86 92`, utf8_flag off. `PERL5OPT=-CDSLA ./test '→'` → codepoint `2192`, utf8_flag on.
3. **`Encode::decode_utf8 @ARGV` is NOT idempotent.** If `@ARGV` is already decoded (e.g. by `-CA`), calling `decode_utf8` again "Wide character" errors because it tries to re-interpret codepoints as bytes. **Implication**: shebang/env change AND explicit decode CANNOT be combined as belt-and-braces.
4. **The existing convention doc has a documentation bug.** `docs/conventions/perl-git-paths.md:10-11` claims `#!/usr/bin/perl -CDSL` decodes `@ARGV`. It does not. This doc bug is what propagated the missing `A` flag throughout the codebase.

## Affected Surface (Survey, This Session — Verified Counts)
- **33 Perl scripts** under `.cwf/scripts/`, split between two shebang patterns:
  - `#!/usr/bin/perl -CDSL` — **11 files**: `backlog-manager`, `context-inheritance-v2.0`, `context-inheritance-v2.1`, `cwf-apply-artefacts`, `security-review-changeset`, `status-aggregator-v2.0`, `status-aggregator-v2.1`, `template-copier-v2.0`, `template-copier-v2.1`, `cwf-manage`, `hooks/stop-uncommitted-changes-warning`.
  - `#!/usr/bin/env perl` — **22 files**: all under `.cwf/scripts/command-helpers/` (incl. `.d/` subcommand dispatchers — `context-manager.d/*`, `task-workflow.d/*`, `workflow-manager.d/*`), plus `hooks/stop-stale-status-detector` (grandfathered per convention doc) and `migrations/migrate-v2.1-file-order`. These rely entirely on `PERL5OPT` for `-C` flags.
- **Validator**: `CWF::Validate::PerlConventions` enforces `#!/usr/bin/perl -CDSL` for path-emitting-git scripts. Any shebang change must update this validator in lockstep.
- **`CWF::Common::check_perl5opt`**: warns if `PERL5OPT` lacks `-C`, recommends `-CDSL`.
- **`cwf-init` skill**: documents `-CDSL` as the recommended `PERL5OPT` value.
- **Convention doc**: `docs/conventions/perl-git-paths.md` — describes `-CDSL` for path handling.

## Key Decisions

### Decision 1: Fix shape — shebang flag, PERL5OPT, or explicit decode?
**Decision**: **Add `A` to the project shebang convention** (`-CDSL` → `-CDSLA`) AND update the `PERL5OPT` recommendation in `cwf-init` + `CWF::Common::check_perl5opt`. Do NOT add explicit `decode_utf8 @ARGV` to script preambles.

**Rationale**:
- **Shebang is project-anchored.** Files in the repo declare their own interpreter flags. A fresh checkout on a machine without `PERL5OPT=-CDSLA` still gets the fix — satisfies the "project-anchored, not per-user" success criterion from a-task-plan.md.
- **Updating the `PERL5OPT` recommendation is defense in depth.** It covers `#!/usr/bin/env perl` scripts (no flags in their shebang). New users running `/cwf-init` get the right value.
- **Explicit `decode_utf8 @ARGV` is rejected** on idempotency grounds (Empirical 3). A script with both the new shebang `-CDSLA` AND an explicit decode would error on every invocation. Picking one route is mandatory; the shebang route extends an existing convention and changes the smallest surface.
- **Single source of truth.** Today the convention is `-CDSL`. Tomorrow it is `-CDSLA`. Everywhere the project mentions one, it mentions the other.

**Trade-offs**:
- Pro: Project-anchored. New helpers inheriting the convention get correct behaviour for free. Validator can enforce.
- Pro: Minimal new code — flag change, not preamble additions.
- Con: The `#!/usr/bin/env perl` scripts still depend on `PERL5OPT` (since `env perl -CDSLA` is not portable across older `env` versions). The defense-in-depth `PERL5OPT` update is what makes this safe.
- Con: A user with stale `PERL5OPT=-CDSL` keeps working *for non-ASCII argv* on the `-CDSLA` shebang scripts, but regresses on `env perl` scripts. Mitigated by the `cwf-init` recommendation update and the `check_perl5opt` warning text update.

### Decision 2: Scope — which scripts get the shebang change?
**Decision**: **All 11 currently-`-CDSL` shebang scripts** get updated to `-CDSLA`. The 22 `#!/usr/bin/env perl` scripts are NOT changed (they would need a separate shebang shape; out of scope for this bugfix).

**Rationale**:
- The bug is generic to any Perl helper that consumes user strings from `@ARGV` and writes them to a file. We don't know which `env perl` scripts will ever be invoked with non-ASCII argv, but we don't need to — the `PERL5OPT=-CDSLA` recommendation covers them when set.
- Changing the existing-shebang scripts as a single batch keeps the diff legible and the validator's expected shebang single-valued.
- Switching `env perl` scripts to `/usr/bin/perl -CDSLA` would be a larger change that crosses convention boundaries — a candidate for a follow-up task, not this one.

**Trade-offs**:
- Pro: Smallest change that fixes the reported bug (`backlog-manager` is in the 12-script group) and any other `-CDSL` helper.
- Pro: Doesn't touch the `env perl` scripts' shebang debate (some are tests, some are hooks — they have their own reasons for `env perl`).
- Con: An `env perl` script that takes argv and writes to a file will regress for a user who removes `PERL5OPT=-CDSLA`. Mitigated by the `check_perl5opt` warning being prominent. Could be a follow-up backlog item if it ever bites in practice.

### Decision 3: Validator update
**Decision**: Update `CWF::Validate::PerlConventions` to require `-CDSLA` (not `-CDSL`) for path-emitting-git scripts. **Apply atomically with the 11 shebang changes** — validator update and script updates land in the same commit so `cwf-manage validate` never sees a half-migrated tree.

Update lines: `PerlConventions.pm:111` (the `ne` comparison string), `:114` (the violation's `expected` field), `:115` (the user-facing error message), plus the file-header documentation comment at `:13` (`PERL5OPT=-CDSL` → `-CDSLA`) and `:17-18` (the shebang rule description).

**Alternatives considered**:
- Dual-accept (`/^#!\/usr\/bin\/perl -CDSLA?$/`) with a transition window: more code, longer-lived ambiguity. Rejected because this is a small change that's safe to land atomically.
- Defer the validator update to a follow-up commit: rejected because it splits a single logical change across two commits with no benefit.

**Trade-offs**: None substantive — atomic batch is the right shape for a tree this size.

### Decision 4: Documentation update
**Decision**: Update `docs/conventions/perl-git-paths.md` to reflect `-CDSLA` and **correct the long-standing doc bug** that claimed `-CDSL` decodes `@ARGV`. Specifically rewrite the "Shebang" bullet (line 10–11) to:

> - **Shebang**: `#!/usr/bin/perl -CDSLA` — `D`=file I/O, `S`=STDIN/STDOUT/STDERR, `L`=locale-conditional, `A`=`@ARGV` decoded as UTF-8. Without `A`, scripts that take user strings via argv and write them to a file double-encode non-ASCII input (Task 137).

Also update line 45 ("`-CDSL` then makes Perl treat git's UTF-8 byte output…") to reference `-CDSLA`, and Enforcement § line 59 ("`#!/usr/bin/perl -CDSL` shebang") similarly.

**Rationale**: The doc bug is the upstream cause of the missing `A` flag in the codebase. Fixing it (and naming the Task 137 reference) prevents the same bug from recurring on new helpers that copy the convention.

### Decision 5: `cwf-init` and `check_perl5opt` updates
**Decision**: Update both the `cwf-init` SKILL.md recommendation block (line 149) and `CWF::Common::check_perl5opt`'s warning text (Common.pm:23) from `-CDSL` to `-CDSLA`. The warning condition (`$ENV{PERL5OPT} =~ /-C/`) is broad enough to accept either; no logic change.

**Rationale**: New installs get the right value. Existing installs keep working but see the (updated) warning text if their `PERL5OPT` is empty.

### Decision 6: Hashes refresh
**Decision**: Every modified script's SHA256 in `.cwf/security/script-hashes.json` is recomputed using `sha256sum` (per the "verifier/producer implementation diversity" feedback memory).

**Rationale**: Standard project convention. The integrity check is the gate, not paperwork.

## Component Overview
- **Shebang change** — 11 scripts under `.cwf/scripts/` (enumerated in Affected Surface). Mechanical: replace first line.
- **Validator** — `.cwf/lib/CWF/Validate/PerlConventions.pm`:
  - Code: lines 111–115 (the `ne` comparison string, the violation's `expected` field, the error message).
  - File header documentation comment: lines 13, 17–18.
- **Convention doc** — `docs/conventions/perl-git-paths.md`. Line 10–11 (Shebang bullet), line 45 (rationale paragraph), line 59 (Enforcement paragraph).
- **Init skill** — `.claude/skills/cwf-init/SKILL.md:149`. One string replacement.
- **Common warning** — `.cwf/lib/CWF/Common.pm:23`. One string replacement. Warning condition (line 20: `$ENV{PERL5OPT} =~ /-C/`) is broad enough to accept either old or new value; no logic change.
- **Hashes** — `.cwf/security/script-hashes.json`. Recompute (with `sha256sum`, per the verifier/producer diversity convention) for each modified script.

## Data Flow
Trivial — there is no new data flow. Existing path: `user shell → @ARGV → Perl script → file write`. The change is to ensure `@ARGV` is decoded before reaching the file write.

## Interface Design
No new interfaces. No API changes. No new helpers, modules, or skills.

## Failure Modes Considered
- **FM-1**: A script that intentionally treats `@ARGV` as raw bytes regresses. **Mitigation**: implementation phase audits each of the 11 affected scripts using this explicit checklist — grep for: (a) `unpack` applied to `@ARGV` elements or strings derived from them; (b) `:raw` mode `open` of `@ARGV`-derived paths; (c) `length` used to count bytes (not characters) on `@ARGV` data; (d) any explicit `Encode::decode_utf8` already at script top (would now error per Empirical 3). None known today (pre-design grep returned no hits); document the result for each script in `f-implementation-exec.md`.
- **FM-2**: A user has `PERL5OPT=-CDSL` (old recommendation) and runs an `env perl` script with non-ASCII argv. **Mitigation**: the `check_perl5opt` warning text updates to recommend `-CDSLA`; the user can fix locally. The bug they hit is no worse than today's behaviour.
- **FM-3**: A future helper adopts `#!/usr/bin/env perl` without setting up `PERL5OPT`. **Mitigation**: the validator covers shebang for path-emitting-git scripts; if the helper hits this rule it will be required to use `-CDSLA`. If it doesn't, the user's `PERL5OPT` (now recommended `-CDSLA`) carries it. No worse than today.
- **FM-4 (known limitation)**: macOS system Perl (5.18, shipped 2013–2015) may have older `-CA` semantics than modern Perl. The defense-in-depth (shebang + `PERL5OPT`) reduces but does not eliminate the risk for a macOS user on system Perl with no `PERL5OPT` set. Not mitigated in this task; documented so it can be addressed if it bites in practice.

## Decomposition Check
Single change, single concern. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
- Chosen design (shebang flag extension) held through implementation without revision. The "Too late for -CDSLA" interaction with stale `PERL5OPT=-CDSL` surfaced during exec, but the resolution (coordinate PERL5OPT update with shebang change) preserved the design's intent rather than forcing a redesign.
- Convention-drift discovery (Tasks 27 → 113 → 115 → 124) was made during implementation, not design. Surfaced and tracked via the Very-High "Re-align Perl-Script Convention" backlog item.

## Lessons Learned
- The design's "shebang vs explicit decode vs PERL5OPT update vs combination" decision space was sound, but it under-weighted the *coordination* cost between shebang and PERL5OPT. Empirically: the two `-C` flag sets must match exactly, or perl rejects with `Too late for -C…`. Future design passes touching `-C` flags should call this constraint out explicitly.
- Choosing the smallest local fix (one flag, eleven scripts) over the systemic fix (return to Task-27's `#!/usr/bin/env perl` + PERL5OPT-only convention) was the right call for a single-session bugfix. The systemic fix gets its own deliberate task.

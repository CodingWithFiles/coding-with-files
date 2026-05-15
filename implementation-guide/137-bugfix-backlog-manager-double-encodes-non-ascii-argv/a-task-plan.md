# backlog-manager double-encodes non-ASCII @ARGV - Plan
**Task**: 137 (bugfix)

## Task Reference
- **Task ID**: internal-137
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/137-backlog-manager-double-encodes-non-ascii-argv
- **Baseline Commit**: e8d1b8f487f2a3c44df2736111c870928324da47
- **Template Version**: 2.1

## Goal
Ensure Perl helpers that consume user strings via `@ARGV` decode them as UTF-8 before writing to file, so non-ASCII metadata (`→`, `§`, `—`, etc.) round-trips correctly instead of being double-encoded into mojibake.

## Bug Report (User-Supplied, Verbatim Diagnosis)
- **Symptom**: `backlog-manager add --identified-in='... → ...'` writes mojibake into `BACKLOG.md`. `→` (U+2192, 3 UTF-8 bytes `E2 86 92`) ends up as 6 bytes `C3 A2 C2 86 C2 92`. Same for `§` (→ `Â§`), `—` (→ `â`-something).
- **Mechanism**: textbook UTF-8 double-encode. `@ARGV` arrives as raw bytes; Perl treats each byte as a Latin-1 codepoint; the write layer encodes those codepoints to UTF-8.
- **Why `normalise` is unaffected**: it reads file bytes and writes them back without re-encoding; only `add` (and other argv-consuming subcommands) takes user strings from argv and writes them to a file, so only argv-consumers exhibit the bug.
- **Pre-existing context**: `~/.claude/settings.json` sets `PERL5OPT=-CDSL` globally. `-CDSL` covers STDIN/STDOUT/STDERR + file I/O + locale lookup. It does **not** include `A` (the flag that decodes `@ARGV`). Empirically verified this turn: `PERL5OPT=-CDSL <script> 'é→'` → raw bytes; `PERL5OPT=-CDSLA <script> 'é→'` → decoded.

## Scope (Bug-Phase Substitute for Requirements)
The bug affects every Perl helper that takes user strings via `@ARGV` and writes them to a file. Survey (this turn) shows ~22 Perl scripts under `.cwf/scripts/`, split between `#!/usr/bin/env perl` (relies entirely on PERL5OPT) and `#!/usr/bin/perl -CDSL` (hardcoded `-CDSL` plus inherits PERL5OPT). Neither group currently decodes `@ARGV`.

The fix surface includes:
- The `-C` flag wherever the project recommends it (shebang convention doc, `cwf-init` skill's PERL5OPT recommendation).
- Possibly per-script shebangs (defense in depth — invocations bypassing Claude Code env).
- Possibly an explicit `Encode::decode_utf8 @ARGV` at script top (most portable; doesn't depend on shebang flags or env).

Design phase decides which combination of these is the right scope.

## Success Criteria
- [ ] Running `backlog-manager add --identified-in='X → Y'` (and any argv-based subcommand) writes the literal `→` to BACKLOG.md; round-trips through `normalise` unchanged.
- [ ] The same property holds for any other in-tree Perl helper that takes user strings via argv (`task-workflow create --description=...`, `cwf-checkpoint-commit "<why>"`, etc.).
- [ ] The fix is anchored in the *project*, not in per-user settings — a fresh checkout on a machine without `PERL5OPT=-CDSLA` does not regress.
- [ ] A regression test demonstrates the property (input contains `→`, output file contains `→`, not mojibake) and would fail against `e8d1b8f` (the current `main`).
- [ ] `cwf-manage validate` still passes; `prove -r t/` still green.

## Original Estimate
**Effort**: 0.5–1 day (single-concern bug, the design choice between "shebang", "explicit decode", "PERL5OPT update", or some combination is the actual work).
**Complexity**: Low (technically) / Medium (scope: how many helpers do we touch?).
**Dependencies**: None — no external coordination.

## Major Milestones
1. **Design**: Decide the fix shape — shebang flag change vs explicit `decode_utf8 @ARGV` vs PERL5OPT recommendation update vs combination. Includes deciding scope: backlog-manager only, all argv-consuming helpers, or all Perl helpers in `.cwf/`.
2. **Implementation**: Apply the chosen fix; refresh `script-hashes.json` for any modified scripts.
3. **Test**: Regression test (argv contains `→`, output file contains `→`); existing `prove -r t/` green; `cwf-manage validate` clean.

## Risk Assessment
### High Priority Risks
- **Risk 1**: Fix only the argv-consuming helpers we know about today, miss a future helper that takes argv strings and writes them.
  - **Mitigation**: Prefer a project-wide convention (shebang or PERL5OPT or both) over per-script patches. Codify the convention in `docs/conventions/perl-git-paths.md` so new helpers inherit it. Consider a lint/test that flags Perl scripts under `.cwf/` that lack the convention.
- **Risk 2**: PERL5OPT change recommended by `cwf-init` is per-user; existing users won't get the fix until they re-run `cwf-init` or edit their settings manually.
  - **Mitigation**: Defense in depth — pair the PERL5OPT recommendation update with a project-anchored fix (shebang or explicit decode) so existing checkouts work even without the user updating their settings.

### Medium Priority Risks
- **Risk 3**: `Encode::decode_utf8 @ARGV` at script top is idempotent if the string is already decoded (it sees the utf8 flag), but if a script is invoked with both `PERL5OPT=-CDSLA` *and* explicit decode at the top, the second decode would interpret already-decoded characters as bytes again — yet another double-encode in the opposite direction.
  - **Mitigation**: Pick one route (shebang/PERL5OPT OR explicit decode); do not do both. Decide in design.
- **Risk 4**: Adding `A` to `-CDSL` everywhere has surface-area effects on scripts that *want* raw `@ARGV` bytes (e.g., one that passes argv-supplied paths to `open`).
  - **Mitigation**: Audit argv usage in each affected helper during design; flag any that depend on raw bytes. None known today, but worth checking.

## Dependencies
- Pre-existing convention doc `docs/conventions/perl-git-paths.md` — will likely need updating.
- `.claude/skills/cwf-init/SKILL.md:149` — currently recommends `PERL5OPT=-CDSL`; may need updating.
- `.cwf/security/script-hashes.json` — every modified script needs a hash refresh.

## Constraints
- POSIX-only project; core-Perl-only constraint applies (`Encode` is a core module — OK).
- Must work without depending on the user's global `~/.claude/settings.json` (project must be self-contained).
- Must not regress any other argv-using behaviour in existing helpers.
- Must not bypass the integrity-check workflow (no `cwf-manage recompute-hashes`-style auto-reconciliation).

## Decomposition Check
- [x] **Time**: Will this take >1 week? No — 0.5–1 day.
- [x] **People**: Does this need >2 people working on different parts? No.
- [x] **Complexity**: Does this involve 3+ distinct concerns? No — single concern (UTF-8 argv decoding). Scope question is "how many files" not "how many concerns".
- [x] **Risk**: Are there high-risk components that need isolation? No — fix is local to script preamble.
- [x] **Independence**: Can parts be worked on separately? No.

No decomposition warranted.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
- Goal achieved: `backlog-manager add` round-trips non-ASCII argv as clean UTF-8.
- Fix shape (post-design): change shebang `-CDSL` → `-CDSLA` on the 11 hardcoded-shebang scripts; pair with PERL5OPT user-side update.
- Final scope shrank during execution from the originally-planned wider convention/doc refresh to *only* the 11 production shebangs, the validator literal, and 7 test fixtures. See `f-implementation-exec.md` § "Scope (minimal, post-discovery)".
- Effort matched the optimistic end of the 0.5–1 day estimate: 1 session.

## Lessons Learned
- The Decomposition Check correctly returned "no decomposition warranted" — the work was a single concern (UTF-8 argv decoding). Decomposition-by-scope was instead handled mid-task by *deferring* orthogonal structural defects as new backlog items rather than expanding this task.
- The Bug Report's "Mechanism" diagnosis (`@ARGV` arrives as raw bytes → Perl treats as Latin-1 → write layer re-encodes) was correct and required no revision through implementation. Verbatim user diagnosis paid off here.

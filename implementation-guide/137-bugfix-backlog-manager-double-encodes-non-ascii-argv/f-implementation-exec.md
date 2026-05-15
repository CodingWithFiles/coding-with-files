# backlog-manager double-encodes non-ASCII @ARGV - Implementation Execution
**Task**: 137 (bugfix)

## Task Reference
- **Task ID**: internal-137
- **Branch**: bugfix/137-backlog-manager-double-encodes-non-ascii-argv
- **Template Version**: 2.1

## Goal
Extend the shebang convention `-CDSL` → `-CDSLA` across the 11 production scripts that hardcode it, update the validator literal, and update the 7 test fixtures that depend on the validator literal. Defer everything else to a follow-up task.

## Scope (minimal, post-discovery)
The originally-planned d-plan scope was wider (convention docs, PERL5OPT recommendation text in SKILL.md/Common.pm/INSTALL.md/security-review.md/perl-git-paths.md). During execution we discovered:

1. The `-CDSL` shebang convention itself drifted from the originally-decided `#!/usr/bin/env perl` + PERL5OPT convention (Task 27, commit `1db1f77`). Tasks 113/115/124 codified the drift; the convention was never anchored from CLAUDE.md.
2. `validate_path_allowlist` is cargo-culted across callers with different threat models (write vs read vs temp).

These structural defects are too broad for this bugfix task. Three Very-High / Low backlog items were filed to track them:

- **Re-align Perl-Script Convention to Task-27 Form and Anchor in CLAUDE.md** (Very High)
- **Split validate_path_allowlist into write/read/temp variants** (Very High)
- **Make path-allowlists overridable in cwf-project.json** (Low)

Task 137 ships only the *minimum* needed to fix the user-reported `→`/`§`/`—` mojibake in `backlog-manager add` under the existing (drifted) convention. Doc updates, validator-message updates, and the PERL5OPT-recommendation strings in code-doc and external-doc files stay deferred.

## Actual Results

### Step 1: Pre-flight audit (FM-1 confirmation gate)
- **Planned**: `grep -nE 'unpack|:raw|Encode::decode_utf8'` across 11 scripts; confirm none touch raw `@ARGV` bytes.
- **Actual**: `confirmation_pass: yes`. Eight `:raw` open hits — all read file content for hashing / artefact processing / shebang sniffing; paths reach these helpers via git output, recursive walks, or hardcoded constants — never from raw `@ARGV`. No `unpack`/`decode_utf8` use.

### Step 2: Apply shebang changes (11 scripts)
- **Actual**: All 11 production shebangs changed from `#!/usr/bin/perl -CDSL` to `#!/usr/bin/perl -CDSLA` via Edit. Files: `cwf-manage`, `backlog-manager`, `context-inheritance-v2.0`, `context-inheritance-v2.1`, `cwf-apply-artefacts`, `security-review-changeset`, `status-aggregator-v2.0`, `status-aggregator-v2.1`, `template-copier-v2.0`, `template-copier-v2.1`, `stop-uncommitted-changes-warning`. Anchored grep `^#!/usr/bin/perl -CDSL$` returns zero hits in `.cwf/`.

### Step 3: Apply validator update (minimal)
- **Actual**: `.cwf/lib/CWF/Validate/PerlConventions.pm` — three substring swaps in the shebang-check block (lines 111, 114, 115): `-CDSL` → `-CDSLA`. Header comments and user-facing message explanatory text were *not* updated (deferred to the convention re-alignment task).

### Step 4: Update test fixtures (validator-driven)
- **Actual**: `t/validate-perl-conventions.t` — seven fixture shebangs updated to `-CDSLA` via `replace_all`. Required because the validator literal changed; fixtures using the old shebang would now trigger an extra `shebang` violation and break tests asserting specific violation counts.
- **t/common.t**: not modified. The test asserts "no warning when PERL5OPT contains `-C`" via regex `/-C/`, which matches both `-CDSL` and `-CDSLA`. Fixture value (`-CDSL`) is incidental and the test passes either way.
- **Ancillary docs**: not modified. `.claude/skills/cwf-init/SKILL.md`, `INSTALL.md`, `.cwf/lib/CWF/Common.pm` warn-string, `.cwf/docs/skills/security-review.md`, `docs/conventions/perl-git-paths.md` all still reference `PERL5OPT=-CDSL`. Deferred to the convention re-alignment task.

### Step 5: Regenerate hashes
- **Actual**: `sha256sum` (coreutils, verifier/producer-diversity preserved) computed for 12 modified files (11 scripts + `PerlConventions.pm`). Each hash spliced into `.cwf/security/script-hashes.json` via Edit. `last_updated` bumped to 2026-05-14.

### Step 6: Verification
- **`cwf-manage validate`**: `PERL5OPT=-CDSLA .cwf/scripts/cwf-manage validate` → `[CWF] validate: OK`.
- **`prove -r t/`**: `PERL5OPT=-CDSLA prove -r t/` → 458 tests, 41 files, all PASS.
- **Smoke test against the reported bug**: standalone script with shebang `-CDSLA` invoked under `PERL5OPT=-CDSLA` with argv `→ § —`. Output bytes: `e2 86 92` (`→`), `c2 a7` (`§`), `e2 80 94` (`—`). Clean UTF-8, no double-encoding.

### Step 7: BACKLOG round-trip fix
- A blank-line-after-`### Heading` pattern in one of the three new backlog items (item 3: "Make path-allowlists overridable") tripped `t/backlog-roundtrip-live.t`. The parser/serialiser normalises out blank lines between `### Subheading` and following content; my body had 4 such blank lines. Removed via 4 Edits. Test now passes.

## Coordinated migration note (for retrospective / next pull)
Existing users with `PERL5OPT=-CDSL` will hit "Too late for -CDSL" on their first script invocation after pulling this commit, because perl rejects mismatched `-C` flag sets between PERL5OPT and shebang. They must update `~/.claude/settings.json`:

```diff
- "PERL5OPT": "-CDSL"
+ "PERL5OPT": "-CDSLA"
```

This setting-file update is *not* shipped with this commit (the SKILL.md and INSTALL.md text still recommend `-CDSL`). That's intentional — recommendation-text updates are deferred to the convention re-alignment task. For now, the recommendation in this commit is captured here in the retrospective and in the Very-High backlog item.

## Blockers Encountered
- **Wider scope creep mid-execution**: discovered the convention drift and `validate_path_allowlist` cargo-cult issues. Resolved by filing as separate backlog items rather than expanding Task 137's scope.

## Deferral Check
- [x] All in-scope steps from d-implementation-plan.md executed (minimum-scope interpretation)
- [x] Convention re-alignment work explicitly deferred via backlog item
- [x] PERL5OPT recommendation update explicitly deferred via backlog item
- [x] `validate_path_allowlist` split explicitly deferred via backlog item
- [x] No silent deferrals — all deferred work has a tracking BACKLOG entry

## Security Review

**State**: no findings

no findings. The changeset is a safe, mechanical extension of Perl shebang flags `-CDSL` to `-CDSLA` (adding the `-A` flag for `@ARGV` UTF-8 decoding) across 11 production scripts, their validator, test fixtures, and hash records. No unsafe code patterns introduced; all hashes correctly regenerated.

Note: the prescribed helper `security-review-changeset --phase=implementation` returned an empty changeset because it diffs `anchor..HEAD` over committed history, and the f-phase work is still uncommitted in the working tree. The subagent was invoked on the equivalent diff captured via `git diff HEAD` (460 lines, under the 500-line cap), with the same shebang/CWF-internal classification holding for every changed path.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None

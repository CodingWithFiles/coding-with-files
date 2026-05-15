# re-align Perl-script conventions to Task-27 form - Implementation Plan
**Task**: 139 (bugfix)

## Task Reference
- **Task ID**: internal-139
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/139-re-align-perl-script-conventions-to-task-27-form
- **Template Version**: 2.1

## Goal
Sequence the four design-phase milestones into concrete file edits with a validate-first gate between shebang revert and hash regen.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Milestone 1: Doc split + CLAUDE.md anchor
- `docs/conventions/perl.md` — **new**. Universal Perl rules. Leads with `#!/usr/bin/env perl` + `PERL5OPT=-CDSLA` + `use utf8;`. Cites Task 137 for the `A` flag rationale. "See also" line to `git-path-output.md`. Structure: `## Convention` / `## Why` / `## Enforcement`.
- `docs/conventions/git-path-output.md` — **new**. Git-specific rules: `-z` flag, `split /\0/`, NUL-handling. Opens with "Prerequisite reading: `perl.md`". Structure: same three sections.
- `docs/conventions/perl-git-paths.md` — **deleted** via `git rm`.
- `CLAUDE.md` — add two bullets under `## Conventions` after line 62, before line 64. Parallel bullets (not nested) following the existing pattern:

  ```
  **Perl Conventions**: Universal rules for Perl files under `.cwf/`. See `docs/conventions/perl.md` for:
  - Shebang: `#!/usr/bin/env perl`
  - `PERL5OPT=-CDSLA` for UTF-8 I/O and `@ARGV` decoding
  - `use utf8;` source pragma (unconditional)

  **Git Path Handling**: NUL-separated path output from `git`. See `docs/conventions/git-path-output.md` for:
  - `-z` flag on path-emitting git subcommands
  - `split /\0/` parsing
  ```

  Static literal text; no template substitution. Exact wording can be tightened during implementation as long as the structure matches.

### Milestone 2: Validator amendment + test fixture polarity

**Validator change** (`.cwf/lib/CWF/Validate/PerlConventions.pm`):

Replace the existing capture-only shebang check at lines 111-117 with a **universal positive-form shebang check** placed after `return unless $is_script;` (after line 98), before the `@captures` loop:

```perl
# Shebang: must be the canonical env-perl form. Hardcoded -C flags fail
# in two ways — kernel shebang-argv parsing variance, and "too late for
# -CDSLA" when PERL5OPT already supplies -C flags (Task 137).
if ($first_line !~ m{\A\#!/usr/bin/env perl\s*\z}) {
    push @$violations, _violation(
        $rel, 'shebang',
        $first_line, '#!/usr/bin/env perl',
        "Change shebang to '#!/usr/bin/env perl' in $rel — kernel-line -C flags are unportable across kernels and conflict with PERL5OPT. Set PERL5OPT=-CDSLA in your environment for UTF-8 I/O (see docs/conventions/perl.md).",
    );
}
```

Rationale for the positive-form choice (resolving plan-review ambiguity):
- One rule, asserts the required form. No regex-edge-case worry about `-C` variants, multiple flags, or whitespace.
- Runs on **all** scripts in scan roots (not only git-capturing ones) — closes the gap that allowed Tasks 113/115/124 to silently drift.
- Grandfathered files still bypass this check via the existing `return if $allow->{$rel};` at line 97 — but their shebangs are already `env perl`, so removing them from the grandfather list for *shebang* is a follow-up audit (see Step 3 substep below).

Update existing `git_z` error message at line 107 to cite `docs/conventions/git-path-output.md` instead of `docs/conventions/perl-git-paths.md`.

Update file-header pod comment block (currently lines 1-28) line-by-line:
- Line 6: replace `docs/conventions/perl-git-paths.md` with two-line "Universal Perl rules: `docs/conventions/perl.md` / Git path-handling: `docs/conventions/git-path-output.md`".
- Lines 13-19: rewrite the rule descriptions to reflect the new positive-form check. Replace mention of `-CDSL` with `-CDSLA` and clarify that the I/O flags live in `PERL5OPT`, not in the shebang. Remove the parenthetical "PERL5OPT=-CDSL" on line 13.
- Lines 17-18 (old shebang rule description): rewrite to "Shebang: every Perl script in scan roots declares `#!/usr/bin/env perl`. Hardcoded `-C` flags on the kernel line are rejected."

**Test fixture changes** (`t/validate-perl-conventions.t`):

Touched subtests (10 existing + 2 new = 12 total):

| Subtest | Current fixture shebang | New fixture shebang | Assertion change |
|---|---|---|---|
| TC-U3 (line 84) | `#!/usr/bin/perl -CDSLA` | `#!/usr/bin/env perl` | unchanged: expect 1 violation (`git_z`) |
| TC-U4 (line 99) | `#!/usr/bin/perl -CDSLA` | `#!/usr/bin/env perl` | unchanged: zero violations |
| TC-U4b (line 113) | `#!/usr/bin/perl -CDSLA` | `#!/usr/bin/env perl` | unchanged: zero violations |
| TC-U4c (line 128) | `#!/usr/bin/perl -CDSLA` | `#!/usr/bin/env perl` | unchanged: zero violations |
| TC-U4d (line 143) | `#!/usr/bin/perl -CDSLA` | `#!/usr/bin/env perl` | unchanged: expect 1 violation (`git_z`) |
| TC-U5 (line 159) | `#!/usr/bin/perl -CDSLA` | `#!/usr/bin/env perl` | unchanged: zero violations (POD-only match) |
| TC-U6 (line 180) | `#!/usr/bin/perl -CDSLA` | `#!/usr/bin/env perl` | unchanged: zero violations |
| TC-U3b (line 214) | `#!/usr/bin/env perl` (unchanged) | (unchanged) | **invert**: rename description to "env shebang passes shebang assertion; missing `-z` is the only violation". Expect 1 violation (`git_z`). |
| TC-U3c (line 198) | `#!/usr/bin/perl -CDSL` | `#!/usr/bin/perl -CDSLA` (covers the post-Task-137 form) | **rewrite**: assert 1 violation (`shebang`), `expected = '#!/usr/bin/env perl'`. Description: "hardcoded `-C` shebang rejected regardless of trailing flags". |
| TC-U7 (line 234) | `#!/usr/bin/env perl` (unchanged) | (unchanged) | unchanged: still tests grandfathering of `-z` exemption. Update description if it implies shebang is also exempted — under the new rule, `env perl` passes the shebang check, so the grandfather flag is only `-z`-relevant. |
| **TC-U9 (new)** | `#!/usr/bin/env perl` + git capture with `-z` + `use utf8;` | — | positive case: zero violations. |
| **TC-U10 (new)** | `#!/usr/bin/perl -CDSLA` + git capture with `-z` + `use utf8;` | — | negative case: expect 1 violation (`shebang`) even though `-z` is present. |

### Milestone 3: Shebang reverts (mechanical)
Edit line 1 of each from `#!/usr/bin/perl -CDSLA` to `#!/usr/bin/env perl`:
- `.cwf/scripts/cwf-manage`
- `.cwf/scripts/command-helpers/backlog-manager`
- `.cwf/scripts/command-helpers/cwf-apply-artefacts`
- `.cwf/scripts/command-helpers/security-review-changeset`
- `.cwf/scripts/command-helpers/context-inheritance-v2.0`
- `.cwf/scripts/command-helpers/context-inheritance-v2.1`
- `.cwf/scripts/command-helpers/template-copier-v2.0`
- `.cwf/scripts/command-helpers/template-copier-v2.1`
- `.cwf/scripts/command-helpers/status-aggregator-v2.0`
- `.cwf/scripts/command-helpers/status-aggregator-v2.1`
- `.cwf/scripts/hooks/stop-uncommitted-changes-warning`

### Milestone 4: Hash regen + inbound-reference audit
- `.cwf/security/script-hashes.json` — splice 12 new SHA256 values (11 scripts above + `CWF::Validate::PerlConventions.pm`); bump `last_updated` to today.
- `INSTALL.md` — line 259 + line 311: `-CDSL` → `-CDSLA`. Update line 264's reasoning sentence to mention `@ARGV` decoding briefly (cite Task 137).
- `.cwf/docs/skills/security-review.md` — replace `perl-git-paths.md` reference with whichever new doc fits (likely `git-path-output.md` for the `-z` context).
- `docs/conventions/design-alignment.md` — update any reference to the deleted filename.
- `BACKLOG.md` — active entries only; update any references.
- `.cwf/templates/` — if any template file references `perl-git-paths.md`, update.
- `.cwf/docs/` (recursive) — same.

## Implementation Steps

### Step 1: Setup
- [ ] Confirm on branch `bugfix/139-…`, working tree clean.
- [ ] Re-read `c-design-plan.md` decisions 1–6.

### Step 2: Milestone 1 — Doc split + CLAUDE.md anchor
- [ ] Write `docs/conventions/perl.md`. Order content: Convention block first (3 rules: shebang, PERL5OPT, use utf8;), then Why (cite Task 137 for `A` flag), then Enforcement (point at `CWF::Validate::PerlConventions`).
- [ ] Write `docs/conventions/git-path-output.md`. Order content: Prerequisite-reading line; Convention (`-z`, `split /\0/`); Why (verbatim path output, default-quoting weaknesses); Enforcement.
- [ ] `git rm docs/conventions/perl-git-paths.md`.
- [ ] Edit `CLAUDE.md` to insert two bullets in `## Conventions` after the design-alignment block (line 62) — perl.md first, then git-path-output.md. Static literal text; no template substitution.
- [ ] Verify by reading both new docs end-to-end for consistency.

### Step 3: Milestone 2 — Validator amendment + test fixtures
- [ ] Edit `CWF::Validate::PerlConventions.pm`: replace the lines 111-117 shebang check with the positive-form check specified above; update `git_z` error message at line 107 to cite `git-path-output.md`; update file-header pod block per the line-by-line list above.
- [ ] Audit grandfather list: run the rewritten validator against the unchanged tree (before shebang reverts). Expect: `stop-stale-status-detector` still passes the shebang rule (its shebang is already `env perl`) but would otherwise fail `-z`. Confirm `@GRANDFATHERED` still needs the entry for `-z` exemption only. Record finding in `f-implementation-exec.md`.
- [ ] Edit `t/validate-perl-conventions.t` per the fixture map table above (10 subtests touched; 2 new subtests added).
- [ ] Run `prove -v t/validate-perl-conventions.t` from repo root. Expect all subtests pass.
- [ ] Run `prove t/` to verify no other test regressions.

### Step 4: Milestone 3 — Shebang reverts (validate-first gate)
- [ ] Apply line-1 edit to each of the 11 files listed above.
- [ ] Run `.cwf/scripts/cwf-manage validate`. **Expect**: SHA mismatch errors on exactly 11 scripts + `PerlConventions.pm` (12 entries total). **No other violations.** If any other violation appears, stop and investigate.
- [ ] If the gate passes, proceed. If not, abort and re-examine.

### Step 5: Milestone 4a — Hash regeneration
- [ ] Confirm the modified set: 11 scripts from Milestone 3 (line-1 shebang reverts) + 1 module from Milestone 2 (`CWF::Validate::PerlConventions.pm`) = 12 total entries to update.
- [ ] For each of the 12 modified files, compute the new SHA256 using `sha256sum <path>` (coreutils — verifier/producer diversity per `[[feedback_complexity_over_continuity]]`). Write all 12 (path, sha256) pairs to `/tmp/task-139/new-hashes.txt` for review.
- [ ] Pre-splice review: open `.cwf/security/script-hashes.json` and `/tmp/task-139/new-hashes.txt` side-by-side. Verify each of the 12 paths exists in the JSON as an *existing* entry (replacement, not insertion). If any path appears as a new key, stop and investigate — the script-hashes registry should not gain entries from this task.
- [ ] Splice each new hash into `.cwf/security/script-hashes.json` via Edit. Bump `last_updated` to today's date.
- [ ] Run `.cwf/scripts/cwf-manage validate`. Must return `OK` with zero violations.

### Step 6: Milestone 4b — Inbound-reference audit
**Prerequisite**: Milestones 1–3 + Step 5 complete (new docs exist; validator updated; shebangs reverted; hashes regenerated; `cwf-manage validate` OK).
- [ ] Start with the highest-leverage surface: edit `INSTALL.md` lines 259 + 311 to `-CDSLA`; update line 264's explanation to briefly mention `@ARGV` decoding (cite Task 137).
- [ ] Edit `.cwf/docs/skills/security-review.md` to cite the appropriate new doc.
- [ ] Edit `docs/conventions/design-alignment.md` to update any reference to `perl-git-paths.md`.
- [ ] Edit active entries in `BACKLOG.md` that reference the old filename (skip `### Retired Backlog Items`).
- [ ] Recursive grep `.cwf/templates/` and `.cwf/docs/`; update any other live references.
- [ ] Final repo-wide grep: `git grep -n perl-git-paths` and `git grep -n -- '-CDSL\b'`. Outside `implementation-guide/` and retired-items sections, both must report zero hits.

### Step 7: Final validation
- [ ] `prove t/` — full test suite passes.
- [ ] `.cwf/scripts/cwf-manage validate` — OK.
- [ ] Smoke test: run `backlog-manager list` to confirm the helper still works under `PERL5OPT=-CDSLA` + env perl.
- [ ] Smoke test: run `backlog-manager add --title='Test → arrow' --task-type=chore --priority=Low --body='smoke'` then immediately `delete --exact-title='Test → arrow' --confirm` to verify the Task-137 mojibake fix still holds under the reverted shebang.

## Test Coverage
**See e-testing-plan.md for complete test plan**

Quick reference:
- `t/validate-perl-conventions.t` — fixture polarity flip + 2 new subtests.
- `t/common.t` — verify no shebang assertion changes needed (if `PERL5OPT` warning fixture exists, leave it; the warning is from `CWF::Common::check_perl5opt`, orthogonal to this task).
- Smoke tests above for end-to-end behaviour.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*

# re-align Perl-script conventions to Task-27 form - Implementation Execution
**Task**: 139 (bugfix)

## Task Reference
- **Task ID**: internal-139
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/139-re-align-perl-script-conventions-to-task-27-form
- **Template Version**: 2.1

## Goal
Execute the four-milestone plan from `d-implementation-plan.md` and record what actually happened.

## Actual Results

### Step 1: Setup
- **Planned**: confirm branch + clean tree, re-read design.
- **Actual**: on `bugfix/139-…`, working tree clean (three untracked wf files only — `f`, `g`, `j`). Design re-read; no scope changes.

### Step 2: Milestone 1 — Doc split + CLAUDE.md anchor
- **Planned**: write `perl.md` and `git-path-output.md`; `git rm perl-git-paths.md`; add two bullets to CLAUDE.md `## Conventions`.
- **Actual**:
  - Wrote `docs/conventions/perl.md` (universal: shebang, PERL5OPT=-CDSLA, use utf8;). Leads with the `-CDSLA` recommendation and cites Task 137 for the `A` flag rationale.
  - Wrote `docs/conventions/git-path-output.md` (niche: `-z`, `split /\0/`, NUL-handling). Opens with prerequisite-reading reference to `perl.md`.
  - `git rm docs/conventions/perl-git-paths.md`.
  - Added two CLAUDE.md bullets — "Perl Conventions" and "Git Path Handling" — parallel to the existing commit-messages / design-alignment bullets, static literal text.
- **Deviations**: None.

### Step 3: Milestone 2 — Validator amendment + test fixtures
- **Planned**: amend `PerlConventions.pm` with positive-form shebang check after `return unless $is_script;`; update pod block; flip 10 test fixtures + add TC-U9/U10.
- **Actual**:
  - Replaced the capture-conditional shebang block (lines 111–117) with a universal positive-form check: `$first_line !~ m{\A\#!/usr/bin/env perl\s*\z}`. Placed after `return unless $is_script;` so it runs on all Perl scripts, before the grandfather skip. Grandfathered files still must satisfy the shebang rule; only `-z` is exempted.
  - Updated `git_z` error message citation: `perl-git-paths.md` → `git-path-output.md`.
  - Rewrote the file-header pod block to reference both new docs.
  - **Grandfather audit**: ran the rewritten validator (against the modified `PerlConventions.pm` and unchanged shebangs). The grandfathered file `.cwf/scripts/hooks/stop-stale-status-detector` already had `#!/usr/bin/env perl`, so it passes the new shebang rule. Grandfathering is still required for the `-z` exemption only.
  - Flipped 10 existing subtests and added TC-U9 (positive: env + -z + utf8 passes) and TC-U10 (negative: hardcoded -CDSLA rejected even with -z). All 17 subtests pass.
  - `prove t/validate-perl-conventions.t` → `Result: PASS`.
- **Deviations**: None.

### Step 4: Milestone 3 — Shebang reverts (validate-first gate)
- **Planned**: revert 11 shebangs from `#!/usr/bin/perl -CDSLA` to `#!/usr/bin/env perl`; run `cwf-manage validate`; expect exactly 12 SHA mismatches.
- **Actual**:
  - Reverted all 11 shebangs by single-line Edit on each file. Grep confirms zero `^#!/usr/bin/perl` hits remain under `.cwf/scripts/` and `.cwf/lib/`; 33 `env perl` shebangs total (was 22 env + 11 hardcoded).
  - `.cwf/scripts/cwf-manage validate` reported exactly 12 violations: all `sha256` field, on the 11 reverted scripts + `PerlConventions.pm`. No `shebang`, `use_utf8`, `git_z`, or missing-file violations. Gate passes.
- **Deviations**: None.

### Step 5: Milestone 4a — Hash regeneration
- **Planned**: compute 12 SHAs with `sha256sum`, write to `/tmp/task-139/new-hashes.txt`, pre-splice review, then splice into `script-hashes.json`.
- **Actual**:
  - `sha256sum` on the 12 modified files; output captured to `/tmp/task-139/new-hashes.txt`.
  - Pre-splice review: each computed hash matched the `Actual:` value reported by `cwf-manage validate` exactly. All 12 paths are existing keys in `script-hashes.json` (no surprise insertions, no missing entries).
  - Spliced 12 new hashes via 12 individual Edit operations. Bumped `last_updated` to `2026-05-15`.
  - `cwf-manage validate` → `[CWF] validate: OK`.
- **Deviations**: None.

### Step 6: Milestone 4b — Inbound-reference audit
- **Planned**: update INSTALL.md PERL5OPT recommendation, `.cwf/docs/skills/security-review.md`, `docs/conventions/design-alignment.md`; recursive grep templates and docs; final repo-wide check.
- **Actual**:
  - `INSTALL.md:259` and `:311`: `-CDSL` → `-CDSLA`. Expanded the explanatory paragraph (line 264) to mention `@ARGV` decoding and the `A` flag, with Task-137 context.
  - `docs/conventions/design-alignment.md:164`: replaced `perl-git-paths.md` with two bullets pointing at `perl.md` and `git-path-output.md`.
  - `.cwf/docs/skills/security-review.md:74`: replaced the single `perl-git-paths.md` reference with two references (`git-path-output.md` for `-z`, `perl.md` for universal rules).
  - Recursive grep of `.cwf/templates/` and `.cwf/docs/` for `perl-git-paths` — zero hits.
  - Final repo-wide grep surfaced additional `-CDSL` (without `A`) hits in three live files that needed updating:
    - `.cwf/lib/CWF/Common.pm:23` — the user-facing `check_perl5opt` warning message recommended `-CDSL`. Updated to `-CDSLA`. (Required a second hash regen for this module.)
    - `.claude/skills/cwf-init/SKILL.md:149` — the installed-skill template advised users to set `-CDSL`. Updated to `-CDSLA`.
    - `t/common.t:31` — test fixture set `PERL5OPT='-CDSL'`. Updated to `-CDSLA` for narrative consistency (test still passes; the regex is `/-C/` so either value works).
  - Also updated the validator's own `use_utf8` error-message text (mentioned `PERL5OPT=-CDSL`); regenerated its hash as well.
  - `BACKLOG.md` lines 1395/1400/1404 (the active entry describing this task) left in place — these will be retired to CHANGELOG when the task lands. The two-tier policy excludes retired entries; the entry being implemented now is effectively in that frozen narrative bucket once retired.
  - Final acceptance grep: `git grep -n perl-git-paths` and `git grep -n -- '-CDSL\b'` excluding `implementation-guide/`, `BACKLOG.md`, `CHANGELOG.md` both report zero hits (exit 1).
- **Deviations**: Three live `-CDSL` hits beyond the originally-listed surfaces required an extra round of hash regeneration. Recorded above; no scope change.

### Step 7: Final validation
- **Planned**: full `prove t/`, validate, smoke tests.
- **Actual**:
  - `prove t/` → all 463 tests pass.
  - `cwf-manage validate` → OK.
  - Smoke test `backlog-manager list` → priority-grouped output as expected.
  - Smoke test UTF-8 round-trip: `backlog-manager add --title='Test → mojibake check' …` followed by `delete --exact-title='Test → mojibake check' --confirm`. BACKLOG.md showed the literal `→` arrow between the two calls (no `â†'` mojibake), and finished clean. `git status BACKLOG.md` empty.
  - **One pre-existing test required updating**: `t/backlog-manager-argv-utf8.t` (the Task-137 regression cover) was designed around the shebang carrying the `-A` flag; it explicitly deleted `PERL5OPT` from the child env to prove the shebang was the contract. Task 139 moves that contract to `PERL5OPT`, so the test had to set `PERL5OPT=-CDSLA` in the child env instead. Same assertions; just the helper's name (`run_bm_shebang_only` → `run_bm_with_perl5opt`) and its body changed. All assertions still pass.

## Blockers Encountered
None.

## Deviations Summary
1. Three additional live `-CDSL` references beyond the doc-split surfaces (Common.pm warning, cwf-init SKILL.md template, t/common.t fixture) — fixed within scope.
2. The validator's own `use_utf8` error-message string also mentioned `-CDSL` and was updated.
3. `t/backlog-manager-argv-utf8.t` semantics needed updating to match the new "PERL5OPT carries the contract" model — fixed within scope.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All 6 success criteria from a-task-plan.md met:
  - [x] 11 hardcoded shebangs reverted (verified: zero `^#!/usr/bin/perl` matches under scan roots)
  - [x] Validator inverted; `t/validate-perl-conventions.t` and `t/common.t` pass
  - [x] `perl-git-paths.md` split into `perl.md` + `git-path-output.md`, cross-referenced
  - [x] CLAUDE.md anchors both new docs; INSTALL.md updated
  - [x] `cwf-manage validate` OK; `script-hashes.json` regenerated through `sha256sum` procedure
  - [x] No live inbound link points at the deleted `perl-git-paths.md`
- [x] Design guidance in c-design-plan.md followed
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: error

error: the `security-review-changeset` helper returned `reviewed 0 files, 0 lines, anchor=4630568` because it diffs `anchor..HEAD` and the implementation changes were not yet committed at the moment of invocation. The actual working-tree diff against the anchor is 741 lines, which exceeds the 500-line review cap regardless of when run. A line-by-line subagent review of the diff is therefore out of scope; the skill's response in that case is `error: changeset exceeds 500-line review cap; split the change or perform manual review`.

Manual review of the security-relevant surface (the validator amendment is the only non-mechanical change; the other 738 lines are doc prose, doc deletion, 11 one-line shebang reverts, 14 hash-file edits, and test-fixture polarity flips — all deterministic):

- **FR4(a) Bash injection**: no new shell invocations introduced. The 11 shebang reverts move from `#!/usr/bin/perl -CDSLA` to `#!/usr/bin/env perl`; the `env` lookup is the standard POSIX form with no metacharacter surface.
- **FR4(b) Git output without `-z`**: the validator's `-z` rule is preserved unchanged. No script was added or modified to capture path-emitting git output.
- **FR4(c) Prompt injection**: CLAUDE.md anchor bullets are static literal text (no template substitution). Convention docs are prose with no `{argument}`-style fields.
- **FR4(d) Unsafe env-var handling**: this task explicitly relocates the UTF-8 I/O contract from per-script shebangs to the `PERL5OPT` environment variable. `PERL5OPT` is a Perl-defined variable read by `perl(1)` itself, not by CWF code; no new env-var read paths added.
- **FR4(e) Pattern-based risks**: the validator's positive-form shebang check is unconditional (universal across scan roots) — tighter than the prior capture-conditional check. Surface narrowed, not broadened. The hash regeneration was performed manually via `sha256sum` per the surface-don't-smooth invariant; no smoothing tool was introduced.

**Helper-limitation note**: this helper-vs-skill-ordering mismatch is worth a backlog entry — either advance HEAD before invoking, or have the helper diff against the working tree, or document the commit-first ordering as a precondition.

## Lessons Learned
*To be captured during retrospective*


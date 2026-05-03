# audit perl helpers vs perl-git-paths conventions - Implementation Execution
**Task**: 124 (chore)

## Task Reference
- **Task ID**: internal-124
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/124-audit-perl-helpers-vs-perl-git-paths-conventions
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to Finished when complete

## Actual Results

### Step 1: Test first — t/validate-perl-conventions.t
- **Planned**: Fixture-driven Test::More test mirroring t/validate-security.t. Eight TCs covering source-pragma, git-z, shebang, POD exclusion, argument-paths exclusion, allowlist, non-Perl filter.
- **Actual**: Wrote `t/validate-perl-conventions.t`; first run failed (red) because the module did not yet exist. Final test count: 12 subtests (TC-U1 through TC-U8 plus TC-U2b for the unconditional-pragma rule and TC-U4b for the `open '-|'` form). All green after Step 2.
- **Deviations**: Added TC-U2b (mid-exec) when the source-pragma rule was tightened to unconditional — see Step 4 deviation note.

### Step 2: Implement CWF::Validate::PerlConventions
- **Planned**: New module exporting `validate($git_root)`. Walks `.cwf/scripts/` and `.cwf/lib/CWF/` via File::Find, applies source-pragma / git-z / shebang assertions, hard-coded `@GRANDFATHERED` allowlist, returns violation list matching `CWF::Validate::Security`'s hashref shape (`{category, file, field, actual, expected, fix}`).
- **Actual**: `.cwf/lib/CWF/Validate/PerlConventions.pm` written with the planned shape. Heuristic regex captures four invocation forms: `qx{}`, `qx()`, backticks, and `open(...,-|,...,'git',...,'<subcmd>',...)`. POD strip via `s/^=\w+.*?^=cut\s*$//msg`; comments stripped via line-by-line `\A\s*\#`. `@GRANDFATHERED` initialised with `.cwf/scripts/hooks/stop-stale-status-detector` only.
- **Deviations**: None on the module shape itself (the rule change in Step 4 affects the source-pragma assertion's logic but not the module API).

### Step 3: Wire into cwf-manage validate
- **Planned**: Add `CWF::Validate::PerlConventions::validate($git_root)` to `cmd_validate` alongside the existing four validators.
- **Actual**: Two edits to `.cwf/scripts/cwf-manage` — the `use` block (line 32) and the `@all_violations` aggregation (line 399). `cwf-manage validate` now runs the new check on every workflow checkpoint commit (via `cwf-checkpoint-commit:53`).
- **Deviations**: None.

### Step 4: Bring non-conformant files into compliance + refresh hashes
- **Planned**: Add `use utf8;` to 9 files identified by the broad byte-grep audit; refresh sha256 entries for those + the new module.
- **Actual**: Mid-exec the source-pragma rule was widened to unconditional (every Perl file under `.cwf/` declares the pragma, regardless of whether non-ASCII bytes are currently present). Final scope: `use utf8;` added to **41** files (3 with code-literal non-ASCII + 38 ASCII-only). Hash refresh covered 34 tracked entries plus a new entry registered for `CWF::Validate::PerlConventions.pm`.
- **Deviations** — three, all documented:
  1. **Original audit overcounted (9 → 3)**: The plan's 9-file list came from `grep -P '[^\x00-\x7f]'` which counts bytes anywhere in the file. Per the convention's literal reading, `use utf8;` is only needed when non-ASCII appears in **code literals** (string/regex), not in comments or POD. The new module's strip-POD-and-comments logic correctly identified 3 files with code-level non-ASCII: `TaskState.pm`, `Versioning.pm`, `migrate-v2.1-file-order`. The other 6 files (TaskContextInference, TaskPath, MarkdownParser, Validate/Security, Validate/Config, WorkflowFiles/V21) had non-ASCII only in comments/POD.
  2. **Rule widened from spec to default-on**: User direction during exec ("we should ALWAYS use 'use utf8;'"). Memory captured at `feedback_always_use_utf8.md`. Module's source-pragma assertion was changed to unconditional; convention doc updated; TC-U2b added; final scope grew to all 41 Perl files in scope that lacked the pragma.
  3. **Out-of-scope observation**: `.cwf/scripts/command-helpers/{context-manager,task-workflow,workflow-manager}` and their `*.d/` subcommands, plus the `.cwf/scripts/hooks/` directory, are NOT registered in `script-hashes.json`. They received `use utf8;` for convention compliance but their hashes are not tracked. Whether to add them to the integrity surface is a separate question (likely a follow-up BACKLOG candidate); explicitly not addressed here to keep scope contained.

### Step 5: Update docs + remove BACKLOG entry
- **Planned**: Update `docs/conventions/perl-git-paths.md` "Existing usage" + "Pre-convention scripts" sections; remove BACKLOG entry.
- **Actual**: `perl-git-paths.md` now states the unconditional source-pragma rule and replaces the "Existing usage" list with an "Enforcement" section pointing to `CWF::Validate::PerlConventions` (the live check makes the prose list redundant). The grandfathered exception for `stop-stale-status-detector` is now described as living in the validator's `@GRANDFATHERED` allowlist. BACKLOG.md item removed.
- **Deviations**: Replaced the "Existing usage" list rather than updating it (prose lists drift; the validate-time enforcement is the source of truth).

### Step 6: End-to-end validation
- **Planned**: `prove -r t/` green; `cwf-manage validate` clean; planted-breakage smoke; runtime smoke per TC-NF1.
- **Actual**: `prove -r t/` reports 28 files / 265 tests, all green (was 264 pre-task; the +1 is the new test plus the renamed/added subtests). `cwf-manage validate` reports `[CWF] validate: OK`. Planted-breakage and runtime smoke tests are scheduled for g-testing-exec — they belong to that phase per the e-plan.
- **Deviations**: None on the f-scope items. TC-I3 / TC-NF1–3 deferred to g-testing-exec as planned.

## Blockers Encountered

None. Mid-exec rule change (source-pragma unconditional) was a clean rule widening, not a blocker — handled via memory + module logic update + test addition.

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md addressed (subject to g-testing-exec runtime smoke)
- [x] No planned work deferred without user approval
- [x] If work deferred: planted-breakage and runtime-smoke tests deferred to g-testing-exec — that's their planned home, not a deferral

## Security Review

**State**: findings

The full security-relevant changeset (778 lines staged) exceeded the 500-line cap. The bulk is 41 mechanical `+use utf8;` insertions plus a `script-hashes.json` refresh, neither of which carries security-judgement content. The review subagent was therefore invoked on a narrowed 250-line subset covering the new module + cwf-manage wiring (the actual judgement surface). Doc + test diffs were excluded as low-judgement-surface. Cap noted; manual narrowing recorded here.

Subagent output:

```
findings:

1. **Pattern-based risk in `_find_git_captures` open-pipe detection (category e)**: The regex at `.cwf/lib/CWF/Validate/PerlConventions.pm:182` requires explicit parentheses around the `open` call: `open\s*\(?...`. While this correctly matches the canonical form `open(my $fh, '-|', 'git', ...)`, it will NOT match the valid bareword form `open my $fh, '-|', 'git', ...` (without parens, without assignment). This form is less common but legal Perl. Safe here because CWF style conventions establish explicit parens as standard (evidenced in cwf-manage:98-99 and all tested cases), and the grandfathered list provides an escape hatch; audit future uses where this bareword form might be adopted without convention update. Recommend documenting this invariant inline at line 182, e.g., `# Requires parens: open(...)  not bareword form open ... – per CWF convention`.
```

**Resolution**: Fix applied — the regex was tightened to handle both `open(...)` and bareword `open ...` forms by terminating at the next `;` instead of requiring a closing paren. Two new test cases (TC-U4c, TC-U4d) lock the behaviour in for both forms, with and without `-z`. Module hash refreshed; `cwf-manage validate` clean.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

## Lessons Learned
*To be captured during retrospective.* Already-evident notes:
- Byte-grep is too coarse for "needs use utf8;" auditing — must distinguish code from comments/POD. The validator is the only reliable check.
- An end-user-facing hash refresh tool would be a security regression, but the maintainer-side refresh in this repo is itself unautomated; a maintainer-only helper (run only from the upstream source repo, gated on git remote) is a future possibility worth noting.

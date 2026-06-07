# changelog header brand name - Implementation Plan
**Task**: 184 (bugfix)

## Task Reference
- **Task ID**: internal-184
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/184-changelog-header-brand-name
- **Template Version**: 2.1

## Goal
Implement the two-part brand fix per `c-design-plan.md` (migration dropped): this-repo `CHANGELOG.md` intro edit, and an intro-scoped `CHANGELOG-005` validation warning as a regression guard.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Canonical strings (from design, user-confirmed)
- Stale: `Code Implementation Guide (CIG)`
- Canonical: `Coding with Files (CWF)`  ← all-caps CWF (current repo canonical; project-wide CwF rebrand deferred to its own backlog item)

## Files to Modify
### Primary Changes
- `CHANGELOG.md` (this repo, line 3) — literal substring swap `Code Implementation Guide (CIG)` → `Coding with Files (CWF)`. **Not hashed.**
- `.cwf/lib/CWF/Backlog.pm` — add `CHANGELOG-005` warning in `validate_changelog_tree` (line 430), scanning `@{$tree->{intro}}` only.

### Supporting Changes (same commit)
- `.cwf/security/script-hashes.json` — refresh the `CWF::Backlog` sha256 (sha256-only entry, no `permissions` key). Per hash-updates convention, same task + same commit as the edit. No new scripts; no perms change.
- `t/backlog-tree-validate.t` — extend for `CHANGELOG-005`.

## Implementation Steps

### Step 1: Validation warning `CHANGELOG-005` (TDD)
- [ ] Extend `t/backlog-tree-validate.t` first with the cases in Test Coverage below.
- [ ] In `validate_changelog_tree` (`.cwf/lib/CWF/Backlog.pm:430`), after the CHANGELOG-001 block, scan `@{$tree->{intro}}` for the literal `Code Implementation Guide (CIG)`; on hit push one
  `{ file => $path, line => 1, rule => 'CHANGELOG-005', severity => 'warning', message => "stale project name in CHANGELOG intro; expected 'Coding with Files (CWF)'" }`.
  Use a fixed package-scoped constant for the stale literal; **message uses all-caps `CWF`** (not the mixed-case the original design interface text mistakenly showed).
- [ ] Confirm the existing `--strict` warning→error promotion covers it (no extra code) and add a `--strict` test asserting escalation.

### Step 2: This-repo header fix
- [ ] Edit `CHANGELOG.md:3`: `Code Implementation Guide (CIG)` → `Coding with Files (CWF)`. Only those bytes change; "organized by task." and the rest of the line stay byte-identical.

### Step 3: Hash refresh (same commit)
- [ ] Per-file pre-refresh check: `git log <last-hash-set-commit>..HEAD -- .cwf/lib/CWF/Backlog.pm` (only this task's edit expected).
- [ ] Recompute via `sha256sum .cwf/lib/CWF/Backlog.pm` and update the `CWF::Backlog` entry in `script-hashes.json`; bump `last_updated`. (No perms key for lib modules.)

### Step 4: Validate & regression
- [ ] `prove t/backlog-tree-validate.t` then full `prove t/` for regressions.
- [ ] `.cwf/scripts/cwf-manage validate` → OK. Because CWF's own CHANGELOG intro is now canonical, `CHANGELOG-005` must **not** fire here; if it does, the header fix (Step 2) is incomplete.
- [ ] Output-level smoke test: `grep -n "Code Implementation Guide" CHANGELOG.md` returns only historical body entries (retired Task-59 mentions), never line 3.

## Code Changes
The only non-obvious part is intro-scoping the scan exactly like CHANGELOG-001 (so the body's historical "(CIG)" fragments never trip it):
```perl
my $STALE_BRAND = 'Code Implementation Guide (CIG)';
# ... inside validate_changelog_tree, after the CHANGELOG-001 H1 check:
if (grep { index($_, $STALE_BRAND) >= 0 } @{$tree->{intro}}) {
    push @errors, {
        file => $path, line => 1, rule => 'CHANGELOG-005', severity => 'warning',
        message => "stale project name in CHANGELOG intro; expected 'Coding with Files (CWF)'",
    };
}
```

## Test Coverage
**See e-testing-plan.md for the complete plan.** Headline cases (all in `t/backlog-tree-validate.t`):
- `CHANGELOG-005` warning fires when an intro line contains the stale literal.
- Silent when the intro carries the canonical `Coding with Files (CWF)`.
- Silent when only the **body** (a `## Task N` entry) contains "(CIG)" — proves intro-scoping.
- Severity is `warning` by default; escalates to `error` under `--strict`.

## Validation Criteria
**See e-testing-plan.md.** Gate: all `t/` pass; `cwf-manage validate` OK (CHANGELOG-005 silent on CWF's own now-canonical file); smoke-grep clean.

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
Steps 1–4 executed as planned. Constant `$STALE_CHANGELOG_BRAND` + `CHANGELOG-005`
added to `Backlog.pm`; header fixed; sha256 refreshed in-commit (provenance clean,
no prior committed edits since `32b3c4c`); validate OK. One deviation: TC-5 (CLI
strict-escalation) was added to `t/backlog-manager.t` rather than
`t/backlog-tree-validate.t`, because the CLI scaffolding (`make_isolated`/`run_bm`)
lives there — DRY. This extended the "Files to Modify" list by one file.

## Lessons Learned
The plan listed only `t/backlog-tree-validate.t` for tests, but a CLI-level test
case necessarily lives where the CLI harness is. When planning test files, map
each test case to the harness it requires, not just the unit under test.

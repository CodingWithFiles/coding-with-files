# Template Reference Linter for Pre-Commit Hook - Implementation Plan
**Task**: 165 (chore)

## Task Reference
- **Task ID**: internal-165
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/165-template-reference-linter-for-pre-commit-hook
- **Template Version**: 2.1

## Goal
Implement a low-false-positive checker that flags any template-filename reference in CWF source which corresponds to no known template name in any supported workflow version (v1.0/v2.0/v2.1), and wire it into the test suite as the enforcement gate.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Approach & Key Decisions
(No separate design phase for chores; decisions captured here for review.)

**D1 — Check semantics: "known in some version", not "current-only".**
Investigation (see a-task-plan risks + evidence below) showed current skills and lib modules *legitimately* reference old names for backward-compatibility (e.g. `cwf-task-plan/SKILL.md`: "Open a-task-plan.md (v2.1) or a-plan.md (v2.0)"; `TaskPath.pm`/`TaskState.pm` handle v2.0 files). The backlog's original "flag v2.0 names used in v2.1 context" goal is therefore infeasible without heavy false positives — the same token is both a valid back-compat reference and a potential stale one, separable only by intent.
**Decision**: flag a template-shaped token only when it matches *no* known name across *any* supported version. This still catches the real risk (orphaned references / typos / names removed from every version) at near-zero false-positive cost. This is a deliberate, documented narrowing from the backlog wording — **primary item for user review**.

**D2 — Authoritative name set is derived, never hardcoded.**
KNOWN = pool basenames (`.cwf/templates/pool/*.template`, strip `.template`) ∪ `CWF::WorkflowFiles::V21` names ∪ `CWF::WorkflowFiles::V20` names ∪ `CWF::WorkflowFiles` migration-map names (both `old` and `new`), unioned over every supported task type. All sources are machine-readable today.

**D3 — Grammar with boundary anchoring (kills substring artefacts).**
Token regex: `(?<![A-Za-z0-9-])[a-j]-[a-z][a-z-]*\.md(?![a-z])`. The left look-behind prevents matching tails of longer filenames (`cw`**`f-plan-reviewer-…`**, `retrospectiv`**`e-extras.md`**); the right look-ahead prevents `…\.markdown`. Verified against the live tree: anchoring removes ~all coincidental hits, leaving only genuine template-shaped tokens.

**D4 — Scan scope.** Tracked `*.md`/`*.pl`/`*.pm` via `git ls-files -z`, excluding: `implementation-guide/` (task *instances*, not references; also holds historical v2.0 task files); and `BACKLOG.md` + `CHANGELOG.md`, which `docs/conventions/cross-doc-references.md` explicitly exempts from reference rules (append-only history that quotes deprecated names verbatim — e.g. this task's own backlog entry cites `e-implementation-exec.md` as an example, and CHANGELOG narrates the `e-testing.md → f-testing-plan.md` migration). Verified against HEAD: with these exclusions the baseline is exactly the 4 source-doc hits in D6; without them the scan reports 12 (the extra 8 are intentional historical mentions in BACKLOG/CHANGELOG).

**D5 — Home & enforcement: a `CWF::Validate::*` sibling wired into `cwf-manage validate`.**
The repo already has six `CWF::Validate::<X>` modules, each exposing `validate($git_root)` → list of violation hashrefs (`{category, file, field, actual, expected, fix}`) with a thin `t/validate-<x>.t`, and each registered in `cwf-manage` (a `use` at line ~36 and an entry in the `@all_violations` list at line ~542). `PerlConventions` is the precedent: a source-*authoring* check that follows this exact pattern. **Decision**: add `CWF::Validate::TemplateRefs` (new module) + `t/validate-template-refs.t`, and register it in `cwf-manage validate` like its siblings. This makes `cwf-manage validate` the gate — and `cwf-checkpoint-commit` already runs `cwf-manage validate` on every CWF commit, so enforcement is automatic with no new infrastructure (no standalone helper, no git hook, no CI). This supersedes the backlog's "add a script to `.cwf/scripts/`" wording.
*Distinct from siblings*: `Validate::Templates` checks pool *symlink structure*; `Validate::Consistency` checks *task-tree* references under `implementation-guide/`. `TemplateRefs` checks *source-text* references against the derived known-name set — no overlap. Note: scan **raw** file text (do not reuse PerlConventions' POD/comment stripping) — the V21.pm orphans live in POD and must be caught.

**D6 — Baseline (post-exclusion) is 4 hits; fixing them is in scope.**
With D4's exclusions the check flags exactly: `.cwf/lib/CWF/WorkflowFiles/V21.pm:19-20` (`e-implementation-exec.md`, `f-testing-plan.md` — valid in no version; v2.1 uses `f-implementation-exec.md`/`e-testing-plan.md`) and `.cwf/docs/workflow/workflow-steps.md:272,319` (`f-testing-plan.md (v2.0 only)` is factually wrong; v2.0 testing was `e-testing.md` per V20.pm). This task corrects these so the gate passes. Editing `V21.pm` and `cwf-manage` (both hashed) requires same-commit `script-hashes.json` refreshes; the new `TemplateRefs.pm` module also needs a hash entry (per the hash-updates convention).

## Files to Modify
### Primary Changes
- `.cwf/lib/CWF/Validate/TemplateRefs.pm` (NEW) - `validate($git_root)` returning violation hashrefs (`{category, file, field, actual, expected, fix}`), following the sibling `CWF::Validate::*` contract. Builds the KNOWN set (D2) and runs the anchored scan (D3) over scoped files (D4).
- `t/validate-template-refs.t` (NEW) - Thin test mirroring `t/validate-perl-conventions.t`: synthetic-tree unit cases + an integration assertion that the real repo has zero violations.
- `.cwf/scripts/cwf-manage` - Register the module: add `use CWF::Validate::TemplateRefs ();` (~line 36) and `CWF::Validate::TemplateRefs::validate($git_root),` to `@all_violations` (~line 542).

### Supporting Changes (fix surfaced orphans so baseline is clean — D6)
- `.cwf/lib/CWF/WorkflowFiles/V21.pm` - Correct POD references (`e-implementation-exec.md`→`f-implementation-exec.md`; `f-testing-plan.md`→`e-testing-plan.md`).
- `.cwf/docs/workflow/workflow-steps.md` - Correct the "f-testing-plan.md (v2.0 only)" inaccuracies to reflect actual v2.0 naming (`e-testing.md`).
- `.cwf/security/script-hashes.json` - Same-commit hash refresh for the new `TemplateRefs.pm`, edited `cwf-manage`, and edited `V21.pm`.

## Distinctness Note
This check does not extend `CWF::Validate::Templates` (symlink structure) or `CWF::Validate::Consistency` (task-tree refs) — both validate different artefacts. It is a new sibling because its concern (source-text references vs. the known template name-set) is orthogonal to all existing validators.

## Implementation Steps
### Step 1: Setup
- [ ] Re-run the scoped scan (D4 exclusions) against HEAD to confirm the exact violation set is the 4 D6 hits — this is the fix target.

### Step 2: Core module — `CWF::Validate::TemplateRefs`
- [ ] Build KNOWN set from the four authoritative sources (D2), unioned over `V21::supported_types()`:
      pool basenames (`s{.*/}{}` then `s/\.template$//`), `V21::get_workflow_files`, `V20::get_workflow_files`, and `@{ workflow_file_mappings() }` (deref the arrayref; `next unless length $m->{old}` to skip the empty-`old` entry).
- [ ] **Fail-closed (gate integrity)**: assert KNOWN contains a known-minimum set — `a-task-plan.md`, `f-implementation-exec.md` (v2.1), `e-testing.md` (v2.0) — so a partial-population bug fails loudly rather than silently passing everything.
- [ ] Anchored scan (D3) over scoped files (D4) via list-form git (`open '-|', 'git','ls-files','-z',...`); read **raw** text; record violation hashrefs `{category, file, field=line, actual=token, expected, fix}` for tokens ∉ KNOWN.
- [ ] Project Perl conventions: `#!/usr/bin/env perl` n/a (module), `use strict/warnings/utf8;`, core modules only, `-z` split on `\0`, Exporter `validate`.

### Step 3: Test cases (`t/validate-template-refs.t`)
- [ ] Tree A — all references valid → zero violations.
- [ ] Tree B — one genuine orphan (`z-bogus.md`-style), one back-compat name (`a-plan.md`, valid), a suffix decoy (`retrospective-extras.md`), and a compound decoy (`f-implementation-exec-audit.md`) → exactly one violation (the orphan); decoys and back-compat name not flagged.
- [ ] Out-of-scope decoy: a `BACKLOG.md`/`CHANGELOG.md` containing an orphan token → not flagged (D4 exclusion).
- [ ] Integration: `validate($real_repo_root)` → zero violations (after Step 4).

### Step 4: Wire in + fix surfaced orphans (D6)
- [ ] Register `TemplateRefs` in `cwf-manage` (use line + `@all_violations` entry).
- [ ] Correct `V21.pm` POD + `workflow-steps.md` references.
- [ ] Refresh `script-hashes.json` for `TemplateRefs.pm`, `cwf-manage`, `V21.pm` (same commit).

### Step 5: Validation
- [ ] `prove t/validate-template-refs.t` green.
- [ ] Full `prove t/` (or representative subset) → no regressions.
- [ ] `.cwf/scripts/cwf-manage validate` clean (new check passes; hash refresh correct).

## Code Changes
Crux is the KNOWN-set derivation and the anchored scan; illustrative only (final form in f-exec). Corrections from plan review applied: basename-strip the pool glob, deref the `workflow_file_mappings()` arrayref, skip the empty-`old` entry, assert a known-minimum (not just non-empty), and return violation hashrefs.
```perl
# KNOWN = pool ∪ V20 ∪ V21 ∪ migration-map, over all task types
my %known;
for (glob "$git_root/.cwf/templates/pool/*.template") {
    s{.*/}{}; s/\.template$//;          # basename, drop .template -> "a-task-plan.md"
    $known{$_}++;
}
for my $type (CWF::WorkflowFiles::V21::supported_types()) {   # V20 has no supported_types(); reuse V21's
    $known{$_}++ for @{ CWF::WorkflowFiles::V21::get_workflow_files($type) };
    $known{$_}++ for @{ CWF::WorkflowFiles::V20::get_workflow_files($type) };
}
for my $m (@{ CWF::WorkflowFiles::workflow_file_mappings() }) {  # returns arrayref of {old,new}
    $known{$m->{old}}++ if length $m->{old};                    # skip empty-old migration entry
    $known{$m->{new}}++;
}
# fail-closed: a partial-population bug must fail the gate, not silently pass everything
for my $must (qw(a-task-plan.md f-implementation-exec.md e-testing.md)) {
    die "[CWF] Validate::TemplateRefs: KNOWN missing '$must'\n" unless $known{$must};
}

# anchored token scan, per scoped source file (raw text, line-numbered)
while ($line =~ /(?<![A-Za-z0-9-])([a-j]-[a-z][a-z-]*\.md)(?![a-z])/g) {
    next if $known{$1};
    push @violations, { category => 'template-ref', file => $rel, field => $.,
                        actual => $1, expected => 'a known template name',
                        fix => 'Use a current template name or remove the stale reference.' };
}
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

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
Plan review caught two snippet bugs (arrayref deref, glob directory-prefix) and the BACKLOG/CHANGELOG false-positive scope gap before exec. Executing the proposed scan against HEAD at plan time would have sized the baseline correctly (4, not the initially-claimed 2) without relying on review.

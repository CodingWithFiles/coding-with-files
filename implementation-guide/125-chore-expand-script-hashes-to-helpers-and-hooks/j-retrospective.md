# expand script-hashes to helpers and hooks - Retrospective
**Task**: 125 (chore)

## Task Reference
- **Task ID**: internal-125
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/125-expand-script-hashes-to-helpers-and-hooks
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-03

## Executive Summary
- **Duration**: 1 session of active work (estimate: 1 session; variance ~0%).
- **Scope**: planned 12 new manifest entries → final 17 (added 5 POSIX shell helpers under user direction during d-plan review) + 4 in-place permissions-drift fixes (`0755` → `0500`); planned coverage test delivered with 4 subtests.
- **Outcome**: SHA256 integrity surface now covers 100% of executable files under `.cwf/scripts/command-helpers/**` (top-level + every `*.d/`) and `.cwf/scripts/hooks/`. `cwf-manage validate` reports zero violations (the four pre-existing perms warnings are also gone). `t/validate-security-coverage.t` is a permanent regression guard against future helpers slipping out of the manifest.

## Variance Analysis
### Time and Effort
- **Estimated**: 1 session, all phases (planning + implementation + testing + retrospective).
- **Actual**: 1 session, completed in the same sitting after Task 124 closed.
- **Variance**: ~0%. The task is mechanical (hash registration + a small test), as predicted.

### Scope Changes
- **Additions**:
  - 5 POSIX shell helpers added to the inventory (`cwf-find-task-numbering-structure`, `cwf-load-{autoload-config,existing-tasks,project-config,status-sections}`). User direction during d-plan review: every executable script under the relevant directories should be tracked, regardless of language.
  - 4 perms-drift fixes folded in (`cwf-set-status`, `migrate-v2.1-file-order`, `task-context-inference`, `task-stack` lowered from recorded `0755` to `0500`). User direction: default to `0500` (minimum bits that allow execution) unless higher would be required.
  - Backlog item added: "Audit Perl-vs-Bash helper scripts and migrate where feasible" (Medium priority). Now that all helpers are tracked, the language split is the next thing worth re-examining.
- **Removals**: none.
- **Impact**: 12 → 17 entries, plus 4 perms updates, plus 1 BACKLOG add. No timeline impact (still single-session).

### Quality Metrics
- **Test coverage**: 100% of executable files under tracked directories (TC-C1 22 + TC-C2 7 + TC-C3 2 = 31 files, all registered).
- **Tier coverage**: planted-byte-flip verified on all four tiers — top-level Perl trampoline, `.d/` subcommand, hook, POSIX shell helper.
- **Defect rate**: zero. All 17 hashes captured cleanly on first attempt; coverage test went RED before splice and GREEN after with no rework.
- **Regression baseline**: 28 files / 267 tests → 29 files / 271 tests (delta exactly +1 file +4 subtests, as planned).

## What Went Well
- **RED-before-splice demonstration** worked exactly as designed. Wrote the test first, ran it pre-splice (17 missing entries flagged across TC-C1/C2/C3), then spliced and confirmed GREEN. TC-U1 from e-testing-plan was directly executed during f-phase rather than treated as a thought experiment.
- **Min-bits permission semantics in `Validate::Security`** let us standardise every new entry on `0500` even though on-disk perms are `0700`. The actual-vs-recorded check is `(actual & expected) != expected`, so `0700 & 0500 == 0500` passes. No on-disk chmod needed; all 17 new entries plus 4 drift fixes share one recorded value.
- **Hash-key shape `<parent>.d/<sub>` worked without code changes**. Read of `lib/CWF/Validate/Security.pm:76` confirmed the validator iterates `sort keys %file_entries` without parsing keys, so embedded `/` and `.` characters are a non-issue.
- **Bundled scope-expansion commit (596f67c)** kept history readable. When the user expanded 12 → 17 + folded in perms drift + added the BACKLOG item, all three changes flowed from one decision and were committed together rather than as three separate edits.
- **/simplify pass after g-phase** caught real duplication (TC-C1 and TC-C2 each `opendir`'d the same root with similar filter logic). Refactor consolidated to one walk + partition, swapped a regex `rel_to_repo` for `File::Spec->abs2rel` matching `CWF::Validate::PerlConventions`, and dropped a what-not-why comment. Net -47/+28 lines, all tests still green.

## What Could Be Improved
- **First task-workflow create call had wrong destination** (passed `--destination="implementation-guide"` instead of the full task-dir path); files landed in the wrong place and had to be moved. Trivial process error; not a recurrence pattern but worth noting.
- **`cwf-checkpoint-commit` first-call argument-order mistake** at the start of the session — the script printed the usage line, no harm done. Reading the helper's own usage output is faster than re-reading `checkpoint-commit.md`.
- **Pre-existing perms warnings noisy during a-d-e phases**: `cwf-manage validate` reported 4 `[SECURITY] permissions` violations on every checkpoint commit until the f-phase splice. Expected (the JSON wasn't updated yet) but visible in the validate output for those three checkpoints. Folding the perms-drift fix into the same task removed them in one go; doing it as a separate task would have left the warnings flickering across both tasks.

## Key Learnings
### Technical Insights
- **Min-bits semantics are the right default** for `permissions` in the manifest. Recording `0500` (owner r+x) is the loosest-but-still-sound floor: actual perms can be `0500`, `0700`, `0750`, etc., and the check still passes. Higher recorded values (e.g. `0700`, `0755`) only buy false precision and create drift if the file's actual perms ever lower. The 4 entries this task fixed had drifted because their on-disk perms were lowered without updating the manifest.
- **The integrity manifest is now a coverage surface, not just a hash list.** Before this task, an executable script under `.cwf/scripts/command-helpers/` could exist without ever being checked. The new coverage test makes registration mandatory for any future helper or hook — `prove -r t/` fails if a file is dropped without an entry. This shifts the trust boundary from "files we happened to register" to "every executable file in the tracked directories".
- **No shebang filter** in the coverage test. The original 12-file inventory was Perl-only; the user's "all scripts" direction made the test language-agnostic. Walker filters on regular-file + non-symlink only — anything executable counts. POSIX shell, Perl, future bash/python helpers all get the same treatment.

### Process Learnings
- **Run the meaningful-test demonstration during f-phase, not just describe it in e-plan.** TC-U1 in e-testing-plan said "test must be RED before splice"; actually running it pre-splice (and recording the 8/7/2 fail counts in g-exec) is what proves the assertion. Otherwise it's an aspirational claim.
- **`/simplify` belongs on the task branch as a post-g cleanup, not folded back into f**. The squash will collapse it; the per-phase checkpoints branch preserves the cleanup as its own commit for archaeology.
- **No-heredocs / no-inline-scripts rule held**: `compute-hashes.pl` and `check-json.pl` written via Write tool to `/tmp/task-125/`, then run from there. The `printf '\n# planted\n' >> file` pattern for planted-byte-flip is a one-token append, not an inline script — used directly in Bash without violating the rule.

## Recommendations
### Process Improvements
- **Default to `0500` for new manifest entries** unless the file genuinely needs higher bits to function. The 4 entries this task corrected drifted because the original recordings were over-precise.
- **Bundle perms-drift fixes into the next task that touches the manifest** rather than carrying them as a separate cleanup. They're trivial and the noise during checkpoint validation is otherwise visible.

### Future Work
- **Perl-vs-Bash audit** (already added to BACKLOG as Medium priority). Now that all helpers are integrity-tracked, the language split is the next thing to re-examine. The 5 POSIX shell helpers under `.cwf/scripts/command-helpers/` (`cwf-find-task-numbering-structure`, `cwf-load-*`) sit outside `CWF::Validate::PerlConventions`'s drift guard; migrating to Perl where feasible would bring them under it.
- **Lower remaining over-stated `0700` entries to `0500`**: `context-inheritance-v2.1`, `cwf-checkpoint-commit`, `cwf-manage`, `migrate-v1-to-v2.sh`, `rollback-migration.sh`, `status-aggregator-v2.1`, `template-copier-v2.1`, `validate-migration.sh`. Two-line cleanup; not in scope here, but follows the same min-bits principle. Consider folding into the next manifest-touching task rather than a standalone chore.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-03
**Sign-off**: maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- `a-task-plan.md` — single-session estimate, Low complexity, no decomposition signals.
- `d-implementation-plan.md` — final inventory (17 new + 4 drift), hash-key naming convention, scope-expansion record.
- `e-testing-plan.md` — 13 test cases (TC-U1/U2/U3/U4 + TC-I1–I5 + TC-NF1/NF2/NF3 + TC-R1).
- `f-implementation-exec.md` — execution record, no deviations, security review `no findings: empty changeset`.
- `g-testing-exec.md` — 13/13 PASS, planted-byte-flip on all four tiers verified, security review `no findings: empty changeset`.
- Commits: a26f7dc (a) → 64399d3 (d) → 7f5843c (e) → 596f67c (scope expansion) → 83874b7 (f) → f1af839 (g) → e5aab40 (/simplify cleanup).

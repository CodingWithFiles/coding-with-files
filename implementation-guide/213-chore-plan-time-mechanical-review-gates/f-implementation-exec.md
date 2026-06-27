# Plan-time mechanical review gates - Implementation Execution
**Task**: 213 (chore)

## Task Reference
- **Task ID**: internal-213
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/213-plan-time-mechanical-review-gates
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met (contracts confirmed: `scratch_dir` tuple, `capture_git` dies-on-nonzero, `resolve_num` returns task dir, `atomic_write_text` mode)
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Implemented" when complete

## Actual Results

### Step 1: Setup & patterns
- **Planned**: Confirm reuse contracts before coding.
- **Actual**: Verified `CWF::Common::scratch_dir` returns `($path, $kind)` (`Common.pm:113`); `run_quiet` redirects to `/dev/null` (exit-code only — unusable for capture, as plan review found); `security-review-changeset::capture_git` dies on non-zero (`:351`, unusable for `git grep`); `resolve_num` returns `{full_path}` = task **directory** (`TaskPath.pm:109`); `atomic_write_text($p,$blob,mode=>0600)` (`ArtefactHelpers.pm:54`).
- **Deviations**: None.

### Step 2-3: Helper + tests (TDD)
- **Planned**: Write `t/plan-mechanical-check.t` (red) then the helper (green).
- **Actual**: Created `.cwf/scripts/command-helpers/plan-mechanical-check` (Perl, 0500). Wrote own `capture_git_z` returning `($stdout, $exit)` — **not** `run_quiet`, **not** `capture_git` (both wrong per plan review). Symbol check uses `git grep -c -z -w -F -e <sym> -- ':!<task-dir>'`, parsed with `/\G(.*?)\0(\d+)\n/sg` (NUL-safe). `git grep` exit 1 = zero matches (no finding), ≥2 = fail-open. Path check extracts backtick tokens, rejects non-path shapes, classifies high-signal (basename exists elsewhere via `git ls-files -z`) vs advisory.
- **Empirical checks** (no fabrication): confirmed `git grep -c -z` emits `path\0count\n`; confirmed `-w` **does** match sigiled symbols like `@EXPORT_OK` (git checks boundaries at match edges, not naive `\b`) — so the Task-174 `@CWF_INTERNAL_PREFIXES` case is safe.
- **Deviations**: None material; the git-capture approach is the plan-review-corrected one.

### Step 4: Wire into pipeline
- **Planned**: plan-review.md, settings allowlist, template hint.
- **Actual**: `plan-review.md` Step 0 retitled "Pre-MAP resolvers" (0a best-practice, 0b mechanical-check) + REDUCE bullet + net-not-proof note. Added `Bash(.cwf/scripts/command-helpers/plan-mechanical-check:*)` to `.claude/settings.json`. Added a **commented** `**Deletes**:` hint to `d-implementation-plan.md.template` (a live placeholder line would be grepped literally — kept inside the comment).
- **Deviations**: None.

### Step 5: Integrity & validation
- **Actual**: helper `chmod 0500`; added `script-hashes.json` entry (sha refreshed after the dogfood fix, same commit). `cwf-manage validate`: **OK**. `prove -lr t/plan-mechanical-check.t`: **37 tests pass**. Full `prove -lr t/`: **74 files, 917 tests, all pass**. settings.json + templates confirmed **not** hash-tracked (no refresh needed).

## Dogfood smoke-test (output-level)
Ran the helper against this task's own d-plan (`--task-num=213 --plan-type=implementation`). First run surfaced two findings:
1. `path-high` on `.cwf/scripts/command-helpers/cwf-manage` — **true positive**: the literal Task-150 example quoted in the d-plan. Correct behaviour; a reviewer adjudicates "intentional example". Demonstrates the net-not-proof design.
2. `path-advisory` on `.cwf/docs/workflow/workflow-steps.md#status-values` — **false positive**: the file exists, but a markdown `#anchor` made `-e` fail. This boilerplate appears in nearly every plan, so it was fixed: strip a trailing `#fragment` before the existence test (added regression TC-11). Re-run: the false positive is gone, leaving only the true positive.

This refinement is exactly what the output-level smoke test is meant to catch — source tests alone would not have surfaced the boilerplate-anchor case.

## Files Changed
- **NEW** `.cwf/scripts/command-helpers/plan-mechanical-check` (helper, 0500)
- **NEW** `t/plan-mechanical-check.t` (TC-1…TC-11, 37 assertions)
- `.cwf/docs/skills/plan-review.md` (Step 0 resolvers + REDUCE + tradeoff note)
- `.cwf/templates/pool/d-implementation-plan.md.template` (commented `**Deletes**` hint)
- `.claude/settings.json` (allowlist entry — not hash-tracked)
- `.cwf/security/script-hashes.json` (new helper entry, same commit)
- `BACKLOG.md` (the content-triggered-best-practice-tags item parked earlier — rolled into this commit per agreement)

## Changeset Reviews (Step 8)
Branch `chore/213-...` (not main). Changeset: 13 files, 1362 lines (399 production, under the 500 cap), anchor `9a8039f`, includes uncommitted. All five reviewers launched in parallel; verdicts classified by `security-review-classify`.

### Security Review
**State**: no findings

plan-mechanical-check is list-form throughout (`open '-|'`, no shell), NUL-safe (`-z` + `split /\0/` / `/\G(.*?)\0(\d+)\n/sg`), validates CLI args (`--task-num` regex, `--plan-type` allowlist), reads no env, writes 0600 scratch. The `-e $sym --` ordering keeps a leading-dash symbol a pattern (FR4(e), TC-9). Residual FR4(c): plan substrings echoed into the findings file do not widen blast radius — plan files are already fully in the reviewer's context. No actionable concerns.

### Best-Practice Review
**State**: no findings

The only resolved sources are the golang/postgres corpora, matched solely via blanket user-global `active-tags` (the very issue parked as a BACKLOG item this commit). The changeset is Perl-only (no Go/SQL) — neither corpus applies; no divergence.

### Improvements Review
**State**: findings

Reuse is strong (shared `scratch_dir`/`atomic_write_text`/`resolve_num`/`find_git_root`; the `capture_git_z` divergence from `capture_git` is justified — `git grep` exit 1 = no-match must not `die`). One minor advisory: `read_deletes` duplicates `best-practice-resolve::read_task_tags` (labelled-CSV line parser) — the **2nd** occurrence, **below the Rule of Three**. **Disposition: accept-and-record.** Not extracted now per the reviewer's own "promote when a 3rd appears"; noted for a future shared `CWF::Common` helper.

### Robustness Review
**State**: no findings

git-grep exit codes (1=no-match→no finding, ≥2→fail-open), resolution-failure-vs-fail-open boundary, worktree-root anchoring (`find_git_root`/`find_base_dir` both on `--git-common-dir`), and option/NUL injection all handled. One latent non-blocking nit: `render` output is written `:raw` while the plan is read decoded, so a non-ASCII symbol/path could write a wide char — realistically ASCII, matches sibling-helper behaviour. **Disposition: accept (latent nit, sibling-consistent).**

### Misalignment Review
**State**: no findings

Helper, test, doc, template, and config edits reuse `best-practice-resolve`, the shared libs, the git-path-output convention, and the sibling test scaffolding; no reinvention or convention drift. The `git -C` use in fixtures is the established test-suite pattern, not the interactive-Bash anti-pattern.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] Requirements/design phases N/A for a chore
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 213
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Dogfooding the helper on its own d-plan caught a markdown-anchor false-positive that source tests missed; empirical verification (not citation) confirmed `git grep -w` matches sigiled symbols. See `j-retrospective.md`.

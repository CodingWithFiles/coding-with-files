# Reject overlong task slugs - Retrospective
**Task**: 119 (feature)

## Task Reference
- **Task ID**: internal-119
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/119-reject-overlong-task-slugs
- **Template Version**: 2.1
- **Retrospective Date**: 2026-04-29

## Executive Summary
- **Duration**: <1 day actual (estimate: ~2–3 hours from a-task-plan.md). On the lower end of the estimate.
- **Scope**: Delivered exactly the planned scope — `template-copier-v2.1` validates slug length and rejects overlong / empty slugs with `[CWF] ERROR:`; both SKILL.md files updated to drop the truncate instruction; 8 unit tests added; hash refreshed. One mid-implementation simplify pass tightened two minor smells. Two adjacent refactors (boy-scout `print STDERR + exit` → `die_msg` migration; lifting `die_msg` into `CWF::Common`) were explicitly deferred and tracked as backlog items.
- **Outcome**: Success. All 17 test cases pass; `cwf-manage validate` clean; FR3 / FR4 / FR5 verified by grep / status-aggregator.

## Variance Analysis

### Time and Effort
- **Estimated**: ~2–3 hours total (a-task-plan.md "Original Estimate"). No per-phase breakdown was provided.
- **Actual**: Phases ran sequentially in a single working session. Plan→retrospective spanned roughly two work-units; the longest single phase was design (driven by the plan-review subagents catching the `do`-load issue) and implementation-exec (4 sequential `Edit`s + hash refresh + test run).
- **Variance**: On-estimate or slightly under. The plan-review subagents added a phase to design but saved an iteration in implementation-exec by surfacing the `do`-load issue before any code was written.

### Scope Changes
- **Additions**:
  - **Empty-slug rejection** — added during c-design (Decision 6 + Robustness F2). Without it, `"!!!"` slugifies to `""`, passes the `>50` guard, and creates absurd path stubs like `1-feature-`. Marginal cost; clear correctness improvement.
  - **Leading/trailing hyphen strip in `generate_slug`** — added during c-design (Improvements F3). `"---foo---"` previously slugified to `"-foo-"`; now produces `"foo"`. Free in cost (two regex lines), removes a latent edge case.
  - **`sub main { } main() unless caller();` refactor** — required for the test pattern to work. Surfaced by Robustness review during d-implementation-plan. Without it the unit tests fail on `do`-load before any assertion runs.
- **Removals**:
  - **Dual validation (description + destination basename)** — earlier draft of c-design validated both. Plan-review (Improvements F1) flagged this as defensive duplication: `--description` is a required parameter, the description-derived slug is checked first, so the destination is never reached when the description fails. Single check is sufficient.
- **Impact**: Net additive but small (a few lines + two test cases). No timeline impact.

### Quality Metrics
- **Test Coverage**: 17/17 test cases pass. New file adds 8 unit tests (`prove t/` 246 = 238 baseline + 8). All five FRs and all named NFRs covered.
- **Defect Rate**: Zero defects found in testing-exec. The /simplify pass after testing-exec found two minor code smells (redundant `$limit` local; redundant `generate_slug` call); both fixed in commit 78a16a5 without regressing any test.
- **Performance**: O(1) per task creation; not a quality gate. The /simplify pass eliminated one duplicate `generate_slug` call per invocation — measurable only in pedantic profiling, but cleaner code.

## What Went Well
- **Plan review caught a critical defect early.** The 3-subagent map/reduce review during d-implementation-plan flagged the `do`-load issue (top-level execution dies on empty `@ARGV` before tests can override `die_msg`). Without that, the test file would have failed during implementation-exec and prompted a panicked "fix the script's main pattern" round-trip mid-coding. Caught in planning, fixed in design, no rework.
- **Dogfooding the new constraint.** Task 119's own slug (`reject-overlong-task-slugs`, 26 chars) was deliberately short — exactly the user-facing recovery action the error message tells future users to take. The first attempt picked an overlong description and got correctly truncated; the user caught it and the slug was redone.
- **Empty-slug edge case caught in design.** Robustness review surfaced the `"!!!"` → `""` case before it was a bug. Bundled into the same die_msg helper with a separate distinct error message.
- **TDD inverted the validation.** Writing the test first, watching it fail for the *expected* reason (top-level execution dying on `do`-load), then implementing the `main() unless caller();` refactor, then watching it pass — this is the canonical TDD loop and it actually executed cleanly.

## What Could Be Improved
- **First attempt at the task slug was overlong** (the very thing this task fixes). Slugged to `error-on-overlong-slugs-instead-of-silent-truncati` — recreated with `"reject overlong task slugs"`. Lesson: when the task itself constrains a system, dogfood the constraint *during task creation*, not after the slug has been silently truncated. The fix this task ships would have surfaced the overrun immediately.
- **Mid-task /simplify revealed two smells that should have been written cleanly the first time.** The redundant `$limit = SLUG_MAX_LEN` local came from the design-doc pseudocode (which used the local because of the `use constant` interpolation footnote in Decision 5). Inlining `. SLUG_MAX_LEN .` was always available; design pseudocode pre-committed to the verbose form. The redundant `generate_slug` call was a missed read of `construct_destination`; checking *all* call-sites of `generate_slug` should have been part of d-implementation-plan's "Files to Modify" pass.
- **Bash composition reflex tripped during testing-exec.** A `find … | head | xargs -I{} ls -la` was issued for what was a one-line glob. Same anti-pattern Task 118 was supposed to inoculate against. Memory updated; bash-habit still leaks.

## Key Learnings

### Technical Insights
- **`use constant` + double-quoted-string interpolation**: `"...$LIMIT..."` won't interpolate; need `"..." . LIMIT . "..."` or sprintf. Documented inline in c-design Decision 5; encountered live in /simplify when inlining `$limit`.
- **`do $SCRIPT` test pattern requires `main() unless caller();`**: any script with bare top-level execution will die on test load if it has required-param checks. The Tasks 115/116 pattern works only when the script wraps top-level in a sub. Worth codifying as a CwF testability convention for new helper scripts.
- **Caching `generate_slug`'s output through `parse_parameters` → `construct_destination`** uses an optional 2nd-argument pattern that defaults to recomputing — preserves the function's standalone usefulness without leaking caching state into `%params`.

### Process Learnings
- **Plan-review subagents earn their keep.** The `do`-load gotcha and the empty-slug edge case were both caught by the design-phase plan-review, before any code was written. Skipping that step (still tempting on small tasks) would have cost an iteration.
- **`--simplify` is a real second pass, not a rubber stamp.** Two real findings on a 60-line diff. Worth running on every implementation-exec output, not just complex ones.
- **Out-of-scope decisions need explicit follow-ups in BACKLOG.md.** Decision 3 deferred two related refactors (boy-scout `print STDERR + exit` audit; lifting `die_msg` to `CWF::Common`). Captured in BACKLOG; without that capture they vanish.

### Risk Mitigation Strategies
- The original a-plan called out the LLM-side pre-truncation risk in cwf-new-task SKILL.md as a Medium-priority risk. Mitigation (rewriting the SKILL.md slug instruction) was applied, and TC-14's grep confirms zero remaining "truncate 50 chars" instructions.

## Recommendations

### Process Improvements
- Add a CwF testability convention: every new helper script that has top-level execution should wrap it in `sub main { ... } main() unless caller();` so it's `do`-loadable from tests. Consider documenting alongside the existing Tasks 115/116 test pattern.
- During d-implementation-plan's "Files to Modify" pass, explicitly grep for *all* call-sites of any function being modified, even when only one site is being changed. Would have caught the redundant `generate_slug` call ahead of /simplify.

### Tool and Technique Recommendations
- The `*main::die_msg = sub { die ... }` symbol-table override + `eval{}` test pattern continues to be the cleanest way to test scripts that exit on error. Now used in three test files (`cwf-manage-check-clean-tree.t`, `cwf-manage-resolve-source.t`, `template-copier-slug-validation.t`).
- Continue running the 3-subagent plan-review on every design and implementation plan. Subagents need the inline rubric from Task 118 to follow tool-selection conventions; the convention doc alone isn't enough (memorialised in the Task 118 retrospective).

### Future Work
- **Boy-scout audit**: migrate the remaining `print STDERR "Error: ..." + exit N` blocks in `template-copier-v2.1` to `die_msg`. Adds to BACKLOG.
- **Extract `die_msg` to `CWF::Common`**: both `cwf-manage` and `template-copier-v2.1` now have identical copies. A shared module deduplicates and gives a single error-prefix convention. Adds to BACKLOG.
- **Codify the `main() unless caller();` testability convention** in `docs/conventions/` (or wherever the Tasks 115/116 test pattern is documented). Adds to BACKLOG.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest fast-forward merge to main
**Blockers**: None
**Completion Date**: 2026-04-29
**Sign-off**: Matt Keenan / Claude

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Workflow files a-j in this directory (planning, requirements, design, implementation plan + exec, testing plan + exec, rollout, maintenance)
- Test file: `t/template-copier-slug-validation.t`
- Pre-squash branch: `feature/119-reject-overlong-task-slugs` (will be archived as `checkpoints/119-…` per CwF convention)
- Squashed commit on main: pending human-driven ff merge after this retrospective

# cwf-manage validate and CWF::Validate module suite - Retrospective
**Task**: 64 (feature)

## Task Reference
- **Task ID**: internal-64
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/64-cwf-manage-validate-and-cwf-validate-module-suite
- **Template Version**: 2.1
- **Retrospective Date**: 2026-02-18

## Executive Summary
- **Duration**: 1 session (estimated: 2-3 sessions — under estimate)
- **Scope**: Delivered as planned; one scope addition (fixing pre-existing bugs found by the validator itself during first run)
- **Outcome**: Full success. `cwf-manage validate` exits 0 on a clean repo, exits 1 with actionable violation output on a broken one. All 25 test cases pass.

## Variance Analysis

### Time and Effort
- **Estimated**: 2-3 sessions
- **Actual**: 1 session (resumed from previous context)
- **Variance**: Under estimate. The four modules were structurally similar (same violation struct, same scan pattern) so writing each was faster than anticipated once the first was done.

### Scope Changes
- **Additions**:
  - Fixed unclosed ` ```perl ` code fence in task 37 `c-design-plan.md` (discovered by the workflow validator on first run)
  - Fixed `source-management` key missing from this repo's own `cwf-project.json` (discovered by the config validator)
  - Fixed `chmod 0755` on three scripts whose recorded permissions didn't match disk (`task-context-inference`, `task-stack`, `migrate-v2.1-file-order`)
  - Added TC-20b: extra test confirming lib files without `permissions` key skip the permissions check
- **Removals**: None — all planned milestones delivered
- **Impact**: Scope additions were all direct fixes found by the new tooling validating itself. Net effect: the tool worked immediately on first use.

### Quality Metrics
- **Test Coverage**: 25/25 planned + 1 unplanned test cases, all PASS
- **Defect Rate**: 0 bugs found during testing (all issues caught and fixed during implementation)
- **perlcritic**: 3 violations found on first run (RequireBriefOpen ×2, ProhibitLeadingZeros ×1), all fixed

## What Went Well

- **Self-validating first run**: Running `cwf-manage validate` on this repo immediately surfaced three real problems (config key, code fence, permissions). The tool validated itself on its first use — a strong signal the detection logic is correct.
- **Module structure**: The violation hashref format `{ category, file, field, actual, expected, fix }` made output consistent across all four modules and trivial to aggregate in `cwf-manage`.
- **Empty import pattern**: Using `use CWF::Validate::Config ()` (empty import) and fully-qualified calls avoids symbol collision cleanly — worth standardising for future multi-module scripts.
- **Permissions design decision**: The decision to skip the permissions check when the `permissions` key is absent from the JSON entry (rather than defaulting to `0500`) was the right call — it eliminated false positives for lib files without any special-casing.
- **Test harness**: Unit tests with `File::Temp` temp dirs give fast, isolated, repeatable tests without touching the real repo.

## What Could Be Improved

- **Inline tests not in `t/`**: The unit tests written during testing exec were inline `perl -e` heredocs. They work but aren't reusable via `prove`. The formal `t/` suite needs proper `.t` files for all four modules — and indeed for all CWF Perl modules, most of which have no tests at all (only `t/task-state.t` exists, and it uses the obsolete `.cig/lib` path). Added to backlog.
- **perlcritic RequireBriefOpen**: The pattern of opening a filehandle and iterating over it in a while loop is natural Perl, but perlcritic objects if the scope is more than ~9 lines. The workaround (slurp into array then iterate) works but is slightly less idiomatic. A team-level `.perlcriticrc` that disables this specific policy for library code may be worth considering.
- **Security module permissions logic**: The current logic checks `(actual_perms & min_perms) == min_perms` — a minimum-permissions check. This means a file with `0777` passes a `0500` check. That's intentional (more permissive than required is fine), but it's worth documenting explicitly in the module.

## Key Learnings

### Technical Insights
- **Unclosed code fences cause silent parser failures**: An unclosed ` ```perl ` at line 112 of a 170-line file made the parser treat the final 60 lines (including `## Status`) as inside a code block. This is impossible to detect by eye when reviewing diff hunks. The workflow validator catches it automatically.
- **Code block tracking is essential for any Markdown parser**: Any tool that extracts content from `.md` files must track ```` ``` ```` fence state. Omitting it will produce false negatives on files with code examples that happen to contain the target pattern.
- **`Digest::SHA` over `sha256sum` backtick**: Using the core `Digest::SHA` module for hashing avoids shell subprocess overhead, portability issues, and perlcritic complaints. No external dependency required.

### Process Learnings
- **The validator found its own integration target's bugs**: On first run, `cwf-manage validate` immediately found a real gap in `cwf-project.json` (missing `source-management`) and a genuine document bug in task 37. This validates the core thesis: deterministic validation catches things LLM-driven heuristic checks miss.
- **`t/` suite gap is a real risk**: Writing tests as inline heredocs works for one-off verification but doesn't accumulate into a reusable suite. Any module that doesn't have a `.t` file is effectively untested from the perspective of CI or a new contributor running `prove t/`. This gap should be closed systematically.
- **Feature templates with rollout/maintenance are overkill for internal tooling**: h-rollout.md and i-maintenance.md were boilerplate for this task. It would save time to detect "internal tooling" tasks and skip or stub those phases automatically.

### Risk Mitigation
- **Risk: Validators too strict → friction on every skill run** — Mitigated well. Config validator returns empty list when no config file exists (pre-init is valid). Workflow validator only checks files in `implementation-guide/` task dirs, not all `.md` files. Consistency validator skips branch check for finished tasks.
- **Risk: Format variation (v1.0/v2.0/v2.1 coexist)** — Mitigated by accepting both `## Status` and `## Current Status` in the workflow validator, and not requiring any field that was only introduced in v2.1.

## Recommendations

### Process Improvements
- **Add `prove t/` to the checkpoint-commit guard**: Once `.t` files exist for all modules, `prove t/` should run before `cwf-manage validate` in the checkpoint commit step. This catches regressions before they're committed.
- **Stub rollout/maintenance for internal tasks**: Consider a task type (e.g. `internal-feature`) that omits h and i from the template pool, or a skip signal in the template that auto-marks them Skipped.

### Future Work
- **Expand `t/` test suite** (added to backlog, High priority): Migrate `t/task-state.t` to `.cwf/lib`, add `.t` files for all four `CWF::Validate::*` modules, then audit remaining 10 library modules
- **Integrate `cwf-manage validate` into CI** (when CI exists): The exit codes are CI-ready — exit 0 for clean, exit 1 for violations
- **Add `cwf-manage validate --fix` mode** (future): For mechanical fixes (chmod, Status update), a `--fix` flag could apply them automatically

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None
**Completion Date**: 2026-02-18

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Implementation: `.cwf/lib/CWF/Validate/Config.pm`, `Workflow.pm`, `Consistency.pm`, `Security.pm`
- Entry point: `.cwf/scripts/cwf-manage` (`validate` subcommand)
- Integration: `.cwf/docs/skills/checkpoint-commit.md` (step 4), `.claude/skills/cwf-security-check/SKILL.md`
- Security registry: `.cwf/security/script-hashes.json` (4 new entries + cwf-manage hash update)
- Side-fixes: `implementation-guide/37-.../c-design-plan.md` (unclosed fence), `implementation-guide/cwf-project.json` (source-management key)

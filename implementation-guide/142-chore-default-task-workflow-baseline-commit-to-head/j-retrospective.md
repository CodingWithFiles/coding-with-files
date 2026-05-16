# default task-workflow baseline-commit to HEAD - Retrospective
**Task**: 142 (chore)

## Task Reference
- **Task ID**: internal-142
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/142-default-task-workflow-baseline-commit-to-head
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-16

## Executive Summary
- **Duration**: ~0.5 day (estimated: ~0.5 day; on-target).
- **Scope**: Identical to a-task-plan. No additions, no descopes. Option 1 (helper resolves HEAD when flag absent) chosen at d-plan time; preserved through exec.
- **Outcome**: Successful. `/cwf-new-task` and `/cwf-new-subtask` SKILL examples no longer contain `$(git rev-parse HEAD)`; the per-invocation Claude Code permission prompt is structurally eliminated. Helper accepts both shapes (explicit SHA pass-through, omitted → HEAD). 478/478 existing tests pass; 5 new tests added.

## Variance Analysis

### Time and Effort
- **Estimated** (a-task-plan): ~0.5 day total, Low complexity.
- **Actual**: a-plan, d-plan, e-plan, f-exec, g-exec all completed in one session. Plan review caught two misalignments that were applied to d-plan before f-exec started, which cost ~5 minutes and saved a likely rework loop.
- **Variance**: On-target. Half-day estimate matched half-day actual.

### Scope Changes
- **Additions**: None.
- **Removals**: None.
- **Deferrals**:
  - TC-7 (manual "no permission prompt" smoke test) deferred to post-merge UX observation. The prompt fires at the Claude Code harness layer, not the helper layer; only a fresh `/cwf-new-task` invocation post-merge can validate it. Structurally clean by grep gate (`git rev-parse HEAD` and `BASELINE_COMMIT` both empty in `.claude/skills/`).
  - TC-6 (helper fails loud when no `--baseline-commit` outside a git repo) covered by inspection rather than executable test. Reason: the helper's `find_templates_directory` calls `git rev-parse --show-toplevel` *before* the resolver runs, so a no-repo cwd kills the helper at template lookup, not at the resolver branch. A synthetic-templates fixture would let us test this end-to-end but was judged not worth the cost — the resolver itself is unit-tested (TC-3 in `common-resolve-head-sha.t`) and the `die_msg` branch is straight-line code.

### Quality Metrics
- **Test Coverage**: 5 new tests across 2 new files — 3 unit (resolver branches: commit / empty / no-repo) + 2 integration (helper omit / helper explicit). All planned cases passing.
- **Defect Rate**: Zero post-implementation defects. One operational misstep during initial task creation (see "What Could Be Improved").
- **Performance**: N/A — single `git rev-parse HEAD` shell-out per task creation; immeasurable.

## What Went Well
- **Plan-review subagents earned their cost again.** Two distinct misalignments surfaced before f-exec: (i) the resolver belongs in `CWF::Common` next to `find_git_root`, not inline in the helper; (ii) tests should use `CWFTest::Fixtures::create_git_repo` rather than rolling a custom tempdir + chdir. Both applied; both visible in the final code; both would have been seen as rework if caught at code-review time. Continues the trend from Task 141 where plan-review caught real issues.
- **Verbatim shape-preservation for the explicit-SHA path.** The `if (defined && length) → pass-through verbatim` branch is identical in shape to the pre-Task-142 `// ''` fallback for any explicit caller. The rare expert path (`--baseline-commit=<40-char-sha>`) keeps working bit-for-bit. The change is a pure superset: behaviour is unchanged for callers who provided the flag; the new behaviour is *additional* and *only* activates when the flag is absent.
- **Hash regen via Task-135 hand-update path was friction-free.** Two files changed (`CWF::Common.pm` and `template-copier-v2.1`); `sha256sum` against both; two `Edit` calls into `script-hashes.json` keyed by entry name; `cwf-manage validate` → `OK`. No `recompute-hashes` tool exists, and the absence keeps the integrity boundary honest.
- **Single-session end-to-end execution.** Every plan/exec phase in one sitting, six checkpoint commits, no abandoned phases or context loss. The auto-flow rule (don't wait for user prompt between plan phases) worked.

## What Could Be Improved
- **`--destination` argument misread on first task-creation invocation.** The SKILL.md example block shows `--destination="{task-dir}"`; I read `{task-dir}` as the parent (`implementation-guide`) rather than the full nested path. The helper accepts both shapes (or omitting entirely — auto-constructs), but my first call dumped templates loose into `implementation-guide/`. One extra `rm` + re-invocation to recover. A-task-plan flagged this as a separate backlog candidate; recorded below.
- **Security-review subagent format compliance: 0/2.** Both the f-phase and g-phase invocations led with prose instead of the required sentinel line. The g-phase prompt was strengthened with an explicit "first non-blank line MUST begin with one of these three sentinel strings — no preamble" instruction and the subagent still led with "Actually the code works because…". This is now a 6-task pattern (137-g, 138-f/g, 139-f/g, 140-f/g, 141-f, 142-f/g; only 141-g succeeded after using the "VERY FIRST CHARACTER" formula from Task-141's retrospective). The Task-141 retrospective documents the working prompt shape (character-level instruction + explicit unacceptable-opener list); that fix is ready to fold into `.cwf/docs/skills/security-review.md`. Both BACKLOG entries ("Tighten security-subagent prompt for sentinel-line compliance"; "Enforce sentinel-first output in security-review subagent prompt") remain unresolved but their empirical case is stronger.
- **Initial security-review changeset under-included new test files.** First invocation of `security-review-changeset --phase=implementation` saw only 4 files (the modified source files) because the new `.t` files were still untracked. `git diff` doesn't show untracked files. Staged them, re-ran, got 6 files / 331 lines. Worth folding into operational habit: stage new files before running the security-review changeset, or extend the helper to surface untracked-file count in the summary line.

## Key Learnings

### Technical Insights
- **`git rev-parse HEAD` is lowercase-only on all POSIX platforms.** A plan-review subagent suggested making the SHA regex case-insensitive (`/[0-9a-fA-F]{40}/`) citing "some systems output uppercase". Verified against git documentation and current behaviour: false. Anchored lowercase regex is correct. Recorded as a rejected review finding to avoid fabrication (`feedback_no_fabricated_citations`).
- **`template-copier-v2.1`'s `find_templates_directory` runs `git rev-parse --show-toplevel` early.** This means a no-repo cwd kills the helper at template lookup *before* the resolver branch runs. The new resolver's no-repo `die_msg` is unreachable through the helper end-to-end; it only fires through `CWF::Common::resolve_head_sha` direct callers (none today, but the function is exportable). Documented as a TC-6 inspection-only coverage note.

### Process Learnings
- **Eating-our-own-dog-food worked here.** Task 142 fixes friction in `/cwf-new-task`; the friction was directly experienced during `/cwf-new-task 142 chore "…"` at the start of this session. The same loop holds at d-exec time — by next task creation, the fix is in main and the prompt disappears.
- **Plan-review subagents are a forcing function on existing-pattern reuse.** The plan originally proposed `resolve_baseline_commit` as a local function in the helper. The "Misalignment" subagent pointed at `CWF::Common::find_git_root` (which uses the exact same backtick + chomp + length-check shape) and asked: why are you adding this here? The answer was "I didn't look". The plan was amended in the same edit pass. Future-self note: when adding a `git rev-parse` shell-out, grep `CWF::Common` first.

### Risk Mitigation Strategies
- **Hard-fail over silent-fallback.** The old code path was `$vars{baselineCommit} = $params->{baseline_commit} // ''` — a silent empty-string fallback. The new code fails loud (`die_msg`) on unresolvable HEAD. Silent fallback masked the omission; loud failure surfaces it. Aligns with the `feedback_surface_security_dont_smooth` principle.

## Recommendations

### Process Improvements
- **Fold the Task-141 sentinel-compliance prompt formula into `.cwf/docs/skills/security-review.md`.** The "Your VERY FIRST CHARACTER of response must be the letter `n`, `f`, or `e`" + explicit unacceptable-opener list ("Now", "Let me", "I'll", "Looking at...") worked once (141-g) where prose-level instructions have failed in 8+ subagent calls. Two BACKLOG items already track this; Task-141's CHANGELOG note has the concrete prompt body. Worth picking up as the next chore.
- **Habit: stage new files before security-review.** Either operationally (a one-line `git add` reflex before `security-review-changeset`), or by extending the helper to print untracked-file count in its stderr summary so the under-inclusion is obvious.

### Tool and Technique Recommendations
- **`CWFTest::Fixtures::create_git_repo` is the canonical test-fixture helper.** Now used by Task 142's `common-resolve-head-sha.t`. Lifting other tests' bespoke `git init` + `git config` blocks to this helper is a small future cleanup but not urgent.

### Future Work
- **SKILL.md `--destination` ambiguity (new BACKLOG entry below).** The example block shows `--destination="{task-dir}"`. Two failure modes: (a) read as parent path → templates land loose in `implementation-guide/`; (b) helper actually auto-constructs the path if the flag is omitted entirely. Neither shape is reflected in the example. Fix shape: drop `--destination` from the example, document the auto-construct behaviour, add an "explicit path" follow-up sentence for the rare case.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-16
**Sign-off**: Maintainer (squash + merge to main pending review)

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- a-task-plan.md, d-implementation-plan.md, e-testing-plan.md, f-implementation-exec.md, g-testing-exec.md — this directory.
- BACKLOG entry being retired: "Default task-workflow --baseline-commit to HEAD (drop shell substitution from SKILL examples)" — Very High priority, identified during Task 141 setup.
- Source-of-truth code changes: `.cwf/lib/CWF/Common.pm`, `.cwf/scripts/command-helpers/template-copier-v2.1`, `.claude/skills/cwf-new-task/SKILL.md`, `.claude/skills/cwf-new-subtask/SKILL.md`, `.cwf/security/script-hashes.json`, `t/common-resolve-head-sha.t`, `t/template-copier-baseline-default.t`.

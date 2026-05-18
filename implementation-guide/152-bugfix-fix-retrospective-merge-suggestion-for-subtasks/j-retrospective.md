# fix retrospective merge suggestion for subtasks - Retrospective
**Task**: 152 (bugfix)

## Task Reference
- **Task ID**: internal-152
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/152-fix-retrospective-merge-suggestion-for-subtasks
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-18

## Executive Summary
- **Duration**: ~½ day (estimated: ~½ day, variance: 0%)
- **Scope**: Bug reported by an external CwF user — the `/cwf-retrospective` skill's Step 12 merge suggestion hardcoded `main` as the target, but for subtasks the correct target is the parent task's branch. User also asked for the `sleep 1 && git` prefix to be applied to the suggested command so it pastes cleanly into Claude Code's Bash tool. Both asks delivered; no scope expansion.
- **Outcome**: Successful. Subtask retrospectives now suggest a parent-aware merge command with the `sleep 1 && git` prefix; SKILL.md, retrospective-extras.md, and versioning-standard.md all updated; two BACKLOG follow-ups recorded (convention-doc promotion for the prefix; trunk-resolution fallback chain for non-`main` adopters).

## Variance Analysis

### Time and Effort
- **Estimated**: ~½ day total
  - Planning (a): ~30 min
  - Design (c): ~60 min
  - Implementation plan (d): ~60 min
  - Testing plan (e): ~30 min
  - Implementation exec (f): ~30 min
  - Testing exec (g): ~15 min
  - Retrospective (j): ~15 min
- **Actual**: ~½ day total. No phase materially over or under estimate.
- **Variance**: 0%.

### Scope Changes
- **Additions**: One small wording addition during f-exec — added a prose paragraph in `retrospective-extras.md` Step 12 that names the `sleep 1 && git` prefix scope inline ("Bash-tool git calls and user-facing suggested git ff merge commands only"). Rationale: the user's naming directive saved as [[feedback-sleep-git-prefix-name]] needs the scope visible at the point of use until the convention doc lands (BACKLOG follow-up #1). Flagged in f-exec.md under Step 1 deviations. Wording addition only, no behavioural change.
- **Removals**: None. Trunk-config and the `sleep 1 && git` convention-doc promotion were deliberately scoped out at design time, with BACKLOG entries.
- **Impact**: None — the addition is consistent with the design intent and the BACKLOG follow-up will eventually replace it with a single-source reference.

### Quality Metrics
- **Test Coverage**: 8/8 functional TCs PASS.
- **Defect Rate**: 0 defects found in testing exec; 0 security findings across the two exec-phase security reviews.
- **`cwf-manage validate`**: only the pre-existing `cwf-plan-reviewer-misalignment.md` permission drift (Task 149 follow-up, unrelated). No new violations introduced.

## What Went Well
- **Plan-review subagents caught the right things**. The four-agent map/reduce on both design and implementation phases produced load-bearing fixes: collapsed two redundant decisions, switched the maintainer note from invisible HTML comment to visible italic text, fixed a self-defeating verification grep that would have flagged the new example fence as a regression, and surfaced `.cwf/rules-inject.txt:4` as an unmodified-but-grep-positive site that needed allow-listing.
- **User correction loop tightened the deliverable**. The user spotted that my summary wording made it sound like the two asks were being deferred to BACKLOG when in fact only meta-architecture follow-ups were deferred. The asks themselves shipped in this task. Saved a misread.
- **Naming feedback captured as durable rule**. The `sleep 1 && git` prefix naming directive landed as a feedback memory + MEMORY.md index entry, so the next session won't re-make the "sleep 1 && convention" naming slip.
- **No new helper, no hash refresh, no script changes**. Doc-only fix kept the blast radius minimal and let `cwf-manage validate` finish cleanly (modulo the pre-existing unrelated permission drift).

## What Could Be Improved
- **Bash habit leak**: used `; echo "exit=$?"` once during TC-4/TC-5 verification (per [[feedback_no_echo_exit]]). Harness already reports exit codes — the `; echo` is superfluous and triggers blocking permissions. Re-noticed mid-task; no impact, but the habit fires on autopilot. A mechanical detector is already in BACKLOG (Task 150 follow-up).
- **Initial summary wording misrepresented scope**. When summarising "BACKLOG-deferred for promotion to a convention doc," the structure invited a misread as "the user's ask is deferred." The asks (parent-target + `sleep 1 && git`) were shipping in this task; only the *meta* (where the convention doc lives) was deferred. Future post-phase summaries should distinguish "what's landing now" from "what's noted for later" more sharply.

## Key Learnings

### Technical Insights
- `context-manager hierarchy --format=json` already exposes everything the derivation rule needs (`parent_path`, `task_type`, `task_num`, `task_slug`) — no new helper required. The retrospective skill's preamble already calls it once, so subtask cases only need one extra call.
- Branch-naming convention (`<type>/<num>-<slug>`) set by `/cwf-new-task` and `/cwf-new-subtask` is the source of truth — derive from on-disk parent directory, not by string-munging the current branch name (subtask's slug ≠ parent's slug).

### Process Learnings
- The "single source of truth" structural principle in CWF skills (SKILL.md = terse, `*-extras.md` = procedure) is well established — Steps 6/8/10 of `cwf-retrospective/SKILL.md` already followed the single-line-reference pattern. New work should mirror it rather than inlining procedure into SKILL.md. The misalignment subagent caught this.
- Plan-time hash-disclosure (per `hash-updates.md`) takes ~10 seconds — one grep — but the design plan initially deferred it to "implementation time." The misalignment subagent flagged it. Doing the grep at design time turned a vague claim into a reproducible test.

### Risk Mitigation Strategies
- **Loud-failure preserved**. The design accepts branch-existence non-verification: if a parent branch doesn't exist (deleted post-merge, never pushed), the suggested `git checkout` fails loudly on paste. Adding `git rev-parse --verify` would shift the failure earlier but not change the outcome. Surfacing > smoothing.
- **Maintainer note as visible italic, not HTML comment**. Improvements subagent caught that HTML comments are invisible in any rendered view. Visible italic note carries the FR4(e) "if ever lifted into a helper, switch to list-form `system()`" guard to future maintainers reading the doc, not just the source.

## Recommendations

### Process Improvements
- When a phase summary mixes "shipping in this task" with "deferred follow-up," lead with what's landing now; mention deferrals as a clearly-labelled coda.
- For doc-only bugfix tasks, the plan-review subagent set is still high-value — three of the eight applied fixes (gotcha-title treatment, self-defeating grep, hash-disclosure-now) wouldn't have been caught by just re-reading the plan.

### Tool and Technique Recommendations
- The `backlog-manager add --body-file=<scratch-path>` pattern (write body to `/tmp/-home-matt-repo-coding-with-files-task-NNN/` via Write tool, pass `--body-file`) honours both [[no_heredocs]] and [[tmp-paths]] cleanly. Worth standardising as the default for any multi-paragraph BACKLOG entry.

### Future Work
Already filed as BACKLOG entries during f-implementation-exec:
1. **Promote `sleep 1 && git` prefix to a referenced convention doc** under `.cwf/docs/conventions/`. Today `retrospective-extras.md` Step 12 restates the scope inline; once a convention doc exists, the Step 12 wording should reference it instead of restating.
2. **Wire trunk-resolution fallback chain** (`cwf-project.json:trunk` → `git symbolic-ref refs/remotes/origin/HEAD` → hardcoded `main`) across `retrospective-extras.md` Step 12 and `security-review-changeset` in one go.

Both are chores, Low priority, follow-ups from Task 152.

## Status
**Status**: Finished
**Next Action**: Task complete; suggest merge per Step 12 (see end of this file).
**Blockers**: None identified
**Completion Date**: 2026-05-18
**Sign-off**: The maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`
- Design: `c-design-plan.md`
- Implementation plan: `d-implementation-plan.md`
- Testing plan: `e-testing-plan.md`
- Implementation exec: `f-implementation-exec.md` (security review: no findings)
- Testing exec: `g-testing-exec.md` (8/8 TCs PASS; security review: no findings)
- Checkpoint commits on `bugfix/152-fix-retrospective-merge-suggestion-for-subtasks` (will be preserved on `…-checkpoints` branch via Step 10).

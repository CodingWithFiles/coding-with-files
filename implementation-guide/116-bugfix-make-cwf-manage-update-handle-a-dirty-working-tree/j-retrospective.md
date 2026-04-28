# Make cwf-manage update handle a dirty working tree - Retrospective
**Task**: 116 (bugfix)

## Task Reference
- **Task ID**: internal-116
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A (sibling follow-up to Task 115; both surfaced from same external-user upgrade report)
- **Branch**: bugfix/116-make-cwf-manage-update-handle-a-dirty-working-tree
- **Template Version**: 2.1
- **Retrospective Date**: 2026-04-28

## Executive Summary
- **Estimated**: 0.5–1 day, Low–Medium complexity
- **Actual**: ~1 session, ~25-line `check_clean_tree` helper, one-line call site, 3-line help-text addition, 3 unit subtests, all-pass on first integration run. Net code add to `cwf-manage`: ~30 lines.
- **Outcome**: External-user upgrade pain point #2 closed. `cwf-manage update` (and via delegation, `rollback`) now refuse to run if `.cwf/` or `.cwf-skills/` has uncommitted changes, replacing the previous opaque `git subtree` failure (subtree method) and silent `rmtree`-then-overwrite (copy method) with a single CWF-prefixed error containing the dirty paths and the recovery recipe.

## Variance Analysis

### Time and Effort
- **Estimated**: 0.5–1 day total
- **Actual**: One session — well under a day. The `/simplify` second pass on the plans was the highest-value time spent: it removed ~66 lines of plan text and translated directly into removing the `eval`-wrapper, the `@paths` parameter, the cap-overflow logic, and one-and-a-half tests. The implementation that resulted ran clean on first attempt with zero deviations.

### Scope Changes
- **Cap-overflow logic**: Originally proposed (cap at 5 entries with "(and N more)"), removed in `/simplify` pass. Show all dirty entries; typical case is 0–2 files. If "too long" complaints arise it's a polish follow-up.
- **Helper-vs-recipe split**: Originally a c-design Decision (helper terse / recipe at call site / `eval` wrapper). Removed in `/simplify` pass. Helper now calls `die_msg` directly with the complete message. Aligns with `resolve_source` and the rest of `cwf-manage`.
- **`@paths` parameter**: Originally part of the helper signature, removed in `/simplify`. One caller, one set of paths — hardcoded inside the helper.
- **Test count**: 5 unit subtests → 3 (combined dirty-tracked + dirty-untracked into one assertion; dropped cap-overflow). One smoke (TC-9 rollback) dropped — delegation verified by code review of 4 lines instead.
- **Documentation**: File-header comment duplicate dropped. `cmd_help` heredoc is the single source of truth.
- **Boy-scout**: None. Task 115's UTF-8 / `-CDSL` boy-scout already cleaned this file. Nothing else surfaced.

### Quality Metrics
- **Tests**: 3/3 unit subtests pass on first green run, 3/3 smokes pass (one fixture re-run for TC-6 — see "What Could Be Improved"), full `prove t/` 238/238 pass (Task 115's 235 baseline + 3 new).
- **Defects caught during exec**: Zero. The `/simplify`-pass plan executed verbatim.
- **Code surface**: ~25-line helper, 1 call-site line, 3-line help-text addition, 1 hash bump, 84-line test file. No new dependencies.

## What Went Well
- **`/simplify` after the first plan-review pass earned its keep loudly.** The initial design committed to a "helper terse / recipe at call site" split with an `eval` wrapper, justified by reusability for "a hypothetical `cwf-manage rollback --safe` mode." Three `/simplify` reviewers converged on the same diagnosis: speculative future-proofing producing real present-day complexity. Removing the split collapsed the helper to one `die_msg` call, eliminated the `eval` wrapper, killed the asymmetric "raw `die` not `die_msg`" contract that needed inline guard comments, and made the test prologue's `*main::die_msg` override actually meaningful (it catches the helper's die instead of being "vestigial-but-harmless").
- **TDD held the line again.** Wrote the test, ran it, got the documented `Undefined subroutine &main::check_clean_tree` red. Added the helper. 3/3 green. Wired the call site. Full suite 238/238. No retry, no debugging loop.
- **Reuse of Task 115's test prologue** worked verbatim — the `*main::die_msg` symbol-table override under `no warnings 'redefine', 'once';` saved on having to think about catching `exit` in tests. Same fixture pattern (`tempdir(CLEANUP => 1)` + `git init` + `.cwf/version` + commit) reused across both tasks, lowering the cognitive cost.
- **`die_msg`-style heredoc message** keeps the recipe near the dirty-file list with no string-building gymnastics. The user-visible output reads as one coherent paragraph: "here's what's wrong, here are the files, here's exactly what to do."
- **Branched from Task 115's tip** (linear-history convention from memory) — when 115 ff-merges, 116 ff-merges immediately after with no rebase work.

## What Could Be Improved
- **TC-6 fixture carry-over (g-testing-exec footnote).** First TC-6 attempt failed because `git stash` (without `-u`) doesn't include untracked files, so the `.cwf/foo.txt` from TC-5's setup persisted into TC-6's invocation and tripped the dirty check. Re-running TC-6 with a fresh fixture passed. Lesson: when running smokes serially in one shell session, prefer `mktemp -d` per scenario over a single fixture + cleanup attempts — cleanup is its own failure surface (especially when the thing under test is "dirtiness detection").
- **The `/simplify` reviewers were not asked to look at the plans during the first plan-review pass.** The plan-review subagents (Improvements / Misalignment / Robustness) produce useful per-phase feedback, but they don't push back on speculative design decisions like "helper-vs-recipe split for hypothetical reuse" — they tend to validate or refine the proposed shape rather than question whether it's needed at all. `/simplify` did that work in a separate pass. Worth considering: should the c-design or d-impl plan-review include a fourth subagent prompt explicitly asking "what could be removed entirely?"
- **Three plan-review subagents + three `/simplify` reviewers + one full implementation = a lot of agent budget for a 30-line bugfix.** No corrective action — the bugfix landed clean and the post-`/simplify` code is materially better. But worth noting that the ratio of review-agent-tokens to product-code-lines is high for small tasks.

## Key Learnings

### Technical
- **Speculative future-proofing translates 1:1 into present-day code.** The c-design "helper terse / recipe at call site" split looked clean on paper, but its concrete realisation was an `eval` wrapper at the call site, an asymmetric `die` vs `die_msg` contract that had to be defended in code comments, and a "vestigial-but-harmless" test override. Each of those was a real edge case waiting to bite. Collapsing back to "helper does one thing, dies the way every other helper dies" removed all of them at once.
- **`die_msg` already has the right shape for multi-line errors.** It does `print STDERR "[CWF] ERROR: @_\n"; exit 1` — a multi-line `@_` (via heredoc) flows through cleanly. No need to invent a "raw `die`" alternative for the recipe case.
- **`git stash` does not include untracked files by default.** The TC-6 fixture issue. For test fixtures, this means: build a fresh `mktemp -d` per scenario rather than reusing one with `git stash` cleanups in between.
- **List-form `open '-|', 'git', '-C', $git_root, ...`** is clean — no shell, no quoting concerns, no `quotemeta` shenanigans, and consistent with how the rest of `cwf-manage` invokes git via list-form `system`. The BACKLOG item "Replace Backtick Operators with IPC::Open3" remains valid for the older backtick-form invocations (e.g., `resolve_ref` line 98, 106) but new code can sidestep the need.

### Process
- **`/simplify` is most valuable BEFORE exec.** When the user asked "ok, call the plan wf step skills then we'll review the plans before we exec", the plans were complete but defensively over-engineered. Running `/simplify` between e-testing-plan and f-implementation-exec saved a full implementation-then-rework cycle. Memory pattern worth keeping: for any plan that introduces an `eval` wrapper or a "design separation for future use", run `/simplify` once before writing code.
- **The "branch from previous task tip when un-merged" pattern (memory-encoded as archaeological main branch development)** worked exactly as advertised. Task 115 sat un-merged on its branch; 116 branched from 115's tip; the linear-squashed-history invariant guarantees both will ff-merge in order with no conflicts.
- **`cwf-checkpoint-commit` directory affinity**: it caught me twice in this session — the previous bash invocation's `cd /tmp` left CWD outside the repo, and the next checkpoint-commit invocation failed with "no such file or directory". Lesson: always re-anchor with `cd /home/matt/repo/coding-with-files &&` after any test that changes directory, or use absolute paths when invoking helpers.

## Recommendations

### Process Improvements
- **Run `/simplify` between testing-plan and implementation-exec for every non-trivial plan.** The pattern from this task: plans complete → `/simplify` → exec on the simplified plan. Saves implementation-then-rework loops. The `/simplify` pass on Task 116 removed ~66 lines of plan text that would otherwise have produced ~25 lines of unnecessary code + ~10 lines of unnecessary tests + ~10 lines of inline-comment defending the choices.
- **Consider adding a "what could be removed entirely?" prompt to the c-design plan-review.** The current Improvements/Misalignment/Robustness trio caught the helper's signature and the cap-overflow as adjustments, not as removals. A fourth Removal-focused subagent could surface the "is this whole abstraction needed?" question without waiting for `/simplify`.

### Future Work
- **Two siblings from the same external-user report remain in BACKLOG**:
  - "Resolve cwf-project.json version drift vs .cwf/version" (discovery, Medium)
  - "Audit Perl helpers against perl-git-paths.md conventions" (chore, Medium)
  - Both filed during Task 115; neither blocked Task 116.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge
**Blockers**: None
**Completion Date**: 2026-04-28

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

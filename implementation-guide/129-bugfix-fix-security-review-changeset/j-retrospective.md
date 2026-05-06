# Fix security-review changeset construction - Retrospective
**Task**: 129 (bugfix)

## Task Reference
- **Task ID**: internal-129
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/129-fix-security-review-changeset
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-06

## Executive Summary
- **Duration**: 1 session of active work (estimated: 1-2 days; variance: well under)
- **Scope**: Final scope matched a-task-plan: closed all three BACKLOG axes (extension-only filtering, hardcoded language stack, merge-base over-inclusion) via one new helper plus baseline-recording template/SKILL changes. No additions, no removals.
- **Outcome**: Success. Helper exercised on this very branch (dogfood) — the fallback path correctly scoped the diff to task 129's own delta (`anchor=9ac3f96`, `main` tip). 13/13 new subtests PASS, 338/338 full regression PASS.

## Variance Analysis
### Time and Effort
- **Estimated**: 1-2 days total; majority in implementation + test, ~half-day for plan/design.
- **Actual**: 1 session, all phases (a → c → d → e → f → g → j) end-to-end. No idle time, no blocked phase.
- **Variance**: Under estimate. Two factors: (a) requirements phase skipped (bugfix template — not in pool for bugfix type), so the planning loop was 4 phases not 5; (b) plan-review subagents in the d-phase removed the usual rework cycle (would-be hand-coded git-ref namespace caught and replaced with the markdown-field approach during c-design review, before any code).

### Scope Changes
- **Additions**: None during exec. The "user-note about base-branch verification" in `cwf-new-task` / `cwf-new-subtask` was already in c-design (KD-5), so writing it in f-phase was plan-conforming.
- **Removals**: None. Step 7 (test) was deferred from f-phase to g-phase per the standard CWF v2.1 workflow split (impl-exec writes code; testing-exec writes the test) — this is workflow conformance, not scope reduction.
- **Impact**: None — final delta exactly matches the scope set in a-task-plan.

### Quality Metrics
- **Test Coverage**: 13 subtests covering 8 functional + 5 non-functional cases. Maps 1:1 to BACKLOG axes 1–3 (TC-F1, TC-F2, TC-F3) plus helper internals (TC-F4..F8) plus security/reliability/performance (TC-NF1..NF5).
- **Defect Rate**: Zero defects shipped. Three issues caught during development:
  - 1 helper bug (`die` → exit 255 instead of spec'd 1) caught by smoke test, fixed before commit.
  - 2 test-code bugs (TC-F7 `$w` compilation error; `git_capture` `chomp` no-op under `local $/`) caught while writing the test, fixed before commit.
- **Performance**: TC-NF5 confirms ~1s for a 200-file noisy diff — bounded by diff size, not repo size, as KD-2 promised.

## What Went Well
- **Plan-review subagents (4 parallel Explore in d-phase) materially improved the plan**: caught (a) shell-out vs Perl module API for `parse_branch`/`resolve_num`, (b) hand-rolled trunk-name regex vs `git check-ref-format --branch`, (c) symlink/FIFO/device DoS guard (`-e && -f && !-l` before `open`), (d) script-hashes.json top-level `scripts` section (not `command-helpers`). All four landed in the d-plan; zero rework in implementation.
- **Anchor design pivot during c-design review**: original c-design proposed a custom git ref namespace (`refs/cwf/task-base/<num>`). User pushback ("we're reaching into the git files and creating refs; is this correct?") triggered the markdown-field approach. Markdown is data; git refs are plumbing. The data approach is discoverable, self-documenting, requires no new namespace, no cleanup story, no `.git/` knowledge. The pivot was cheap because it happened before any code was written.
- **Dogfood of the helper itself**: f-phase smoke (`reviewed 8 files, 593 lines, anchor=9ac3f96`) and g-phase smoke (`reviewed 9 files, 1112 lines, anchor=9ac3f96`) both anchor at `main` tip via the fallback path — exactly the behaviour the design promised for in-flight tasks (whose `a-task-plan.md` lacks the new field). Validates the fallback path is not dead code.
- **`die` → `warn; exit 1;` convention discovery**: smoke-testing `--task-num='foo;bar'` returned exit 255 (Perl's `die` default), not the spec'd exit 1. Caught early, fixed by adopting the existing CWF helper convention from `cwf-checkpoint-commit:14-15`. Future helpers should follow this pattern from the start.
- **Test scaffolding caught its own bugs**: `local $/; <fh>; chomp` was a no-op (chomp uses `$/` which is undef in slurp mode) — SHA strings retained trailing `\n`, breaking `git checkout <sha>`. Switched to `s/\s+\z//` outside the slurp scope. Lesson: `local $/` and `chomp` are awkward neighbours; prefer explicit whitespace strip.

## What Could Be Improved
- **Cap-overflow in both exec phases**: f recorded 593 lines (just over cap), g recorded 1112 (well over). Both required manual threat-category walkthroughs in the wf step file. Self-reviewing the change that *is* the security-review fix is awkward — the BACKLOG entry "Quantitatively justify the security-review subagent line-count cap" should follow this task to address the cap value with the now-correctly-scoped diff in hand.
- **In-flight tasks remain on the fallback indefinitely**: tasks created before this lands have no `**Baseline Commit**:` field. Their reviews continue to use `merge-base` against trunk — same behaviour as today, no regression, but no upgrade either. A backfill helper was deferred; if a maintainer wants it, it's one-line per task.
- **Bash-habit leakage**: caught using `sed -n 'X,Yp'` for line-range reads in this session despite the existing memory rule. The Read tool with `offset`/`limit` is the correct path. No process change needed — the memory rule already exists; the lapse was attention.

## Key Learnings
### Technical Insights
- **Markdown fields beat custom git refs for per-task metadata.** A field in `a-task-plan.md` is human-readable, survives rebase of the task-plan checkpoint commit (the file content moves with the commit), needs no cleanup story, and integrates with the existing template-copier pipeline. Custom git refs would have needed a namespace, a cleanup helper, and `cwf-manage` awareness. The pivot was a simplification and a correctness win.
- **Content-based classification (shebang sniff) is bounded by diff size, not repo size.** Applying `open <:raw` + `sysread 128` to each path in the diff window is fast (~1s for 200 files in TC-NF5). The `-e && -f && !-l` guard before `open` avoids a class of DoS / surprise-target attacks (FIFO, `/dev/zero`, symlink to `/etc/passwd`).
- **`git check-ref-format --branch` is the correct trunk-name validator.** Hand-rolled regexes (`^[A-Za-z0-9_./\-]+$`) miss git-specific rules: `..`, `.`, `@{`, leading `/`, trailing `.lock`, etc. Letting git validate its own ref-format is one fork-exec but cuts the maintenance surface to zero.
- **Anchored regexes for interpreter classification need an explicit invariant.** `^(?:perl|bash|sh|...)$` is anchored at both ends. Future maintainers extending the list MUST preserve `^…$` — an unanchored alternative would match arbitrary substrings. Stated as comment in the helper source AND in the contract doc.

### Process Learnings
- **Plan-review subagents are paying for themselves.** Two consecutive tasks (128 design-alignment audit, this one) credited plan-review with catching plan defects. The phase-skip risk has been called out explicitly in `cwf-implementation-plan/SKILL.md` Gotchas and `cwf-design-plan/SKILL.md` Gotchas; both fired this session.
- **Dogfood discovery → backlog is a working loop.** Task 128's g-phase cap-overflow (1422 / 1545 lines) wasn't a process-only complaint — it surfaced *three* underlying bugs in changeset construction. The cap-as-canary mode caught a real defect class that pure-source review wouldn't have.
- **Phase-split (impl-exec writes code; test-exec writes test) is correct.** The split keeps each exec phase commit small and lets the test-writing pass run with the helper already present and exercisable. Resisted the temptation to bundle Step 7 into f-phase — phase-split paid off when test-helper bugs surfaced and were fixed locally without churning the implementation commit.

### Risk Mitigation Strategies
- **Mid-task rebase risk (KD-1 trade-off)**: explicitly accepted ("if you break it you get to keep the pieces"). CWF tasks land via squash + `git branch -f`, never via rebase onto main mid-task. The recorded SHA names the fork point; rebasing the task branch onto a newer trunk would invalidate it. No mitigation in code; documented in c-design KD-1 trade-offs and called out in cwf-new-task / cwf-new-subtask SKILL notes.
- **Symlink/FIFO/device DoS** in shebang sniff: handled by `-e && -f && !-l` guard. Prevents the helper from following symlinks to `/etc/passwd` or hanging on FIFO reads.
- **Trunk-name shell injection** via `cwf-project.json`: handled by `git check-ref-format --branch` validation before any reach-out to git. Captured as TC-NF1.

## Recommendations
### Process Improvements
- None for the workflow itself this round. The four plan-review subagents are working; the phase-split is working; `die` → `warn; exit 1;` is now the documented helper convention.

### Tool and Technique Recommendations
- **Standardise the `-e && -f && !-l` guard for any future content-sniff helper.** Document in `docs/conventions/perl-git-paths.md` if not already.
- **Consider `File::chdir`'s `local $CWD`** for tests that change directory — exception-safe, lexically-scoped. Current test uses `chdir $repo` ... `chdir $orig` which leaks cwd if a die escapes. Not a v1 concern (tests die fast and tempdirs auto-clean), but a worth-it refactor if the test scaffold grows.

### Future Work
- **Backlog**: "Quantitatively justify the security-review subagent line-count cap" — should run next so the cap is re-justified against the now-correctly-scoped diff (no more inflation from unmerged predecessors).
- **Backlog (new, low priority)**: consider a one-line backfill helper that writes `**Baseline Commit**:` into in-flight tasks' `a-task-plan.md` files. Optional; manual edit is one line.
- **Backlog (new, low priority)**: extend the shebang interpreter regex to cover `awk`, `tcl`, `make`, `gawk`, version-pinned `python3.11`. v1 list covers >95% of in-the-wild interpreters; extension is a focused follow-up.
- **Backlog (new, low priority)**: `File::chdir` adoption for test scaffolds — exception-safe cwd handling.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-06
**Sign-off**: the maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- a-task-plan.md, c-design-plan.md, d-implementation-plan.md, e-testing-plan.md (this directory)
- f-implementation-exec.md, g-testing-exec.md (this directory)
- Helper: `.cwf/scripts/command-helpers/security-review-changeset`
- Test: `t/security-review-changeset.t`
- Doc (rewritten): `.cwf/docs/skills/security-review.md`
- Commits on this branch:
  - `e80615e` Task plan checkpoint
  - `f3072f1` Design plan checkpoint
  - `aaf060b` Implementation plan checkpoint
  - `1c24032` Testing plan checkpoint
  - `a355e84` Implement security-review-changeset helper
  - `657715f` Complete implementation exec phase
  - `a2a795d` Add security-review-changeset regression test
  - `181421f` Complete testing exec phase

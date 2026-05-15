# Remove cd to git root from backlog-manager skill - Retrospective
**Task**: 138 (bugfix)

## Task Reference
- **Task ID**: internal-138
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/138-remove-cd-to-git-root-from-backlog-manager-skill
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-15

## Executive Summary
- **Duration**: 1 session; estimated <0.5 day; on-target.
- **Scope**: Documentation-only edit to `.claude/skills/cwf-backlog-manager/SKILL.md` — strip `cd "$(git rev-parse --show-toplevel)" && ` prefix from every example (×8), delete the "Mandatory pre-step / threat-model" paragraph, delete one stale Success-Criteria checkbox. No code, no tests added.
- **Outcome**: All edits applied cleanly. 9/10 tests PASS, 1 N/A. The negative test (TC-8) confirmed the design-phase claim that kernel ENOENT enforces the repo-root invariant — the cd guard was redundant noise. Security-review subagent returned a category-(e) "preserve documented reasoning" finding; declined with three-part rationale.

## Variance Analysis

### Time and Effort
- **Estimated** (a-task-plan): <0.5 day
- **Actual**: 1 session, well under 0.5 day equivalent
- **Variance**: on-target.

### Scope Changes
- **Additions**: None.
- **Removals**: None planned, none deferred.
- **Impact**: Scope held exactly to the planned three Edit-tool calls plus verification.

### Quality Metrics
- Test cases: 9/10 PASS, 1 N/A (TC-10's `cwf-manage status` requires `.cwf/version`, which is an installed-only file; intent covered by TC-9's `cwf-manage validate`).
- Defects: 0.
- Security findings: 1 (category e), declined with rationale (HTML-comment remediation is non-markdown; markdown-native remediation collapses to "undo the change"; design plan already weighed and rejected the alternative).

## What Went Well

- **Design phase pre-empted the security finding.** `c-design-plan.md` "Alternatives Considered" #3 explicitly rejected "keep a sanitised note" because it re-introduces noise to defend against a debunked threat model. When the security subagent later proposed exactly that as remediation, the rejection rationale was already in hand — turning what could have been a re-debate into a one-line decision. Concrete evidence that design-plan "Alternatives Considered" entries are not bureaucratic boilerplate.
- **The negative test (TC-8) was load-bearing.** Running the rewritten example from `/tmp` and observing exit 127 + "No such file or directory" is the *direct* runtime confirmation of the design's central claim. Beats a paragraph of reasoning. The deleted "Mandatory pre-step" paragraph could have been a couple of lines reading "we tested this — the kernel does the work" but the test is more durable than prose.
- **Plan review surfaced a real bug.** The robustness reviewer flagged that deleting lines 18-23 (paragraph only) would leave a double-blank line before `## Subcommands` (the blanks on lines 17 and 24 would collapse). Plan was updated to delete 18-24 inclusive. Without the review, the edit would have shipped with a markdown-structural defect.
- **One `replace_all` call stripped all eight prefix occurrences cleanly.** Single string match, no false positives. The d-plan's choice of `replace_all` over per-occurrence edits proved correct — saved seven Edit calls with no loss of safety because the prefix substring was unique.

## What Could Be Improved

- **`security-review-changeset` is blind to uncommitted work.** Running the helper during f-implementation-exec (before the checkpoint commit) returned `reviewed 0 files, 0 lines` — the edit was unstaged. I recorded `no findings: empty changeset` per the workflow's empty-changeset rule, which is technically correct for the helper's state but materially misleading: there *was* a changeset, just not a committed one. Caught in the testing phase where the post-checkpoint helper returned the full 88-line diff. Re-ran the subagent against the real diff and updated `f-implementation-exec.md` with the substantive review. **Backlog item already exists** ("Improve security-review-changeset feedback on empty-from-uncommitted changesets", filed in Task 136); not adding a duplicate. Task 137 hit the same issue.
- **Plan's residue grep was too broad.** d-plan specified `grep 'git rev-parse --show-toplevel'` as the residue check, expecting a single out-of-scope hit. The pattern fired on ~12 hits — every internal Perl helper that legitimately captures the git root into a variable for absolute-path argument passing. Rescoped the grep at exec time to the literal cd-prefix form `cd "$(git rev-parse --show-toplevel)"`, which left exactly one out-of-scope match (`update-cwf-skill-docs.sh:10`, a Task-40 migration shell script). Lesson: a "removal verification" grep must anchor on the *form being removed*, not on a substring shared with legitimate code paths.
- **Two subagent runs against the same diff returned different verdicts.** The g-phase subagent classified the change as `no findings` ("removes a redundant and incorrectly-documented security control"). The f-phase re-run, given identical 88-line input, classified it as `findings` (category e, "loss of invariant documentation"). Both reasonings are defensible; the difference is whether you weight "remove cargo-cult noise" or "preserve archival reasoning at the callsite" more highly. The user is the final arbiter in these cases — record the verbatim subagent output, present the trade-off, decide. Worth knowing that the review is not deterministic.

## Key Learnings

### Technical Insights
- **Relative paths are self-anchoring via kernel ENOENT.** Invoking `.cwf/scripts/command-helpers/foo` only resolves to a real file when cwd contains `.cwf/scripts/command-helpers/foo`. If it doesn't, `execve` returns ENOENT and the call is loud. This is *not* a check the helper performs — it's the kernel's path resolution behaviour at the call site. Any "cd to git root before invoking" guard at the *call site* is dead weight when the invocation path is relative. (The pattern is genuinely useful when the helper needs an absolute path passed as an *argument*, as in `cwf-init`'s `GIT_ROOT="$(...)"` line — that's a different use of `git rev-parse`.)
- **Nested-repo behaviour favours the no-cd form.** If cwd happens to be inside a different repo, the old `cd "$(...)"` form would silently `cd` into that other repo's toplevel and run whatever `.cwf/scripts/...` exists there. The new form fails cleanly with ENOENT. Removing the guard was a small *gain* in robustness, not a loss.
- **HTML inside markdown is a smell.** The security subagent suggested `<!-- ... -->` as a documentation-preservation tactic. Even setting aside the design-plan rationale, the suggestion was form-wrong: markdown documents should use markdown for content. If reasoning matters enough to preserve, write it in markdown prose; if it doesn't, don't write it. Once HTML is off the table, the only markdown-native "preserve at the callsite" approach is a regular paragraph — which is exactly the content the task deleted. The remediation collapses back to undoing the change, sharpening the decline.

### Process Learnings
- **`security-review-changeset` requires commit-then-review.** The helper diffs `anchor..HEAD` over committed history. To get a substantive review, commit the phase's work first, *then* run the helper. This task hit the same trap as Tasks 135, 136, and 137. The backlog item exists; the trap will keep biting until the helper either warns on `(committed=∅, uncommitted=∃)` or the workflow doc says "checkpoint first, review second" explicitly.
- **Design-plan "Alternatives Considered" is load-bearing.** The cleanest decisions in this retrospective trace directly to options that c-design-plan.md spelled out and rejected. When the same option resurfaces later (e.g., in a security-review finding), the rejection rationale converts a re-debate into a citation. This is the second task in a row where this pattern paid off (Task 135 also relied on it for the "no `recompute-hashes` button" decision).
- **Review judgement is not deterministic — record verbatim, decide explicitly.** Two runs of the same security-review prompt against byte-identical input returned different verdicts. Don't pretend determinism. Record the verbatim subagent output, weigh it against the task's design intent, and write down the decision with reasons. The decision *is* the record.

### Risk Mitigation Strategies
- **Negative tests are the strongest evidence.** TC-8 (run from `/tmp`, expect ENOENT) is a one-liner that empirically proves the design's central claim. Worth more than any amount of architectural reasoning. Pattern to reuse: any time a design claims "X enforces invariant Y", write the negative test that breaks Y and observe the enforcement firing.

## Recommendations

### Process Improvements
- **For removal-verification greps, anchor on the form being removed.** When a task deletes pattern X, the grep should match X's *form*, not just a substring inside X that may also appear in legitimate code. Future d-plan templates could include a one-line "your residue grep should match only the form being removed" reminder.
- **Treat security-review verdicts as inputs to decision, not as decisions themselves.** Record verbatim, weigh against design intent, decide explicitly with three-part rationale. This task's `findings`-declined-with-reasoning pattern is reusable.

### Tool and Technique Recommendations
- **The negative test for self-anchoring runtime invariants.** Whenever a design relies on a runtime invariant ("X cannot happen because Y"), include a test that *attempts* the disallowed action and verifies the failure mode (exit code, error message). Cheap to write, durable, beats prose documentation.

### Future Work
- **Investigate whether `cwf-init`'s `GIT_ROOT="$(git rev-parse --show-toplevel)"` pattern is also redundant** (Low / discovery). The helper `cwf-apply-artefacts` may already resolve the git root internally via `find_git_root()`; if so, the GIT_ROOT argument is dead weight and the cd-prefix-style cleanup logic of Task 138 may apply there too. Out-of-scope here; worth a 30-minute investigation.

## Status
**Status**: Finished
**Next Action**: Squash, then suggest merge
**Blockers**: None
**Completion Date**: 2026-05-15

## Archived Materials
- a-task-plan.md, c-design-plan.md, d-implementation-plan.md, e-testing-plan.md, f-implementation-exec.md, g-testing-exec.md in this directory.
- Edited skill: `.claude/skills/cwf-backlog-manager/SKILL.md`.
- Negative-test confirmation in `g-testing-exec.md` TC-8.
- Security-review subagent output (verbatim) in `f-implementation-exec.md` and `g-testing-exec.md`.
